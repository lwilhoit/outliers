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
WHENEVER SQLERROR EXIT 1 ROLLBACK
WHENEVER OSERROR EXIT 1 ROLLBACK

/* Create table fixed_outlier_rates_ais, which has the ai_rate_type for
   each AI.
 
   General idea of how to determine the AI rate type of each AI:
   Use the percent of records greater than each of several different
   values, such as 500 lbs/acre, 200, 100, 50, and 10.
   Place AIs into the group in which less than 0.2% of the records
   are greater than the rate limits.
   Difficulties occur when there are no records at those limits,
   but typical rates are high for an AI could be nevertheless be
   high and the AI should be put into a high rate group.
   On the other hand, the percentage may be high but only
   because of a few extreme outliers, but otherwise typical
   rates are low, so these AIs should be put into low rate group.
 */
VARIABLE log_level NUMBER;

PROMPT ________________________________________________
PROMPT Creating fixed_outlier_lbs_app_ais table...
DECLARE
	v_table_exists		INTEGER := 0;
BEGIN
   :log_level := &&3;

	SELECT	COUNT(*)
	INTO		v_table_exists
	FROM		user_tables
	WHERE		table_name = 'FIXED_OUTLIER_LBS_APP_AIS_OLD';

   IF v_table_exists > 0 THEN
		EXECUTE IMMEDIATE 'DROP TABLE FIXED_OUTLIER_LBS_APP_AIS_OLD';
      print_info('Dropped table FIXED_OUTLIER_LBS_APP_AIS_OLD', :log_level);
   ELSE
      print_debug('Table FIXED_OUTLIER_LBS_APP_AIS_OLD does not exist.', :log_level);
	END IF;

   SELECT	COUNT(*)
   INTO		v_table_exists
   FROM		user_tables
   WHERE		table_name = 'FIXED_OUTLIER_LBS_APP_AIS';

   IF v_table_exists > 0 THEN
      EXECUTE IMMEDIATE 'RENAME FIXED_OUTLIER_LBS_APP_AIS TO FIXED_OUTLIER_LBS_APP_AIS_OLD';
		print_info('Renamed table FIXED_OUTLIER_LBS_APP_AIS to FIXED_OUTLIER_LBS_APP_AIS_OLD', :log_level);
   ELSE
      print_info('Table FIXED_OUTLIER_LBS_APP_AIS does not exist', :log_level);
   END IF;

   print_info('Create table FIXED_OUTLIER_LBS_APP_AIS now...', :log_level);
EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/
show errors

CREATE TABLE fixed_outlier_lbs_app_ais
   (lbs_ai_app_type	VARCHAR2(20),
    site_type        VARCHAR2(20),
	 chem_code			INTEGER,
	 chemname			VARCHAR2(200))
NOLOGGING
PCTUSED 95
PCTFREE 3
STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0)
TABLESPACE pur_report;

DECLARE
   v_lbs_ai_app_type    VARCHAR2(100);
   v_site_type          VARCHAR2(100);
   v_chem_code          INTEGER;
   v_chemname           VARCHAR2(500);
   v_num_xxxx_last_8yr  INTEGER;
   v_num_yyyy_last_8yr  INTEGER;
   v_num_xxxx           INTEGER;
   v_num_yyyy           INTEGER;
   v_num_recs           INTEGER;

   CURSOR pur_cur IS
      SELECT   chem_code, chemname, adjuvant,
               CASE WHEN site_general = 'STRUCTURAL PEST CONTROL' THEN 'STRUCTURAL'
                    WHEN site_general = 'LANDSCAPE MAINTENANCE' THEN 'LANDSCAPE'
                    WHEN site_code = 40 THEN 'RIGHTS_OF_WAY'
                    ELSE 'OTHER'
               END site_type,
               COUNT(distinct year) num_years,
               COUNT(*) num_recs,
               SUM(CASE WHEN year BETWEEN (&&1 - 7) AND &&1 THEN 1 END) num_recs_last_8yr,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN applic_cnt IS NULL OR applic_cnt = 0 THEN 1 ELSE applic_cnt END) > 500
                        THEN 1 END) num_500,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN applic_cnt IS NULL OR applic_cnt = 0 THEN 1 ELSE applic_cnt END) > 500 AND
                              year BETWEEN (&&1 - 7) AND &&1
                        THEN 1 END) num_500_last_8yr,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN applic_cnt IS NULL OR applic_cnt = 0 THEN 1 ELSE applic_cnt END) > 1000
                        THEN 1 END) num_1000,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN applic_cnt IS NULL OR applic_cnt = 0 THEN 1 ELSE applic_cnt END) > 1000 AND
                              year BETWEEN (&&1 - 7) AND &&1
                        THEN 1 END) num_1000_last_8yr,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN applic_cnt IS NULL OR applic_cnt = 0 THEN 1 ELSE applic_cnt END) > 2000
                        THEN 1 END) num_2000,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN applic_cnt IS NULL OR applic_cnt = 0 THEN 1 ELSE applic_cnt END) > 2000 AND
                              year BETWEEN (&&1 - 7) AND &&1
                        THEN 1 END) num_2000_last_8yr,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN applic_cnt IS NULL OR applic_cnt = 0 THEN 1 ELSE applic_cnt END) > 3000
                        THEN 1 END) num_3000,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN applic_cnt IS NULL OR applic_cnt = 0 THEN 1 ELSE applic_cnt END) > 3000 AND
                              year BETWEEN (&&1 - 7) AND &&1
                        THEN 1 END) num_3000_last_8yr,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN applic_cnt IS NULL OR applic_cnt = 0 THEN 1 ELSE applic_cnt END) > 4000
                        THEN 1 END) num_4000,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN applic_cnt IS NULL OR applic_cnt = 0 THEN 1 ELSE applic_cnt END) > 4000 AND
                              year BETWEEN (&&1 - 7) AND &&1
                        THEN 1 END) num_4000_last_8yr,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN applic_cnt IS NULL OR applic_cnt = 0 THEN 1 ELSE applic_cnt END) > 5000
                        THEN 1 END) num_5000,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN applic_cnt IS NULL OR applic_cnt = 0 THEN 1 ELSE applic_cnt END) > 5000 AND
                              year BETWEEN (&&1 - 7) AND &&1
                        THEN 1 END) num_5000_last_8yr
      FROM     pur LEFT JOIN prod_chem_major_ai pcma USING (prodno)
                   LEFT JOIN chemical USING (chem_code)
                   LEFT JOIN chem_adjuvant USING (chem_code)
                   LEFT JOIN pur_site_groups USING (site_code)
      WHERE    year between (&&1 - &&2 + 1) and &&1 AND
               record_id IN ('2', 'C') AND
      			unit_treated IS NULL AND
               lbs_prd_used > 0 
               &&4 AND county_cd = '26' &&5
      GROUP BY chem_code, chemname, adjuvant,
               CASE WHEN site_general = 'STRUCTURAL PEST CONTROL' THEN 'STRUCTURAL'
                    WHEN site_general = 'LANDSCAPE MAINTENANCE' THEN 'LANDSCAPE'
                    WHEN site_code = 40 THEN 'RIGHTS_OF_WAY'
                    ELSE 'OTHER'
               END;

BEGIN

   FOR pur_rec IN pur_cur LOOP
      v_site_type := pur_rec.site_type;
      v_chem_code := NVL(pur_rec.chem_code, -1);
      v_chemname := NVL(pur_rec.chemname, 'UNKNOWN');

      /* Formula for Excel - first define a name for each column, first select the column then choose: insert -> name -> define.
      =if(num_recs_last_8yr > 50,
         if(num_2000_last_8yr > 10, "HIGH", if(num_500_last_8yr > 10, "MEDIUM", "NORMAL")),
         if(num_recs > 50,
            if(num_2000 > 10, "HIGH", if(num_500 > 10, "MEDIUM", "NORMAL")),
            "NORMAL")
         )

      =if(num_recs_last_8yr > 50, if(num_2000_last_8yr > 10, "HIGH", if(num_500_last_8yr > 10, "MEDIUM", "NORMAL")),if(num_recs > 50,if(num_2000 > 10, "HIGH", if(num_500 > 10, "MEDIUM", "NORMAL")), "NORMAL"))
      */
      IF v_site_type = 'STRUCTURAL' THEN
         v_num_xxxx_last_8yr := pur_rec.num_5000_last_8yr;
         v_num_yyyy_last_8yr := pur_rec.num_1000_last_8yr;
         v_num_xxxx := pur_rec.num_5000;
         v_num_yyyy := pur_rec.num_1000;
      ELSIF v_site_type = 'RIGHTS_OF_WAY' THEN
         v_num_xxxx_last_8yr := pur_rec.num_3000_last_8yr;
         v_num_yyyy_last_8yr := pur_rec.num_1000_last_8yr;
         v_num_xxxx := pur_rec.num_3000;
         v_num_yyyy := pur_rec.num_1000;
      ELSIF v_site_type = 'LANDSCAPE' THEN
         v_num_xxxx_last_8yr := pur_rec.num_2000_last_8yr;
         v_num_yyyy_last_8yr := pur_rec.num_500_last_8yr;
         v_num_xxxx := pur_rec.num_2000;
         v_num_yyyy := pur_rec.num_500;
      ELSE
         v_num_xxxx_last_8yr := pur_rec.num_2000_last_8yr;
         v_num_yyyy_last_8yr := pur_rec.num_500_last_8yr;
         v_num_xxxx := pur_rec.num_2000;
         v_num_yyyy := pur_rec.num_500;
      END IF;

      IF pur_rec.adjuvant = 'Y' THEN
         v_lbs_ai_app_type := 'ADJUVANT';
      ELSIF pur_rec.num_recs_last_8yr > 50 THEN
         IF v_num_xxxx_last_8yr > 10 THEN
            v_lbs_ai_app_type := 'HIGH';
         ELSIF v_num_yyyy_last_8yr > 10 THEN
            v_lbs_ai_app_type := 'MEDIUM';
         ELSE
            v_lbs_ai_app_type := 'NORMAL';
         END IF;
      ELSIF pur_rec.num_recs > 50 THEN
         IF v_num_xxxx > 10 THEN
            v_lbs_ai_app_type := 'HIGH';
         ELSIF v_num_YYYY > 10 THEN
            v_lbs_ai_app_type := 'MEDIUM';
         ELSE
            v_lbs_ai_app_type := 'NORMAL';
         END IF;
      ELSE
         v_lbs_ai_app_type := 'NORMAL';
      END IF;

      INSERT INTO fixed_outlier_lbs_app_ais VALUES
         (v_lbs_ai_app_type, v_site_type, v_chem_code, v_chemname);

      COMMIT;
   END LOOP;
   COMMIT;

   SELECT   count(*)
   INTO     v_num_recs
   FROM     fixed_outlier_rates_ais;

   print_info('Table FIXED_OUTLIER_LBS_APP_AIS was created, with '||v_num_recs ||' number of recrods.', :log_level);

EXCEPTION
	WHEN OTHERS THEN
		DBMS_OUTPUT.PUT_LINE(SQLERRM||'; chem_code = '||v_chem_code);
END;
/
show errors

EXIT 0

