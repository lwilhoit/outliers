
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
PROMPT Creating FIXED_OUTLIER_RATES2 table...
DECLARE
	v_table_exists		INTEGER := 0;
   v_med   INTEGER;
BEGIN
   DBMS_OUTPUT.PUT_LINE('Does FIXED_OUTLIER_RATES_OLD2 exist?');

	SELECT	COUNT(*)
	INTO		v_table_exists
	FROM		user_tables
	WHERE		table_name = 'FIXED_OUTLIER_RATES_OLD2';

   DBMS_OUTPUT.PUT_LINE('If so, drop FIXED_OUTLIER_RATES_OLD2.');

   IF v_table_exists > 0 THEN
		EXECUTE IMMEDIATE 'DROP TABLE FIXED_OUTLIER_RATES_OLD2';
      DBMS_OUTPUT.PUT_LINE('Dropped table fixed_outlier_rates_OLD2');
   ELSE
      DBMS_OUTPUT.PUT_LINE('fixed_outlier_rates_OLD2 does not exist');
	END IF;

   DBMS_OUTPUT.PUT_LINE('Does FIXED_OUTLIER_rates2 exist?');

   SELECT	COUNT(*)
   INTO		v_table_exists
   FROM		user_tables
   WHERE		table_name = UPPER('FIXED_OUTLIER_rates2');

   DBMS_OUTPUT.PUT_LINE('If so, rename FIXED_OUTLIER_rates2 to FIXED_OUTLIER_RATES_OLD2.');

   IF v_table_exists > 0 THEN
      EXECUTE IMMEDIATE 'RENAME FIXED_OUTLIER_rates2 TO FIXED_OUTLIER_RATES_OLD2';
      DBMS_OUTPUT.PUT_LINE('Renamed table fixed_outlier_rates2 to fixed_outlier_rates_OLD2');
   ELSE
      DBMS_OUTPUT.PUT_LINE('fixed_outlier_rates2 does not exist');
   END IF;

   /*
   FOR yr IN 2000..2005 LOOP
       SELECT  median(use_no)
       INTO    v_med
       FROM    pur
       WHERE   year = yr;

       DBMS_OUTPUT.PUT_LINE(yr||', '||v_med);
   END LOOP;
   */

EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/
show errors

CREATE TABLE fixed_outlier_rates2
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

/*
CREATE TABLE test_temp
   (use_no			NUMBER,
	 median			NUMBER)
NOLOGGING
PCTUSED 95
PCTFREE 3
STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0)
TABLESPACE pur_report;

DECLARE
    v_med   INTEGER;
BEGIN
    FOR yr IN 2000..2002 LOOP
        SELECT  median(use_no)
        INTO    v_med
        FROM    pur
        WHERE   year = yr;

        DBMS_OUTPUT.PUT_LINE(yr||', '||v_med);
    END LOOP;
EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/
show errors

*/
