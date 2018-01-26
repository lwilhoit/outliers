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

/* Create table fixed_outlier_rates, which has the fixed outlier limits
   for each ago_ind, unit_treated, ai_rate_type, and site_type.
 */

PROMPT ________________________________________________
PROMPT Creating FIXED_OUTLIER_RATES table...
DECLARE
	v_table_exists		INTEGER := 0;
BEGIN
   DBMS_OUTPUT.PUT_LINE('Does FIXED_OUTLIER_RATES_OLD exist?');

	SELECT	COUNT(*)
	INTO		v_table_exists
	FROM		user_tables
	WHERE		table_name = 'FIXED_OUTLIER_RATES_OLD';

   DBMS_OUTPUT.PUT_LINE('If so, drop FIXED_OUTLIER_RATES_OLD.');

   IF v_table_exists > 0 THEN
		EXECUTE IMMEDIATE 'DROP TABLE FIXED_OUTLIER_RATES_OLD';
      DBMS_OUTPUT.PUT_LINE('Dropped table fixed_outlier_rates_old');
   ELSE
      DBMS_OUTPUT.PUT_LINE('fixed_outlier_rates_old does not exist');
	END IF;

   DBMS_OUTPUT.PUT_LINE('Does FIXED_OUTLIER_RATES exist?');

   SELECT	COUNT(*)
   INTO		v_table_exists
   FROM		user_tables
   WHERE		table_name = 'FIXED_OUTLIER_RATES';

   DBMS_OUTPUT.PUT_LINE('If so, rename FIXED_OUTLIER_RATES to FIXED_OUTLIER_RATES_OLD.');

   IF v_table_exists > 0 THEN
      EXECUTE IMMEDIATE 'RENAME FIXED_OUTLIER_RATES TO FIXED_OUTLIER_RATES_OLD';
      DBMS_OUTPUT.PUT_LINE('Renamed table fixed_outlier_rates to fixed_outlier_rates_old');
   ELSE
      DBMS_OUTPUT.PUT_LINE('fixed_outlier_rates does not exist');
   END IF;

EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/
show errors

CREATE TABLE fixed_outlier_rates
   (ago_ind			VARCHAR2(1),
	 unit_treated	VARCHAR2(1),
	 ai_rate_type	VARCHAR2(20),
    site_type     VARCHAR2(20),
	 rate1			NUMBER,
	 rate2			NUMBER,
	 rate3			NUMBER,
	 log_rate1 		NUMBER,
	 log_rate2 		NUMBER,
	 log_rate3 		NUMBER)
NOLOGGING
PCTUSED 95
PCTFREE 3
STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0)
TABLESPACE pur_report;

EXIT 0


