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
VARIABLE log_level NUMBER;

PROMPT ________________________________________________
PROMPT Run procedures to create table OUTLIER_ALL_STATS ...
DECLARE
	v_table_exists		INTEGER := 0;
   v_create_table    BOOLEAN := FALSE;
   v_table_name      VARCHAR2(100);
   v_table_name1     VARCHAR2(100);
   v_stat_year       INTEGER := &&1;
   v_num_regno_years INTEGER := &&2;
   v_num_days_old1   INTEGER := &&3;
   v_created_date    DATE;
BEGIN
   :log_level := &&4;
   :returncode := 0;

   print_info('__________________________________________________________________________________________________________________', :log_level);
   print_info('First, check that the tables needed to create OUTLIER_ALL_STATS exist and have been created recently.', :log_level);

   -------------------------------------------------------------------------------------------------------------------------------
   -- Check existence and creation date for tables REGNO_SHORT_TABLE and REGNO_AGO_SITE_UNIT.
   v_table_name1 := UPPER('REGNO_SHORT_TABLE');
   v_table_name := v_table_name1;
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

   v_table_name := UPPER('REGNO_AGO_SITE_UNIT');
   print_info('------------------------------------------------------------------', :log_level);
   print_info('Check if table '||v_table_name||' exists; if it older than '||v_num_days_old1||' days recreate it.', :log_level);

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

   v_table_name := UPPER('OUTLIER_ALL_STATS');
   print_info('------------------------------------------------------------------', :log_level);
   print_info('Check if table '||v_table_name||' exists; if it older than '||v_num_days_old1||' days recreate it.', :log_level);

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
       'CREATE TABLE regno_short_table
           (regno_short	VARCHAR2(20))
        NOLOGGING
        PCTUSED 95
        PCTFREE 3
        TABLESPACE pur_report';

      INSERT INTO regno_short_table
         SELECT   DISTINCT mfg_firmno||'-'||label_seq_no
         FROM     pur left JOIN product using (prodno)
         WHERE    year BETWEEN v_stat_year - v_num_regno_years + 1 AND v_stat_year;

      COMMIT;

      /*
      EXECUTE IMMEDIATE 
      'INSERT INTO '||v_table_name1||
      '  SELECT   DISTINCT mfg_firmno'||'-'||'label_seq_no'||
      '  FROM     pur left JOIN product using (prodno)'||
      '  WHERE    year BETWEEN ('||v_stat_year||' - '||v_num_regno_years||' + 1) AND '||v_stat_year;
      */

      EXECUTE IMMEDIATE 
        'CREATE TABLE prodno_regno_short
            (prodno        INTEGER,
             regno_short	VARCHAR2(20))
         NOLOGGING
         PCTUSED 95
         PCTFREE 3
         TABLESPACE pur_report';

      INSERT INTO prodno_regno_short
         SELECT   prodno, mfg_firmno||'-'||label_seq_no
         FROM     product;

      COMMIT;

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

      EXECUTE IMMEDIATE 
        'CREATE TABLE outlier_all_stats
            (regno_short			VARCHAR2(20),
             ago_ind             VARCHAR2(1),
             site_general        VARCHAR2(100),
             site_type           VARCHAR2(100),
             unit_treated 			VARCHAR2(1),
             chem_code           INTEGER,
             chemname            VARCHAR2(200), -- The AI which resulted in this product having outlier
             ai_group            INTEGER,
             prodchem_pct        NUMBER,
             ai_rate_type        VARCHAR2(50),
             median              NUMBER,
             mean5sd   				NUMBER,
             mean7sd   				NUMBER,
             mean8sd   				NUMBER,
             mean10sd   			NUMBER,
             mean12sd   			NUMBER,
             fixed1              NUMBER,
             fixed2              NUMBER,
             fixed3              NUMBER,
             outlier_limit       NUMBER,
             outlier_limit_prod  NUMBER,
             median_ai           NUMBER,
             mean5sd_ai   			NUMBER,
             mean7sd_ai   			NUMBER,
             mean8sd_ai   			NUMBER,
             mean10sd_ai   		NUMBER,
             mean12sd_ai   		NUMBER,
             fixed1_ai           NUMBER,
             fixed2_ai           NUMBER,
             fixed3_ai           NUMBER,
             outlier_limit_ai    NUMBER,
             max_rate            NUMBER,
             unit_conversion     NUMBER,
             mean_limit_prod_str VARCHAR2(100))
         NOLOGGING
         PCTUSED 95
         PCTFREE 3
         TABLESPACE pur_report';


   END IF;

EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/
show errors


PROMPT ________________________________________________

EXIT :returncode

