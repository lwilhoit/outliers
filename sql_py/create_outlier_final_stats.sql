SET pause OFF
SET pagesize 75
SET linesize 120
SET termout ON
SET feedback ON
SET document OFF
SET verify OFF
SET trimspool ON
SET numwidth 11
SET SERVEROUTPUT ON
SET SERVEROUTPUT ON SIZE 1000000 FORMAT WORD_WRAPPED
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
   v_create_table    BOOLEAN := FALSE;
   v_table_name      VARCHAR2(100);
   v_num_days_old1   INTEGER := &&1;
   v_created_date    DATE;

BEGIN
   :log_level := &&2;

   v_table_name := UPPER('OUTLIER_FINAL_STATS');
   print_info('__________________________________________________________________________________________________________________', :log_level);
   print_info('Check if table '||v_table_name||' exists; if it older than '||v_num_days_old1||' days recreate it.', :log_level);

   SELECT	COUNT(*)
	INTO		v_table_exists
	FROM		user_tables
	WHERE		table_name = v_table_name;

	IF v_table_exists > 0 THEN
      SELECT   created
      INTO     v_created_date
      FROM     all_tables left JOIN all_objects 
                  ON all_tables.owner = all_objects.owner AND
                     all_tables.table_name = all_objects.object_name
      WHERE    object_type = 'TABLE' AND
               all_tables.owner IN ('PUR_REPORT', 'LWILHOIT') AND
               table_name = v_table_name;

      IF v_created_date < SYSDATE - v_num_days_old1 THEN     
         EXECUTE IMMEDIATE 'DROP TABLE '||v_table_name;
         v_create_table := TRUE;
         print_info('Table '|| v_table_name ||' exists but is old so will will be replaced.', :log_level);
      ELSE
         v_create_table := FALSE;
         print_info('Table '|| v_table_name ||' exists but is recent so will left unchanged.', :log_level);
      END IF;
   ELSE
      v_create_table := TRUE;
      print_info('Table '|| v_table_name ||' does not exist so it will be created.', :log_level);
	END IF;

   print_info('------------------------------------------------------------------', :log_level);
   IF v_create_table THEN
      EXECUTE IMMEDIATE 
       'CREATE TABLE outlier_final_stats
         (ago_ind        		VARCHAR2(1),
          unit_treated 			VARCHAR2(1),
          ai_rate_type        VARCHAR2(20),
          site_type           VARCHAR2(20),
          fixed2              NUMBER,
      	 mean_limit   			VARCHAR2(20))
        NOLOGGING
        PCTUSED 95
        PCTFREE 3
        TABLESPACE pur_report';

      print_info('Table '||v_table_name||' created.', :log_level);

   END IF;

EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/
show errors

PROMPT ________________________________________________

EXIT 0


