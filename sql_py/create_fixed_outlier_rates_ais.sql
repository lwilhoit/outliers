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

/* Create table fixed_outlier_rates_ais, which has the ai_rate_type for
   each AI.

   Also, creates temporary table fixed_outlier_rates_stats, which 
   is used to create fixed_outlier_rates_ais.
 */
/*
   General idea of how to determine the AI rate type of each AI:
   ________________________________
   Ag acres:
   High rate AIs:
   percent recs last 8 years > 100 lbs/acre > 50 and
   num recs last 8 years > 100.

   Medium rate AIs:
   percent recs last 8 years > 25 lbs/acre > 2 and
   num recs last 8 years > 50.

   ________________________________
   Ag cubic feet and pounds:
   No high rate AIs, at least not enough records to determine high rate AIs

   ________________________________
   Ag misc:
   High rate AIs:
   percent recs last 17 years > 1 lbs/misc unit > 4 and
   num recs last 17 years > 20.

   ________________________________
   Nonag acres - other sites:
   High rate AIs:
   percent recs last 8 years > 100 lbs/acre > 50 and
   num recs last 8 years > 10.

   Medium rate AIs:
   percent recs last 8 years > 50 lbs/acre > 4 and
   num recs last 8 years > 25.

   ------------------------------------
   Nonag acres - water sites:
   High rate AIs:
   percent recs last 8 years > 100 lbs/acre > 20 and
   num recs last 8 years > 20.

   Medium rate AIs:
   percent recs last 8 years > 50 lbs/acre > 10 and
   num recs last 8 years > 20.

   ________________________________
   Nonag cubic feet - other and water sites:
   High rate AIs:
   None - few records and great variability

   ________________________________
   Nonag pounds - other sites:
   High rate AIs:
   percent recs last 8 years > 1 lbs/acre > 1 and
   num recs last 8 years  > 25.

   Medium rate AIs:
   percent recs last 8 years > 1 lbs/acre > 0.1 and 
   num recs last 8 years > 25.

   ------------------------------------
   Nonag pounds - water sites:
   No High rate AIs.

   ________________________________
   Nonag misc units - other sites:
   High rate AIs:
   percent recs last 8 years > 50 lbs/misc > 15 and
   num recs last 8 years  > 10.

   Medium rate AIs:
   percent recs last 8 years > 20 lbs/acre > 5 and
   num recs last 8 years > 10.

   ------------------------------------
   Nonag pounds - water sites:
   No High rate AIs.


   Use the percent of records greater than each of several different
   values, such as 500 lbs/acre, 200, 100, 50, and 10.
   Place AIs into the group in which less than 0.2% of the records
   are greater than the rate limits.
   Difficulties occur when there are no records at those limits,
   but typical rates are high for an AI could be nevertheless be
   high and the AI should be put into a high rate group.
   On the other hand, the percentage may be high but only
   because of a few extreme outliers, but otherwise typical
   rates are low, so these AIs should be put into low rate group.

   ************ Change the following chem_codes to adjuvant?
   1379, 1664, 2173, 2216, 5068

 */
VARIABLE log_level NUMBER;

PROMPT ________________________________________________
PROMPT Creating FIXED_OUTLIER_RATES_AIS table...
DECLARE
	v_table_exists		INTEGER := 0;
BEGIN
   :log_level := &&3;

	SELECT	COUNT(*)
	INTO		v_table_exists
	FROM		user_tables
	WHERE		table_name = 'FIXED_OUTLIER_RATES_AIS_OLD';

   IF v_table_exists > 0 THEN
		EXECUTE IMMEDIATE 'DROP TABLE FIXED_OUTLIER_RATES_AIS_OLD';
      print_info('Dropped table FIXED_OUTLIER_RATES_AIS_OLD', :log_level);
   ELSE
      print_debug('Table FIXED_OUTLIER_RATES_AIS_OLD does not exist.', :log_level);
	END IF;

   SELECT	COUNT(*)
   INTO		v_table_exists
   FROM		user_tables
   WHERE		table_name = 'FIXED_OUTLIER_RATES_AIS';

   IF v_table_exists > 0 THEN
      EXECUTE IMMEDIATE 'RENAME FIXED_OUTLIER_RATES_AIS TO FIXED_OUTLIER_RATES_AIS_OLD';
		print_info('Renamed table FIXED_OUTLIER_RATES_AIS to FIXED_OUTLIER_RATES_AIS_OLD', :log_level);
   ELSE
      print_info('Table FIXED_OUTLIER_RATES_AIS does not exist', :log_level);
   END IF;

   print_info('Create table FIXED_OUTLIER_RATES_AIS now...', :log_level);
EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/
show errors

CREATE TABLE fixed_outlier_rates_ais
   (ago_ind             VARCHAR2(1),
    unit_treated        VARCHAR2(1),
    ai_rate_type        VARCHAR2(20),
    site_type           VARCHAR2(20),
    chem_code           INTEGER,
    chemname            VARCHAR2(200))
NOLOGGING
PCTUSED 95
PCTFREE 3
STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0)
TABLESPACE pur_report;


PROMPT .................................................
PROMPT Creating temporary FIXED_OUTLIER_RATES_STATS table...
DECLARE
	v_table_exists		INTEGER := 0;
BEGIN
	SELECT	COUNT(*)
	INTO		v_table_exists
	FROM		user_tables
	WHERE		table_name = 'FIXED_OUTLIER_RATES_STATS';

   IF v_table_exists > 0 THEN
      EXECUTE IMMEDIATE 'DROP TABLE FIXED_OUTLIER_RATES_STATS';
      print_info('Table FIXED_OUTLIER_RATES_STATS exists, so it was deleted.', :log_level);
   ELSE
      print_info('Table FIXED_OUTLIER_RATES_STATS does not exist.', :log_level);
   END IF;

   print_info('Create table FIXED_OUTLIER_RATES_STATS now...', :log_level);

EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/
show errors

CREATE TABLE fixed_outlier_rates_stats
   (ago_ind             VARCHAR2(1),
    unit_treated        VARCHAR2(1),
    site_type           VARCHAR2(20),
    chem_code           INTEGER,
    chemname            VARCHAR2(200),
    ai_adjuvant         VARCHAR2(1),
    num_years           INTEGER,
    num_recs            INTEGER,
    num_recs_last_8yr   INTEGER,
    num_01             INTEGER,
    num_01_last_8yr    INTEGER,
    num_02             INTEGER,
    num_02_last_8yr    INTEGER,
    num_04             INTEGER,
    num_04_last_8yr    INTEGER,
    num_06             INTEGER,
    num_06_last_8yr    INTEGER,
    num_08             INTEGER,
    num_08_last_8yr    INTEGER,
    num_1             INTEGER,
    num_1_last_8yr    INTEGER,
    num_2             INTEGER,
    num_2_last_8yr    INTEGER,
    num_3             INTEGER,
    num_3_last_8yr    INTEGER,
    num_4             INTEGER,
    num_4_last_8yr    INTEGER,
    num_5             INTEGER,
    num_5_last_8yr    INTEGER,
    num_6             INTEGER,
    num_6_last_8yr    INTEGER,
    num_7             INTEGER,
    num_7_last_8yr    INTEGER,
    num_8             INTEGER,
    num_8_last_8yr    INTEGER,
    num_9             INTEGER,
    num_9_last_8yr    INTEGER,
    num_10             INTEGER,
    num_10_last_8yr    INTEGER,
    num_12             INTEGER,
    num_12_last_8yr    INTEGER,
    num_14             INTEGER,
    num_14_last_8yr    INTEGER,
    num_16             INTEGER,
    num_16_last_8yr    INTEGER,
    num_18             INTEGER,
    num_18_last_8yr    INTEGER,
    num_20             INTEGER,
    num_20_last_8yr    INTEGER,
    num_25             INTEGER,
    num_25_last_8yr    INTEGER,
    num_30             INTEGER,
    num_30_last_8yr    INTEGER,
    num_35             INTEGER,
    num_35_last_8yr    INTEGER,
    num_40             INTEGER,
    num_40_last_8yr    INTEGER,
    num_45             INTEGER,
    num_45_last_8yr    INTEGER,
    num_50             INTEGER,
    num_50_last_8yr    INTEGER,
    num_60             INTEGER,
    num_60_last_8yr    INTEGER,
    num_70             INTEGER,
    num_70_last_8yr    INTEGER,
    num_80             INTEGER,
    num_80_last_8yr    INTEGER,
    num_90             INTEGER,
    num_90_last_8yr    INTEGER,
    num_100             INTEGER,
    num_100_last_8yr    INTEGER,
    num_200             INTEGER,
    num_200_last_8yr    INTEGER,
    num_300             INTEGER,
    num_300_last_8yr    INTEGER,
    num_400             INTEGER,
    num_400_last_8yr    INTEGER,
    num_500             INTEGER,
    num_500_last_8yr    INTEGER,
    num_600             INTEGER,
    num_600_last_8yr    INTEGER,
    num_700             INTEGER,
    num_700_last_8yr    INTEGER,
    num_800             INTEGER,
    num_800_last_8yr    INTEGER,
    num_900             INTEGER,
    num_900_last_8yr    INTEGER,
    num_1000            INTEGER,
    num_1000_last_8yr   INTEGER,
    num_2000            INTEGER,
    num_2000_last_8yr   INTEGER,
    num_3000            INTEGER,
    num_3000_last_8yr   INTEGER,
    num_4000            INTEGER,
    num_4000_last_8yr   INTEGER,
    num_5000            INTEGER,
    num_5000_last_8yr   INTEGER)
NOLOGGING
PCTUSED 95
PCTFREE 3
STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0)
TABLESPACE pur_report;

INSERT INTO fixed_outlier_rates_stats
      SELECT   CASE WHEN pur.record_id IN ('2', 'C') OR pur.site_code < 100 OR pur.site_code > 29500
						  THEN 'N' ELSE 'A' END ago_ind,
               CASE WHEN unit_treated = 'S' THEN 'A'
                    WHEN unit_treated = 'T' THEN 'P'
                    WHEN unit_treated = 'K' THEN 'C'
                    ELSE unit_treated END unit_treated,
               CASE WHEN site_code IN (65000, 65011, 65015, 65021, 65026, 65029, 65503, 65505) 
                    THEN 'WATER'
                    ELSE 'OTHER'
               END site_type,
               chem_code, chemname, 
               --CASE WHEN chem_code IN (1379, 1664, 2173, 2216, 5068) THEN 'Y' 
               --     WHEN chem_code IS NULL THEN 'N' ELSE ca.adjuvant END ai_adjuvant, 
               CASE WHEN chem_code IS NULL THEN 'N' ELSE ca.adjuvant END ai_adjuvant, 
               COUNT(distinct year) num_years,
               COUNT(*) num_recs,
               SUM(CASE WHEN year BETWEEN (&&1 - 7) AND &&1 THEN 1 END) num_recs_last_8yr,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 0.1
                        THEN 1 END) num_01,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 0.1 AND
                              year BETWEEN (&&1 - 7) AND &&1
                        THEN 1 END) num_01_last_8yr,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 0.2
                        THEN 1 END) num_02,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 0.2 AND
                              year BETWEEN (&&1 - 7) AND &&1
                        THEN 1 END) num_02_last_8yr,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 0.4
                        THEN 1 END) num_04,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 0.4 AND
                              year BETWEEN (&&1 - 7) AND &&1
                        THEN 1 END) num_04_last_8yr,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 0.6
                        THEN 1 END) num_06,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 0.6 AND
                              year BETWEEN (&&1 - 7) AND &&1
                        THEN 1 END) num_06_last_8yr,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 0.8
                        THEN 1 END) num_08,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 0.8 AND
                              year BETWEEN (&&1 - 7) AND &&1
                        THEN 1 END) num_08_last_8yr,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 1
                        THEN 1 END) num_1,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 1 AND
                              year BETWEEN (&&1 - 7) AND &&1
                        THEN 1 END) num_1_last_8yr,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 2
                        THEN 1 END) num_2,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 2 AND
                              year BETWEEN (&&1 - 7) AND &&1
                        THEN 1 END) num_2_last_8yr,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 3
                        THEN 1 END) num_3,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 3 AND
                              year BETWEEN (&&1 - 7) AND &&1
                        THEN 1 END) num_3_last_8yr,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 4
                        THEN 1 END) num_4,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 4 AND
                              year BETWEEN (&&1 - 7) AND &&1
                        THEN 1 END) num_4_last_8yr,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 5
                        THEN 1 END) num_5,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 5 AND
                              year BETWEEN (&&1 - 7) AND &&1
                        THEN 1 END) num_5_last_8yr,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 6
                        THEN 1 END) num_6,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 6 AND
                              year BETWEEN (&&1 - 7) AND &&1
                        THEN 1 END) num_6_last_8yr,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 7
                        THEN 1 END) num_7,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 7 AND
                              year BETWEEN (&&1 - 7) AND &&1
                        THEN 1 END) num_7_last_8yr,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 8
                        THEN 1 END) num_8,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 8 AND
                              year BETWEEN (&&1 - 7) AND &&1
                        THEN 1 END) num_8_last_8yr,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 9
                        THEN 1 END) num_9,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 9 AND
                              year BETWEEN (&&1 - 7) AND &&1
                        THEN 1 END) num_9_last_8yr,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 10
                        THEN 1 END) num_10,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 10 AND
                              year BETWEEN (&&1 - 7) AND &&1
                        THEN 1 END) num_10_last_8yr,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 12
                        THEN 1 END) num_12,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 12 AND
                              year BETWEEN (&&1 - 7) AND &&1
                        THEN 1 END) num_12_last_8yr,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 14
                        THEN 1 END) num_14,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 14 AND
                              year BETWEEN (&&1 - 7) AND &&1
                        THEN 1 END) num_14_last_8yr,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 16
                        THEN 1 END) num_16,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 16 AND
                              year BETWEEN (&&1 - 7) AND &&1
                        THEN 1 END) num_16_last_8yr,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 18
                        THEN 1 END) num_18,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 18 AND
                              year BETWEEN (&&1 - 7) AND &&1
                        THEN 1 END) num_18_last_8yr,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 20
                        THEN 1 END) num_20,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 20 AND
                              year BETWEEN (&&1 - 7) AND &&1
                        THEN 1 END) num_20_last_8yr,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 25
                        THEN 1 END) num_25,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 25 AND
                              year BETWEEN (&&1 - 7) AND &&1
                        THEN 1 END) num_25_last_8yr,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 30
                        THEN 1 END) num_30,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 30 AND
                              year BETWEEN (&&1 - 7) AND &&1
                        THEN 1 END) num_30_last_8yr,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 35
                        THEN 1 END) num_35,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 35 AND
                              year BETWEEN (&&1 - 7) AND &&1
                        THEN 1 END) num_35_last_8yr,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 40
                        THEN 1 END) num_40,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 40 AND
                              year BETWEEN (&&1 - 7) AND &&1
                        THEN 1 END) num_40_last_8yr,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 45
                        THEN 1 END) num_45,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 45 AND
                              year BETWEEN (&&1 - 7) AND &&1
                        THEN 1 END) num_45_last_8yr,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 50
                        THEN 1 END) num_50,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 50 AND
                              year BETWEEN (&&1 - 7) AND &&1
                        THEN 1 END) num_50_last_8yr,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 60
                        THEN 1 END) num_60,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 60 AND
                              year BETWEEN (&&1 - 7) AND &&1
                        THEN 1 END) num_60_last_8yr,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 70
                        THEN 1 END) num_70,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 70 AND
                              year BETWEEN (&&1 - 7) AND &&1
                        THEN 1 END) num_70_last_8yr,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 80
                        THEN 1 END) num_80,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 80 AND
                              year BETWEEN (&&1 - 7) AND &&1
                        THEN 1 END) num_80_last_8yr,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 90
                        THEN 1 END) num_90,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 90 AND
                              year BETWEEN (&&1 - 7) AND &&1
                        THEN 1 END) num_90_last_8yr,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 100
                        THEN 1 END) num_100,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 100 AND
                              year BETWEEN (&&1 - 7) AND &&1
                        THEN 1 END) num_100_last_8yr,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 200
                        THEN 1 END) num_200,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 200 AND
                              year BETWEEN (&&1 - 7) AND &&1
                        THEN 1 END) num_200_last_8yr,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 300
                        THEN 1 END) num_300,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 300 AND
                              year BETWEEN (&&1 - 7) AND &&1
                        THEN 1 END) num_300_last_8yr,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 400
                        THEN 1 END) num_400,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 400 AND
                              year BETWEEN (&&1 - 7) AND &&1
                        THEN 1 END) num_400_last_8yr,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 500
                        THEN 1 END) num_500,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 500 AND
                              year BETWEEN (&&1 - 7) AND &&1
                        THEN 1 END) num_500_last_8yr,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 600
                        THEN 1 END) num_600,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 600 AND
                              year BETWEEN (&&1 - 7) AND &&1
                        THEN 1 END) num_600_last_8yr,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 700
                        THEN 1 END) num_700,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 700 AND
                              year BETWEEN (&&1 - 7) AND &&1
                        THEN 1 END) num_700_last_8yr,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 800
                        THEN 1 END) num_800,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 800 AND
                              year BETWEEN (&&1 - 7) AND &&1
                        THEN 1 END) num_800_last_8yr,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 900
                        THEN 1 END) num_900,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 900 AND
                              year BETWEEN (&&1 - 7) AND &&1
                        THEN 1 END) num_900_last_8yr,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 1000
                        THEN 1 END) num_1000,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 1000 AND
                              year BETWEEN (&&1 - 7) AND &&1
                        THEN 1 END) num_1000_last_8yr,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 2000
                        THEN 1 END) num_2000,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 2000 AND
                              year BETWEEN (&&1 - 7) AND &&1
                        THEN 1 END) num_2000_last_8yr,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 3000
                        THEN 1 END) num_3000,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 3000 AND
                              year BETWEEN (&&1 - 7) AND &&1
                        THEN 1 END) num_3000_last_8yr,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 4000
                        THEN 1 END) num_4000,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 4000 AND
                              year BETWEEN (&&1 - 7) AND &&1
                        THEN 1 END) num_4000_last_8yr,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 5000
                        THEN 1 END) num_5000,
               SUM(CASE WHEN lbs_prd_used*prodchem_pct/
                              (100*CASE WHEN unit_treated = 'S' THEN acre_treated/43560 
                                        WHEN unit_treated = 'K' THEN acre_treated*1000 
                                        WHEN unit_treated = 'T' THEN acre_treated*2000 
                                        ELSE acre_treated END) > 5000 AND
                              year BETWEEN (&&1 - 7) AND &&1
                        THEN 1 END) num_5000_last_8yr
      FROM     pur LEFT JOIN prod_chem_major_ai pcma USING (prodno)
                   LEFT JOIN chemical USING (chem_code)
                   LEFT JOIN chem_adjuvant ca USING (chem_code)
      WHERE    year between (&&1 - &&2 + 1) and &&1 AND
               unit_treated IS NOT NULL AND
               acre_treated > 0 AND
               lbs_prd_used > 0 
               &&4 AND county_cd = '26' &&5
      GROUP BY CASE WHEN pur.record_id IN ('2', 'C') OR pur.site_code < 100 OR pur.site_code > 29500
						  THEN 'N' ELSE 'A' END,
               CASE WHEN unit_treated = 'S' THEN 'A'
                    WHEN unit_treated = 'T' THEN 'P'
                    WHEN unit_treated = 'K' THEN 'C'
                    ELSE unit_treated END,
               CASE WHEN site_code IN (65000, 65011, 65015, 65021, 65026, 65029, 65503, 65505) 
                    THEN 'WATER'
                    ELSE 'OTHER'
               END,
               chem_code, chemname, 
               CASE WHEN chem_code IS NULL THEN 'N' ELSE ca.adjuvant END; 

               --CASE WHEN chem_code IN (1379, 1664, 2173, 2216, 5068) THEN 'Y' 
               --     WHEN chem_code IS NULL THEN 'N' ELSE ca.adjuvant END ai_adjuvant, 

COMMIT;



DECLARE
   v_ago_ind            VARCHAR2(1);
   v_unit_treated       VARCHAR2(1);
   v_ai_rate_type            VARCHAR2(100);
   v_site_type          VARCHAR2(100);
   v_chem_code          INTEGER;
   v_chemname           VARCHAR2(500);
   v_adjuvant           VARCHAR2(1);
   v_num_recs           INTEGER;
   v_num_recs_last_8yr  INTEGER;

   CURSOR pur_cur IS
      SELECT   *
      FROM     fixed_outlier_rates_stats;

BEGIN
   print_info('Create table FIXED_OUTLIER_RATES_AIS now...', :log_level);

   FOR pur_rec IN pur_cur LOOP
      v_ago_ind := pur_rec.ago_ind;
      v_unit_treated := pur_rec.unit_treated;
      v_site_type := pur_rec.site_type;
      v_chem_code := NVL(pur_rec.chem_code, -1);
      v_chemname := NVL(pur_rec.chemname, 'UNKNOWN');
      v_adjuvant := pur_rec.ai_adjuvant;
      v_num_recs := pur_rec.num_recs;
      v_num_recs_last_8yr := pur_rec.num_recs_last_8yr;

      /* Formula for Excel - first define a name for each column, first select the column then choose: insert -> name -> define.
      =if(num_recs_last_8yr > 50,
         if(num_2000_last_8yr > 10, "HIGH", if(num_500_last_8yr > 10, "MEDIUM", "NORMAL")),
         if(num_recs > 50,
            if(num_2000 > 10, "HIGH", if(num_500 > 10, "MEDIUM", "NORMAL")),
            "NORMAL")
         )

      =if(num_recs_last_8yr > 50, if(num_2000_last_8yr > 10, "HIGH", if(num_500_last_8yr > 10, "MEDIUM", "NORMAL")),if(num_recs > 50,if(num_2000 > 10, "HIGH", if(num_500 > 10, "MEDIUM", "NORMAL")), "NORMAL"))
      */
      v_ai_rate_type := 'NORMAL';

      IF v_adjuvant = 'Y' THEN
         v_ai_rate_type := 'ADJUVANT';
      ELSIF v_ago_ind = 'A' THEN
         IF v_unit_treated = 'A' THEN
            IF pur_rec.num_100_last_8yr/v_num_recs_last_8yr * 100 > 50 AND 
               v_num_recs_last_8yr > 100 
            THEN v_ai_rate_type := 'HIGH';
            ELSIF pur_rec.num_25_last_8yr/v_num_recs_last_8yr * 100 > 2 AND 
                  v_num_recs_last_8yr > 50 
            THEN v_ai_rate_type := 'MEDIUM';
            END IF;
         ELSIF v_unit_treated = 'U' THEN
            IF pur_rec.num_1/v_num_recs * 100 > 4 AND 
               v_num_recs > 20 
            THEN v_ai_rate_type := 'HIGH';
            END IF;
         END IF;
      ELSIF v_ago_ind = 'N' THEN
         IF v_unit_treated = 'A' THEN
            IF v_site_type = 'OTHER' THEN
               IF pur_rec.num_100_last_8yr/v_num_recs_last_8yr * 100 > 50 AND 
                  v_num_recs_last_8yr > 10 
               THEN v_ai_rate_type := 'HIGH';
               ELSIF pur_rec.num_50_last_8yr/v_num_recs_last_8yr * 100 > 4 AND 
                     v_num_recs_last_8yr > 25 
               THEN v_ai_rate_type := 'MEDIUM'; 
               END IF;
            ELSIF v_site_type = 'WATER' THEN
               IF pur_rec.num_100_last_8yr/v_num_recs_last_8yr * 100 > 20 AND 
                  v_num_recs_last_8yr > 20 
               THEN v_ai_rate_type := 'HIGH';
               ELSIF pur_rec.num_50_last_8yr/v_num_recs_last_8yr * 100 > 10 AND 
                     v_num_recs_last_8yr > 20 
               THEN v_ai_rate_type := 'MEDIUM'; 
               END IF;
            END IF;
         ELSIF v_unit_treated = 'P' THEN
            IF v_site_type = 'OTHER' THEN
               IF pur_rec.num_01_last_8yr/v_num_recs_last_8yr * 100 > 1 AND 
                  v_num_recs_last_8yr > 25 
               THEN v_ai_rate_type := 'HIGH';
               ELSIF pur_rec.num_01_last_8yr/v_num_recs_last_8yr * 100 > 0.1 AND 
                     v_num_recs_last_8yr > 25 
               THEN v_ai_rate_type := 'MEDIUM'; 
               END IF;
            END IF;         
         ELSIF v_unit_treated = 'U' THEN
            IF v_site_type = 'OTHER' THEN
               IF pur_rec.num_50_last_8yr/v_num_recs_last_8yr * 100 > 15 AND 
                  v_num_recs_last_8yr > 10 
               THEN v_ai_rate_type := 'HIGH';
               ELSIF pur_rec.num_20_last_8yr/v_num_recs_last_8yr * 100 > 5 AND 
                     v_num_recs_last_8yr> 10 
               THEN v_ai_rate_type := 'MEDIUM'; 
               END IF;
           END IF;
         END IF;
      END IF;

      INSERT INTO fixed_outlier_rates_ais VALUES
         (v_ago_ind, v_unit_treated, v_ai_rate_type, v_site_type, v_chem_code, v_chemname);

      COMMIT;
   END LOOP;
   COMMIT;

   SELECT   count(*)
   INTO     v_num_recs
   FROM     fixed_outlier_rates_ais;

   print_info('Table FIXED_OUTLIER_RATES_AIS was created, with '||v_num_recs ||' number of recrods.', :log_level);

EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(SQLERRM||'; chem_code = '||v_chem_code);
END;
/
show errors

PROMPT ________________________________________________

EXIT 0

