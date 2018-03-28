SET pagesize 75
SET linesize 120
SET termout ON
SET feedback ON
SET document OFF
SET verify OFF
SET trimspool ON
SET numwidth 11
SET SERVEROUTPUT ON SIZE 1000000 FORMAT WORD_WRAPPED


VARIABLE log_level NUMBER;

PROMPT ________________________________________________
PROMPT Run procedures to create table OUTLIER_ALL_STATS ...
DECLARE
	v_table_exists		INTEGER := 0;
   v_create_table    BOOLEAN := FALSE;
   v_table_name      VARCHAR2(100);
   v_num_days_old1   INTEGER := 10;
   v_created_date    DATE;
BEGIN
   :log_level := 10;

   print_info('__________________________________________________________________________________________________________________', :log_level);
   print_info('First, check that the tables needed to create OUTLIER_ALL_STATS exist and have been created recently.', :log_level);
   v_table_name := UPPER('AI_STATS_TEMP');
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
         print_info('Table '|| v_table_name ||' exists but old and will be replaced.', :log_level);
      ELSE
         v_create_table := FALSE;
         print_info('Table '|| v_table_name ||' exists but is recent so will left unchanged.', :log_level);
      END IF;
   ELSE
      v_create_table := TRUE;
      print_info('Table '|| v_table_name ||' does not exist so it will be created.', :log_level);
	END IF;

   IF v_create_table THEN
       EXECUTE IMMEDIATE 
        'CREATE TABLE ai_stats_temp
            (ai_code             INTEGER,
             active_ingredient	VARCHAR2(200),
             num_recs            INTEGER,
             mean_rate           NUMBER,
             med_rate            NUMBER,
             std_rate            NUMBER)
         NOLOGGING
         PCTUSED 95
         PCTFREE 3
         TABLESPACE pur_report';

      INSERT INTO AI_STATS_TEMP
         SELECT   *
         FROM     AI_STATS_TEMP1;

      COMMIT;

      /*
       EXECUTE IMMEDIATE 
        'CREATE TABLE ctemp
            (county_cd	VARCHAR2(2),
             coname     VARCHAR2(30))
         NOLOGGING
         PCTUSED 95
         PCTFREE 3
         TABLESPACE pur_report';

      INSERT INTO ctemp
         SELECT   county_cd, coname
         FROM     county;

      COMMIT;
      */

   END IF;

EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/

/*
execute print_info('test', 10)

*/
show errors

