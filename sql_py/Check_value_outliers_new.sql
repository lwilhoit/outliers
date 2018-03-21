SET pause OFF
SET pagesize 75
SET linesize 120
SET termout ON
SET feedback ON
SET document OFF
SET verify OFF
SET trimspool ON
SET numwidth 11
SET SERVEROUTPUT ON SIZE 1000000 FORMAT WORD_WRAPPED

/* A test version of this script is in cvo_test.sql
 */
CREATE OR REPLACE PROCEDURE Check_value_outliers_new
   (p_record_id VARCHAR2,
    p_prodno IN NUMBER,
    p_site_code IN NUMBER,

    p_lbs_prd_used IN OUT NUMBER,
    p_amt_prd_used IN OUT NUMBER,
    p_acre_treated IN OUT NUMBER,
    p_unit_treated IN OUT VARCHAR2,
    p_acre_planted IN NUMBER,
    p_unit_planted IN VARCHAR2,
    p_applic_cnt IN NUMBER,

    p_fixed1_rate_outlier OUT VARCHAR2,
    p_fixed2_rate_outlier OUT VARCHAR2,
    p_fixed3_rate_outlier OUT VARCHAR2,
    p_mean5sd_rate_outlier OUT VARCHAR2,
    p_mean7sd_rate_outlier OUT VARCHAR2,
    p_mean8sd_rate_outlier OUT VARCHAR2,
    p_mean10sd_rate_outlier OUT VARCHAR2,
    p_mean12sd_rate_outlier OUT VARCHAR2,
    p_max_label_outlier OUT VARCHAR2,
    p_limit_rate_outlier OUT VARCHAR2,

    p_fixed1_lbsapp_outlier OUT VARCHAR2,
    p_fixed2_lbsapp_outlier OUT VARCHAR2,
    p_fixed3_lbsapp_outlier OUT VARCHAR2,
    p_mean3sd_lbsapp_outlier OUT VARCHAR2,
    p_mean5sd_lbsapp_outlier OUT VARCHAR2,
    p_mean7sd_lbsapp_outlier OUT VARCHAR2,
    p_mean8sd_lbsapp_outlier OUT VARCHAR2,
    p_mean10sd_lbsapp_outlier OUT VARCHAR2,
    p_mean12sd_lbsapp_outlier OUT VARCHAR2,
    p_limit_lbsapp_outlier OUT VARCHAR2,

    p_comments OUT VARCHAR2,
    p_estimated_field OUT VARCHAR2,
    p_error_code OUT INTEGER,
    p_error_type OUT VARCHAR2,
    p_replace_type OUT VARCHAR2)
IS
   --v_stat_year             INTEGER := NULL;

   v_ago_ind            VARCHAR2(1);
   v_regno_short         VARCHAR2(100);
   v_site_general        VARCHAR2(50);

   v_chemname              VARCHAR2(200);
   v_chem_code             INTEGER;
   v_prodchem_pct          NUMBER;
   --v_site_type            VARCHAR2(100);
   -- v_ai_adjuvant         VARCHAR2(1);


   --v_lbs_ai               NUMBER;
   --v_amount_treated       NUMBER;
   --v_gen_unit_treated   VARCHAR2(1);

   v_has_outlier_limits    BOOLEAN;
   v_outlier_limit         NUMBER;
   v_median_ai            NUMBER;          
   v_median_prod            NUMBER;          
   v_fixed1_prod               NUMBER := NULL;
   v_fixed2_prod               NUMBER := NULL;
   v_fixed3_prod               NUMBER := NULL;
   v_mean5sd_prod            NUMBER := NULL;
   v_mean7sd_prod            NUMBER := NULL;
   v_mean8sd_prod            NUMBER := NULL;
   v_mean10sd_prod            NUMBER := NULL;
   v_mean12sd_prod            NUMBER := NULL;

   v_prod_rate                NUMBER;
   v_ai_rate                  NUMBER;
   v_max_label_prod           NUMBER;

   v_ai_rate_ch            VARCHAR2(100);
   v_prod_rate_ch          VARCHAR2(100);
   v_median_ai_ch          VARCHAR2(100);
   v_max_label_ch          VARCHAR2(100);
   v_acre_treated_ch       VARCHAR2(100);
   v_lbs_prd_used_ch       VARCHAR2(100);
   v_amt_prd_used_ch       VARCHAR2(100);
   v_acre_treated_orig_ch  VARCHAR2(100);
   v_lbs_prd_used_orig_ch  VARCHAR2(100);
   v_amt_prd_used_orig_ch  VARCHAR2(100);
   v_unit_treated_word     VARCHAR2(100);
   v_unit_treated_orig     VARCHAR2(1);

   -- v_ai_lbsapp_ch          VARCHAR2(100);
   -- v_med_lbsapp_ch         VARCHAR2(100);


BEGIN
   p_comments := NULL;
   p_estimated_field := NULL;
   p_error_code := NULL;
   p_error_type := NULL;
   p_replace_type := NULL;

   -- --DBMS_OUTPUT.PUT_LINE('1: use_no = '||p_use_no||'; p_amt_prd_used = '||p_amt_prd_used);
   --DBMS_OUTPUT.PUT_LINE('p_record_id = '||p_record_id);
   --DBMS_OUTPUT.PUT_LINE('p_prodno = '||p_prodno);
   --DBMS_OUTPUT.PUT_LINE('p_site_code = '||p_site_code);
   --DBMS_OUTPUT.PUT_LINE('p_lbs_prd_used = '||p_lbs_prd_used);
   --DBMS_OUTPUT.PUT_LINE('p_acre_treated = '||p_acre_treated);
   --DBMS_OUTPUT.PUT_LINE('p_unit_treated = '||p_unit_treated);

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

   BEGIN
      SELECT   mfg_firmno||'-'||label_seq_no
      INTO     v_regno_short
      FROM     product
      WHERE    prodno = p_prodno;
   EXCEPTION
      WHEN OTHERS THEN
         v_regno_short := NULL;
   END;

   /*********************************************************************************
      Get outliers in rates of use (pounds AI per unit treated).
      These includes some non-ag records, when a unit treated is reported.
    ********************************************************************************/
   IF p_acre_treated > 0 THEN
      v_prod_rate := p_lbs_prd_used/p_acre_treated;
      --DBMS_OUTPUT.PUT_LINE('v_prod_rate = '||v_prod_rate);
 
      BEGIN
         SELECT  fixed1, fixed2, fixed3, 
                 median, mean5sd, mean7sd, mean8sd, mean10sd, mean12sd,
                 outlier_limit, chem_code, chemname, prodchem_pct
         INTO    v_fixed1_prod, v_fixed2_prod, v_fixed3_prod,
                 v_median_prod, v_mean5sd_prod, v_mean7sd_prod, v_mean8sd_prod, v_mean10sd_prod, v_mean12sd_prod,
                 v_outlier_limit, v_chem_code, v_chemname, v_prodchem_pct
         FROM    outlier_all_stats
         WHERE   regno_short = v_regno_short AND
                 ago_ind = v_ago_ind AND
                 site_general = v_site_general AND
                 unit_treated = p_unit_treated;

         v_has_outlier_limits := TRUE;
         --DBMS_OUTPUT.PUT_LINE('v_has_outlier_limits = TRUE');
         --DBMS_OUTPUT.PUT_LINE('v_chem_code = '||v_chem_code);
         --DBMS_OUTPUT.PUT_LINE('v_chemname = '||v_chemname);
      EXCEPTION
         WHEN OTHERS THEN
            v_has_outlier_limits := FALSE;
            --DBMS_OUTPUT.PUT_LINE('v_has_outlier_limits = FALSE');
            v_median_prod := NULL;
            v_fixed1_prod := NULL;
            v_fixed2_prod := NULL;
            v_fixed3_prod := NULL;
            v_mean5sd_prod := NULL;
            v_mean7sd_prod := NULL;
            v_mean8sd_prod := NULL;
            v_mean10sd_prod := NULL;
            v_mean12sd_prod := NULL;
            v_outlier_limit := NULL;
            v_chem_code := NULL;
            v_chemname := NULL;
      END;

      


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
         SELECT   CASE p_unit_treated
                     WHEN 'S' THEN max_rate/43560
                     WHEN 'K' THEN max_rate*1000
                     WHEN 'T' THEN max_rate*2000
                     ELSE max_rate
                  END * 1.1
         INTO     v_max_label_prod
         FROM     max_label_rates
         WHERE    prodno = p_prodno AND
                  unit_treated = 
                     CASE p_unit_treated
                        WHEN 'S' THEN 'A'
                        WHEN 'K' THEN 'C'
                        WHEN 'T' THEN 'P'
                        ELSE p_unit_treated
                     END;
      EXCEPTION
         WHEN OTHERS THEN
            v_max_label_prod := NULL;
      END;

      --DBMS_OUTPUT.PUT_LINE('v_max_label_prod = '||v_max_label_prod);


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
         v_fixed1_prod := COALESCE(GREATEST(v_fixed1_prod, v_max_label_prod), v_fixed1_prod, v_max_label_prod);
         v_fixed2_prod := COALESCE(GREATEST(v_fixed2_prod, v_max_label_prod), v_fixed2_prod, v_max_label_prod);
         v_fixed3_prod := COALESCE(GREATEST(v_fixed3_prod, v_max_label_prod), v_fixed3_prod, v_max_label_prod);
         v_mean5sd_prod := COALESCE(GREATEST(v_mean5sd_prod, v_max_label_prod), v_mean5sd_prod, v_max_label_prod);
         v_mean7sd_prod := COALESCE(GREATEST(v_mean7sd_prod, v_max_label_prod), v_mean7sd_prod, v_max_label_prod);
         v_mean8sd_prod := COALESCE(GREATEST(v_mean8sd_prod, v_max_label_prod), v_mean8sd_prod, v_max_label_prod);
         v_mean10sd_prod := COALESCE(GREATEST(v_mean10sd_prod, v_max_label_prod), v_mean10sd_prod, v_max_label_prod);
         v_mean12sd_prod := COALESCE(GREATEST(v_mean12sd_prod, v_max_label_prod), v_mean12sd_prod, v_max_label_prod);

      END IF;

      /* Determine if this rate is an outlier by each criterion.
       */
      IF v_prod_rate > 0 AND
         ((v_prod_rate > v_max_label_prod AND v_max_label_prod IS NOT NULL) OR
          (v_prod_rate > v_fixed1_prod AND v_fixed1_prod IS NOT NULL) OR
          (v_prod_rate > v_fixed2_prod AND v_fixed2_prod IS NOT NULL) OR
          (v_prod_rate > v_fixed3_prod AND v_fixed3_prod IS NOT NULL) OR
          (v_prod_rate > v_mean5sd_prod AND v_mean5sd_prod IS NOT NULL) OR
          (v_prod_rate > v_mean7sd_prod AND v_mean7sd_prod IS NOT NULL) OR
          (v_prod_rate > v_mean8sd_prod AND v_mean8sd_prod IS NOT NULL) OR
          (v_prod_rate > v_mean10sd_prod AND v_mean10sd_prod IS NOT NULL) OR
          (v_prod_rate > v_mean12sd_prod AND v_mean12sd_prod IS NOT NULL))
      THEN
         v_ai_rate := v_prod_rate*v_prodchem_pct/100;
         v_median_ai := v_median_prod*v_prodchem_pct/100;

         --DBMS_OUTPUT.PUT_LINE('v_ai_rate = '||v_ai_rate);
         /*
         --DBMS_OUTPUT.PUT_LINE('v_prod_rate = '||v_prod_rate);
         --DBMS_OUTPUT.PUT_LINE('v_fixed1_prod = '||v_fixed1_prod);
         --DBMS_OUTPUT.PUT_LINE('v_fixed2_prod = '||v_fixed2_prod);
         --DBMS_OUTPUT.PUT_LINE('v_fixed3_prod = '||v_fixed3_prod);
         --DBMS_OUTPUT.PUT_LINE('v_mean5sd_prod = '||v_mean5sd_prod);
         --DBMS_OUTPUT.PUT_LINE('v_mean7sd_prod = '||v_mean7sd_prod);
         --DBMS_OUTPUT.PUT_LINE('v_mean8sd_prod = '||v_mean8sd_prod);
         --DBMS_OUTPUT.PUT_LINE('v_mean10sd_prod = '||v_mean10sd_prod);
         --DBMS_OUTPUT.PUT_LINE('v_mean12sd_prod = '||v_mean12sd_prod);
         --DBMS_OUTPUT.PUT_LINE('v_prodchem_pct = '||v_prodchem_pct);
         */

         /* For rates of use set number of decimals to display
            based on size of the rate.
          */
         IF v_ai_rate >= 100 THEN
            v_ai_rate_ch := TO_CHAR(v_ai_rate, 'FM9,999,999,999');
         ELSIF v_ai_rate >= 1.0 THEN
            v_ai_rate_ch := CASE WHEN REMAINDER(v_ai_rate, 1) = 0 THEN TO_CHAR(v_ai_rate, 'FM9,999') ELSE TO_CHAR(v_ai_rate, 'FM9,999.99') END;
            --v_ai_rate_ch := TO_CHAR(v_ai_rate, 'FM9,999.99');
         ELSIF v_ai_rate >= 0.1 THEN
            v_ai_rate_ch := TO_CHAR(v_ai_rate, 'FM0.99');
         ELSIF v_ai_rate >= 0.01 THEN
            v_ai_rate_ch := TO_CHAR(v_ai_rate, 'FM0.999');
         ELSIF v_ai_rate >= 0.001 THEN
            v_ai_rate_ch := TO_CHAR(v_ai_rate, 'FM0.9999');
         ELSIF v_ai_rate >= 0.0001 THEN
            v_ai_rate_ch := TO_CHAR(v_ai_rate, 'FM0.99999');
         ELSIF v_ai_rate >= 0.00001 THEN
            v_ai_rate_ch := TO_CHAR(v_ai_rate, 'FM0.999999');
         ELSIF v_ai_rate >= 0.000001 THEN
            v_ai_rate_ch := TO_CHAR(v_ai_rate, 'FM0.9999999');
         ELSIF v_ai_rate >= 0.0000001 THEN
            v_ai_rate_ch := TO_CHAR(v_ai_rate, 'FM0.99999999');
         ELSE
            v_ai_rate_ch := TO_CHAR(v_ai_rate, 'FM0.9999999999');
         END IF;

         IF v_prod_rate >= 100 THEN
            v_prod_rate_ch := TO_CHAR(v_prod_rate, 'FM9,999,999,999');
         ELSIF v_prod_rate >= 1.0 THEN
            v_prod_rate_ch := CASE WHEN REMAINDER(v_prod_rate, 1) = 0 THEN TO_CHAR(v_prod_rate, 'FM9,999') ELSE TO_CHAR(v_prod_rate, 'FM9,999.99') END;
            --v_prod_rate_ch := TO_CHAR(v_prod_rate, 'FM9,999.99');
         ELSIF v_prod_rate >= 0.1 THEN
            v_prod_rate_ch := TO_CHAR(v_prod_rate, 'FM0.99');
         ELSIF v_prod_rate >= 0.01 THEN
            v_prod_rate_ch := TO_CHAR(v_prod_rate, 'FM0.999');
         ELSIF v_prod_rate >= 0.001 THEN
            v_prod_rate_ch := TO_CHAR(v_prod_rate, 'FM0.9999');
         ELSIF v_prod_rate >= 0.0001 THEN
            v_prod_rate_ch := TO_CHAR(v_prod_rate, 'FM0.99999');
         ELSE
            v_prod_rate_ch := TO_CHAR(v_prod_rate, 'FM0.999999');
         END IF;

         /* Get median rate
          */
         IF v_median_ai >= 100 THEN
            v_median_ai_ch := TO_CHAR(v_median_ai, 'FM9,999,999,999');
         ELSIF v_median_ai >= 1.0 THEN
            v_median_ai_ch := CASE WHEN REMAINDER(v_median_ai, 1) = 0 THEN TO_CHAR(v_median_ai, 'FM9,999') ELSE TO_CHAR(v_median_ai, 'FM9,999.99') END;
            --v_median_ai_ch := TO_CHAR(v_median_ai, 'FM9,999.99');
         ELSIF v_median_ai >= 0.1 THEN
            v_median_ai_ch := TO_CHAR(v_median_ai, 'FM0.99');
         ELSIF v_median_ai >= 0.01 THEN
            v_median_ai_ch := TO_CHAR(v_median_ai, 'FM0.999');
         ELSIF v_median_ai >= 0.001 THEN
            v_median_ai_ch := TO_CHAR(v_median_ai, 'FM0.9999');
         ELSIF v_median_ai >= 0.0001 THEN
            v_median_ai_ch := TO_CHAR(v_median_ai, 'FM0.99999');
         ELSE
            v_median_ai_ch := TO_CHAR(v_median_ai, 'FM0.999999');
         END IF;

         /* Get maximum label rate
          */
         IF v_max_label_prod >= 100 THEN
            v_max_label_ch := TO_CHAR(v_max_label_prod, 'FM9,999,999,999');
         ELSIF v_max_label_prod >= 1.0 THEN
            v_max_label_ch := CASE WHEN REMAINDER(v_max_label_prod, 1) = 0 THEN TO_CHAR(v_max_label_prod, 'FM9,999') ELSE TO_CHAR(v_max_label_prod, 'FM9,999.99') END;
            --v_max_label_ch := TO_CHAR(v_max_label_prod, 'FM9,999.99');
         ELSIF v_max_label_prod >= 0.1 THEN
            v_max_label_ch := TO_CHAR(v_max_label_prod, 'FM0.99');
         ELSIF v_max_label_prod >= 0.01 THEN
            v_max_label_ch := TO_CHAR(v_max_label_prod, 'FM0.999');
         ELSIF v_max_label_prod >= 0.001 THEN
            v_max_label_ch := TO_CHAR(v_max_label_prod, 'FM0.9999');
         ELSIF v_max_label_prod >= 0.0001 THEN
            v_max_label_ch := TO_CHAR(v_max_label_prod, 'FM0.99999');
         ELSE
            v_max_label_ch := TO_CHAR(v_max_label_prod, 'FM0.999999');
         END IF;

         /* Get acre treated
          */
         IF p_acre_treated >= 100 THEN
            v_acre_treated_orig_ch := TO_CHAR(p_acre_treated, 'FM9,999,999,999');
         ELSIF p_acre_treated >= 1.0 THEN
            v_acre_treated_orig_ch := CASE WHEN REMAINDER(p_acre_treated, 1) = 0 THEN TO_CHAR(p_acre_treated, 'FM9,999') ELSE TO_CHAR(p_acre_treated, 'FM9,999.99') END;
         ELSIF p_acre_treated >= 0.1 THEN
            v_acre_treated_orig_ch := TO_CHAR(p_acre_treated, 'FM0.99');
         ELSIF p_acre_treated >= 0.01 THEN
            v_acre_treated_orig_ch := TO_CHAR(p_acre_treated, 'FM0.999');
         ELSIF p_acre_treated >= 0.001 THEN
            v_acre_treated_orig_ch := TO_CHAR(p_acre_treated, 'FM0.9999');
         ELSIF p_acre_treated >= 0.0001 THEN
            v_acre_treated_orig_ch := TO_CHAR(p_acre_treated, 'FM0.99999');
         ELSE
            v_acre_treated_orig_ch := TO_CHAR(p_acre_treated, 'FM0.999999');
         END IF;

         /* Get lbs_prd_used
          */
         IF p_lbs_prd_used >= 100 THEN
            v_lbs_prd_used_orig_ch := TO_CHAR(p_lbs_prd_used, 'FM9,999,999,999');
         ELSIF p_lbs_prd_used >= 1.0 THEN
            v_lbs_prd_used_orig_ch := CASE WHEN REMAINDER(p_lbs_prd_used, 1) = 0 THEN TO_CHAR(p_lbs_prd_used, 'FM9,999') ELSE TO_CHAR(p_lbs_prd_used, 'FM9,999.99') END;
         ELSIF p_lbs_prd_used >= 0.1 THEN
            v_lbs_prd_used_orig_ch := TO_CHAR(p_lbs_prd_used, 'FM0.99');
         ELSIF p_lbs_prd_used >= 0.01 THEN
            v_lbs_prd_used_orig_ch := TO_CHAR(p_lbs_prd_used, 'FM0.999');
         ELSIF p_lbs_prd_used >= 0.001 THEN
            v_lbs_prd_used_orig_ch := TO_CHAR(p_lbs_prd_used, 'FM0.9999');
         ELSIF p_lbs_prd_used >= 0.0001 THEN
            v_lbs_prd_used_orig_ch := TO_CHAR(p_lbs_prd_used, 'FM0.99999');
         ELSE
            v_lbs_prd_used_orig_ch := TO_CHAR(p_lbs_prd_used, 'FM0.999999');
         END IF;

         /* Get amt_prd_used
          */
         IF p_amt_prd_used >= 100 THEN
            v_amt_prd_used_orig_ch := TO_CHAR(p_amt_prd_used, 'FM9,999,999,999');
         ELSIF p_amt_prd_used >= 1.0 THEN
            v_amt_prd_used_orig_ch := CASE WHEN REMAINDER(p_amt_prd_used, 1) = 0 THEN TO_CHAR(p_amt_prd_used, 'FM9,999') ELSE TO_CHAR(p_amt_prd_used, 'FM9,999.99') END;
         ELSIF p_amt_prd_used >= 0.1 THEN
            v_amt_prd_used_orig_ch := TO_CHAR(p_amt_prd_used, 'FM0.99');
         ELSIF p_amt_prd_used >= 0.01 THEN
            v_amt_prd_used_orig_ch := TO_CHAR(p_amt_prd_used, 'FM0.999');
         ELSIF p_amt_prd_used >= 0.001 THEN
            v_amt_prd_used_orig_ch := TO_CHAR(p_amt_prd_used, 'FM0.9999');
         ELSIF p_amt_prd_used >= 0.0001 THEN
            v_amt_prd_used_orig_ch := TO_CHAR(p_amt_prd_used, 'FM0.99999');
         ELSE
            v_amt_prd_used_orig_ch := TO_CHAR(p_amt_prd_used, 'FM0.999999');
         END IF;

         /* Get unit treated as full word.
          */
         v_unit_treated_word := 
            CASE p_unit_treated
                  WHEN 'A' THEN 'acre'
                  WHEN 'S' THEN 'square feet'
                  WHEN 'C' THEN 'cubic feet'
                  WHEN 'K' THEN '1000 cubic feet'
                  WHEN 'P' THEN 'pound'
                  WHEN 'T' THEN 'ton'
                  WHEN 'U' THEN 'miscellaneous unit'
                  ELSE 'unknown unit'
            END;


         /* Construct the comment.
          */
         IF v_ai_rate IS NOT NULL THEN
            p_comments :=
               'Reported rate of use = '||v_ai_rate_ch||' pounds of '||lower(v_chemname)||' per '||v_unit_treated_word;
            p_comments := p_comments||
               ' (or '||v_prod_rate_ch||' pounds of product per '||v_unit_treated_word||'); ';
         ELSE
            p_comments := 'Reported rate of use is unknown; ';
         END IF;
         
         IF v_median_ai IS NOT NULL THEN
            p_comments := p_comments||
               'median rate of use is '||v_median_ai_ch||' pounds AI per '||v_unit_treated_word;
         ELSE
            p_comments := p_comments||
               'median rate of use is unknown';
         END IF;         

         IF v_max_label_prod > 0 THEN
            p_comments := p_comments||
               '; maximum label rate = '||v_max_label_ch||' pounds product per '||v_unit_treated_word;
         END IF;

         p_fixed1_rate_outlier := NULL;
         p_fixed2_rate_outlier := NULL;
         p_fixed3_rate_outlier := NULL;
         p_mean5sd_rate_outlier := NULL;
         p_mean7sd_rate_outlier := NULL;
         p_mean8sd_rate_outlier := NULL;
         p_mean10sd_rate_outlier := NULL;
         p_mean12sd_rate_outlier := NULL;

         IF v_prod_rate > v_fixed3_prod AND v_fixed3_prod > 0 THEN
            p_fixed1_rate_outlier := 'X';
            p_fixed2_rate_outlier := 'X';
            p_fixed3_rate_outlier := 'X';
            p_comments := p_comments||'; rate > fixed3 limit';
         ELSIF v_prod_rate > v_fixed2_prod AND v_fixed2_prod > 0 THEN
            p_fixed1_rate_outlier := 'X';
            p_fixed2_rate_outlier := 'X';
            p_comments := p_comments||'; rate > fixed2 limit';
         ELSIF v_prod_rate > v_fixed1_prod AND v_fixed1_prod > 0 THEN
            p_fixed1_rate_outlier := 'X';
            p_comments := p_comments||'; rate > fixed1 limit';
         END IF;

         IF v_prod_rate > v_mean12sd_prod AND v_mean12sd_prod > 0 THEN
            p_mean5sd_rate_outlier := 'X';
            p_mean7sd_rate_outlier := 'X';
            p_mean8sd_rate_outlier := 'X';
            p_mean10sd_rate_outlier := 'X';
            p_mean12sd_rate_outlier := 'X';
            p_comments := p_comments||'; rate > mean + 12*SD';
         ELSIF v_prod_rate > v_mean10sd_prod AND v_mean10sd_prod > 0 THEN
            p_mean5sd_rate_outlier := 'X';
            p_mean7sd_rate_outlier := 'X';
            p_mean8sd_rate_outlier := 'X';
            p_mean10sd_rate_outlier := 'X';
            p_comments := p_comments||'; rate > mean + 10*SD';
         ELSIF v_prod_rate > v_mean8sd_prod AND v_mean8sd_prod > 0 THEN
            p_mean5sd_rate_outlier := 'X';
            p_mean7sd_rate_outlier := 'X';
            p_mean8sd_rate_outlier := 'X';
           p_comments := p_comments||'; rate > mean + 8*SD';
         ELSIF v_prod_rate > v_mean7sd_prod AND v_mean7sd_prod > 0 THEN
            p_mean5sd_rate_outlier := 'X';
            p_mean7sd_rate_outlier := 'X';
            p_comments := p_comments||'; rate > mean + 7*SD';
         ELSIF v_prod_rate > v_mean5sd_prod AND v_mean5sd_prod > 0 THEN
            p_mean5sd_rate_outlier := 'X';
            p_comments := p_comments||'; rate > mean + 5*SD';
         END IF;

         IF v_prod_rate > v_max_label_prod AND v_max_label_prod > 0 THEN
            p_max_label_outlier := 'X';
            p_comments := p_comments||'; rate > maximum label rate';
         END IF;

         IF v_prod_rate > v_outlier_limit AND v_outlier_limit > 0  THEN
            p_limit_rate_outlier := 'X';
            p_comments := p_comments||'; rate > outlier limit';

            p_estimated_field := NULL;
            p_error_code := 75;
            p_error_type := 'POSSIBLE';
            p_replace_type := NULL;

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

            v_unit_treated_orig := p_unit_treated;
            IF Outlier_new_package.Wrong_unit
                  (v_ago_ind, v_regno_short,
                   v_site_general, p_site_code, p_lbs_prd_used,
                   p_acre_planted, p_unit_planted,
                   p_acre_treated, p_unit_treated,
                   p_replace_type)
            THEN
               p_estimated_field := 'UNIT_TREATED';
            ELSIF Outlier_new_package.Wrong_acres
               (v_ago_ind, p_site_code, p_lbs_prd_used, v_median_prod,
                p_acre_planted, p_unit_planted,
                p_acre_treated, p_unit_treated,
                p_replace_type)
            THEN
               p_estimated_field := 'ACRE_TREATED';
            ELSE
               -- DBMS_OUTPUT.PUT_LINE('3 (before wrong_lbs): p_amt_prd_used = '||p_amt_prd_used||'; error_type = '||p_error_type);
               Outlier_new_package.Wrong_lbs
               (v_prod_rate, v_median_prod, v_prodchem_pct, p_acre_treated, p_lbs_prd_used, p_amt_prd_used,
                p_replace_type);

               IF p_replace_type = 'ESTIMATE' THEN
                  p_estimated_field := 'LBS_PRD_USED';
               END IF;
               -- DBMS_OUTPUT.PUT_LINE('3 (after wrong_lbs): p_amt_prd_used = '||p_amt_prd_used||'; error_type = '||p_error_type);
            END IF;

            IF p_estimated_field = 'UNIT_TREATED' THEN
               p_comments := p_comments||'; the value for unit_treated was estimated as '||p_unit_treated||' (originally '||v_unit_treated_orig||')';
            ELSIF p_estimated_field = 'ACRE_TREATED'  THEN
               IF p_acre_treated >= 100 THEN
                  v_acre_treated_ch := TO_CHAR(p_acre_treated, 'FM9,999,999,999');
               ELSIF p_acre_treated >= 1.0 THEN
                  v_acre_treated_ch := CASE WHEN REMAINDER(p_acre_treated, 1) = 0 THEN TO_CHAR(p_acre_treated, 'FM9,999') ELSE TO_CHAR(p_acre_treated, 'FM9,999.99') END;
               ELSIF p_acre_treated >= 0.1 THEN
                  v_acre_treated_ch := TO_CHAR(p_acre_treated, 'FM0.99');
               ELSIF p_acre_treated >= 0.01 THEN
                  v_acre_treated_ch := TO_CHAR(p_acre_treated, 'FM0.999');
               ELSIF p_acre_treated >= 0.001 THEN
                  v_acre_treated_ch := TO_CHAR(p_acre_treated, 'FM0.9999');
               ELSIF p_acre_treated >= 0.0001 THEN
                  v_acre_treated_ch := TO_CHAR(p_acre_treated, 'FM0.99999');
               ELSE
                  v_acre_treated_ch := TO_CHAR(p_acre_treated, 'FM0.999999');
               END IF;

               p_comments := p_comments||'; the value for acre_treated was estimated as '||v_acre_treated_ch||' (originally '||v_acre_treated_orig_ch||')';
            ELSIF p_estimated_field = 'LBS_PRD_USED'  THEN
               IF p_lbs_prd_used >= 100 THEN
                  v_lbs_prd_used_ch := TO_CHAR(p_lbs_prd_used, 'FM9,999,999,999');
               ELSIF p_lbs_prd_used >= 1.0 THEN
                  v_lbs_prd_used_ch := CASE WHEN REMAINDER(p_lbs_prd_used, 1) = 0 THEN TO_CHAR(p_lbs_prd_used, 'FM9,999') ELSE TO_CHAR(p_lbs_prd_used, 'FM9,999.99') END;
               ELSIF p_lbs_prd_used >= 0.1 THEN
                  v_lbs_prd_used_ch := TO_CHAR(p_lbs_prd_used, 'FM0.99');
               ELSIF p_lbs_prd_used >= 0.01 THEN
                  v_lbs_prd_used_ch := TO_CHAR(p_lbs_prd_used, 'FM0.999');
               ELSIF p_lbs_prd_used >= 0.001 THEN
                  v_lbs_prd_used_ch := TO_CHAR(p_lbs_prd_used, 'FM0.9999');
               ELSIF p_lbs_prd_used >= 0.0001 THEN
                  v_lbs_prd_used_ch := TO_CHAR(p_lbs_prd_used, 'FM0.99999');
               ELSE
                  v_lbs_prd_used_ch := TO_CHAR(p_lbs_prd_used, 'FM0.999999');
               END IF;

               IF p_amt_prd_used >= 100 THEN
                  v_amt_prd_used_ch := TO_CHAR(p_amt_prd_used, 'FM9,999,999,999');
               ELSIF p_amt_prd_used >= 1.0 THEN
                  v_amt_prd_used_ch := CASE WHEN REMAINDER(p_amt_prd_used, 1) = 0 THEN TO_CHAR(p_amt_prd_used, 'FM9,999') ELSE TO_CHAR(p_amt_prd_used, 'FM9,999.99') END;
               ELSIF p_amt_prd_used >= 0.1 THEN
                  v_amt_prd_used_ch := TO_CHAR(p_amt_prd_used, 'FM0.99');
               ELSIF p_amt_prd_used >= 0.01 THEN
                  v_amt_prd_used_ch := TO_CHAR(p_amt_prd_used, 'FM0.999');
               ELSIF p_amt_prd_used >= 0.001 THEN
                  v_amt_prd_used_ch := TO_CHAR(p_amt_prd_used, 'FM0.9999');
               ELSIF p_amt_prd_used >= 0.0001 THEN
                  v_amt_prd_used_ch := TO_CHAR(p_amt_prd_used, 'FM0.99999');
               ELSE
                  v_amt_prd_used_ch := TO_CHAR(p_amt_prd_used, 'FM0.999999');
               END IF;
               p_comments := p_comments||'; the values for lbs_prd_used and amt_prd_used were estimated as '||
                                       v_lbs_prd_used_ch ||' and '||v_amt_prd_used_ch||' (originally '||v_lbs_prd_used_orig_ch||' and '||v_amt_prd_used_orig_ch||')';
            END IF;

         ELSE
            p_estimated_field := NULL;
            p_error_code := 76;
            p_error_type := 'POSSIBLE';
            p_replace_type := 'SAME';
         END IF;
      END IF;
   END IF;

   /*********************************************************************************
      Get outliers in pounds AI per application.
      These are all "non-ag" applications - more specifically records with
      record_id = 2 or C.  We include even records with a unit treated reported;
      in those case we check both its rate of use (lbs/unit) and its lbs/application.
    ********************************************************************************/
   IF p_record_id IN ('2', 'C') AND (p_error_type IS NULL OR p_error_type = 'N') THEN
      v_prod_rate := p_lbs_prd_used/CASE WHEN p_applic_cnt IS NULL OR p_applic_cnt < 1 THEN 1 ELSE p_applic_cnt END;
      --DBMS_OUTPUT.PUT_LINE('v_prod_rate = '||v_prod_rate);

      BEGIN
         SELECT  fixed1, fixed2, fixed3, 
                 median, mean5sd, mean7sd, mean8sd, mean10sd, mean12sd,
                 outlier_limit, chem_code, chemname, prodchem_pct
         INTO    v_fixed1_prod, v_fixed2_prod, v_fixed3_prod,
                 v_median_prod, v_mean5sd_prod, v_mean7sd_prod, v_mean8sd_prod, v_mean10sd_prod, v_mean12sd_prod,
                 v_outlier_limit, v_chem_code, v_chemname, v_prodchem_pct
         FROM    outlier_all_stats_nonag
         WHERE   regno_short = v_regno_short AND
                 site_general = v_site_general;

         v_has_outlier_limits := TRUE;
         --DBMS_OUTPUT.PUT_LINE('v_has_outlier_limits = TRUE');
         --DBMS_OUTPUT.PUT_LINE('v_chem_code = '||v_chem_code);
         --DBMS_OUTPUT.PUT_LINE('v_chemname = '||v_chemname);
      EXCEPTION
         WHEN OTHERS THEN
            v_has_outlier_limits := FALSE;
            --DBMS_OUTPUT.PUT_LINE('v_has_outlier_limits = FALSE');
            v_median_prod := NULL;
            v_fixed1_prod := NULL;
            v_fixed2_prod := NULL;
            v_fixed3_prod := NULL;
            v_mean5sd_prod := NULL;
            v_mean7sd_prod := NULL;
            v_mean8sd_prod := NULL;
            v_mean10sd_prod := NULL;
            v_mean12sd_prod := NULL;
            v_outlier_limit := NULL;
            v_chem_code := NULL;
            v_chemname := NULL;
      END;

      /* Determine if this rate is an outlier by each criterion.
       */
      IF v_prod_rate > 0 AND
         ((v_prod_rate > v_fixed1_prod AND v_fixed1_prod IS NOT NULL) OR
          (v_prod_rate > v_fixed2_prod AND v_fixed2_prod IS NOT NULL) OR
          (v_prod_rate > v_fixed3_prod AND v_fixed3_prod IS NOT NULL) OR
          (v_prod_rate > v_mean5sd_prod AND v_mean5sd_prod IS NOT NULL) OR
          (v_prod_rate > v_mean7sd_prod AND v_mean7sd_prod IS NOT NULL) OR
          (v_prod_rate > v_mean8sd_prod AND v_mean8sd_prod IS NOT NULL) OR
          (v_prod_rate > v_mean10sd_prod AND v_mean10sd_prod IS NOT NULL) OR
          (v_prod_rate > v_mean12sd_prod AND v_mean12sd_prod IS NOT NULL))
      THEN
         v_ai_rate := v_prod_rate*v_prodchem_pct/100;
         v_median_ai := v_median_prod*v_prodchem_pct/100;

         --DBMS_OUTPUT.PUT_LINE('v_ai_rate = '||v_ai_rate);
         /*
         --DBMS_OUTPUT.PUT_LINE('v_prod_rate = '||v_prod_rate);
         --DBMS_OUTPUT.PUT_LINE('v_fixed1_prod = '||v_fixed1_prod);
         --DBMS_OUTPUT.PUT_LINE('v_fixed2_prod = '||v_fixed2_prod);
         --DBMS_OUTPUT.PUT_LINE('v_fixed3_prod = '||v_fixed3_prod);
         --DBMS_OUTPUT.PUT_LINE('v_mean5sd_prod = '||v_mean5sd_prod);
         --DBMS_OUTPUT.PUT_LINE('v_mean7sd_prod = '||v_mean7sd_prod);
         --DBMS_OUTPUT.PUT_LINE('v_mean8sd_prod = '||v_mean8sd_prod);
         --DBMS_OUTPUT.PUT_LINE('v_mean10sd_prod = '||v_mean10sd_prod);
         --DBMS_OUTPUT.PUT_LINE('v_mean12sd_prod = '||v_mean12sd_prod);
         --DBMS_OUTPUT.PUT_LINE('v_prodchem_pct = '||v_prodchem_pct);
         */

         /* For rates of use set number of decimals to display
            based on size of the rate.
          */
         IF v_ai_rate >= 100 THEN
            v_ai_rate_ch := TO_CHAR(v_ai_rate, 'FM9,999,999,999');
         ELSIF v_ai_rate >= 1.0 THEN
            v_ai_rate_ch := CASE WHEN REMAINDER(v_ai_rate, 1) = 0 THEN TO_CHAR(v_ai_rate, 'FM9,999') ELSE TO_CHAR(v_ai_rate, 'FM9,999.99') END;
         ELSIF v_ai_rate >= 0.1 THEN
            v_ai_rate_ch := TO_CHAR(v_ai_rate, 'FM0.99');
         ELSIF v_ai_rate >= 0.01 THEN
            v_ai_rate_ch := TO_CHAR(v_ai_rate, 'FM0.999');
         ELSIF v_ai_rate >= 0.001 THEN
            v_ai_rate_ch := TO_CHAR(v_ai_rate, 'FM0.9999');
         ELSIF v_ai_rate >= 0.0001 THEN
            v_ai_rate_ch := TO_CHAR(v_ai_rate, 'FM0.99999');
         ELSIF v_ai_rate >= 0.00001 THEN
            v_ai_rate_ch := TO_CHAR(v_ai_rate, 'FM0.999999');
         ELSIF v_ai_rate >= 0.000001 THEN
            v_ai_rate_ch := TO_CHAR(v_ai_rate, 'FM0.9999999');
         ELSIF v_ai_rate >= 0.0000001 THEN
            v_ai_rate_ch := TO_CHAR(v_ai_rate, 'FM0.99999999');
         ELSE
            v_ai_rate_ch := TO_CHAR(v_ai_rate, 'FM0.9999999999');
         END IF;

         IF v_prod_rate >= 100 THEN
            v_prod_rate_ch := TO_CHAR(v_prod_rate, 'FM9,999,999,999');
         ELSIF v_prod_rate >= 1.0 THEN
            v_prod_rate_ch := CASE WHEN REMAINDER(v_prod_rate, 1) = 0 THEN TO_CHAR(v_prod_rate, 'FM9,999') ELSE TO_CHAR(v_prod_rate, 'FM9,999.99') END;
         ELSIF v_prod_rate >= 0.1 THEN
            v_prod_rate_ch := TO_CHAR(v_prod_rate, 'FM0.99');
         ELSIF v_prod_rate >= 0.01 THEN
            v_prod_rate_ch := TO_CHAR(v_prod_rate, 'FM0.999');
         ELSIF v_prod_rate >= 0.001 THEN
            v_prod_rate_ch := TO_CHAR(v_prod_rate, 'FM0.9999');
         ELSE
            v_prod_rate_ch := TO_CHAR(v_prod_rate, 'FM0.9999999');
         END IF;

         /* Get median rate
          */
         IF v_median_ai >= 100 THEN
            v_median_ai_ch := TO_CHAR(v_median_ai, 'FM9,999,999,999');
         ELSIF v_median_ai >= 1.0 THEN
            v_median_ai_ch := CASE WHEN REMAINDER(v_median_ai, 1) = 0 THEN TO_CHAR(v_median_ai, 'FM9,999') ELSE TO_CHAR(v_median_ai, 'FM9,999.99') END;
         ELSIF v_median_ai >= 0.1 THEN
            v_median_ai_ch := TO_CHAR(v_median_ai, 'FM0.99');
         ELSIF v_median_ai >= 0.01 THEN
            v_median_ai_ch := TO_CHAR(v_median_ai, 'FM0.999');
         ELSIF v_median_ai >= 0.001 THEN
            v_median_ai_ch := TO_CHAR(v_median_ai, 'FM0.9999');
         ELSE
            v_median_ai_ch := TO_CHAR(v_median_ai, 'FM0.9999999');
         END IF;

         /* Construct the comment.
          */
         IF v_ai_rate IS NOT NULL THEN
            p_comments :=
               'Reported rate of use (per application) = '||v_ai_rate_ch||' pounds of '||lower(v_chemname)||' per application';
            p_comments := p_comments||
               ' (or '||v_prod_rate_ch||' pounds of product per application) ';
         ELSE
            p_comments := 'Reported rate of use (per application) is unknown ';
         END IF;

         p_fixed1_lbsapp_outlier := NULL;
         p_fixed2_lbsapp_outlier := NULL;
         p_fixed3_lbsapp_outlier := NULL;
         p_mean5sd_lbsapp_outlier := NULL;
         p_mean7sd_lbsapp_outlier := NULL;
         p_mean8sd_lbsapp_outlier := NULL;
         p_mean10sd_lbsapp_outlier := NULL;
         p_mean12sd_lbsapp_outlier := NULL;

         IF v_prod_rate > v_fixed3_prod AND v_fixed3_prod > 0 THEN
            p_fixed1_lbsapp_outlier := 'X';
            p_fixed2_lbsapp_outlier := 'X';
            p_fixed3_lbsapp_outlier := 'X';
            p_comments := p_comments||'; rate > fixed3 limit';
         ELSIF v_prod_rate > v_fixed2_prod AND v_fixed2_prod > 0 THEN
            p_fixed1_lbsapp_outlier := 'X';
            p_fixed2_lbsapp_outlier := 'X';
            p_comments := p_comments||'; rate > fixed2 limit';
         ELSIF v_prod_rate > v_fixed1_prod AND v_fixed1_prod > 0 THEN
            p_fixed1_lbsapp_outlier := 'X';
            p_comments := p_comments||'; rate > fixed1 limit';
         END IF;

         IF v_prod_rate > v_mean12sd_prod AND v_mean12sd_prod > 0 THEN
            p_mean5sd_lbsapp_outlier := 'X';
            p_mean7sd_lbsapp_outlier := 'X';
            p_mean8sd_lbsapp_outlier := 'X';
            p_mean10sd_lbsapp_outlier := 'X';
            p_mean12sd_lbsapp_outlier := 'X';
            p_comments := p_comments||'; rate > mean + 12*SD';
         ELSIF v_prod_rate > v_mean10sd_prod AND v_mean10sd_prod > 0 THEN
            p_mean5sd_lbsapp_outlier := 'X';
            p_mean7sd_lbsapp_outlier := 'X';
            p_mean8sd_lbsapp_outlier := 'X';
            p_mean10sd_lbsapp_outlier := 'X';
            p_comments := p_comments||'; rate > mean + 10*SD';
         ELSIF v_prod_rate > v_mean8sd_prod AND v_mean8sd_prod > 0 THEN
            p_mean5sd_lbsapp_outlier := 'X';
            p_mean7sd_lbsapp_outlier := 'X';
            p_mean8sd_lbsapp_outlier := 'X';
           p_comments := p_comments||'; rate > mean + 8*SD';
         ELSIF v_prod_rate > v_mean7sd_prod AND v_mean7sd_prod > 0 THEN
            p_mean5sd_lbsapp_outlier := 'X';
            p_mean7sd_lbsapp_outlier := 'X';
            p_comments := p_comments||'; rate > mean + 7*SD';
         ELSIF v_prod_rate > v_mean5sd_prod AND v_mean5sd_prod > 0 THEN
            p_mean5sd_lbsapp_outlier := 'X';
            p_comments := p_comments||'; rate > mean + 5*SD';
         END IF;

         IF v_prod_rate > v_outlier_limit AND v_outlier_limit > 0  THEN
            p_limit_lbsapp_outlier := 'X';
            p_comments := p_comments||'; rate > outlier limit';

            p_estimated_field := NULL;
            p_error_code := 75;
            p_error_type := 'POSSIBLE';
            p_replace_type := NULL;

            Outlier_new_package.Wrong_lbs_app
               (v_prod_rate, v_median_prod, v_prodchem_pct, p_applic_cnt, p_lbs_prd_used, p_amt_prd_used,
                p_replace_type);
         
            IF p_replace_type = 'ESTIMATE' THEN
               p_estimated_field := 'LBS_PRD_USED';
               p_comments := p_comments||'; the values for lbs_prd_used and amt_prd_used were estimated as '||
                                       p_lbs_prd_used ||' and '||p_amt_prd_used;
            END IF;
            -- DBMS_OUTPUT.PUT_LINE('3 (after wrong_lbs): p_amt_prd_used = '||p_amt_prd_used||'; error_type = '||p_error_type);
            
         ELSE
            p_estimated_field := NULL;
            p_error_code := 76;
            p_error_type := 'POSSIBLE';
            p_replace_type := 'SAME';
         END IF;
      END IF;

   END IF;
EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(SQLERRM);
END Outliers_test;
/
show errors


