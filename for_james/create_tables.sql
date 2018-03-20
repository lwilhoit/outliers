SET pause OFF
SET pagesize 75
SET linesize 120
SET termout ON
SET feedback ON
SET document OFF
SET verify OFF
SET trimspool ON
SET numwidth 11
SET serveroutput on size 1000000 format word_wrapped

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
pctused 90
pctfree 10
storage (initial 1M next 1M);

-- Owned by PUR_REPORT
CREATE TABLE pur_site_groups
CREATE TABLE chem_adjuvant

CREATE TABLE fixed_outlier_rates_ais
CREATE TABLE fixed_outlier_rates
CREATE TABLE fixed_outlier_lbs_app_ais
CREATE TABLE fixed_outlier_lbs_app

CREATE TABLE ai_group_stats
CREATE TABLE ai_outlier_stats
CREATE TABLE ai_group_nonag_stats
CREATE TABLE ai_outlier_nonag_stats

-- owned by PUR.
CREATE TABLE max_label_rates

