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

/* Create table that groups sites into more general categories,
	which will be used by the outlier procedures.
 */
PROMPT ________________________________________________
PROMPT Creating PUR_SITE_GROUPS table...
DECLARE
	v_table_exists		INTEGER := 0;
BEGIN
	SELECT	COUNT(*)
	INTO		v_table_exists
	FROM		user_tables
	WHERE		table_name = 'PUR_SITE_GROUPS';

	IF v_table_exists > 0 THEN
		EXECUTE IMMEDIATE 'DROP TABLE PUR_SITE_GROUPS';
	END IF;
EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/
show errors


CREATE TABLE pur_site_groups
   (site_code     	NUMBER(6),
	 site_name			VARCHAR2(50),
    site_general		VARCHAR2(50),
	 site_general1		VARCHAR2(50),
    site_general_ag	VARCHAR2(50))
NOLOGGING
PCTUSED 95
PCTFREE 3
STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0)
TABLESPACE pur_report;


EXIT 0

