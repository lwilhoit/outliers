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
/*
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
*/
/*
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
               use_no <= 12000;
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
END;
/
show errors
*/

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
               use_no BETWEEN 1000001 AND 2000000;
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
END;
/
show errors


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
               use_no BETWEEN 2000001 AND 3000000;
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
END;
/
show errors


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
               use_no > 3000001;
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
END;
/
show errors




