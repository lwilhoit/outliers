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

VARIABLE returncode NUMBER;
VARIABLE log_level NUMBER;

PROMPT ________________________________________________
PROMPT Creating AI_NUM_RECS_NONAG_&&1 table...
DECLARE
	v_table_exists		INTEGER := 0;
   v_table_name      VARCHAR2(100);
   v_num_days_old    INTEGER := &&3;
   v_created_date    DATE;
   v_log_level       VARCHAR2(100);
   e_old_table       EXCEPTION;
   v_dummy           VARCHAR2(10);
BEGIN
   :returncode := 0;
   :log_level := &&4;

   print_info('First, check that the tables needed to create AI_NUM_RECS_NONAG_&&1 exist and have been created recently.', :log_level);
   print_info('If any of the tables are older than required for that table, the script will quit.', :log_level);

   v_table_name := UPPER('PROD_CHEM_MAJOR_AI');

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
   -- Check existence of table AI_NUM_RECS_NONAG_&&1
   print_info('__________________________________________________________________________________________________________________', :log_level);
   print_info('Check if table AI_NUM_RECS_NONAG_&&1 exists; if it does delete the table so it can be recreated with the current PUR data.', :log_level);

   SELECT	COUNT(*)
	INTO		v_table_exists
	FROM		user_tables
	WHERE		table_name = UPPER('AI_NUM_RECS_NONAG_&&1');

	IF v_table_exists > 0 THEN
		EXECUTE IMMEDIATE 'DROP TABLE AI_NUM_RECS_NONAG_&&1';
      print_info('Table AI_NUM_RECS_NONAG_&&1 exists, so it was deleted.', :log_level);
   ELSE
      print_info('Table AI_NUM_RECS_NONAG_&&1 does not exist.', :log_level);
	END IF;
EXCEPTION
   WHEN e_old_table THEN
      print_critical('Table '||v_table_name||' was created on '||v_created_date ||', which is more than '||v_num_days_old||' days old.', :log_level);
      RAISE_APPLICATION_ERROR(-20000, 'Table is too old and needs to be recreated'); 
      -- RAISE_APPLICATION_ERROR is needed in order to exit this entire script; otherwise, the script will continue with CREATE TABLE ai_num_recs_&&1.
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/
show errors

CREATE TABLE ai_num_recs_nonag_&&1
   (year				INTEGER,
	 chem_code		INTEGER,
	 num_recs		INTEGER)
NOLOGGING
PCTUSED 95
PCTFREE 3
STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0)
TABLESPACE pur_report;

INSERT INTO ai_num_recs_nonag_&&1
	SELECT	year, chem_code,
				COUNT(*)
	FROM		pur JOIN prod_chem_major_ai USING (prodno)
	WHERE		year BETWEEN (&&1 - &&2 + 1) AND &&1 AND
				record_id IN ('2', 'C') AND
				lbs_prd_used > 0 AND
				chem_code > 0 
            &&5 AND county_cd = '33' &&6
	GROUP BY year, chem_code;

COMMIT;

 
PROMPT ________________________________________________
PROMPT Creating AI_NUM_RECS_NONAG_SUM_&&1 table...
DECLARE
	v_table_exists		INTEGER := 0;
BEGIN
   print_info('__________________________________________________________________________________________________________________', :log_level);
   print_info('Check if table AI_NUM_RECS_NONAG_SUM_&&1 exists; if it does delete the table so it can be recreated with the current PUR data.', :log_level);
   SELECT	COUNT(*)
	INTO		v_table_exists
	FROM		user_tables
	WHERE		table_name = UPPER('AI_NUM_RECS_NONAG_SUM_&&1');

	IF v_table_exists > 0 THEN
		EXECUTE IMMEDIATE 'DROP TABLE AI_NUM_RECS_NONAG_SUM_&&1';
      print_info('Table AI_NUM_RECS_NONAG_SUM_&&1 exists, so it was deleted.', :log_level);
   ELSE
      print_info('Table AI_NUM_RECS_NONAG_SUM_&&1 does not exist.', :log_level);
	END IF;
EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/
show errors

CREATE TABLE ai_num_recs_nonag_sum_&&1
   (num_years		INTEGER,
	 chem_code		INTEGER,
	 num_recs		INTEGER)
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
		DBMS_OUTPUT.PUT_LINE('v_num_years = '||v_num_years);

		IF v_num_years = 1 AND &&2 > 1 THEN
			INSERT INTO ai_num_recs_nonag_sum_&&1
				SELECT	v_num_years, chem_code, num_recs
				FROM		ai_num_recs_nonag_&&1
				WHERE		year = &&1 AND
							num_recs > 10000;

			COMMIT;
		ELSIF v_num_years < &&2 THEN
			INSERT INTO ai_num_recs_nonag_sum_&&1
				SELECT	v_num_years, chem_code, SUM(num_recs)
				FROM		ai_num_recs_nonag_&&1
				WHERE		year BETWEEN (&&1 - v_num_years + 1) AND &&1 AND
							(chem_code) NOT IN
							(SELECT chem_code FROM ai_num_recs_nonag_sum_&&1)
				GROUP BY chem_code
				HAVING	SUM(num_recs) > 10000;

			COMMIT;
		ELSE
			INSERT INTO ai_num_recs_nonag_sum_&&1
				SELECT	v_num_years, chem_code, SUM(num_recs)
				FROM		ai_num_recs_nonag_&&1
				WHERE		year BETWEEN (&&1 - v_num_years + 1) AND &&1 AND
							(chem_code) NOT IN
							(SELECT chem_code FROM ai_num_recs_nonag_sum_&&1)
				GROUP BY chem_code;

			COMMIT;
		END IF;
	END LOOP;

   SELECT   count(*)
   INTO     v_num_recs
   FROM     ai_num_recs_nonag_sum_&&1;

   print_info('Table AI_NUM_RECS_NONAG_SUM_&&1 was created, with '||v_num_recs ||' number of records.', :log_level);
EXCEPTION
  WHEN OTHERS THEN
	  DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/
show errors

CREATE INDEX ai_num_recs_nonag_sum_&&1._ndx ON ai_num_recs_nonag_sum_&&1
	(chem_code)
   PCTFREE 2
   STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0);


PROMPT ________________________________________________

EXIT :returncode


