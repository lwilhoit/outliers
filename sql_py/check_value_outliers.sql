
PROCEDURE Outliers
   (p_year IN NUMBER,
    p_use_no IN NUMBER,
    p_record_id VARCHAR2,
    p_prodno IN NUMBER,
    -- p_chem_code IN NUMBER,
    p_prodchem_pct IN NUMBER,
    p_site_code IN NUMBER,

    p_amt_prd_used IN OUT NUMBER,
    p_lbs_prd_used IN OUT NUMBER,
    p_acre_treated IN OUT NUMBER,
    p_unit_treated IN OUT VARCHAR2,
    p_acre_planted IN NUMBER,
    p_unit_planted IN VARCHAR2,
    p_applic_cnt IN NUMBER,

    p_comments OUT VARCHAR2,
    p_estimated_field OUT VARCHAR2,
    p_error_code OUT INTEGER,
    p_error_type OUT VARCHAR2,
    p_replace_type OUT VARCHAR2,

    p_fixed1_rate_outlier      OUT VARCHAR2,
    p_fixed2_rate_outlier      OUT VARCHAR2,
    p_fixed3_rate_outlier      OUT VARCHAR2,
    p_mean5sd_rate_outlier      OUT VARCHAR2,
    p_mean7sd_rate_outlier      OUT VARCHAR2,
    p_mean8sd_rate_outlier      OUT VARCHAR2,
    p_mean10sd_rate_outlier      OUT VARCHAR2,
    p_mean12sd_rate_outlier      OUT VARCHAR2,

    p_fixed1_lbsapp_outlier      OUT VARCHAR2,
    p_fixed2_lbsapp_outlier      OUT VARCHAR2,
    p_fixed3_lbsapp_outlier      OUT VARCHAR2,
    p_mean3sd_lbsapp_outlier   OUT VARCHAR2,
    p_mean5sd_lbsapp_outlier   OUT VARCHAR2,
    p_mean7sd_lbsapp_outlier   OUT VARCHAR2,
    p_mean8sd_lbsapp_outlier   OUT VARCHAR2,
    p_mean10sd_lbsapp_outlier   OUT VARCHAR2,
    p_mean12sd_lbsapp_outlier   OUT VARCHAR2)
IS
   v_stat_year             INTEGER := NULL;

   v_chemname              VARCHAR2(200);
   v_chem_code             INTEGER;
   v_ai_group            INTEGER := NULL;
   v_ai_group_lbsapp      INTEGER := NULL;
   v_ago_ind            VARCHAR2(1);
   v_ai_rate_type          VARCHAR2(100);
   v_lbs_ai_app_type      VARCHAR2(100);
   v_site_type            VARCHAR2(100);
   v_ai_adjuvant         VARCHAR2(1);

   v_regno_short         VARCHAR2(100);
   v_site_general        VARCHAR2(50);

   v_lbs_ai               NUMBER;
   v_amount_treated       NUMBER;
   v_gen_unit_treated   VARCHAR2(1);

   v_has_outlier_limits    BOOLEAN;
   v_ai_rate            NUMBER;           -- AI rate uses gen_unit_treated
   v_med_rate            NUMBER;          -- median rate uses gen_unit_treated
   v_fixed1               NUMBER := NULL;
   v_fixed2               NUMBER := NULL;
   v_fixed3               NUMBER := NULL;
   v_mean5sd            NUMBER := NULL;
   v_mean7sd            NUMBER := NULL;
   v_mean8sd            NUMBER := NULL;
   v_mean10sd            NUMBER := NULL;
   v_mean12sd            NUMBER := NULL;
   v_max_label_prod      NUMBER;
   v_max_label            NUMBER;

   v_ai_rate_log         NUMBER;         -- Log of AI rate uses gen_unit_treated
   v_med_rate_log         NUMBER;           -- Log of median rate uses gen_unit_treated
   v_mean5sd_log         NUMBER := NULL;
   v_mean7sd_log         NUMBER := NULL;
   v_mean8sd_log         NUMBER := NULL;
   v_mean10sd_log         NUMBER := NULL;
   v_mean12sd_log         NUMBER := NULL;
   v_max_label_log      NUMBER;

   v_fixed1_error         BOOLEAN;
   v_fixed2_error         BOOLEAN;
   v_fixed3_error         BOOLEAN;
   v_mean5sd_error      BOOLEAN;
   v_mean7sd_error      BOOLEAN;
   v_mean8sd_error      BOOLEAN;
   v_mean10sd_error      BOOLEAN;
   v_mean12sd_error      BOOLEAN;

   v_ai_lbsapp               NUMBER;           -- AI pounds per application (used in nonag records with no acre_treated)
   v_med_lbsapp            NUMBER;          -- median pounds per app
   v_fixed1_lbsapp         NUMBER := NULL;
   v_fixed2_lbsapp         NUMBER := NULL;
   v_fixed3_lbsapp         NUMBER := NULL;
   v_mean3sd_lbsapp         NUMBER := NULL;
   v_mean5sd_lbsapp         NUMBER := NULL;
   v_mean7sd_lbsapp         NUMBER := NULL;
   v_mean8sd_lbsapp         NUMBER := NULL;
   v_mean10sd_lbsapp         NUMBER := NULL;
   v_mean12sd_lbsapp         NUMBER := NULL;

   v_ai_lbsapp_log         NUMBER;
   v_med_lbsapp_log         NUMBER;
   v_mean3sd_lbsapp_log      NUMBER := NULL;
   v_mean5sd_lbsapp_log      NUMBER := NULL;
   v_mean7sd_lbsapp_log      NUMBER := NULL;
   v_mean8sd_lbsapp_log      NUMBER := NULL;
   v_mean10sd_lbsapp_log   NUMBER := NULL;
   v_mean12sd_lbsapp_log   NUMBER := NULL;

   v_fixed1_lbsapp_error   BOOLEAN;
   v_fixed2_lbsapp_error   BOOLEAN;
   v_fixed3_lbsapp_error   BOOLEAN;
   v_mean3sd_lbsapp_error   BOOLEAN;
   v_mean5sd_lbsapp_error   BOOLEAN;
   v_mean7sd_lbsapp_error   BOOLEAN;
   v_mean8sd_lbsapp_error   BOOLEAN;
   v_mean10sd_lbsapp_error   BOOLEAN;
   v_mean12sd_lbsapp_error   BOOLEAN;

   v_ai_rate_ch            VARCHAR2(100);
   v_med_rate_ch            VARCHAR2(100);
   v_max_label_ch            VARCHAR2(100);
   v_unit_treated_word      VARCHAR2(100);

   v_ai_lbsapp_ch            VARCHAR2(100);
   v_med_lbsapp_ch         VARCHAR2(100);


BEGIN
   p_comments := NULL;
   p_estimated_field := NULL;
   p_error_code := NULL;
   p_error_type := NULL;
   p_replace_type := NULL;

   -- DBMS_OUTPUT.PUT_LINE('1: use_no = '||p_use_no||'; p_amt_prd_used = '||p_amt_prd_used);

   /* Get the record type
    */
   IF p_record_id IN ('2', 'C') OR p_site_code < 100 OR
                      (p_site_code > 29500 AND p_site_code NOT IN (30000, 30005, 40008, 66000)) THEN
      v_ago_ind := 'N';
   ELSE
      v_ago_ind := 'A';
   END IF;

   BEGIN
      SELECT   site_general
      INTO     v_site_general
      FROM     pur_site_groups
      WHERE    site_code = p_site_code;
   EXCEPTION
      WHEN OTHERS THEN
         v_site_general := NULL;
   END;

   /*
   BEGIN
      SELECT   adjuvant
      INTO     v_ai_adjuvant
      FROM     chem_adjuvant
      WHERE    chem_code = p_chem_code;
   EXCEPTION
      WHEN OTHERS THEN
         v_ai_adjuvant := 'N';
   END;
   */

   BEGIN
      SELECT   mfg_firmno||'-'||label_seq_no
      INTO     v_regno_short
      FROM     product
      WHERE    prodno = p_prodno;
   EXCEPTION
      WHEN OTHERS THEN
         v_regno_short := NULL;
   END;

   /* Get chemname.
    */
   /*
   BEGIN
      SELECT    chemname
      INTO      v_chemname
      FROM      chemical
      WHERE     chem_code = p_chem_code;
   EXCEPTION
      WHEN OTHERS THEN
         v_chemname := NULL;
   END;
   */

   /*********************************************************************************
      Get outliers in rates of use (pounds AI per unit treated).
      These includes some non-ag records, when a unit treated is reported.
    ********************************************************************************/
   IF p_acre_treated > 0 THEN
      v_prod_rate := p_lbs_prd_used/p_acre_treated;

      BEGIN
         SELECT  fixed1, fixed2, fixed3, 
                 mean5sd, mean7sd, mean8sd, mean10sd, mean12sd,
                 outlier_limit, chem_code, chemname
         INTO    v_fixed1, v_fixed2, v_fixed3,
                 v_mean5sd, v_mean7sd, v_mean8sd, v_mean10sd, v_mean12sd,
                 v_outlier_limit, v_chem_code, v_chemname
         FROM    outlier_all_stats
         WHERE   regno_short = v_regno_short AND
                 ago_ind = v_ago_ind AND
                 site_general = v_site_general AND
                 unit_treated = v_gen_unit_treated;

         v_has_outlier_limits := TRUE;
      EXCEPTION
         WHEN OTHERS THEN
            v_has_outlier_limits := FALSE;
            v_fixed1 := NULL;
            v_fixed2 := NULL;
            v_fixed3 := NULL;
            v_mean5sd := NULL;
            v_mean7sd := NULL;
            v_mean8sd := NULL;
            v_mean10sd := NULL;
            v_mean12sd := NULL;
            v_chem_code := NULL;
            v_chemname := NULL;
      END;


      /* Get the most recent year from the ai_stats table;
         use that year's values to get median rates.
      BEGIN
         SELECT  MAX(year)
         INTO    v_stat_year
         FROM    ai_outlier_stats;

      EXCEPTION
         WHEN OTHERS THEN
            v_stat_year := NULL;
      END;
       */


      /*****************************************************************
      Get max label rate for this product, site, and unit treated.
      If there is no rate for this product, site, and unit,
      then take max rate for all sites for this product and unit.
      If the are no rates for this product and unit, set
      max rate = 0.
     Unit_treated in max_label_rates is either
     A (acres), C (cubic feet), or P (pounds).
     */

     /* Get the maximum label rate for products that are in table MAX_LABEL_RATES.
       Variable max_label in MAX_LABEL_RATES is product rate of use;
       we need rate of AI.
      */
     BEGIN
         SELECT   max_rate * 1.1
         INTO     v_max_label
         FROM     max_label_rates
         WHERE    prodno = p_prodno AND
                  unit_treated = v_gen_unit_treated;
      EXCEPTION
         WHEN OTHERS THEN
            v_max_label := NULL;
      END;


      /**************************************************************

      Flag a rate as on outlier by each criteria only if
      it is greater than both outlier limit and
      max label rate. That is, if max label rate
      is less than outlier limit, flag rate if it is
      greater than outlier limit.  However, if
      outlier limit is less than max label rate,
      flag rate only if it is greater than max label rate.

      Note that if any argument in GREATEST (or LEAST) is NULL
      the function returns NULL no matter what other values are
      in other arguments.
      COALESCE() returns the first non-null expression in the list.
      */
      IF v_has_outlier_limits THEN
         v_fixed1 := COALESCE(GREATEST(v_fixed1, v_max_label), v_fixed1, v_max_label);
         v_fixed2 := COALESCE(GREATEST(v_fixed2, v_max_label), v_fixed2, v_max_label);
         v_fixed3 := COALESCE(GREATEST(v_fixed3, v_max_label), v_fixed3, v_max_label);
         v_mean5sd := COALESCE(GREATEST(v_mean5sd, v_max_label), v_mean5sd, v_max_label);
         v_mean7sd := COALESCE(GREATEST(v_mean7sd, v_max_label), v_mean7sd, v_max_label);
         v_mean8sd := COALESCE(GREATEST(v_mean8sd, v_max_label), v_mean8sd, v_max_label);
         v_mean10sd := COALESCE(GREATEST(v_mean10sd, v_max_label), v_mean10sd, v_max_label);
         v_mean12sd := COALESCE(GREATEST(v_mean12sd, v_max_label), v_mean12sd, v_max_label);
      END IF;

      /* Determine if this rate is an outlier by each criterion.
       */
      IF v_ai_rate > 0 AND
         ((v_ai_rate > v_max_label AND v_max_label IS NOT NULL) OR
          (v_ai_rate > v_fixed1 AND v_fixed1 IS NOT NULL) OR
          (v_ai_rate > v_fixed2 AND v_fixed2 IS NOT NULL) OR
          (v_ai_rate > v_fixed3 AND v_fixed3 IS NOT NULL) OR
          (v_ai_rate > v_mean5sd AND v_mean5sd IS NOT NULL) OR
          (v_ai_rate > v_mean7sd AND v_mean7sd IS NOT NULL) OR
          (v_ai_rate > v_mean8sd AND v_mean8sd IS NOT NULL) OR
          (v_ai_rate > v_mean10sd AND v_mean10sd IS NOT NULL) OR
          (v_ai_rate > v_mean12sd AND v_mean12sd IS NOT NULL))
      THEN
         /* For rates of use set number of decimals to display
            based on size of the rate.
          */
         IF v_ai_rate >= 100 THEN
            v_ai_rate_ch := TO_CHAR(v_ai_rate, 'FM9,999,999,999');
         ELSIF v_ai_rate >= 1.0 THEN
            v_ai_rate_ch := TO_CHAR(v_ai_rate, 'FM9,999.99');
         ELSIF v_ai_rate >= 0.001 THEN
            v_ai_rate_ch := TO_CHAR(v_ai_rate, 'FM0.99999');
         ELSE
            v_ai_rate_ch := TO_CHAR(v_ai_rate, 'FM0.9999999');
         END IF;

         /* Get median rate
          */
         IF v_med_rate >= 100 THEN
            v_med_rate_ch := TO_CHAR(v_med_rate, 'FM9,999,999,999');
         ELSIF v_med_rate >= 1.0 THEN
            v_med_rate_ch := TO_CHAR(v_med_rate, 'FM9,999.99');
         ELSIF v_med_rate >= 0.001 THEN
            v_med_rate_ch := TO_CHAR(v_med_rate, 'FM0.99999');
         ELSE
            v_med_rate_ch := TO_CHAR(v_med_rate, 'FM0.9999999');
         END IF;

         /* Get maximum label rate
          */
         IF v_max_label >= 100 THEN
            v_max_label_ch := TO_CHAR(v_max_label, 'FM9,999,999,999');
         ELSIF v_max_label >= 1.0 THEN
            v_max_label_ch := TO_CHAR(v_max_label, 'FM9,999.99');
         ELSIF v_max_label >= 0.001 THEN
            v_max_label_ch := TO_CHAR(v_max_label, 'FM0.99999');
         ELSE
            v_max_label_ch := TO_CHAR(v_max_label, 'FM0.9999999');
         END IF;

         /* Get unit treated as full word.
          */
         IF v_gen_unit_treated = 'A' THEN
            v_unit_treated_word := 'acre';
         ELSIF v_gen_unit_treated = 'C' THEN
            v_unit_treated_word := 'cubic feet';
         ELSIF v_gen_unit_treated = 'P' THEN
            v_unit_treated_word := 'pound';
         ELSIF v_gen_unit_treated = 'U' THEN
            v_unit_treated_word := 'miscellaneous unit';
         ELSE
            v_unit_treated_word := 'unknown unit';
         END IF;

         /* Construct the comment.
            This function returns only one comment string, so if there are more
            than one AI, it needs to concatenate comments for all AIs,
            or else somehow, summarize for all AIs.
            But I think better to include each AI in comments.

          */
         IF v_ai_rate IS NOT NULL THEN
            p_comments :=
               'Reported rate of use = '||v_ai_rate_ch||' pounds AI per '||v_unit_treated_word||' for '||INITCAP(v_chemname)||'; ';
         ELSE
            p_comments := 'Reported rate of use is unknown;';
         END IF;

         IF v_med_rate IS NOT NULL THEN
            p_comments := p_comments||
               'median rate of use in '||v_stat_year||' = '||v_med_rate_ch||' pounds AI per '||v_unit_treated_word;
         ELSE
            p_comments := p_comments||
               'median rate of use in '||v_stat_year||' is unknown';
         END IF;

         IF v_max_label > 0 THEN
            p_comments := p_comments||
               '; maximum label rate = '||v_max_label_ch||' pounds AI per '||v_unit_treated_word;
         END IF;

         /* What error codes should we use? One for each criterion?
            However, error_code can have only one value.
            Should we still use code 75 for records sent to county?

            These boolean variables seem to serve no purpose other
            than in help determing which error_code to use.
          */
         v_fixed1_error := FALSE;
         v_fixed2_error := FALSE;
         v_fixed3_error := FALSE;
         v_mean5sd_error := FALSE;
         v_mean7sd_error := FALSE;
         v_mean8sd_error := FALSE;
         v_mean10sd_error := FALSE;
         v_mean12sd_error := FALSE;

         IF v_ai_rate > v_fixed3 AND v_fixed3 > 0 THEN
            v_fixed3_error := TRUE;
            v_fixed2_error := TRUE;
            v_fixed1_error := TRUE;
            p_comments := p_comments||'; rate > fixed3 limit';
         ELSIF v_ai_rate > v_fixed2 AND v_fixed2 > 0 THEN
            v_fixed2_error := TRUE;
            v_fixed1_error := TRUE;
            p_comments := p_comments||'; rate > fixed2 limit';
         ELSIF v_ai_rate > v_fixed1 AND v_fixed1 > 0 THEN
            v_fixed1_error := TRUE;
            p_comments := p_comments||'; rate > fixed1 limit';
         END IF;

         IF v_ai_rate > v_mean12sd AND v_mean12sd > 0 THEN
            v_mean12sd_error := TRUE;
            v_mean10sd_error := TRUE;
            v_mean8sd_error := TRUE;
            v_mean7sd_error := TRUE;
            v_mean5sd_error := TRUE;
            p_comments := p_comments||'; rate > mean + 12*SD';
         ELSIF v_ai_rate > v_mean10sd AND v_mean10sd > 0 THEN
            v_mean10sd_error := TRUE;
            v_mean8sd_error := TRUE;
            v_mean7sd_error := TRUE;
            v_mean5sd_error := TRUE;
            p_comments := p_comments||'; rate > mean + 10*SD';
         ELSIF v_ai_rate > v_mean8sd AND v_mean8sd > 0 THEN
            v_mean8sd_error := TRUE;
            v_mean7sd_error := TRUE;
            v_mean5sd_error := TRUE;
            p_comments := p_comments||'; rate > mean + 8*SD';
         ELSIF v_ai_rate > v_mean7sd AND v_mean7sd > 0 THEN
            v_mean7sd_error := TRUE;
            v_mean5sd_error := TRUE;
            p_comments := p_comments||'; rate > mean + 7*SD';
         ELSIF v_ai_rate > v_mean5sd AND v_mean5sd > 0 THEN
            v_mean5sd_error := TRUE;
            p_comments := p_comments||'; rate > mean + 5*SD';
         END IF;

         /* If we implement option 3 for handling multiple AIs,
            this section needs to be outside loop that gets each AI,
            since this function returns just one error_code, estimates, and
            comment string.

            Use error_code 75 when when specific conditions are met;
            for these records replace the rate with an estimate,
            either in lbs_prd_used, acre_treated, or unit_treated.
            Otherwise, use error_code 76 (note that in this location
            in the code, the rate is greater than at least one of the
            outlier limits).
          */
         -- DBMS_OUTPUT.PUT_LINE('2: p_amt_prd_used = '||p_amt_prd_used);
         IF (v_ago_ind = 'A' AND v_gen_unit_treated = 'A' AND v_ai_rate_type = 'NORMAL_RATE_AI' AND
            (v_fixed2_error OR v_mean10sd_error)) OR
            (v_ago_ind = 'A' AND v_gen_unit_treated = 'A' AND
             v_ai_rate_type IN ('MEDIUM_RATE_AI', 'HIGH_RATE_AI') AND
            (v_fixed2_error OR v_mean5sd_error)) OR
            (v_ago_ind = 'A' AND v_gen_unit_treated = 'A' AND
             v_ai_rate_type = 'ADJUVANT' AND
            (v_fixed3_error OR v_mean10sd_error)) OR
            (v_ago_ind = 'A' AND v_gen_unit_treated IN ('C', 'P', 'U') AND
            (v_fixed2_error OR v_mean7sd_error)) OR
            (v_ago_ind = 'N' AND v_gen_unit_treated = 'A' AND
            (v_fixed2_error OR v_mean7sd_error)) OR
            (v_ago_ind = 'N' AND v_gen_unit_treated IN ('C', 'P', 'U') AND
            (v_fixed2_error OR v_mean10sd_error))

         THEN
            p_estimated_field := NULL;
            p_error_code := 75;
            p_error_type := 'POSSIBLE';
            p_replace_type := NULL;
            --debug_statment := NULL;

            /* More English-like statement of the following code:
            IF rate of use is unusally high THEN
               IF replacing unit_treated with 'A' makes rate reasonable THEN
                  estimate unit_treated with 'A';
               ELSIF replacing acre_treated using median rate
                     gives acre_treated < acre_planted THEN
                  estimate acre_treated;
               ELSE
                  estimate lbs_prd_used using median rate and acre_treated;
               END IF;
            END IF;
            */

            IF Outlier_new_package.Wrong_unit
                  (v_stat_year, v_ago_ind,
                   p_chem_code, v_ai_group,
                   v_ai_rate_type, v_regno_short,
                   p_site_code, v_site_general, v_lbs_ai,
                   v_fixed2, v_mean5sd, v_mean7sd, v_mean10sd,
                   p_acre_planted, p_unit_planted,
                   p_acre_treated, p_unit_treated,
                   p_replace_type)
            THEN
               p_estimated_field := 'UNIT_TREATED';
               p_comments := p_comments||'; the value for unit_treated was estimated.';
            ELSIF Outlier_new_package.Wrong_acres
               (v_ago_ind, p_site_code, v_lbs_ai, v_ai_rate, v_med_rate,
                p_acre_planted, p_unit_planted,
                p_acre_treated, p_unit_treated,
                p_replace_type)
            THEN
               IF p_replace_type = 'ESTIMATE' THEN
                  p_estimated_field := 'ACRE_TREATED';
                  p_comments := p_comments||'; the value for acre_treated was estimated.';
               END IF;
            ELSE
               -- DBMS_OUTPUT.PUT_LINE('3 (before wrong_lbs): p_amt_prd_used = '||p_amt_prd_used||'; error_type = '||p_error_type);
               Outlier_new_package.Wrong_lbs
               (v_ai_rate, v_med_rate, p_prodchem_pct, v_amount_treated, p_lbs_prd_used, p_amt_prd_used,
                p_replace_type);

               IF p_replace_type = 'ESTIMATE' THEN
                  p_estimated_field := 'LBS_PRD_USED';
                  p_comments := p_comments||'; the values for lbs_prd_used and amt_prd_used were estimated.';
               END IF;
               -- DBMS_OUTPUT.PUT_LINE('3 (after wrong_lbs): p_amt_prd_used = '||p_amt_prd_used||'; error_type = '||p_error_type);
            END IF;

         ELSE
            p_estimated_field := NULL;
            p_error_code := 76;
            p_error_type := 'POSSIBLE';
            p_replace_type := 'SAME';
         END IF;

      ELSE
         p_comments := NULL;
         p_estimated_field := NULL;
         p_error_code := NULL;
         p_error_type := NULL;
         p_replace_type := NULL;

         v_ai_rate_type := 'NORMAL_RATE_AI';
         v_ai_group := NULL;

         -- No_error(p_error_code, p_error_type, p_replace_type);
      END IF; -- v_ai_rate > 0
      -- DBMS_OUTPUT.PUT_LINE('3 (after wrong_lbs): p_amt_prd_used = '||p_amt_prd_used||'; error_type = '||p_error_type);
   END IF;

   -- DBMS_OUTPUT.PUT_LINE('4: p_amt_prd_used = '||p_amt_prd_used||'; error_type = '||p_error_type);




   /*********************************************************************************
      Get outliers in pounds AI per application.
      These are all "non-ag" applications - more specifically records with
      record_id = 2 or C.  We include even records with a unit treated reported;
      in those case we check both its rate of use (lbs/unit) and its lbs/application.
    ********************************************************************************/
   IF p_record_id IN ('2', 'C') AND (p_error_type IS NULL OR p_error_type = 'N') THEN
      -- DBMS_OUTPUT.PUT_LINE('5 (nonag record): p_amt_prd_used = '||p_amt_prd_used||'; error_type = '||p_error_type);
      v_lbs_ai := p_lbs_prd_used * p_prodchem_pct/100;

      IF p_applic_cnt > 1 THEN
         v_ai_lbsapp := v_lbs_ai/p_applic_cnt;
      ELSE
         v_ai_lbsapp := v_lbs_ai;
      END IF;

      IF v_ai_lbsapp > 0 THEN
         v_ai_lbsapp_log := LOG(10, v_ai_lbsapp);
      ELSE
         v_ai_lbsapp_log := NULL;
      END IF;

      IF v_ai_adjuvant = 'Y' THEN
         v_lbs_ai_app_type := 'ADJUVANT';
      ELSE
         BEGIN
            SELECT   lbs_ai_app_type
            INTO      v_lbs_ai_app_type
            FROM      fixed_outlier_lbs_app_ais
            WHERE      chem_code = p_chem_code;
         EXCEPTION
            WHEN OTHERS THEN
               v_lbs_ai_app_type := 'HIGH_LBS_AI_5';
         END;
      END IF;

      IF p_site_code IN (65000, 65503) THEN
         v_site_type := 'WATER_SITE';
      ELSE
         v_site_type := 'OTHER_SITE';
      END IF;

      /* Get the fixed outlier limit for lbs per app.
       */
      BEGIN
         SELECT   lbs_ai_app1, lbs_ai_app2, lbs_ai_app3
         INTO      v_fixed1_lbsapp, v_fixed2_lbsapp, v_fixed3_lbsapp
         FROM      fixed_outlier_lbs_app
         WHERE      lbs_ai_app_type = v_lbs_ai_app_type AND
                  site_type = v_site_type;
      EXCEPTION
         WHEN OTHERS THEN
            v_fixed1_lbsapp := NULL;
            v_fixed2_lbsapp := NULL;
            v_fixed3_lbsapp := NULL;
      END;

      /* Get the most recent year from the ai_stats table;
         use that year's values to get median rates.
       */
      BEGIN
         SELECT   MAX(year)
         INTO    v_stat_year
         FROM    ai_outlier_nonag_stats;

      EXCEPTION
         WHEN OTHERS THEN
            v_stat_year := NULL;
      END;

      /* Get the other outlier limits.  First need the AI group number for this AI, product, site, ago_ind, and
         unit_treated.
       */
      BEGIN
         SELECT   ai_group
         INTO      v_ai_group_lbsapp
         FROM      ai_group_nonag_stats
         WHERE      year = v_stat_year AND
                  chem_code = p_chem_code AND
                  regno_short = v_regno_short AND
                  site_general = v_site_general;
      EXCEPTION
         WHEN OTHERS THEN
            v_ai_group_lbsapp := NULL;
      END;

      /* Get the outlier statistics for this application from table AI_OUTLIER_STATS.
       */
      IF v_ai_group_lbsapp IS NULL THEN
         /* If no statistics found for this AI, ago_ind, unit_treated, product, and site,
            then use maximum outlier limits for this AI, ago_ind, and unit_treated.
            If no statistics found for this AI, ago_ind, and unit_treated, just use fixed limits.
          */
         BEGIN
            SELECT   MAX(median_rate), MAX(mean3sd), MAX(mean5sd),
                     MAX(mean7sd), MAX(mean8sd), MAX(mean10sd), MAX(mean12sd)
            INTO      v_med_lbsapp_log, v_mean3sd_lbsapp_log, v_mean5sd_lbsapp_log,
                     v_mean7sd_lbsapp_log, v_mean8sd_lbsapp_log, v_mean10sd_lbsapp_log,
                     v_mean12sd_lbsapp_log
            FROM      ai_outlier_nonag_stats
            WHERE      year = v_stat_year AND
                     chem_code = p_chem_code;
         EXCEPTION
            WHEN OTHERS THEN
               v_med_lbsapp_log := NULL;
               v_mean3sd_lbsapp_log := NULL;
               v_mean5sd_lbsapp_log := NULL;
               v_mean7sd_lbsapp_log := NULL;
               v_mean8sd_lbsapp_log := NULL;
               v_mean10sd_lbsapp_log := NULL;
               v_mean12sd_lbsapp_log := NULL;
         END;
      ELSE -- An AI group is found for this record.
         BEGIN
            SELECT   median_rate, mean3sd, mean5sd, mean7sd, mean8sd, mean10sd,
                     mean12sd
            INTO      v_med_lbsapp_log, v_mean3sd_lbsapp_log, v_mean5sd_lbsapp_log,
                     v_mean7sd_lbsapp_log, v_mean8sd_lbsapp_log, v_mean10sd_lbsapp_log,
                     v_mean12sd_lbsapp_log
            FROM      ai_outlier_nonag_stats
            WHERE      year = v_stat_year AND
                     chem_code = p_chem_code AND
                     ai_group = v_ai_group_lbsapp;
         EXCEPTION
            WHEN OTHERS THEN
               v_med_lbsapp_log := NULL;
               v_mean3sd_lbsapp_log := NULL;
               v_mean5sd_lbsapp_log := NULL;
               v_mean7sd_lbsapp_log := NULL;
               v_mean8sd_lbsapp_log := NULL;
               v_mean10sd_lbsapp_log := NULL;
               v_mean12sd_lbsapp_log := NULL;
         END;

      END IF;

      IF v_med_lbsapp_log < 10 THEN
         v_med_lbsapp := power(10, v_med_lbsapp_log);
      ELSE
         v_med_lbsapp := power(10, 10);
      END IF;

      IF v_mean3sd_lbsapp_log < 10 THEN
         v_mean3sd_lbsapp := power(10, v_mean3sd_lbsapp_log);
      ELSE
         v_mean3sd_lbsapp := power(10, 10);
      END IF;

      IF v_mean5sd_lbsapp_log < 10 THEN
         v_mean5sd_lbsapp := power(10, v_mean5sd_lbsapp_log);
      ELSE
         v_mean5sd_lbsapp := power(10, 10);
      END IF;

      IF v_mean7sd_lbsapp_log < 10 THEN
         v_mean7sd_lbsapp := power(10, v_mean7sd_lbsapp_log);
      ELSE
         v_mean7sd_lbsapp := power(10, 10);
      END IF;

      IF v_mean8sd_lbsapp_log < 10 THEN
         v_mean8sd_lbsapp := power(10, v_mean8sd_lbsapp_log);
      ELSE
         v_mean8sd_lbsapp := power(10, 10);
      END IF;

      IF v_mean10sd_lbsapp_log < 10 THEN
         v_mean10sd_lbsapp := power(10, v_mean10sd_lbsapp_log);
      ELSE
         v_mean10sd_lbsapp := power(10, 10);
      END IF;

      IF v_mean12sd_lbsapp_log < 10 THEN
         v_mean12sd_lbsapp := power(10, v_mean12sd_lbsapp_log);
      ELSE
         v_mean12sd_lbsapp := power(10, 10);
      END IF;

      IF v_fixed1_lbsapp = 0 THEN
         v_fixed1_lbsapp := NULL;
      END IF;

      IF v_fixed2_lbsapp = 0 THEN
         v_fixed2_lbsapp := NULL;
      END IF;

      IF v_fixed3_lbsapp = 0 THEN
         v_fixed3_lbsapp := NULL;
      END IF;

      IF v_mean3sd_lbsapp = 0 THEN
         v_mean3sd_lbsapp := NULL;
      END IF;

      IF v_mean5sd_lbsapp = 0 THEN
         v_mean5sd_lbsapp := NULL;
      END IF;

      IF v_mean7sd_lbsapp = 0 THEN
         v_mean7sd_lbsapp := NULL;
      END IF;

      IF v_mean8sd_lbsapp = 0 THEN
         v_mean8sd_lbsapp := NULL;
      END IF;

      IF v_mean10sd_lbsapp = 0 THEN
         v_mean10sd_lbsapp := NULL;
      END IF;

      IF v_mean12sd_lbsapp = 0 THEN
         v_mean12sd_lbsapp := NULL;
      END IF;

      /* Determine if this rate is an outlier by each criterion.
       */
      IF v_ai_lbsapp > 0 AND
         ((v_ai_lbsapp > v_fixed1_lbsapp AND v_fixed1_lbsapp IS NOT NULL) OR
          (v_ai_lbsapp > v_fixed2_lbsapp AND v_fixed2_lbsapp IS NOT NULL) OR
          (v_ai_lbsapp > v_fixed3_lbsapp AND v_fixed3_lbsapp IS NOT NULL) OR
          (v_ai_lbsapp > v_mean3sd_lbsapp AND v_mean3sd_lbsapp IS NOT NULL) OR
          (v_ai_lbsapp > v_mean5sd_lbsapp AND v_mean5sd_lbsapp IS NOT NULL) OR
          (v_ai_lbsapp > v_mean7sd_lbsapp AND v_mean7sd_lbsapp IS NOT NULL) OR
          (v_ai_lbsapp > v_mean8sd_lbsapp AND v_mean8sd_lbsapp IS NOT NULL) OR
          (v_ai_lbsapp > v_mean10sd_lbsapp AND v_mean10sd_lbsapp IS NOT NULL) OR
          (v_ai_lbsapp > v_mean12sd_lbsapp AND v_mean12sd_lbsapp IS NOT NULL))
      THEN
         /* For rates of use set number of decimals to display
            based on size of the rate.
          */
         IF v_ai_lbsapp >= 100 THEN
            v_ai_lbsapp_ch := TO_CHAR(v_ai_lbsapp, 'FM9,999,999,999');
         ELSIF v_ai_lbsapp >= 1.0 THEN
            v_ai_lbsapp_ch := TO_CHAR(v_ai_lbsapp, 'FM9,999.99');
         ELSIF v_ai_lbsapp >= 0.001 THEN
            v_ai_lbsapp_ch := TO_CHAR(v_ai_lbsapp, 'FM0.99999');
         ELSE
            v_ai_lbsapp_ch := TO_CHAR(v_ai_lbsapp, 'FM0.9999999');
         END IF;

         /* Get median rate
          */
         IF v_med_lbsapp_ch >= 100 THEN
            v_med_lbsapp_ch := TO_CHAR(v_med_lbsapp, 'FM9,999,999,999');
         ELSIF v_med_rate >= 1.0 THEN
            v_med_lbsapp_ch := TO_CHAR(v_med_lbsapp, 'FM9,999.99');
         ELSIF v_med_rate >= 0.001 THEN
            v_med_lbsapp_ch := TO_CHAR(v_med_lbsapp, 'FM0.99999');
         ELSE
            v_med_lbsapp_ch := TO_CHAR(v_med_lbsapp, 'FM0.9999999');
         END IF;

         /* Construct the comment.
            This function returns only one comment string, so if there are more
            than one AI, it needs to concatenate comments for all AIs,
            or else somehow, summarize for all AIs.
            But I think better to include each AI in comments.

          */
         IF v_ai_lbsapp IS NOT NULL THEN
            p_comments := p_comments||
               'Reported pounds AI per application = '||v_ai_lbsapp_ch||' for '||INITCAP(v_chemname)||'; ';
         ELSE
            p_comments := p_comments||'Reported pounds AI per application is unknown;';
         END IF;

         IF v_med_lbsapp IS NOT NULL THEN
            p_comments := p_comments||
               'median pounds AI per application in '||v_stat_year||' = '||v_med_lbsapp_ch;
         ELSE
            p_comments := p_comments||
               'median pounds AI per application in '||v_stat_year||' is unknown';
         END IF;

         /* What error codes should we use? One for each criterion?
            However, error_code can have only one value.
            Should we still use code 75 for records sent to county?

            These boolean variables seem to serve no purpose other
            than in help determing which error_code to use.
          */
         v_fixed1_lbsapp_error := FALSE;
         v_fixed2_lbsapp_error := FALSE;
         v_fixed3_lbsapp_error := FALSE;
         v_mean3sd_lbsapp_error := FALSE;
         v_mean5sd_lbsapp_error := FALSE;
         v_mean7sd_lbsapp_error := FALSE;
         v_mean8sd_lbsapp_error := FALSE;
         v_mean10sd_lbsapp_error := FALSE;
         v_mean12sd_lbsapp_error := FALSE;

         IF v_ai_lbsapp > v_fixed3_lbsapp AND v_fixed3_lbsapp > 0 THEN
            v_fixed3_lbsapp_error := TRUE;
            v_fixed2_lbsapp_error := TRUE;
            v_fixed1_lbsapp_error := TRUE;
            p_comments := p_comments||'; lbs/app > fixed3 limit';
         ELSIF v_ai_lbsapp > v_fixed2_lbsapp AND v_fixed2_lbsapp > 0 THEN
            v_fixed2_lbsapp_error := TRUE;
            v_fixed1_lbsapp_error := TRUE;
            p_comments := p_comments||'; lbs/app > fixed2 limit';
         ELSIF v_ai_lbsapp > v_fixed1_lbsapp AND v_fixed1_lbsapp > 0 THEN
            v_fixed1_lbsapp_error := TRUE;
            p_comments := p_comments||'; lbs/app > fixed1 limit';
         END IF;

         IF v_ai_lbsapp > v_mean12sd_lbsapp AND v_mean12sd_lbsapp > 0 THEN
            v_mean12sd_lbsapp_error := TRUE;
            v_mean10sd_lbsapp_error := TRUE;
            v_mean8sd_lbsapp_error := TRUE;
            v_mean7sd_lbsapp_error := TRUE;
            v_mean5sd_lbsapp_error := TRUE;
            v_mean3sd_lbsapp_error := TRUE;
            p_comments := p_comments||'; lbs/app > mean + 12*SD';
         ELSIF v_ai_lbsapp > v_mean10sd_lbsapp AND v_mean10sd_lbsapp > 0 THEN
            v_mean10sd_lbsapp_error := TRUE;
            v_mean8sd_lbsapp_error := TRUE;
            v_mean7sd_lbsapp_error := TRUE;
            v_mean5sd_lbsapp_error := TRUE;
            v_mean3sd_lbsapp_error := TRUE;
            p_comments := p_comments||'; lbs/app > mean + 10*SD';
         ELSIF v_ai_lbsapp > v_mean8sd_lbsapp AND v_mean8sd_lbsapp > 0 THEN
            v_mean8sd_lbsapp_error := TRUE;
            v_mean7sd_lbsapp_error := TRUE;
            v_mean5sd_lbsapp_error := TRUE;
            v_mean3sd_lbsapp_error := TRUE;
            p_comments := p_comments||'; lbs/app > mean + 8*SD';
         ELSIF v_ai_lbsapp > v_mean7sd_lbsapp AND v_mean7sd_lbsapp > 0 THEN
            v_mean7sd_lbsapp_error := TRUE;
            v_mean5sd_lbsapp_error := TRUE;
            v_mean3sd_lbsapp_error := TRUE;
            p_comments := p_comments||'; lbs/app > mean + 7*SD';
         ELSIF v_ai_lbsapp > v_mean5sd_lbsapp AND v_mean5sd_lbsapp > 0 THEN
            v_mean3sd_lbsapp_error := TRUE;
            v_mean5sd_lbsapp_error := TRUE;
            p_comments := p_comments||'; lbs/app > mean + 5*SD';
         ELSIF v_ai_lbsapp > v_mean3sd_lbsapp AND v_mean3sd_lbsapp > 0 THEN
            v_mean3sd_lbsapp_error := TRUE;
            p_comments := p_comments||'; lbs/app > mean + 3*SD';
         END IF;

         IF p_error_code IS NULL THEN
            p_estimated_field := NULL;
            p_error_code := 76;
            p_error_type := 'POSSIBLE';
            p_replace_type := 'SAME';
         END IF;
      ELSE
         p_comments := NULL;
         p_estimated_field := NULL;
         p_error_code := NULL;
         p_error_type := NULL;
         p_replace_type := NULL;

         v_lbs_ai_app_type := 'HIGH_LBS_AI_5';
         v_site_type := 'OTHER_SITE';
         v_ai_group_lbsapp := NULL;
      END IF;
   END IF;
   -- DBMS_OUTPUT.PUT_LINE('6: p_amt_prd_used = '||p_amt_prd_used||'; error_type = '||p_error_type);

   IF v_fixed1_error THEN
      p_fixed1_rate_outlier := 'X';
   ELSE
      p_fixed1_rate_outlier := NULL;
   END IF;

   IF v_fixed2_error THEN
      p_fixed2_rate_outlier := 'X';
   ELSE
      p_fixed2_rate_outlier := NULL;
   END IF;

   IF v_fixed3_error THEN
      p_fixed3_rate_outlier := 'X';
   ELSE
      p_fixed3_rate_outlier := NULL;
   END IF;

   IF v_mean5sd_error THEN
      p_mean5sd_rate_outlier := 'X';
   ELSE
      p_mean5sd_rate_outlier := NULL;
   END IF;

   IF v_mean7sd_error THEN
      p_mean7sd_rate_outlier := 'X';
   ELSE
      p_mean7sd_rate_outlier := NULL;
   END IF;

   IF v_mean8sd_error THEN
      p_mean8sd_rate_outlier := 'X';
   ELSE
      p_mean8sd_rate_outlier := NULL;
   END IF;

   IF v_mean10sd_error THEN
      p_mean10sd_rate_outlier := 'X';
   ELSE
      p_mean10sd_rate_outlier := NULL;
   END IF;

   IF v_mean12sd_error THEN
      p_mean12sd_rate_outlier := 'X';
   ELSE
      p_mean12sd_rate_outlier := NULL;
   END IF;


   IF v_fixed1_lbsapp_error THEN
      p_fixed1_lbsapp_outlier := 'X';
   ELSE
      p_fixed1_lbsapp_outlier := NULL;
   END IF;

   IF v_fixed2_lbsapp_error THEN
      p_fixed2_lbsapp_outlier := 'X';
   ELSE
      p_fixed2_lbsapp_outlier := NULL;
   END IF;

   IF v_fixed3_lbsapp_error THEN
      p_fixed3_lbsapp_outlier := 'X';
   ELSE
      p_fixed3_lbsapp_outlier := NULL;
   END IF;

   IF v_mean3sd_lbsapp_error THEN
      p_mean3sd_lbsapp_outlier := 'X';
   ELSE
      p_mean3sd_lbsapp_outlier := NULL;
   END IF;

   IF v_mean5sd_lbsapp_error THEN
      p_mean5sd_lbsapp_outlier := 'X';
   ELSE
      p_mean5sd_lbsapp_outlier := NULL;
   END IF;

   IF v_mean7sd_lbsapp_error THEN
      p_mean7sd_lbsapp_outlier := 'X';
   ELSE
      p_mean7sd_lbsapp_outlier := NULL;
   END IF;

   IF v_mean8sd_lbsapp_error THEN
      p_mean8sd_lbsapp_outlier := 'X';
   ELSE
      p_mean8sd_lbsapp_outlier := NULL;
   END IF;

   IF v_mean10sd_lbsapp_error THEN
      p_mean10sd_lbsapp_outlier := 'X';
   ELSE
      p_mean10sd_lbsapp_outlier := NULL;
   END IF;

   IF v_mean12sd_lbsapp_error THEN
      p_mean12sd_lbsapp_outlier := 'X';
   ELSE
      p_mean12sd_lbsapp_outlier := NULL;
   END IF;

EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(SQLERRM||' use_no = '||p_use_no);
END Outliers;

