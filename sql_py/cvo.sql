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

DROP TABLE Outliers_test_results;
CREATE TABLE Outliers_test_results
   (use_no              INTEGER,
    ago_ind             VARCHAR2(1),
    record_id           VARCHAR2(1),
    unit_treated 			VARCHAR2(1),
    regno_short			VARCHAR2(20),
    site_general        VARCHAR2(100),
    site_type           VARCHAR2(100),
    site_code           INTEGER,
    site_name           VARCHAR2(100),
    chem_code           INTEGER,
    chemname            VARCHAR2(200), -- The AI which resulted in this product having outlier
    prodchem_pct        NUMBER,
    ai_rate_type        VARCHAR2(50),
    prodno              INTEGER,
    lbs_prd_used        NUMBER,
    amt_treated         NUMBER,
    acre_treated        NUMBER,
    unit_treated_report VARCHAR2(1),
    lbs_ai              NUMBER,
    ai_rate             NUMBER,
    prod_rate           NUMBER,
    fixed1              VARCHAR2(1),
    fixed2              VARCHAR2(1),
    fixed3              VARCHAR2(1),
    mean5sd   				VARCHAR2(1),
    mean7sd   				VARCHAR2(1),
    mean8sd   				VARCHAR2(1),
    mean10sd   			VARCHAR2(1),
    mean12sd   			VARCHAR2(1),
    outlier_limit       VARCHAR2(1),
    comments            VARCHAR2(2000),
    estimated_field     VARCHAR2(100),
    error_code          INTEGER,
    error_type          VARCHAR2(100),
    replace_type        VARCHAR2(100))
NOLOGGING
PCTUSED 95
PCTFREE 3
STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0)
TABLESPACE pur_report;

DECLARE
   v_fixed1          VARCHAR2(1);
   v_fixed2          VARCHAR2(1);
   v_fixed3          VARCHAR2(1);
   v_mean5           VARCHAR2(1);
   v_mean7           VARCHAR2(1);
   v_mean8           VARCHAR2(1);
   v_mean10          VARCHAR2(1);
   v_mean12          VARCHAR2(1);
   v_outlier_limit   VARCHAR2(1);
   v_comments        VARCHAR2(1000);
   v_estimated_field VARCHAR2(100);
   v_error_code      INTEGER;
   v_error_type      VARCHAR2(100);
   v_replace_type    VARCHAR2(100);

   v_index           INTEGER;

   CURSOR raw_cur IS
      SELECT   *
      FROM     ai_raw_rates left JOIN chemical using (chem_code)
      WHERE    year = 2016 AND
               use_no < 10000;
BEGIN
   v_index := 0;
   FOR raw_rec IN raw_cur LOOP
      Outliers_test(raw_rec.record_id, raw_rec.prodno, raw_rec.site_code, raw_rec.lbs_prd_used, 
                    raw_rec.acre_treated, raw_rec.unit_treated_report, 
                    v_fixed1, v_fixed2, v_fixed3, 
                    v_mean5, v_mean7, v_mean8, v_mean10, v_mean12, v_outlier_limit, 
                    v_comments, v_estimated_field, v_error_code, v_error_type, v_replace_type);

      INSERT INTO Outliers_test_results VALUES
         (raw_rec.use_no, raw_rec.ago_ind, raw_rec.record_id, raw_rec.unit_treated, raw_rec.regno_short, 
          raw_rec.site_general, raw_rec.site_type, raw_rec.site_code, raw_rec.site_name,
          raw_rec.chem_code, raw_rec.chemname, raw_rec.prodchem_pct,
          raw_rec.ai_rate_type, 
          raw_rec.prodno, raw_rec.lbs_prd_used, raw_rec.amt_treated, raw_rec.acre_treated, raw_rec.unit_treated_report, 
          raw_rec.lbs_ai, raw_rec.ai_rate, raw_rec.prod_rate,
          v_fixed1, v_fixed2, v_fixed3, 
          v_mean5, v_mean7, v_mean8, v_mean10, v_mean12, v_outlier_limit, 
          v_comments, v_estimated_field, v_error_code, v_error_type, v_replace_type);

      v_index := v_index + 1;
      IF v_index > 100 THEN
         v_index := 0;
         COMMIT;
      END IF;

   END LOOP;
   COMMIT;

EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(SQLERRM);
END Outliers_test;
/
show errors


variable fixed1 VARCHAR2(1);
variable fixed2 VARCHAR2(1);
variable fixed3 VARCHAR2(1);
variable mean5 VARCHAR2(1);
variable mean7 VARCHAR2(1);
variable mean8 VARCHAR2(1);
variable mean10 VARCHAR2(1);
variable mean12 VARCHAR2(1);
variable outlier_limit VARCHAR2(1);
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

    p_fixed1_rate_outlier OUT VARCHAR2,
    p_fixed2_rate_outlier OUT VARCHAR2,
    p_fixed3_rate_outlier OUT VARCHAR2,
    p_mean5sd_rate_outlier OUT VARCHAR2,
    p_mean7sd_rate_outlier OUT VARCHAR2,
    p_mean8sd_rate_outlier OUT VARCHAR2,
    p_mean10sd_rate_outlier OUT VARCHAR2,
    p_mean12sd_rate_outlier OUT VARCHAR2,
    p_outlier_limit_outlier OUT VARCHAR2,

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
   v_median_prod            NUMBER;          
   v_median_ai            NUMBER;          
   v_fixed1_prod               NUMBER := NULL;
   v_fixed2_prod               NUMBER := NULL;
   v_fixed3_prod               NUMBER := NULL;
   v_mean5sd_prod            NUMBER := NULL;
   v_mean7sd_prod            NUMBER := NULL;
   v_mean8sd_prod            NUMBER := NULL;
   v_mean10sd_prod            NUMBER := NULL;
   v_mean12sd_prod            NUMBER := NULL;
   v_max_label_prod            NUMBER;

   v_ai_rate_ch            VARCHAR2(100);
   v_prod_rate_ch            VARCHAR2(100);
   v_median_ai_ch           VARCHAR2(100);
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
         /* For rates of use set number of decimals to display
            based on size of the rate.
          */
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

         IF v_ai_rate >= 100 THEN
            v_ai_rate_ch := TO_CHAR(v_ai_rate, 'FM9,999,999,999');
         ELSIF v_ai_rate >= 1.0 THEN
            v_ai_rate_ch := CASE WHEN REMAINDER(v_ai_rate, 1) = 0 THEN TO_CHAR(v_ai_rate, 'FM9,999') ELSE TO_CHAR(v_ai_rate, 'FM9,999.99') END;
            --v_ai_rate_ch := TO_CHAR(v_ai_rate, 'FM9,999.99');
         ELSIF v_ai_rate >= 0.001 THEN
            v_ai_rate_ch := TO_CHAR(v_ai_rate, 'FM0.99999');
         ELSE
            v_ai_rate_ch := TO_CHAR(v_ai_rate, 'FM0.9999999');
         END IF;

         IF v_prod_rate >= 100 THEN
            v_prod_rate_ch := TO_CHAR(v_prod_rate, 'FM9,999,999,999');
         ELSIF v_prod_rate >= 1.0 THEN
            v_prod_rate_ch := CASE WHEN REMAINDER(v_prod_rate, 1) = 0 THEN TO_CHAR(v_prod_rate, 'FM9,999') ELSE TO_CHAR(v_prod_rate, 'FM9,999.99') END;
            --v_prod_rate_ch := TO_CHAR(v_prod_rate, 'FM9,999.99');
         ELSIF v_prod_rate >= 0.001 THEN
            v_prod_rate_ch := TO_CHAR(v_prod_rate, 'FM0.99999');
         ELSE
            v_prod_rate_ch := TO_CHAR(v_prod_rate, 'FM0.9999999');
         END IF;

         /* Get median rate
          */
         IF v_median_ai >= 100 THEN
            v_median_ai_ch := TO_CHAR(v_median_ai, 'FM9,999,999,999');
         ELSIF v_median_ai >= 1.0 THEN
            v_median_ai_ch := TO_CHAR(v_median_ai, 'FM9,999.99');
         ELSIF v_median_ai >= 0.001 THEN
            v_median_ai_ch := TO_CHAR(v_median_ai, 'FM0.99999');
         ELSE
            v_median_ai_ch := TO_CHAR(v_median_ai, 'FM0.9999999');
         END IF;

         /* Get maximum label rate
          */
         IF v_max_label_prod >= 100 THEN
            v_max_label_ch := TO_CHAR(v_max_label_prod, 'FM9,999,999,999');
         ELSIF v_max_label_prod >= 1.0 THEN
            v_max_label_ch := TO_CHAR(v_max_label_prod, 'FM9,999.99');
         ELSIF v_max_label_prod >= 0.001 THEN
            v_max_label_ch := TO_CHAR(v_max_label_prod, 'FM0.99999');
         ELSE
            v_max_label_ch := TO_CHAR(v_max_label_prod, 'FM0.9999999');
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
               '; maximum label rate = '||v_max_label_ch||' pounds AI per '||v_unit_treated_word;
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

         IF v_prod_rate > v_outlier_limit AND v_outlier_limit > 0  THEN
            p_outlier_limit_outlier := 'X';
            p_comments := p_comments||'; rate > outlier limit';

            p_estimated_field := NULL;
            p_error_code := 75;
            p_error_type := 'POSSIBLE';
            p_replace_type := NULL;

         END IF;

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

   END IF;
EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(SQLERRM);
END Outliers_test;
/
show errors


SELECT   ago_ind, product.prodno, chem_code, chemname, ai_group, ai_rate_type, prodchem_pct, site_general, oas.site_type, psg.site_code, oas.unit_treated,
			median median_prod, median*prodchem_pct/100 median_ai,
         CASE oas.unit_treated
               WHEN 'S' THEN max_rate/43560
               WHEN 'K' THEN max_rate*1000
               WHEN 'T' THEN max_rate*2000
               ELSE max_rate
            END * 1.1 max_label_rate,
         mean5sd, mean7sd, mean8sd, mean10sd, mean12sd, fixed1, fixed2, fixed3, outlier_limit
FROM     outlier_all_stats oas left JOIN product ON regno_short = mfg_firmno||'-'||label_seq_no
                           left JOIN pur_site_groups psg using (site_general)
                           LEFT JOIN max_label_rates mlr on mlr.prodno = product.prodno AND
                                                         mlr.unit_treated = CASE oas.unit_treated
                                                                                 WHEN 'S' THEN 'A'
                                                                                 WHEN 'K' THEN 'C'
                                                                                 WHEN 'T' THEN 'P'
                                                                                 ELSE oas.unit_treated
                                                                              END
WHERE    regno_short = '100-1093'
ORDER BY ago_ind, regno_short, product.prodno, chem_code, site_general, psg.site_code, oas.unit_treated;

SELECT   ago_ind, 
         CASE unit_treated
               WHEN 'S' THEN 'A'
               WHEN 'K' THEN 'C'
               WHEN 'T' THEN 'P'
               ELSE unit_treated
            END unit_treated, 
         ai_rate_type, site_type,
         MIN(CASE unit_treated
               WHEN 'S' THEN fixed2/43560
               WHEN 'K' THEN fixed2*1000
               WHEN 'T' THEN fixed2*2000
               ELSE fixed2
            END*prodchem_pct/100) min_fixed2, 
         MAX(CASE unit_treated
               WHEN 'S' THEN fixed2/43560
               WHEN 'K' THEN fixed2*1000
               WHEN 'T' THEN fixed2*2000
               ELSE fixed2
            END*prodchem_pct/100) max_fixed2
FROM     outlier_all_stats
GROUP BY ago_ind, 
         CASE unit_treated
               WHEN 'S' THEN 'A'
               WHEN 'K' THEN 'C'
               WHEN 'T' THEN 'P'
               ELSE unit_treated
            END unit_treated, 
         ai_rate_type, site_type
ORDER BY ago_ind, 
         CASE unit_treated
               WHEN 'S' THEN 'A'
               WHEN 'K' THEN 'C'
               WHEN 'T' THEN 'P'
               ELSE unit_treated
            END unit_treated, 
         ai_rate_type, site_type;

SELECT   ago_ind, 
         CASE unit_treated
               WHEN 'S' THEN 'A'
               WHEN 'K' THEN 'C'
               WHEN 'T' THEN 'P'
               ELSE unit_treated
            END gen_unit_treated, 
         unit_treated,
         ai_rate_type, site_type,
         CASE unit_treated
               WHEN 'S' THEN fixed2/43560
               WHEN 'K' THEN fixed2*1000
               WHEN 'T' THEN fixed2*2000
               ELSE fixed2
            END*prodchem_pct/100 gen_fixed2_ai,
         fixed2*prodchem_pct/100 fixed_ai,
         fixed2
FROM     outlier_all_stats
WHERE    ago_ind = 'A' AND
         unit_treated IN ('A', 'S') AND
         ai_rate_type = 'NORMAL' AND
         site_type = 'ALL'
ORDER BY CASE unit_treated
               WHEN 'S' THEN fixed2/43560
               WHEN 'K' THEN fixed2*1000
               WHEN 'T' THEN fixed2*2000
               ELSE fixed2
         END DESC,
         fixed2*prodchem_pct/100,
         fixed2;

SELECT   ago_ind,
         CASE unit_treated
               WHEN 'S' THEN 'A'
               WHEN 'K' THEN 'C'
               WHEN 'T' THEN 'P'
               ELSE unit_treated
            END gen_unit_treated,
         unit_treated,
         ai_rate_type, site_type,
         product.prodno, chem_code, chemname, ai_group, prodchem_pct, 
         site_code, site_name,
         CASE unit_treated
               WHEN 'S' THEN fixed2/43560
               WHEN 'K' THEN fixed2*1000
               WHEN 'T' THEN fixed2*2000
               ELSE fixed2
            END*prodchem_pct/100 gen_fixed2_ai,
         fixed2*prodchem_pct/100 fixed_ai,
         fixed2, 
         outlier_limit,
         outlier_limit*prodchem_pct/100 outlier_limit_ai
FROM     outlier_all_stats oas left JOIN product ON regno_short = mfg_firmno||'-'||label_seq_no
                           left JOIN pur_site_groups psg using (site_general)
WHERE    ago_ind = 'A' AND
         unit_treated IN ('A', 'S') AND
         ai_rate_type = 'NORMAL' AND
         site_type = 'ALL' AND
         prodno = 61490
ORDER BY CASE unit_treated
               WHEN 'S' THEN fixed2/43560
               WHEN 'K' THEN fixed2*1000
               WHEN 'T' THEN fixed2*2000
               ELSE fixed2
         END DESC,
         fixed2*prodchem_pct/100,
         fixed2;

SELECT   ago_ind,
         CASE unit_treated
               WHEN 'S' THEN 'A'
               WHEN 'K' THEN 'C'
               WHEN 'T' THEN 'P'
               ELSE unit_treated
            END gen_unit_treated,
         unit_treated,
         ai_rate_type, site_type,
         regno_short,  chem_code, chemname, ai_group, prodchem_pct, 
         CASE unit_treated
               WHEN 'S' THEN fixed2/43560
               WHEN 'K' THEN fixed2*1000
               WHEN 'T' THEN fixed2*2000
               ELSE fixed2
            END*prodchem_pct/100 gen_fixed2_ai,
         fixed2*prodchem_pct/100 fixed_ai,
         fixed2, 
         outlier_limit,
         outlier_limit*prodchem_pct/100 outlier_limit_ai
FROM     outlier_all_stats oas 
WHERE    ago_ind = 'A' AND
         unit_treated IN ('A', 'S') AND
         ai_rate_type = 'NORMAL' AND
         site_type = 'ALL' AND
         regno_short = '67986-1'
ORDER BY CASE unit_treated
               WHEN 'S' THEN fixed2/43560
               WHEN 'K' THEN fixed2*1000
               WHEN 'T' THEN fixed2*2000
               ELSE fixed2
         END DESC,
         fixed2*prodchem_pct/100,
         fixed2;



SELECT   year, CASE WHEN record_id IN ('2', 'C', 'G') THEN 'N' ELSE 'A' END ag_ind, 
         MAX(lbs_prd_used) max_lbs
FROM     pur
GROUP BY year, CASE WHEN record_id IN ('2', 'C', 'G') THEN 'N' ELSE 'A' END
ORDER BY year, CASE WHEN record_id IN ('2', 'C', 'G') THEN 'N' ELSE 'A' END;

SELECT   year, unit_treated, CASE WHEN record_id IN ('2', 'C', 'G') THEN 'N' ELSE 'A' END ag_ind, 
         MAX(lbs_prd_used/acre_treated) max_rate
FROM     pur
WHERE    acre_treated > 0
GROUP BY year, unit_treated, CASE WHEN record_id IN ('2', 'C', 'G') THEN 'N' ELSE 'A' END
ORDER BY year, unit_treated, CASE WHEN record_id IN ('2', 'C', 'G') THEN 'N' ELSE 'A' END;

SELECT   year, unit_treated_report unit, CASE WHEN record_id IN ('2', 'C', 'G') THEN 'N' ELSE 'A' END ag_ind, 
         MAX(lbs_prd_used/acre_treated) max_rate,
         MAX(prod_rate) max_rate2
FROM     ai_raw_rates
WHERE    acre_treated > 0
GROUP BY year, unit_treated_report, CASE WHEN record_id IN ('2', 'C', 'G') THEN 'N' ELSE 'A' END
ORDER BY year, unit_treated_report, CASE WHEN record_id IN ('2', 'C', 'G') THEN 'N' ELSE 'A' END;

SELECT   year, unit_treated_report unit, CASE WHEN record_id IN ('2', 'C', 'G') THEN 'N' ELSE 'A' END ag_ind, 
         lbs_prd_used/acre_treated rate
FROM     ai_raw_rates
WHERE    acre_treated > 0 AND
         year = 2015 AND
         unit_treated = 'S'
GROUP BY year, unit_treated_report, CASE WHEN record_id IN ('2', 'C', 'G') THEN 'N' ELSE 'A' END
ORDER BY lbs_prd_used/acre_treated DESC;


SELECT   ai_group, mean5sd, fixed2,
         power(10, LEAST(mean5sd, 15)) mean5sd_pow,
         power(10, LEAST(fixed2, 15)) fixed2_pow
FROM     pur_report.ai_outlier_stats
WHERE    ago_ind = 'A' AND
         unit_treated = 'A' AND
         chem_code = 5940;


SELECT   regno_short, ai_group
FROM     pur_report.ai_group_stats
WHERE    ago_ind = 'A' AND
         unit_treated = 'A' AND
         site_general = 'CITRUS' AND
         chem_code = 5940;

               WHERE    chem_code = ai_rec.chem_code AND
                        regno_short = oas_rec.regno_short AND
                        site_general = oas_rec.site_general AND
                        ago_ind = oas_rec.ago_ind AND
                        unit_treated = v_gen_unit_treated;

*/
--EXECUTE Outliers_test('A', 64279, 2000, 55, 1, 'A', :fixed1, :fixed2, :fixed3, :mean5, :mean7, :mean8, :mean10, :mean12, :comments, :estimated_field, :error_code, :error_type, :replace_type);
--EXECUTE Outliers_test('A', 48721, 2002, 5, 1, 'A', :fixed1, :fixed2, :fixed3, :mean5, :mean7, :mean8, :mean10, :mean12, :comments, :estimated_field, :error_code, :error_type, :replace_type);
--EXECUTE Outliers_test('A', 48721, 2002, 0.003, 1, 'S', :fixed1, :fixed2, :fixed3, :mean5, :mean7, :mean8, :mean10, :mean12, :comments, :estimated_field, :error_code, :error_type, :replace_type);
--EXECUTE Outliers_test('A', 48721, 2008, 80, 1, 'U', :fixed1, :fixed2, :fixed3, :mean5, :mean7, :mean8, :mean10, :mean12, :comments, :estimated_field, :error_code, :error_type, :replace_type);
--EXECUTE Outliers_test('A', 48721, 2008, 80, 1, 'U', :fixed1, :fixed2, :fixed3, :mean5, :mean7, :mean8, :mean10, :mean12, :comments, :estimated_field, :error_code, :error_type, :replace_type);
--EXECUTE Outliers_test('A', 49039, 10002, 8, 1, 'A', :fixed1, :fixed2, :fixed3, :mean5, :mean7, :mean8, :mean10, :mean12, :comments, :estimated_field, :error_code, :error_type, :replace_type);
EXECUTE Outliers_test('A', 49039, 10002, 800, 1, 'A', :fixed1, :fixed2, :fixed3, :mean5, :mean7, :mean8, :mean10, :mean12, :outlier_limit, :comments, :estimated_field, :error_code, :error_type, :replace_type);
print :error_code
print :error_type
print :comments
print :fixed1
print :fixed2
print :fixed3
print :mean5
print :mean7
print :mean8
print :mean10
print :mean12
print :outlier_limit

