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

PROMPT ________________________________________________
PROMPT Creating AI_NUM_RECS_NONAG_&&1 table...
DECLARE
	v_table_exists		INTEGER := 0;
BEGIN
	SELECT	COUNT(*)
	INTO		v_table_exists
	FROM		user_tables
	WHERE		table_name = 'AI_NUM_RECS_NONAG_&&1';

	IF v_table_exists > 0 THEN
		EXECUTE IMMEDIATE 'DROP TABLE ai_num_recs_nonag_&&1';
	END IF;
EXCEPTION
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
	GROUP BY year, chem_code;

COMMIT;


PROMPT ________________________________________________
PROMPT Creating AI_NUM_RECS_NONAG_SUM_&&1 table...
DECLARE
	v_table_exists		INTEGER := 0;
BEGIN
	SELECT	COUNT(*)
	INTO		v_table_exists
	FROM		user_tables
	WHERE		table_name = 'AI_NUM_RECS_NONAG_SUM_&&1';

	IF v_table_exists > 0 THEN
		EXECUTE IMMEDIATE 'DROP TABLE ai_num_recs_nonag_sum_&&1';
		EXECUTE IMMEDIATE 'DROP INDEX ai_num_recs_nonag_sum_&&1._ndx';
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
BEGIN
	FOR v_num_years IN 1..(&&2) LOOP
		DBMS_OUTPUT.PUT_LINE('v_num_years = '||v_num_years);

		IF v_num_years = 1 THEN
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


EXIT 0


