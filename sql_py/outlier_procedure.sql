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


CREATE TABLE ai_outlier_stats
   (year						INTEGER,
  	 chem_code				INTEGER,
	 ai_group				INTEGER,
    ago_ind        		VARCHAR2(1),
    unit_treated 			VARCHAR2(1),
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
	 med100    				NUMBER,
	 med150    				NUMBER,
	 med200    				NUMBER,
	 med250    				NUMBER,
	 med300    				NUMBER,
	 med400    				NUMBER,
	 med500    				NUMBER,
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


CREATE TABLE outlier_stats
   (year						INTEGER,
  	 chem_code				INTEGER,
	 ai_group				INTEGER,
	 ai_adjuvant			VARCHAR2(1),
    ai_rate_type        VARCHAR2(20),
	 site_general			VARCHAR2(100),
    site_code           INTEGER,
    site_type           VARCHAR2(20),
	 regno_short			VARCHAR2(20),
    prodno              INTEGER,
    ago_ind        		VARCHAR2(1),
    unit_treated 			VARCHAR2(1),
    unit_treated_report VARCHAR2(1),
	 num_recs     			INTEGER,
	 median_rate			NUMBER,
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

DECLARE
   CURSOR aig AS
      SELECT   chem_code, ai_group, site_general, regno_short, ago_ind,
               unit_treated
      FROM     ai_group_stats;
   
BEGIN


EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(SQLERRM||'; use_no = '||v_use_no);
END;
/
show errors


