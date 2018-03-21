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

CREATE SEQUENCE errors_seq_test_2016 increment by 1 start with 1;
CREATE SEQUENCE changes_seq_test_2016 increment by 1 start with 1;


DROP TABLE outliers_new;
CREATE TABLE outliers_new
   (year								INTEGER,
    use_no           			INTEGER,
	 fixed1_rate_outlier			VARCHAR2(1),
	 fixed2_rate_outlier			VARCHAR2(1),
	 fixed3_rate_outlier			VARCHAR2(1),
	 mean5sd_rate_outlier		VARCHAR2(1),
	 mean7sd_rate_outlier		VARCHAR2(1),
	 mean8sd_rate_outlier		VARCHAR2(1),
	 mean10sd_rate_outlier		VARCHAR2(1),
	 mean12sd_rate_outlier		VARCHAR2(1),
	 fixed1_lbsapp_outlier		VARCHAR2(1),
	 fixed2_lbsapp_outlier		VARCHAR2(1),
	 fixed3_lbsapp_outlier		VARCHAR2(1),
	 mean3sd_lbsapp_outlier   	VARCHAR2(1),
	 mean5sd_lbsapp_outlier   	VARCHAR2(1),
	 mean7sd_lbsapp_outlier   	VARCHAR2(1),
	 mean8sd_lbsapp_outlier   	VARCHAR2(1),
	 mean10sd_lbsapp_outlier  	VARCHAR2(1),
	 mean12sd_lbsapp_outlier  	VARCHAR2(1))
NOLOGGING
PCTUSED 95
PCTFREE 3
STORAGE (INITIAL 1 NEXT 1M PCTINCREASE 0)
TABLESPACE pur;

CREATE TABLE pur_test
   (acre_planted    NUMBER(10,2),
    acre_treated    NUMBER(10,2),
    aer_gnd_ind     VARCHAR2(1),
    amt_prd_used    NUMBER(12,4),
    applic_cnt      NUMBER(6),
    applic_dt       DATE,
    county_cd       VARCHAR2(2),
    lbs_prd_used    NUMBER(14,4),
    license_no      VARCHAR2(13),
    prodno          NUMBER(7),
    record_id       VARCHAR2(1),
    site_code       NUMBER(6),
    site_loc_id     VARCHAR2(8),
    unit_of_meas    VARCHAR2(2),
    unit_planted    VARCHAR2(1),
    unit_treated    VARCHAR2(1),
    use_no          INTEGER,
    year            NUMBER(4))
pctused 95
pctfree 0
storage (initial 5M next 5M pctincrease 0)
nologging
tablespace pur;


EXECUTE Co_error.Check_records(2016);
