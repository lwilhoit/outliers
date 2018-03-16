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
CREATE TABLE ai_raw_rates_test
   (year                     NUMBER(4),
    use_no                  INTEGER,
    record_id              VARCHAR2(1),
    ago_ind                 VARCHAR2(1),
    prodno                    NUMBER(7),
    regno_short            VARCHAR2(20),
    prod_adjuvant            VARCHAR2(1),
    ai_adjuvant            VARCHAR2(1),
    formula_cd               VARCHAR2(2),
    formulation            VARCHAR2(50),
    chem_code              NUMBER(5),
    chemname               VARCHAR2(200),
    prodchem_pct            NUMBER,
    main_ai_pct             NUMBER,
    ai_rate_type            VARCHAR2(20),
    site_type               VARCHAR2(20),
    lbs_ai_app_type         VARCHAR2(20),
    site_code              NUMBER(6),
    site_name               VARCHAR2(50),
    site_general            VARCHAR2(50),
    aer_gnd_ind            VARCHAR2(1),
    applic_dt               DATE,
    month                  VARCHAR2(50),
    app_month               INTEGER,
    county_cd               VARCHAR2(2),
    county                  VARCHAR2(50),
    region                  VARCHAR2(20),
    operator_id            VARCHAR2(7),
    site_loc_id            VARCHAR2(8),
    license_no               VARCHAR2(13),
    lbs_prd_used            NUMBER(20,4),
    amt_prd_used            NUMBER(20,4),
    unit_of_meas            VARCHAR2(2),
    lbs_ai                  NUMBER,
    acre_treated            NUMBER,
    unit_treated_report    VARCHAR2(1),
    amt_treated            NUMBER,
    unit_treated             VARCHAR2(1),
    acre_planted            NUMBER,
    unit_planted            VARCHAR2(1),
    applic_cnt               INTEGER,
    prod_rate               NUMBER,
    log_prod_rate            NUMBER,
    ai_rate                NUMBER,
    log_ai_rate             NUMBER,
    lbs_prod_per_app         NUMBER,
    lbs_ai_per_app         NUMBER,
    log_lbs_ai_per_app     NUMBER
    )
NOLOGGING
PCTUSED 95
PCTFREE 3
STORAGE (INITIAL 5M NEXT 1M PCTINCREASE 0)
TABLESPACE pur;

INSERT INTO ai_raw_rates_test
   SELECT   year, use_no, record_id, ago_ind, prodno, regno_short, prod_adjuvant, ai_adjuvant, formula_cd, 
            formulation, chem_code, chemname, prodchem_pct, main_ai_pct, ai_rate_type, site_type, 
            lbs_ai_app_type, site_code, site_name, site_general, aer_gnd_ind, applic_dt, month, 
            app_month, county_cd, county, region, operator_id, site_loc_id, license_no, lbs_prd_used, 
            amt_prd_used, unit_of_meas, lbs_ai, acre_treated, unit_treated_report, amt_treated, unit_treated, 
            acre_planted, unit_planted, applic_cnt, prod_rate, log_prod_rate, ai_rate, log_ai_rate, 
            lbs_prod_per_app, lbs_ai_per_app, log_lbs_ai_per_app
   FROM     ai_raw_rates left JOIN chemical using (chem_code)
   WHERE    year = 2016 AND
            use_no IN (SELECT use_no FROM Outliers_test_results_old2 WHERE error_code IS NOT NULL);

COMMIT;
*/

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
    amt_prd_used        NUMBER,
    amt_treated         NUMBER,
    acre_treated        NUMBER,
    unit_treated_report VARCHAR2(1),
    applic_cnt          INTEGER,
    lbs_ai              NUMBER,
    ai_rate             NUMBER,
    prod_rate           NUMBER,
    lbs_ai_per_app      NUMBER,
    lbs_prod_per_app    NUMBER,
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
    replace_type        VARCHAR2(100),
    median_prod         NUMBER,
    fixed1_prod         NUMBER,
    fixed2_prod         NUMBER,
    fixed3_prod         NUMBER,
    mean5sd_prod   		NUMBER,
    mean7sd_prod   		NUMBER,
    mean8sd_prod   		NUMBER,
    mean10sd_prod   		NUMBER,
    mean12sd_prod   		NUMBER)
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

   v_median_prod     NUMBER;          
   v_fixed1_prod     NUMBER := NULL;
   v_fixed2_prod     NUMBER := NULL;
   v_fixed3_prod     NUMBER := NULL;
   v_mean5sd_prod    NUMBER := NULL;
   v_mean7sd_prod    NUMBER := NULL;
   v_mean8sd_prod    NUMBER := NULL;
   v_mean10sd_prod   NUMBER := NULL;
   v_mean12sd_prod   NUMBER := NULL;

   v_index           INTEGER;

   CURSOR raw_cur IS
      SELECT   *
      FROM     ai_raw_rates_test;
   /*
   CURSOR raw_cur IS
      SELECT   *
      FROM     ai_raw_rates left JOIN chemical using (chem_code)
      WHERE    year = 2016 AND
               use_no < 1000000;
   */
BEGIN
   v_index := 0;
   FOR raw_rec IN raw_cur LOOP
      Outliers_test(raw_rec.record_id, raw_rec.prodno, raw_rec.site_code, raw_rec.lbs_prd_used, 
                    raw_rec.amt_prd_used, raw_rec.acre_treated, raw_rec.unit_treated_report, 
                    raw_rec.acre_planted, raw_rec.unit_planted, raw_rec.applic_cnt, 
                    v_fixed1, v_fixed2, v_fixed3, 
                    v_mean5, v_mean7, v_mean8, v_mean10, v_mean12, v_outlier_limit, 
                    v_comments, v_estimated_field, v_error_code, v_error_type, v_replace_type,
                    v_median_prod, v_fixed1_prod, v_fixed2_prod, v_fixed3_prod,
                    v_mean5sd_prod, v_mean7sd_prod, v_mean8sd_prod, v_mean10sd_prod, v_mean12sd_prod);

      INSERT INTO Outliers_test_results VALUES
         (raw_rec.use_no, raw_rec.ago_ind, raw_rec.record_id, raw_rec.unit_treated, 
          raw_rec.regno_short, raw_rec.site_general, raw_rec.site_type, raw_rec.site_code, raw_rec.site_name,
          raw_rec.chem_code, raw_rec.chemname, raw_rec.prodchem_pct,
          raw_rec.ai_rate_type, 
          raw_rec.prodno, raw_rec.lbs_prd_used, raw_rec.amt_prd_used, raw_rec.amt_treated, raw_rec.acre_treated, 
          raw_rec.unit_treated_report, raw_rec.applic_cnt, 
          raw_rec.lbs_ai, raw_rec.ai_rate, raw_rec.prod_rate,
          raw_rec.lbs_ai_per_app, raw_rec.lbs_prod_per_app,
          v_fixed1, v_fixed2, v_fixed3, 
          v_mean5, v_mean7, v_mean8, v_mean10, v_mean12, v_outlier_limit, 
          v_comments, v_estimated_field, v_error_code, v_error_type, v_replace_type,
          v_median_prod, v_fixed1_prod, v_fixed2_prod, v_fixed3_prod,
          v_mean5sd_prod, v_mean7sd_prod, v_mean8sd_prod, v_mean10sd_prod, v_mean12sd_prod);

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

   v_median_prod     NUMBER;          
   v_fixed1_prod     NUMBER := NULL;
   v_fixed2_prod     NUMBER := NULL;
   v_fixed3_prod     NUMBER := NULL;
   v_mean5sd_prod    NUMBER := NULL;
   v_mean7sd_prod    NUMBER := NULL;
   v_mean8sd_prod    NUMBER := NULL;
   v_mean10sd_prod   NUMBER := NULL;
   v_mean12sd_prod   NUMBER := NULL;

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
                    raw_rec.amt_prd_used, raw_rec.acre_treated, raw_rec.unit_treated_report, raw_rec.applic_cnt, 
                    v_fixed1, v_fixed2, v_fixed3, 
                    v_mean5, v_mean7, v_mean8, v_mean10, v_mean12, v_outlier_limit, 
                    v_comments, v_estimated_field, v_error_code, v_error_type, v_replace_type,
                    v_median_prod, v_fixed1_prod, v_fixed2_prod, v_fixed3_prod,
                    v_mean5sd_prod, v_mean7sd_prod, v_mean8sd_prod, v_mean10sd_prod, v_mean12sd_prod);

      INSERT INTO Outliers_test_results VALUES
         (raw_rec.use_no, raw_rec.ago_ind, raw_rec.record_id, raw_rec.unit_treated, 
          raw_rec.regno_short, raw_rec.site_general, raw_rec.site_type, raw_rec.site_code, raw_rec.site_name,
          raw_rec.chem_code, raw_rec.chemname, raw_rec.prodchem_pct,
          raw_rec.ai_rate_type, 
          raw_rec.prodno, raw_rec.lbs_prd_used, raw_rec.amt_prd_used, raw_rec.amt_treated, raw_rec.acre_treated, 
          raw_rec.unit_treated_report, raw_rec.applic_cnt, 
          raw_rec.lbs_ai, raw_rec.ai_rate, raw_rec.prod_rate,
          raw_rec.lbs_ai_per_app, raw_rec.lbs_prod_per_app,
          v_fixed1, v_fixed2, v_fixed3, 
          v_mean5, v_mean7, v_mean8, v_mean10, v_mean12, v_outlier_limit, 
          v_comments, v_estimated_field, v_error_code, v_error_type, v_replace_type,
          v_median_prod, v_fixed1_prod, v_fixed2_prod, v_fixed3_prod,
          v_mean5sd_prod, v_mean7sd_prod, v_mean8sd_prod, v_mean10sd_prod, v_mean12sd_prod);

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

   v_median_prod     NUMBER;          
   v_fixed1_prod     NUMBER := NULL;
   v_fixed2_prod     NUMBER := NULL;
   v_fixed3_prod     NUMBER := NULL;
   v_mean5sd_prod    NUMBER := NULL;
   v_mean7sd_prod    NUMBER := NULL;
   v_mean8sd_prod    NUMBER := NULL;
   v_mean10sd_prod   NUMBER := NULL;
   v_mean12sd_prod   NUMBER := NULL;

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
                    raw_rec.amt_prd_used, raw_rec.acre_treated, raw_rec.unit_treated_report, raw_rec.applic_cnt, 
                    v_fixed1, v_fixed2, v_fixed3, 
                    v_mean5, v_mean7, v_mean8, v_mean10, v_mean12, v_outlier_limit, 
                    v_comments, v_estimated_field, v_error_code, v_error_type, v_replace_type,
                    v_median_prod, v_fixed1_prod, v_fixed2_prod, v_fixed3_prod,
                    v_mean5sd_prod, v_mean7sd_prod, v_mean8sd_prod, v_mean10sd_prod, v_mean12sd_prod);

      INSERT INTO Outliers_test_results VALUES
         (raw_rec.use_no, raw_rec.ago_ind, raw_rec.record_id, raw_rec.unit_treated, 
          raw_rec.regno_short, raw_rec.site_general, raw_rec.site_type, raw_rec.site_code, raw_rec.site_name,
          raw_rec.chem_code, raw_rec.chemname, raw_rec.prodchem_pct,
          raw_rec.ai_rate_type, 
          raw_rec.prodno, raw_rec.lbs_prd_used, raw_rec.amt_prd_used, raw_rec.amt_treated, raw_rec.acre_treated, 
          raw_rec.unit_treated_report, raw_rec.applic_cnt, 
          raw_rec.lbs_ai, raw_rec.ai_rate, raw_rec.prod_rate,
          raw_rec.lbs_ai_per_app, raw_rec.lbs_prod_per_app,
          v_fixed1, v_fixed2, v_fixed3, 
          v_mean5, v_mean7, v_mean8, v_mean10, v_mean12, v_outlier_limit, 
          v_comments, v_estimated_field, v_error_code, v_error_type, v_replace_type,
          v_median_prod, v_fixed1_prod, v_fixed2_prod, v_fixed3_prod,
          v_mean5sd_prod, v_mean7sd_prod, v_mean8sd_prod, v_mean10sd_prod, v_mean12sd_prod);

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

   v_median_prod     NUMBER;          
   v_fixed1_prod     NUMBER := NULL;
   v_fixed2_prod     NUMBER := NULL;
   v_fixed3_prod     NUMBER := NULL;
   v_mean5sd_prod    NUMBER := NULL;
   v_mean7sd_prod    NUMBER := NULL;
   v_mean8sd_prod    NUMBER := NULL;
   v_mean10sd_prod   NUMBER := NULL;
   v_mean12sd_prod   NUMBER := NULL;

   v_index           INTEGER;

   CURSOR raw_cur IS
      SELECT   *
      FROM     ai_raw_rates left JOIN chemical using (chem_code)
      WHERE    year = 2016 AND
               use_no > 3000000;
BEGIN
   v_index := 0;
   FOR raw_rec IN raw_cur LOOP
      Outliers_test(raw_rec.record_id, raw_rec.prodno, raw_rec.site_code, raw_rec.lbs_prd_used, 
                    raw_rec.amt_prd_used, raw_rec.acre_treated, raw_rec.unit_treated_report, raw_rec.applic_cnt, 
                    v_fixed1, v_fixed2, v_fixed3, 
                    v_mean5, v_mean7, v_mean8, v_mean10, v_mean12, v_outlier_limit, 
                    v_comments, v_estimated_field, v_error_code, v_error_type, v_replace_type,
                    v_median_prod, v_fixed1_prod, v_fixed2_prod, v_fixed3_prod,
                    v_mean5sd_prod, v_mean7sd_prod, v_mean8sd_prod, v_mean10sd_prod, v_mean12sd_prod);

      INSERT INTO Outliers_test_results VALUES
         (raw_rec.use_no, raw_rec.ago_ind, raw_rec.record_id, raw_rec.unit_treated, 
          raw_rec.regno_short, raw_rec.site_general, raw_rec.site_type, raw_rec.site_code, raw_rec.site_name,
          raw_rec.chem_code, raw_rec.chemname, raw_rec.prodchem_pct,
          raw_rec.ai_rate_type, 
          raw_rec.prodno, raw_rec.lbs_prd_used, raw_rec.amt_prd_used, raw_rec.amt_treated, raw_rec.acre_treated, 
          raw_rec.unit_treated_report, raw_rec.applic_cnt, 
          raw_rec.lbs_ai, raw_rec.ai_rate, raw_rec.prod_rate,
          raw_rec.lbs_ai_per_app, raw_rec.lbs_prod_per_app,
          v_fixed1, v_fixed2, v_fixed3, 
          v_mean5, v_mean7, v_mean8, v_mean10, v_mean12, v_outlier_limit, 
          v_comments, v_estimated_field, v_error_code, v_error_type, v_replace_type,
          v_median_prod, v_fixed1_prod, v_fixed2_prod, v_fixed3_prod,
          v_mean5sd_prod, v_mean7sd_prod, v_mean8sd_prod, v_mean10sd_prod, v_mean12sd_prod);

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

*/
