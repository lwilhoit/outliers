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

/* Create table FIXED_OUTLIER_LBS_APP, which has the fixed outlier limits
   for rates as pounds per application for each
   lbs_ai_app_type and site_type.
 */

PROMPT ________________________________________________
PROMPT Creating FIXED_OUTLIER_LBS_APP table...
DECLARE
	v_table_exists		INTEGER := 0;
BEGIN
   SELECT	COUNT(*)
   INTO		v_table_exists
   FROM		user_tables
   WHERE		table_name = 'FIXED_OUTLIER_LBS_APP_OLD';

   IF v_table_exists > 0 THEN
      EXECUTE IMMEDIATE 'DROP TABLE FIXED_OUTLIER_LBS_APP_OLD';
      DBMS_OUTPUT.PUT_LINE('Dropped table FIXED_OUTLIER_LBS_APP_OLD');
   END IF;

   SELECT	COUNT(*)
   INTO		v_table_exists
   FROM		user_tables
   WHERE		table_name = 'FIXED_OUTLIER_LBS_APP';

   IF v_table_exists > 0 THEN
      EXECUTE IMMEDIATE 'RENAME FIXED_OUTLIER_LBS_APP TO FIXED_OUTLIER_LBS_APP_OLD';
      DBMS_OUTPUT.PUT_LINE('Renamed table FIXED_OUTLIER_LBS_APP to FIXED_OUTLIER_LBS_APP_OLD');
   END IF;

EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/
show errors

CREATE TABLE fixed_outlier_lbs_app
   (lbs_ai_app_type	VARCHAR2(20),
	 site_type			VARCHAR2(20),
	 lbs_ai_app1		NUMBER,
	 lbs_ai_app2		NUMBER,
	 lbs_ai_app3		NUMBER,
	 log_lbs_ai_app1	NUMBER,
	 log_lbs_ai_app2	NUMBER,
	 log_lbs_ai_app3	NUMBER)
NOLOGGING
PCTUSED 95
PCTFREE 3
STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0)
TABLESPACE pur_report;


EXIT 0


