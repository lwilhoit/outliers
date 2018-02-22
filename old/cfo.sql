SET pause OFF
SET pagesize 75
SET linesize 120
SET termout ON
SET feedback ON
SET document ON
SET verify ON
SET trimspool ON
SET numwidth 11
SET SERVEROUTPUT ON SIZE 1000000 FORMAT WORD_WRAPPED

DROP TABLE fixed_outlier_rates_stats_test;
CREATE TABLE fixed_outlier_rates_stats_test
   (ago_ind             VARCHAR2(1),
    unit_treated        VARCHAR2(1),
    site_type           VARCHAR2(20),
    chem_code           INTEGER,
    chemname            VARCHAR2(200),
    ai_adjuvant         VARCHAR2(1),
    num_years           INTEGER,
    num_recs            INTEGER,
    num_recs_last_8yr   INTEGER,
    num_01             INTEGER,
    num_01_last_8yr    INTEGER)
NOLOGGING
PCTUSED 95
PCTFREE 3
STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0)
TABLESPACE pur_report;


INSERT INTO fixed_outlier_rates_stats_test
      SELECT   CASE WHEN pur.record_id IN ('2', 'C') OR pur.site_code < 100 OR pur.site_code > 29500
						  THEN 'N' ELSE 'A' END ago_ind,
               CASE WHEN unit_treated = 'S' THEN 'A'
                    WHEN unit_treated = 'T' THEN 'P'
                    WHEN unit_treated = 'K' THEN 'C'
                    ELSE unit_treated END unit_treated,
               CASE WHEN pur.record_id IN ('2', 'C') OR pur.site_code < 100 OR pur.site_code > 29500 THEN
                    CASE  WHEN site_code IN (65000, 65011, 65015, 65021, 65026, 65029, 65503, 65505) 
                          THEN 'WATER'
                          ELSE 'OTHER'
                    END
                    ELSE 'ALL'                       
               END site_type,
               chem_code, chemname, 
               CASE WHEN chem_code IS NULL THEN 'N' ELSE ca.adjuvant END ai_adjuvant, 
               COUNT(distinct year) num_years,
               COUNT(*) num_recs,
               SUM(CASE WHEN year BETWEEN (&&1 - 7) AND &&1 THEN 1 END) num_recs_last_8yr,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 0.1
                        THEN 1 END) num_01,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 0.1 AND
                              year BETWEEN (&&1 - 7) AND &&1
                        THEN 1 END) num_01_last_8yr
      FROM     pur LEFT JOIN prod_chem_major_ai pcma USING (prodno)
                   LEFT JOIN chemical USING (chem_code)
                   LEFT JOIN chem_adjuvant ca USING (chem_code)
      WHERE    year between (&&1 - &&2 + 1) and &&1 AND
               unit_treated IS NOT NULL AND
               acre_treated > 0 AND
               lbs_prd_used > 0 
               &&3 AND county_cd = '26' &&4
      GROUP BY CASE WHEN pur.record_id IN ('2', 'C') OR pur.site_code < 100 OR pur.site_code > 29500
						  THEN 'N' ELSE 'A' END,
               CASE WHEN unit_treated = 'S' THEN 'A'
                    WHEN unit_treated = 'T' THEN 'P'
                    WHEN unit_treated = 'K' THEN 'C'
                    ELSE unit_treated END,
               CASE WHEN pur.record_id IN ('2', 'C') OR pur.site_code < 100 OR pur.site_code > 29500 THEN
                    CASE  WHEN site_code IN (65000, 65011, 65015, 65021, 65026, 65029, 65503, 65505) 
                          THEN 'WATER'
                          ELSE 'OTHER'
                    END
                    ELSE 'ALL'                       
               END,
               chem_code, chemname, 
               CASE WHEN chem_code IS NULL THEN 'N' ELSE ca.adjuvant END; 
