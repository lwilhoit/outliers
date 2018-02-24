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

variable comments VARCHAR2(1000);
variable estimated_field VARCHAR2(100);
variable error_code NUMBER;
variable error_type VARCHAR2(100);
variable replace_type VARCHAR2(100);

CREATE OR REPLACE PROCEDURE Outliers_test
   (--p_year IN NUMBER,
    --p_use_no IN NUMBER,
    p_record_id VARCHAR2,
    p_prodno IN NUMBER,
    p_site_code IN NUMBER,

    p_lbs_prd_used IN NUMBER,
    p_acre_treated IN NUMBER,
    p_unit_treated IN VARCHAR2,

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
   v_prod_rate             NUMBER;
   v_ai_rate            NUMBER;           -- AI rate uses gen_unit_treated
   --v_med_rate            NUMBER;          -- median rate uses gen_unit_treated
   v_fixed1               NUMBER := NULL;
   v_fixed2               NUMBER := NULL;
   v_fixed3               NUMBER := NULL;
   v_mean5sd            NUMBER := NULL;
   v_mean7sd            NUMBER := NULL;
   v_mean8sd            NUMBER := NULL;
   v_mean10sd            NUMBER := NULL;
   v_mean12sd            NUMBER := NULL;
   v_max_label            NUMBER;

   v_ai_rate_ch            VARCHAR2(100);
   -- v_med_rate_ch           VARCHAR2(100);
   v_max_label_ch          VARCHAR2(100);
   v_unit_treated_word     VARCHAR2(100);

   -- v_ai_lbsapp_ch          VARCHAR2(100);
   -- v_med_lbsapp_ch         VARCHAR2(100);


BEGIN
   p_comments := NULL;
   p_estimated_field := NULL;
   p_error_code := NULL;
   p_error_type := NULL;
   p_replace_type := NULL;

   -- DBMS_OUTPUT.PUT_LINE('1: use_no = '||p_use_no||'; p_amt_prd_used = '||p_amt_prd_used);
   DBMS_OUTPUT.PUT_LINE('p_record_id = '||p_record_id);
   DBMS_OUTPUT.PUT_LINE('p_prodno = '||p_prodno);
   DBMS_OUTPUT.PUT_LINE('p_site_code = '||p_site_code);
   DBMS_OUTPUT.PUT_LINE('p_lbs_prd_used = '||p_lbs_prd_used);
   DBMS_OUTPUT.PUT_LINE('p_acre_treated = '||p_acre_treated);
   DBMS_OUTPUT.PUT_LINE('p_unit_treated = '||p_unit_treated);

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
      DBMS_OUTPUT.PUT_LINE('v_prod_rate = '||v_prod_rate);
 
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
                 unit_treated = p_unit_treated;

         v_has_outlier_limits := TRUE;
         DBMS_OUTPUT.PUT_LINE('v_has_outlier_limits = TRUE');
         DBMS_OUTPUT.PUT_LINE('v_chem_code = '||v_chem_code);
         DBMS_OUTPUT.PUT_LINE('v_chemname = '||v_chemname);
      EXCEPTION
         WHEN OTHERS THEN
            v_has_outlier_limits := FALSE;
            DBMS_OUTPUT.PUT_LINE('v_has_outlier_limits = FALSE');
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
         INTO     v_max_label
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
            v_max_label := NULL;
      END;

      DBMS_OUTPUT.PUT_LINE('v_max_label = '||v_max_label);


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
      IF v_prod_rate > 0 AND
         ((v_prod_rate > v_max_label AND v_max_label IS NOT NULL) OR
          (v_prod_rate > v_fixed1 AND v_fixed1 IS NOT NULL) OR
          (v_prod_rate > v_fixed2 AND v_fixed2 IS NOT NULL) OR
          (v_prod_rate > v_fixed3 AND v_fixed3 IS NOT NULL) OR
          (v_prod_rate > v_mean5sd AND v_mean5sd IS NOT NULL) OR
          (v_prod_rate > v_mean7sd AND v_mean7sd IS NOT NULL) OR
          (v_prod_rate > v_mean8sd AND v_mean8sd IS NOT NULL) OR
          (v_prod_rate > v_mean10sd AND v_mean10sd IS NOT NULL) OR
          (v_prod_rate > v_mean12sd AND v_mean12sd IS NOT NULL))
      THEN
         /* For rates of use set number of decimals to display
            based on size of the rate.
          */
         BEGIN
            SELECT   prodchem_pct
            INTO     v_prodchem_pct
            FROM     prod_chem
            WHERE    prodno = p_prodno AND
                     chem_code = v_chem_code;
         EXCEPTION
            WHEN OTHERS THEN
               v_prodchem_pct := NULL;
         END;
         DBMS_OUTPUT.PUT_LINE('v_prodchem_pct = '||v_prodchem_pct);

         v_ai_rate := v_prod_rate*v_prodchem_pct/100;
         DBMS_OUTPUT.PUT_LINE('v_ai_rate = '||v_ai_rate);

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
         /*
         IF v_med_rate >= 100 THEN
            v_med_rate_ch := TO_CHAR(v_med_rate, 'FM9,999,999,999');
         ELSIF v_med_rate >= 1.0 THEN
            v_med_rate_ch := TO_CHAR(v_med_rate, 'FM9,999.99');
         ELSIF v_med_rate >= 0.001 THEN
            v_med_rate_ch := TO_CHAR(v_med_rate, 'FM0.99999');
         ELSE
            v_med_rate_ch := TO_CHAR(v_med_rate, 'FM0.9999999');
         END IF;
         */

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
               'Reported rate of use = '||v_ai_rate_ch||' pounds AI per '||v_unit_treated_word||' for '||INITCAP(v_chemname)||'; ';
         ELSE
            p_comments := 'Reported rate of use is unknown;';
         END IF;

         /*
         IF v_med_rate IS NOT NULL THEN
            p_comments := p_comments||
               'median rate of use in '||v_stat_year||' = '||v_med_rate_ch||' pounds AI per '||v_unit_treated_word;
         ELSE
            p_comments := p_comments||
               'median rate of use in '||v_stat_year||' is unknown';
         END IF;
         */

         IF v_max_label > 0 THEN
            p_comments := p_comments||
               '; maximum label rate = '||v_max_label_ch||' pounds AI per '||v_unit_treated_word;
         END IF;

         p_estimated_field := NULL;
         p_error_code := 75;
         p_error_type := 'POSSIBLE';
         p_replace_type := NULL;
      END IF;
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(SQLERRM);
END Outliers_test;
/
show errors


EXECUTE Outliers_test('A', 64279, 2000, 55, 1, 'A', :comments, :estimated_field, :error_code, :error_type, :replace_type);
print :error_code
print :error_type
print :comments

