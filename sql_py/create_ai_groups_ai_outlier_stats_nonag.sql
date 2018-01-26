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

/* Table of AI groups, which for each AI are determined by particular combinations of
	short registration number and general site.
	From R data.frame stats_all
   In previous versions of ai_outlier_nonag_stats, there were fields for the 
   fixed limits but these have been removed because fixed limits now
   depend on site_type which is not in table ai_outlier_nonag_stats.
   To get the fixed limits, you need to use table fixed_outlier_lbs_app.
 */
PROMPT ________________________________________________
PROMPT Creating AI_GROUP_NONAG_STATS table...
DECLARE
	v_table_exists		INTEGER := 0;
BEGIN
	SELECT	COUNT(*)
	INTO		v_table_exists
	FROM		user_tables
	WHERE		table_name = 'AI_GROUP_NONAG_STATS';

	IF v_table_exists > 0 THEN
		EXECUTE IMMEDIATE 'DROP TABLE ai_group_nonag_stats';
	END IF;
EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/
show errors

CREATE TABLE ai_group_nonag_stats
   (chem_code				INTEGER,
	 ai_group				INTEGER,
	 site_general			VARCHAR2(100),
	 regno_short			VARCHAR2(20),
	 chemname				VARCHAR2(500),
	 ai_name					VARCHAR2(500),
	 ai_adjuvant			VARCHAR2(1),
	 mean_trim   			NUMBER,
	 mean  					NUMBER,
	 median   				NUMBER,
	 sd_rate_trim  		NUMBER,
	 sd_rate_trim_orig	NUMBER,
	 sd_rate  				NUMBER,
	 sum_sq_rate_trim		NUMBER,
	 num_recs  				INTEGER,
	 num_recs_trim  		INTEGER,
	 year						INTEGER )
NOLOGGING
PCTUSED 95
PCTFREE 3
STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0)
TABLESPACE pur_report;



/* Table of statistics for each AI and group which are used to determine outliers in rates of use.
	From R data.frame stats_summary
 */
PROMPT ________________________________________________
PROMPT Creating AI_OUTLIER_NONAG_STATS table...
DECLARE
	v_table_exists		INTEGER := 0;
BEGIN
	SELECT	COUNT(*)
	INTO		v_table_exists
	FROM		user_tables
	WHERE		table_name = 'AI_OUTLIER_NONAG_STATS';

	IF v_table_exists > 0 THEN
		EXECUTE IMMEDIATE 'DROP TABLE ai_outlier_nonag_stats';
	END IF;
EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/
show errors

CREATE TABLE ai_outlier_nonag_stats
   (year						INTEGER,
  	 chem_code				INTEGER,
	 ai_group				INTEGER,
	 num_recs     			INTEGER,
	 num_recs_trim			INTEGER,
	 median_rate			NUMBER,
	 mean_rate				NUMBER,
	 mean_rate_trim		NUMBER,
	 sd_rate		     		NUMBER,
	 sd_rate_trim_orig 	NUMBER,
	 sd_rate_trim     	NUMBER,
	 sum_sq_rate_trim		NUMBER,
	 med50     				NUMBER,
	 med100     			NUMBER,
	 med150     			NUMBER,
	 med200     			NUMBER,
	 med250     			NUMBER,
	 med300     			NUMBER,
	 med400     			NUMBER,
	 med500     			NUMBER,
	 med1000   				NUMBER,
	 med5000   				NUMBER,
	 med10000  				NUMBER,
	 med50000  				NUMBER,
	 med100000 				NUMBER,
	 mean3sd   				NUMBER,
	 mean5sd   				NUMBER,
	 mean7sd   				NUMBER,
	 mean8sd   				NUMBER,
	 mean10sd  				NUMBER,
	 mean12sd  				NUMBER,
	 mean15sd  				NUMBER)
NOLOGGING
PCTUSED 95
PCTFREE 3
STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0)
TABLESPACE pur_report;

EXIT 0



