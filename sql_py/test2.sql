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

DECLARE
	v_table_exists		INTEGER := 0;
   v_table_name      VARCHAR2(100);
   v_num_days_old    INTEGER := 10;
   v_created_date    DATE;
   e_old_table       EXCEPTION;
BEGIN
   :returncode := 0;
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
      :returncode := 1;
      RAISE e_old_table;
   END IF;

   DBMS_OUTPUT.PUT_LINE('Table '||v_table_name||' was created on '||v_created_date ||' is recent.');

EXCEPTION
   WHEN e_old_table THEN
      DBMS_OUTPUT.PUT_LINE('Table '||v_table_name||' was created on '||v_created_date ||', which is more than '||10||' days old.');
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/
show errors

EXIT :returncode
