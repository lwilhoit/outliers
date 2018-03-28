SET pagesize 75
SET linesize 120
SET termout ON
SET feedback ON
SET document OFF
SET verify OFF
SET trimspool ON
SET numwidth 11
SET SERVEROUTPUT ON SIZE 1000000 FORMAT WORD_WRAPPED

/*
SELECT   created
FROM     all_tables left JOIN all_objects 
            ON all_tables.owner = all_objects.owner AND
               all_tables.table_name = all_objects.object_name
WHERE    object_type = 'TABLE' AND
         all_tables.owner IN ('PUR_REPORT', 'LWILHOIT') AND
         table_name = 'REGNO_AGO_SITE_UNIT';
*/

VARIABLE log_level NUMBER;

PROMPT ________________________________________________
PROMPT Run procedures to create table OUTLIER_ALL_STATS ...
DECLARE
	v_table_exists		INTEGER := 0;
   v_create_table    BOOLEAN := FALSE;
   v_table_name      VARCHAR2(100);
   v_table_name1     VARCHAR2(100);
   v_stat_year       INTEGER := 2017;
   v_num_regno_years INTEGER := 2;
   v_num_days_old1   INTEGER := 0;
   v_created_date    DATE;
BEGIN
   :log_level := 10;

   print_info('__________________________________________________________________________________________________________________', :log_level);
   print_info('First, check that the tables needed to create OUTLIER_ALL_STATS exist and have been created recently.', :log_level);
   v_table_name := UPPER('REGNO_AGO_SITE_UNIT');
   print_info('------------------------------------------------------------------', :log_level);
   print_info('Check if table '||v_table_name||' exists; if it older than '||v_num_days_old1||' days recreate it.', :log_level);

   v_create_table := TRUE;

   SELECT	COUNT(*)
	INTO		v_table_exists
	FROM		user_tables
	WHERE		table_name = v_table_name;

	IF v_table_exists > 0 THEN
      IF v_create_table THEN     
         EXECUTE IMMEDIATE 'DROP TABLE '||v_table_name;
         print_info('Table '|| v_table_name ||' exists but old and will be replaced.', :log_level);
      ELSE
         print_info('Table '|| v_table_name ||' exists but is recent so will left unchanged.', :log_level);
      END IF;
   ELSE
      print_info('Table '|| v_table_name ||' does not exist so it will be created.', :log_level);
	END IF;

   print_info('------------------------------------------------------------------', :log_level);
   IF v_create_table THEN
      EXECUTE IMMEDIATE 
        'CREATE TABLE regno_ago_site_unit
            (regno_short			VARCHAR2(20),
         	 ago_ind        		VARCHAR2(1),
             site_general        VARCHAR2(100),
             unit_treated 			VARCHAR2(1))
         NOLOGGING
         PCTUSED 95
         PCTFREE 3
         TABLESPACE pur_report';

      INSERT INTO regno_ago_site_unit (regno_short, ago_ind, site_general, unit_treated)
         SELECT   regno_short, ago_ind, site_general, unit_treated
         FROM     regno_short_table 
                     CROSS JOIN 
                  (SELECT   DISTINCT site_general
                   FROM     pur_site_groups)
                     CROSS JOIN 
                  (SELECT 'A' ago_ind FROM dual
      				 UNION
      				 SELECT 'N' FROM dual)
                     CROSS JOIN 
                  (SELECT 'A' unit_treated FROM dual
      				 UNION
      				 SELECT 'S' FROM dual
      				 UNION
      				 SELECT 'C' FROM dual
      				 UNION
      				 SELECT 'K' FROM dual
      				 UNION
      				 SELECT 'P' FROM dual
      				 UNION
      				 SELECT 'T' FROM dual
      				 UNION
      				 SELECT 'U' FROM dual);

      COMMIT;
   END IF;

EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/


show errors

