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

DROP SEQUENCE errors_seq_test_2016;
DROP SEQUENCE changes_seq_test_2016;
CREATE SEQUENCE errors_seq_test_2016 increment by 1 start with 1;
CREATE SEQUENCE changes_seq_test_2016 increment by 1 start with 1;

DROP TABLE errors_i;
CREATE TABLE errors_i
   (error_id		   INTEGER,
	 error_code       NUMBER(3),
    year					INTEGER,
    use_no           INTEGER,
  	 error_type			VARCHAR2(20),
    duplicate_set    INTEGER,
    who              VARCHAR2(30),
    found_date       DATE,
    comments         VARCHAR2(2000))
NOLOGGING
PCTUSED 95
PCTFREE 3
STORAGE (INITIAL 1 NEXT 1M PCTINCREASE 0)
TABLESPACE pur;

DROP TABLE changes_i;
CREATE TABLE changes_i
   (change_id		   INTEGER,
    year					INTEGER,
    use_no           INTEGER,
  	 field_name		   VARCHAR2(50),
    old_value        VARCHAR2(50),
    new_value        VARCHAR2(50),
    action_taken     VARCHAR2(20),
    action_date      DATE,
    who              VARCHAR2(30),
    error_id		   INTEGER,
    error_codes      VARCHAR2(1000),
    edit_version     VARCHAR2(100),
    county_validated VARCHAR2(1),
    comments         VARCHAR2(2000))
NOLOGGING
PCTUSED 95
PCTFREE 3
STORAGE (INITIAL 1 NEXT 1M PCTINCREASE 0)
TABLESPACE pur;


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
	 max_label_outlier   		VARCHAR2(1),
	 limit_rate_outlier  		VARCHAR2(1),
	 fixed1_lbsapp_outlier		VARCHAR2(1),
	 fixed2_lbsapp_outlier		VARCHAR2(1),
	 fixed3_lbsapp_outlier		VARCHAR2(1),
	 mean3sd_lbsapp_outlier   	VARCHAR2(1),
	 mean5sd_lbsapp_outlier   	VARCHAR2(1),
	 mean7sd_lbsapp_outlier   	VARCHAR2(1),
	 mean8sd_lbsapp_outlier   	VARCHAR2(1),
	 mean10sd_lbsapp_outlier  	VARCHAR2(1),
	 mean12sd_lbsapp_outlier  	VARCHAR2(1),
	 limit_lbsapp_outlier     	VARCHAR2(1))
NOLOGGING
PCTUSED 95
PCTFREE 3
STORAGE (INITIAL 1 NEXT 1M PCTINCREASE 0)
TABLESPACE pur;


DROP TABLE pur_test;
CREATE TABLE pur_test
   (use_no          INTEGER,
    record_id       VARCHAR2(1),
    site_code       NUMBER(6),
    prodno          NUMBER(7),
    lbs_prd_used    NUMBER(14,4),
    amt_prd_used    NUMBER(12,4),
    unit_of_meas    VARCHAR2(2),
    acre_treated    NUMBER(10,2),
    unit_treated    VARCHAR2(1),
    applic_cnt      NUMBER(6),
    acre_planted    NUMBER(10,2),
    unit_planted    VARCHAR2(1),
    applic_dt       DATE,
    county_cd       VARCHAR2(2),
    license_no      VARCHAR2(13),
    site_loc_id     VARCHAR2(8),
    aer_gnd_ind     VARCHAR2(1),
    year            NUMBER(4))
pctused 95
pctfree 0
storage (initial 5M next 2M pctincrease 0)
nologging
tablespace pur;

EXECUTE Co_error_new.Check_records(2016);

