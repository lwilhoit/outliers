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

variable returncode number;
VARIABLE log_level NUMBER;

PROMPT ________________________________________________
PROMPT Run procedures to create table PUR_RATES_&&1 ...
DECLARE
	v_table_exists		INTEGER := 0;
   v_table_name      VARCHAR2(100);
   p_num_days_old    INTEGER := &&3;
   v_num_days_old    INTEGER;
   v_num_days_old1   INTEGER;
   v_num_days_old2   INTEGER;
   v_created_date    DATE;
   e_old_table       EXCEPTION;
BEGIN
   :log_level := &&4;
   :returncode := 0;

   print_info('First, check that the tables needed to create PUR_RATES_&&1 exist and have been created recently.', :log_level);
   print_info('If any of the tables are older than required for that table, the script will quit.', :log_level);

   v_num_days_old1 := 2; -- Number of days table AI_NUM_RECS_SUM_&&1 is old enough to recreate
   v_num_days_old2 := 400; -- Number of days table PUR_SITE_GROUPS is old enough to recreate

   -- Check creation data for table AI_NUM_RECS_SUM_&&1.
   -- This table needs to be created within the last day. 
   v_table_name := UPPER('AI_NUM_RECS_SUM_&&1');
   v_num_days_old := v_num_days_old1;

   SELECT   created
   INTO     v_created_date
   FROM     all_tables left JOIN all_objects 
               ON all_tables.owner = all_objects.owner AND
                  all_tables.table_name = all_objects.object_name
   WHERE    object_type = 'TABLE' AND
            all_tables.owner IN ('PUR_REPORT', 'LWILHOIT') AND
            table_name = v_table_name;

   IF v_created_date < SYSDATE - v_num_days_old THEN     
      :returncode := 2;
      RAISE e_old_table;
   END IF;

   print_info('Table '||v_table_name||' was created on '||v_created_date ||', which is less than '||v_num_days_old||' days old.', :log_level);

   -------------------------------------------------
   -- Check creation data for table AI_NAMES
   v_table_name := UPPER('AI_NAMES');
   v_num_days_old := p_num_days_old;


   SELECT   created
   INTO     v_created_date
   FROM     all_tables left JOIN all_objects 
               ON all_tables.owner = all_objects.owner AND
                  all_tables.table_name = all_objects.object_name
   WHERE    object_type = 'TABLE' AND
            all_tables.owner = 'PUR_REPORT' AND
            table_name = v_table_name;

   IF v_created_date < SYSDATE - v_num_days_old THEN     
      :returncode := 2;
      RAISE e_old_table;
   END IF;

   print_info('Table '||v_table_name||' was created on '||v_created_date ||', which is less than '||v_num_days_old||' days old.', :log_level);

   -------------------------------------------------
   -- Check creation data for table CHEM_ADJUVANT
   v_table_name := UPPER('CHEM_ADJUVANT');
   v_num_days_old := p_num_days_old;

   SELECT   created
   INTO     v_created_date
   FROM     all_tables left JOIN all_objects 
               ON all_tables.owner = all_objects.owner AND
                  all_tables.table_name = all_objects.object_name
   WHERE    object_type = 'TABLE' AND
            all_tables.owner = 'PUR_REPORT' AND
            table_name = v_table_name;

   IF v_created_date < SYSDATE - v_num_days_old THEN     
      :returncode := 2;
      RAISE e_old_table;
   END IF;

   print_info('Table '||v_table_name||' was created on '||v_created_date ||', which is less than '||v_num_days_old||' days old.', :log_level);


   -------------------------------------------------
   -- Check creation data for table PUR_SITE_GROUPS:
   v_table_name := UPPER('PUR_SITE_GROUPS');
   v_num_days_old := v_num_days_old2;

   SELECT   created
   INTO     v_created_date
   FROM     all_tables left JOIN all_objects 
               ON all_tables.owner = all_objects.owner AND
                  all_tables.table_name = all_objects.object_name
   WHERE    object_type = 'TABLE' AND
            all_tables.owner = 'PUR_REPORT' AND
            table_name = v_table_name;

   IF v_created_date < SYSDATE - v_num_days_old THEN     
      :returncode := 2;
      RAISE e_old_table;
   END IF;

   print_info('Table '||v_table_name||' was created on '||v_created_date ||', which is less than '||v_num_days_old||' days old.', :log_level);


  -------------------------------------------------
   -- Check existence of table PUR_RATES_&&1
   print_info('__________________________________________________________________________________________________________________', :log_level);
   print_info('Check if table PUR_RATES_&&1 exists; if it does delete the table so it can be recreated with the current PUR data.', :log_level);
   SELECT	COUNT(*)
	INTO		v_table_exists
	FROM		user_tables
	WHERE		table_name = UPPER('PUR_RATES_&&1');

	IF v_table_exists > 0 THEN
		EXECUTE IMMEDIATE 'DROP TABLE pur_rates_&&1';
      print_info('Table PUR_RATES_&&1 exists, so it was deleted.', :log_level);
   ELSE
      print_info('Table PUR_RATES_&&1 does not exist.'), :log_level;
	END IF;
EXCEPTION
   WHEN e_old_table THEN
      print_critical('Table '||v_table_name||' was created on '||v_created_date ||', which is more than '||v_num_days_old||' days old.', :log_level);
      RAISE_APPLICATION_ERROR(-20000, 'Table is too old and needs to be recreated'); 
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/
show errors


PROMPT .................................
PROMPT Now, create PUR_RATES_&&1 table...
CREATE TABLE pur_rates_&&1
   (years			VARCHAR2(20),
	 year				INTEGER,
	 use_no			INTEGER,
	 ago_ind			VARCHAR2(1),
	 chem_code		INTEGER,
	 chemname		VARCHAR2(500),
	 ai_name			VARCHAR2(500),
	 ai_adjuvant	VARCHAR2(1),
	 prodno			INTEGER,
	 regno_short	VARCHAR2(20),
	 product_name	VARCHAR2(200),
	 site_code		INTEGER,
	 site_general	VARCHAR2(200),
	 unit_treated	VARCHAR2(1),
	 ai_rate			NUMBER,
	 log_ai_rate	NUMBER,
	 ai_group		INTEGER)
NOLOGGING
PCTUSED 95
PCTFREE 3
STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0)
TABLESPACE pur_report;

DECLARE
	v_num_years		INTEGER;
   v_num_recs     INTEGER;
BEGIN
	FOR v_num_years IN 1..(&&2) LOOP

		INSERT INTO pur_rates_&&1
			(years, year, use_no, ago_ind, chem_code, chemname, ai_name, ai_adjuvant,
			 prodno, regno_short, product_name, site_code, site_general,
			 unit_treated, ai_rate, log_ai_rate)
		SELECT	(&&1 - &&2 + 1) ||'-'||(&&1), year, use_no,
					CASE WHEN record_id IN ('2', 'C') OR site_code < 100 OR site_code > 29500
						  THEN 'N' ELSE 'A' END,
					pcma.chem_code, chemname, ai_name, NVL(adjuvant, 'N'),
					prodno, mfg_firmno||'-'||label_seq_no, product_name,
					NVL(site_code, -1), NVL(site_general, 'UNKNOWN'),
					CASE
						WHEN pur.unit_treated = 'A' THEN 'A'
						WHEN pur.unit_treated = 'S' THEN 'A'
						WHEN pur.unit_treated = 'C' THEN 'C'
						WHEN pur.unit_treated = 'K' THEN 'C'
						WHEN pur.unit_treated = 'P' THEN 'P'
						WHEN pur.unit_treated = 'T' THEN 'P'
						ELSE 'U'
					END,
					lbs_prd_used*prodchem_pct/
							(100*CASE
									WHEN pur.unit_treated = 'A' THEN acre_treated
									WHEN pur.unit_treated = 'S' THEN acre_treated/43560
									WHEN pur.unit_treated = 'C' THEN acre_treated
									WHEN pur.unit_treated = 'K' THEN acre_treated*1000
									WHEN pur.unit_treated = 'P' THEN acre_treated
									WHEN pur.unit_treated = 'T' THEN acre_treated*2000
									ELSE acre_treated
								END),
					log(10, lbs_prd_used*prodchem_pct/
							(100*CASE
									WHEN pur.unit_treated = 'A' THEN acre_treated
									WHEN pur.unit_treated = 'S' THEN acre_treated/43560
									WHEN pur.unit_treated = 'C' THEN acre_treated
									WHEN pur.unit_treated = 'K' THEN acre_treated*1000
									WHEN pur.unit_treated = 'P' THEN acre_treated
									WHEN pur.unit_treated = 'T' THEN acre_treated*2000
									ELSE acre_treated
								END))
		FROM		pur LEFT JOIN prod_chem_major_ai pcma USING (prodno)
						 LEFT JOIN product USING (prodno)
						 LEFT JOIN ai_names ain ON pcma.chem_code = ain.chem_code
						 LEFT JOIN chem_adjuvant ca ON pcma.chem_code = ca.chem_code
						 LEFT JOIN pur_site_groups USING (site_code)
						 JOIN ai_num_recs_sum_&&1 anrs
										ON pcma.chem_code = anrs.chem_code AND
											CASE WHEN record_id IN ('2', 'C') OR site_code < 100 OR site_code > 29500
													THEN 'N' ELSE 'A' END = anrs.ago_ind AND
											CASE
												WHEN pur.unit_treated = 'A' THEN 'A'
												WHEN pur.unit_treated = 'S' THEN 'A'
												WHEN pur.unit_treated = 'C' THEN 'C'
												WHEN pur.unit_treated = 'K' THEN 'C'
												WHEN pur.unit_treated = 'P' THEN 'P'
												WHEN pur.unit_treated = 'T' THEN 'P'
												ELSE 'U'
											END = anrs.unit_treated
		WHERE		year BETWEEN (&&1 - v_num_years + 1) AND &&1 AND
					acre_treated > 0 AND
					lbs_prd_used > 0 AND
					pur.unit_treated IN ('A', 'S', 'C', 'K', 'P', 'T', 'U') AND
					num_years = v_num_years 
               &&5 AND county_cd = '33' &&6
               ; 

		COMMIT;
	END LOOP;

   SELECT   count(*)
   INTO     v_num_recs
   FROM     pur_rates_&&1;

   print_info('Table pur_rates_&&1 was created, with '||v_num_recs ||' number of recrods.', :log_level);

EXCEPTION
	WHEN OTHERS THEN
		DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/
show errors

PROMPT ________________________________________________

EXIT :returncode

