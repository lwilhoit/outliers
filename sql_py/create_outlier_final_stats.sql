SET pause OFF
SET pagesize 75
SET linesize 120
SET termout ON
SET feedback ON
SET document ON
SET verify ON
SET trimspool ON
SET numwidth 11
SET SERVEROUTPUT ON
WHENEVER SQLERROR EXIT 1 ROLLBACK
WHENEVER OSERROR EXIT 1 ROLLBACK

/*
   Table OUTLIER_FINAL_STATS is a table of the .

 */

VARIABLE log_level NUMBER;

PROMPT ________________________________________________
PROMPT Create OUTLIER_FINAL_STATS table...
DECLARE
	v_table_exists		INTEGER := 0;
BEGIN
   :log_level := &&1;

   SELECT	COUNT(*)
	INTO		v_table_exists
	FROM		user_tables
	WHERE		table_name = 'OUTLIER_FINAL_STATS';

	IF v_table_exists > 0 THEN
		EXECUTE IMMEDIATE 'DROP TABLE OUTLIER_FINAL_STATS';
      print_info('Table OUTLIER_FINAL_STATS exists, so it was deleted.', :log_level);
   ELSE
      print_info('Table OUTLIER_FINAL_STATS does not exist.', :log_level);
   END IF;

EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/
show errors

CREATE TABLE outlier_final_stats
   (ago_ind        		VARCHAR2(1),
    unit_treated 			VARCHAR2(1),
    ai_rate_type        VARCHAR2(20),
    site_type           VARCHAR2(20),
    fixed2              NUMBER,
	 mean_limit   			VARCHAR2(20))
NOLOGGING
PCTUSED 95
PCTFREE 3
STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0)
TABLESPACE pur_report;

PROMPT ________________________________________________

EXIT 0


