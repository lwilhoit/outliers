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
   Table REGNO_AGO_TABLE is a list of all short registration numbers
   and ago_ind values.

 */

VARIABLE log_level NUMBER;

PROMPT ________________________________________________
PROMPT Create REGNO_AGO_TABLE table...
DECLARE
	v_table_exists		INTEGER := 0;
BEGIN
   :log_level := &&1;

   SELECT	COUNT(*)
	INTO		v_table_exists
	FROM		user_tables
	WHERE		table_name = 'REGNO_AGO_TABLE';

	IF v_table_exists > 0 THEN
		EXECUTE IMMEDIATE 'DROP TABLE regno_ago_table';
      print_info('Table regno_ago_table exists, so it was deleted.', :log_level);
   ELSE
      print_info('Table regno_ago_table does not exist.', :log_level);
   END IF;

EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/
show errors

CREATE TABLE regno_ago_table
   (regno_short	VARCHAR2(20),
    ago_ind       VARCHAR2(1))
NOLOGGING
PCTUSED 95
PCTFREE 3
TABLESPACE pur_report;

INSERT INTO regno_ago_table
   SELECT   DISTINCT mfg_firmno||'-'||label_seq_no, 'A'
   FROM     pur left JOIN product using (prodno)
   WHERE    year BETWEEN 2012 AND 2016;

COMMIT;

INSERT INTO regno_ago_table
   SELECT   regno_short, 'N'
   FROM     regno_ago_table;

COMMIT;


PROMPT ________________________________________________

EXIT 0



