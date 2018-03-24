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

/*
   This query takes about one hour to run.
*/

DROP TABLE regno_ago_table;
CREATE TABLE regno_ago_table
   (regno_short	VARCHAR2(20))
NOLOGGING
PCTUSED 95
PCTFREE 3
TABLESPACE pur_report;

INSERT INTO regno_ago_table
   SELECT   DISTINCT mfg_firmno||'-'||label_seq_no
   FROM     pur left JOIN product using (prodno)
   WHERE    year BETWEEN 2012 AND 2016;

COMMIT;

DROP TABLE outlier_all_stats_temp;
CREATE TABLE outlier_all_stats_temp
   (regno_short			VARCHAR2(20),
	 ago_ind        		VARCHAR2(1),
    site_general        VARCHAR2(100),
    unit_treated 			VARCHAR2(1))
NOLOGGING
PCTUSED 95
PCTFREE 3
STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0)
TABLESPACE pur_report;

INSERT INTO outlier_all_stats_temp (regno_short, ago_ind, site_general, unit_treated)
   SELECT   regno_short, ago_ind, site_general, unit_treated
   FROM     regno_ago_table 
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

