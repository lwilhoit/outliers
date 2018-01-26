/* This code is an example of how CalAgPermits could check for outliers
	in rates of use in pounds of AI per unit treated and
	rates in pounds of AI per application.

	It checks each PUR record and if the rate of use (or either kind of rate)
	is an outlier by any criteria, the record along with the various
	outlier limits and statistics is stored in table PUR_OUTLIER.

	It uses 4 tables, AI_GROUP_STATS, AI_OUTLIER_STATS, AI_GROUP_NONAG_STATS,
	AI_OUTLIER_NONAG_STATS which have statistics on outlier limits
	for different properties of a pesticide application, such as AI, product,
	site treated, record type (ago_ind), unit treated.

	These four tables are created in create_ai_groups_ai_outlier_stats.sql,
	outlier_stats.py, create_ai_groups_ai_outlier_stats_nonag.sql, AND.
	outlier_stats_nonag.py

	This can be run using the statistics from the previous 10 years or statistics
	using the current year and previous 9 years by setting paramter
	v_use_current_year = TRUE or FALSE.
	While data is being received from the counties, the statistics are based
	on previous 10 years (so set v_use_current_year = FALSE).
	When all data for a year has been entered you can run this script with
	v_use_current_year = TRUE.

	Another outlier limit comes from the maximum rate of use on the pesticide label.
	Currently, we have maximum label rates for only a few products. These
	data are in table MAX_LABEL_RATES.

	For situations (AI, ago_ind, unit_treated) where the total number of PUR records
	in previous years was <= 4, use only the fixed outlier limit.  I consider
	that 4 or fewer records are too few to use as a basis for determining typical uses.
	This value is set with the parameter v_num_recs_min.

	DPR will recreate this table every year with updated outlier statistics.
	This table is not yet ready - we are still developing the code to
	create it.  The final version may be slightly different.  For example,
	we may add a field for the county or region where the application was made
	and we may add an additional outlier criterion.

	The other table in this script, PUR_OUTLIER_&&1, is used only for debugging
	purposes, and I doubt if it would be needed in the production system.

	To do:
	1. Add SD to pur_outlier_&&1
	2. When no group found (because of uses on new site or product), increase the outlier limit
		by either:
		a. add 1 to mean8sd
		b. use mean12sd or mean15sd
		c. use med50

	3. Include month and county or region in determing groups; if there are few records for these
		groups, use larger group (either with all counties or all months).

	4. Calculate percent outliers for adjuvants (both AI and prod), sites, products, counties, SD,
		others?

 */
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

/* Create a table with an outlier flag for each PUR record.
	This table is used only for debugging purposes.
	If the reported rate of use > the fixed outlier limit, then fixed_outlier = 'X';
	if the reported rate of use > the 50*median outlier limit, then med50_outlier = 'X';
	if the reported rate of use > the maximum label rate, then label_outlier = 'X';
 */
PROMPT ________________________________________________
PROMPT Creating PUR_OUTLIER_&&1 table...
DECLARE
	v_table_exists		INTEGER := 0;
BEGIN
	SELECT	COUNT(*)
	INTO		v_table_exists
	FROM		user_tables
	WHERE		table_name = 'PUR_OUTLIER_&&1';

	IF v_table_exists > 0 THEN
		EXECUTE IMMEDIATE 'DROP TABLE pur_outlier_&&1';
	END IF;
EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/
show errors

CREATE TABLE pur_outlier_&&1
   (year								INTEGER,
	 use_no							INTEGER,
	 record_id						VARCHAR2(1),
  	 chem_code						INTEGER,
	 ai_rate_type					VARCHAR2(20),
	 site_type						VARCHAR2(20),
	 lbs_ai_app_type				VARCHAR2(20),
	 regno_short					VARCHAR2(20),
	 site_general					VARCHAR2(100),
    ago_ind        				VARCHAR2(1),
    unit_treated 					VARCHAR2(1),
	 ai_group_rate					INTEGER,
	 ai_group_lbsapp				INTEGER,
	 prod_adjuvant					VARCHAR2(1),
	 ai_adjuvant					VARCHAR2(1),
	 prodno							INTEGER,
	 site_code						INTEGER,
	 county_cd						VARCHAR2(2),
	 app_month						INTEGER,
	 grower_id						VARCHAR2(11),
	 site_loc_id					VARCHAR2(8),
	 license_no						VARCHAR2(13),
	 amt_prd_used					NUMBER,
	 unit_of_meas					VARCHAR2(2),
	 lbs_prd_used					NUMBER,
	 lbs_ai							NUMBER,
	 acre_treated					NUMBER,
	 unit_treated_report			VARCHAR2(1),
	 applic_cnt						INTEGER,
	 prod_rate						NUMBER,
	 ai_rate							NUMBER,
	 lbs_ai_per_app				NUMBER,
	 log_prod_rate					NUMBER,
	 log_ai_rate					NUMBER,
	 log_lbs_ai_per_app			NUMBER,
	 num_recs_rate     			INTEGER,
	 sd_rate		     				NUMBER,
	 sd_trim_orig_rate 			NUMBER,
	 sd_trim_rate     			NUMBER,
	 fixed1_rate					NUMBER,
	 fixed2_rate					NUMBER,
	 fixed3_rate					NUMBER,
	 med50_rate     				NUMBER,
	 med100_rate    				NUMBER,
	 med150_rate    				NUMBER,
	 med200_rate    				NUMBER,
	 med250_rate    				NUMBER,
	 med300_rate    				NUMBER,
	 med400_rate    				NUMBER,
	 med500_rate    				NUMBER,
	 mean3sd_rate   				NUMBER,
	 mean5sd_rate   				NUMBER,
	 mean7sd_rate   				NUMBER,
	 mean8sd_rate   				NUMBER,
	 mean10sd_rate  				NUMBER,
	 mean12sd_rate  				NUMBER,
	 mean15sd_rate  				NUMBER,
	 max_label 						NUMBER,
	 old_fixed_rate 				NUMBER,
	 old_med50_rate 				NUMBER,
	 fixed1_rate_outlier			VARCHAR2(1),
	 fixed2_rate_outlier			VARCHAR2(1),
	 fixed3_rate_outlier			VARCHAR2(1),
	 med50_rate_outlier			VARCHAR2(1),
	 med100_rate_outlier			VARCHAR2(1),
	 med150_rate_outlier			VARCHAR2(1),
	 med200_rate_outlier			VARCHAR2(1),
	 med250_rate_outlier			VARCHAR2(1),
	 med300_rate_outlier			VARCHAR2(1),
	 med400_rate_outlier			VARCHAR2(1),
	 med500_rate_outlier			VARCHAR2(1),
	 mean3sd_rate_outlier		VARCHAR2(1),
	 mean5sd_rate_outlier		VARCHAR2(1),
	 mean7sd_rate_outlier		VARCHAR2(1),
	 mean8sd_rate_outlier		VARCHAR2(1),
	 mean10sd_rate_outlier		VARCHAR2(1),
	 mean12sd_rate_outlier		VARCHAR2(1),
	 mean15sd_rate_outlier		VARCHAR2(1),
	 label_rate_outlier			VARCHAR2(1),
	 old_fixed_rate_outlier		VARCHAR2(1),
	 old_med50_rate_outlier		VARCHAR2(1),
	 num_recs_lbsapp     		INTEGER,
	 sd_lbsapp		     			NUMBER,
	 sd_trim_orig_lbsapp 		NUMBER,
	 sd_trim_lbsapp     			NUMBER,
	 fixed1_lbsapp					NUMBER,
	 fixed2_lbsapp					NUMBER,
	 fixed3_lbsapp					NUMBER,
	 med50_lbsapp     			NUMBER,
	 med100_lbsapp    			NUMBER,
	 med150_lbsapp    			NUMBER,
	 med200_lbsapp 				NUMBER,
	 med250_lbsapp 				NUMBER,
	 med300_lbsapp 				NUMBER,
	 med400_lbsapp 				NUMBER,
	 med500_lbsapp 				NUMBER,
	 med1000_lbsapp   			NUMBER,
	 med5000_lbsapp   			NUMBER,
	 med10000_lbsapp  			NUMBER,
	 med50000_lbsapp  			NUMBER,
	 med100000_lbsapp  			NUMBER,
	 mean3sd_lbsapp   			NUMBER,
	 mean5sd_lbsapp   			NUMBER,
	 mean7sd_lbsapp   			NUMBER,
	 mean8sd_lbsapp   			NUMBER,
	 mean10sd_lbsapp  			NUMBER,
	 mean12sd_lbsapp  			NUMBER,
	 mean15sd_lbsapp  			NUMBER,
	 fixed1_lbsapp_outlier		VARCHAR2(1),
	 fixed2_lbsapp_outlier		VARCHAR2(1),
	 fixed3_lbsapp_outlier		VARCHAR2(1),
	 med50_lbsapp_outlier		VARCHAR2(1),
	 med100_lbsapp_outlier		VARCHAR2(1),
	 med150_lbsapp_outlier    	VARCHAR2(1),
	 med200_lbsapp_outlier 		VARCHAR2(1),
	 med250_lbsapp_outlier 		VARCHAR2(1),
	 med300_lbsapp_outlier 		VARCHAR2(1),
	 med400_lbsapp_outlier 		VARCHAR2(1),
	 med500_lbsapp_outlier 		VARCHAR2(1),
	 med1000_lbsapp_outlier   	VARCHAR2(1),
	 med5000_lbsapp_outlier   	VARCHAR2(1),
	 med10000_lbsapp_outlier  	VARCHAR2(1),
	 med50000_lbsapp_outlier  	VARCHAR2(1),
	 med100000_lbsapp_outlier  VARCHAR2(1),
	 mean3sd_lbsapp_outlier   	VARCHAR2(1),
	 mean5sd_lbsapp_outlier   	VARCHAR2(1),
	 mean7sd_lbsapp_outlier   	VARCHAR2(1),
	 mean8sd_lbsapp_outlier   	VARCHAR2(1),
	 mean10sd_lbsapp_outlier  	VARCHAR2(1),
	 mean12sd_lbsapp_outlier  	VARCHAR2(1),
	 mean15sd_lbsapp_outlier  	VARCHAR2(1),
    recommend_outlier        	VARCHAR2(1))
NOLOGGING
PCTUSED 95
PCTFREE 3
STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0)
TABLESPACE pur_report;

DECLARE
	v_num_recs_min			INTEGER := 4;
	v_ai_rate				NUMBER;
	v_prod_rate				NUMBER;
	v_lbs_ai_per_app		NUMBER;
	v_log_ai_rate			NUMBER;
	v_log_prod_rate		NUMBER;
	v_log_lbs_ai_per_app	NUMBER;

	v_ai_rate_type				VARCHAR2(30);
	v_site_type					VARCHAR2(30);
	v_lbs_ai_app_type			VARCHAR2(30);

	v_ai_group_rate				INTEGER;
	v_num_recs_rate				INTEGER;
	v_sd_rate						NUMBER;
	v_sd_trim_orig_rate			NUMBER;
	v_sd_trim_rate					NUMBER;

	v_fixed1_rate					NUMBER;
	v_fixed2_rate					NUMBER;
	v_fixed3_rate					NUMBER;
	v_med50_rate     				NUMBER;
	v_med100_rate    				NUMBER;
	v_med150_rate    				NUMBER;
	v_med200_rate    				NUMBER;
	v_med250_rate    				NUMBER;
	v_med300_rate    				NUMBER;
	v_med400_rate    				NUMBER;
	v_med500_rate    				NUMBER;
	v_mean3sd_rate   				NUMBER;
	v_mean5sd_rate   				NUMBER;
	v_mean7sd_rate   				NUMBER;
	v_mean8sd_rate   				NUMBER;
	v_mean10sd_rate  				NUMBER;
	v_mean12sd_rate  				NUMBER;
	v_mean15sd_rate  				NUMBER;
	v_max_label_prod				NUMBER;
	v_max_label						NUMBER;
	v_old_fixed_rate				NUMBER;
	v_old_med50_rate				NUMBER;

	v_ai_group_lbsapp				INTEGER;
	v_num_recs_lbsapp				INTEGER;
	v_sd_lbsapp						NUMBER;
	v_sd_trim_orig_lbsapp		NUMBER;
	v_sd_trim_lbsapp				NUMBER;

	v_fixed1_lbsapp				NUMBER;
	v_fixed2_lbsapp				NUMBER;
	v_fixed3_lbsapp				NUMBER;
	v_med50_lbsapp					NUMBER;
	v_med100_lbsapp				NUMBER;
	v_med150_lbsapp    			NUMBER;
	v_med200_lbsapp 				NUMBER;
	v_med250_lbsapp 				NUMBER;
	v_med300_lbsapp 				NUMBER;
	v_med400_lbsapp 				NUMBER;
	v_med500_lbsapp 				NUMBER;
	v_med1000_lbsapp   			NUMBER;
	v_med5000_lbsapp   			NUMBER;
	v_med10000_lbsapp  			NUMBER;
	v_med50000_lbsapp  			NUMBER;
	v_med100000_lbsapp  			NUMBER;
	v_mean3sd_lbsapp				NUMBER;
	v_mean5sd_lbsapp				NUMBER;
	v_mean7sd_lbsapp				NUMBER;
	v_mean8sd_lbsapp				NUMBER;
	v_mean10sd_lbsapp				NUMBER;
	v_mean12sd_lbsapp				NUMBER;
	v_mean15sd_lbsapp				NUMBER;

	v_fixed1_rate_outlier		VARCHAR2(1);
	v_fixed2_rate_outlier		VARCHAR2(1);
	v_fixed3_rate_outlier		VARCHAR2(1);
	v_med50_rate_outlier			VARCHAR2(1);
	v_med100_rate_outlier		VARCHAR2(1);
	v_med150_rate_outlier		VARCHAR2(1);
	v_med200_rate_outlier		VARCHAR2(1);
	v_med250_rate_outlier    	VARCHAR2(1);
	v_med300_rate_outlier    	VARCHAR2(1);
	v_med400_rate_outlier    	VARCHAR2(1);
	v_med500_rate_outlier    	VARCHAR2(1);
	v_mean3sd_rate_outlier   	VARCHAR2(1);
	v_mean5sd_rate_outlier   	VARCHAR2(1);
	v_mean7sd_rate_outlier		VARCHAR2(1);
	v_mean8sd_rate_outlier		VARCHAR2(1);
	v_mean10sd_rate_outlier		VARCHAR2(1);
	v_mean12sd_rate_outlier		VARCHAR2(1);
	v_mean15sd_rate_outlier		VARCHAR2(1);
	v_label_rate_outlier			VARCHAR2(1);
	v_old_fixed_rate_outlier	VARCHAR2(1);
	v_old_med50_rate_outlier	VARCHAR2(1);

	v_fixed1_lbsapp_outlier		VARCHAR2(1);
	v_fixed2_lbsapp_outlier		VARCHAR2(1);
	v_fixed3_lbsapp_outlier		VARCHAR2(1);
	v_med50_lbsapp_outlier		VARCHAR2(1);
	v_med100_lbsapp_outlier		VARCHAR2(1);
	v_med150_lbsapp_outlier		VARCHAR2(1);
	v_med200_lbsapp_outlier		VARCHAR2(1);
	v_med250_lbsapp_outlier		VARCHAR2(1);
	v_med300_lbsapp_outlier		VARCHAR2(1);
	v_med400_lbsapp_outlier		VARCHAR2(1);
	v_med500_lbsapp_outlier		VARCHAR2(1);
	v_med1000_lbsapp_outlier	VARCHAR2(1);
	v_med5000_lbsapp_outlier	VARCHAR2(1);
	v_med10000_lbsapp_outlier	VARCHAR2(1);
	v_med50000_lbsapp_outlier  VARCHAR2(1);
	v_med100000_lbsapp_outlier VARCHAR2(1);
	v_mean3sd_lbsapp_outlier 	VARCHAR2(1);
	v_mean5sd_lbsapp_outlier 	VARCHAR2(1);
	v_mean7sd_lbsapp_outlier	VARCHAR2(1);
	v_mean8sd_lbsapp_outlier	VARCHAR2(1);
	v_mean10sd_lbsapp_outlier	VARCHAR2(1);
	v_mean12sd_lbsapp_outlier	VARCHAR2(1);
	v_mean15sd_lbsapp_outlier	VARCHAR2(1);

   v_recommend_outlier        VARCHAR2(1);

	v_use_no					INTEGER;
	v_index					INTEGER;
	v_found_outlier		BOOLEAN;

	CURSOR pur_cur IS
		SELECT	year, use_no, record_id,
					CASE WHEN record_id IN ('2', 'C') OR site_code < 100 OR site_code > 29500
						  THEN 'N' ELSE 'A' END ago_ind,
					prodno, chem_code, mfg_firmno||'-'||label_seq_no regno_short,
					NVL(pa.adjuvant, 'N') prod_adjuvant, NVL(ca.adjuvant, 'N') ai_adjuvant,
					site_code, site_general, TO_NUMBER(TO_CHAR(applic_dt, 'MM')) app_month,
					county_cd, grower_id, site_loc_id, license_no, amt_prd_used, unit_of_meas,
					lbs_prd_used, lbs_prd_used*prodchem_pct/100 lbs_ai,
					acre_treated, unit_treated unit_treated_report,
					CASE
						WHEN unit_treated = 'A' THEN acre_treated
						WHEN unit_treated = 'S' THEN acre_treated/43560
						WHEN unit_treated = 'C' THEN acre_treated
						WHEN unit_treated = 'K' THEN acre_treated*1000
						WHEN unit_treated = 'P' THEN acre_treated
						WHEN unit_treated = 'T' THEN acre_treated*2000
						WHEN unit_treated = 'U' THEN acre_treated
						ELSE acre_treated
					END amt_treated,
					CASE
						WHEN unit_treated = 'A' THEN 'A'
						WHEN unit_treated = 'S' THEN 'A'
						WHEN unit_treated = 'C' THEN 'C'
						WHEN unit_treated = 'K' THEN 'C'
						WHEN unit_treated = 'P' THEN 'P'
						WHEN unit_treated = 'T' THEN 'P'
						WHEN unit_treated = 'U' THEN 'U'
						ELSE NULL
					END unit_treated,
					CASE WHEN applic_cnt IS NULL OR applic_cnt = 0 THEN 1 ELSE applic_cnt END applic_cnt
		FROM		pur LEFT JOIN prod_chem_major_ai USING (prodno)
						 LEFT JOIN product USING (prodno)
						 LEFT JOIN pur_site_groups USING (site_code)
						 LEFT JOIN chem_adjuvant ca USING (chem_code)
						 LEFT JOIN prod_adjuvant pa USING (prodno)
		WHERE		year = &&1 AND
					lbs_prd_used > 0;


BEGIN
	v_index := 0;
	FOR pur_rec IN pur_cur LOOP
		v_use_no := pur_rec.use_no;
		v_found_outlier := FALSE;

		v_ai_rate := NULL;
		v_prod_rate := NULL;
		v_lbs_ai_per_app := NULL;
		v_log_ai_rate := NULL;
		v_log_prod_rate := NULL;
		v_log_lbs_ai_per_app := NULL;

		v_ai_rate_type := NULL;
		v_site_type := NULL;
		v_lbs_ai_app_type := NULL;

		v_ai_group_rate := NULL;
		v_num_recs_rate := NULL;
		v_sd_rate := NULL;
		v_sd_trim_orig_rate := NULL;
		v_sd_trim_rate := NULL;

		v_fixed1_rate := NULL;
		v_fixed2_rate := NULL;
		v_fixed3_rate := NULL;
		v_med50_rate := NULL;
		v_med100_rate := NULL;
		v_med150_rate := NULL;
		v_med200_rate := NULL;
		v_med250_rate := NULL;
		v_med300_rate := NULL;
		v_med400_rate := NULL;
		v_med500_rate := NULL;
		v_mean3sd_rate := NULL;
		v_mean5sd_rate := NULL;
		v_mean7sd_rate := NULL;
		v_mean8sd_rate := NULL;
		v_mean10sd_rate := NULL;
		v_mean12sd_rate := NULL;
		v_mean15sd_rate := NULL;
		v_max_label_prod := NULL;
		v_max_label := NULL;
		v_old_fixed_rate := NULL;
		v_old_med50_rate := NULL;

		v_ai_group_lbsapp := NULL;
		v_num_recs_lbsapp := NULL;
		v_sd_lbsapp := NULL;
		v_sd_trim_orig_lbsapp := NULL;
		v_sd_trim_lbsapp := NULL;

		v_fixed1_lbsapp := NULL;
		v_fixed2_lbsapp := NULL;
		v_fixed3_lbsapp := NULL;
		v_med50_lbsapp := NULL;
		v_med100_lbsapp := NULL;
		v_med150_lbsapp := NULL;
		v_med200_lbsapp := NULL;
		v_med250_lbsapp := NULL;
		v_med300_lbsapp := NULL;
		v_med400_lbsapp := NULL;
		v_med500_lbsapp := NULL;
		v_med1000_lbsapp := NULL;
		v_med5000_lbsapp := NULL;
		v_med10000_lbsapp := NULL;
		v_med50000_lbsapp := NULL;
		v_med100000_lbsapp := NULL;
		v_mean3sd_lbsapp := NULL;
		v_mean5sd_lbsapp := NULL;
		v_mean7sd_lbsapp := NULL;
		v_mean8sd_lbsapp := NULL;
		v_mean10sd_lbsapp := NULL;
		v_mean12sd_lbsapp := NULL;
		v_mean15sd_lbsapp := NULL;

		v_fixed1_rate_outlier := NULL;
		v_fixed2_rate_outlier := NULL;
		v_fixed3_rate_outlier := NULL;
		v_med50_rate_outlier := NULL;
		v_med100_rate_outlier := NULL;
		v_med150_rate_outlier := NULL;
		v_med200_rate_outlier := NULL;
		v_med250_rate_outlier     := NULL;
		v_med300_rate_outlier     := NULL;
		v_med400_rate_outlier     := NULL;
		v_med500_rate_outlier     := NULL;
		v_mean3sd_rate_outlier    := NULL;
		v_mean5sd_rate_outlier    := NULL;
		v_mean7sd_rate_outlier := NULL;
		v_mean8sd_rate_outlier := NULL;
		v_mean10sd_rate_outlier := NULL;
		v_mean12sd_rate_outlier := NULL;
		v_mean15sd_rate_outlier := NULL;

		v_label_rate_outlier := NULL;
		v_old_fixed_rate_outlier := NULL;
		v_old_med50_rate_outlier := NULL;

		v_fixed1_lbsapp_outlier := NULL;
		v_fixed2_lbsapp_outlier := NULL;
		v_fixed3_lbsapp_outlier := NULL;
		v_med50_lbsapp_outlier	 := NULL;
		v_med100_lbsapp_outlier	 := NULL;
		v_med150_lbsapp_outlier	 := NULL;
		v_med200_lbsapp_outlier	 := NULL;
		v_med250_lbsapp_outlier	 := NULL;
		v_med300_lbsapp_outlier	 := NULL;
		v_med400_lbsapp_outlier	 := NULL;
		v_med500_lbsapp_outlier	 := NULL;
		v_med1000_lbsapp_outlier := NULL;
		v_med5000_lbsapp_outlier := NULL;
		v_med10000_lbsapp_outlier := NULL;
		v_med50000_lbsapp_outlier := NULL;
		v_med100000_lbsapp_outlier := NULL;
		v_mean3sd_lbsapp_outlier  := NULL;
		v_mean5sd_lbsapp_outlier  := NULL;
		v_mean7sd_lbsapp_outlier := NULL;
		v_mean8sd_lbsapp_outlier := NULL;
		v_mean10sd_lbsapp_outlier := NULL;
		v_mean12sd_lbsapp_outlier := NULL;
		v_mean15sd_lbsapp_outlier := NULL;

      v_recommend_outlier := NULL;


		/*********************************************************************************
		 * Get outliers in rates of use ("ag" records)
		 ********************************************************************************/
		IF pur_rec.amt_treated > 0 AND pur_rec.unit_treated IN ('A', 'C', 'P', 'U') THEN
			/* Get the reported product rate of use (pounds of product per unit treated).
			 */
			v_prod_rate := pur_rec.lbs_prd_used/pur_rec.amt_treated;

			/* Here we are capturing outliers for each record and AI;
				in production version, we should just report if any outliers for any AI in the record.
			 */
			v_ai_rate := pur_rec.lbs_ai/pur_rec.amt_treated;
			v_log_ai_rate := log(10, v_ai_rate);


         /* Get the site_type:
       
            Water sites:
            65000   WATER AREA
            65011   SWIMMING POOL
            65015   WATER FILTER
            65021   DITCH BANK
            65026   SEWAGE SYSTEM
            65029   INDUSTRIAL PROCESSING WATER
            65503   WATER (INDUSTRIAL)
            65505   WATER WASHER/COOLER/CONDENSER SYSTEMS

            Previously, just
            65000 WATER AREA
            65503 INDUSTRIAL WATER
          */
         IF pur_rec.ago_ind = 'N' AND 
            pur_rec.site_code IN (65000, 65011, 65015, 65021, 65026, 65029, 65503, 65505) 
         THEN
            v_site_type := 'WATER';
         ELSE
            v_site_type := 'OTHER';
         END IF;

         /* Get the AI rate type for this AI and type of application:
          */
         IF pur_rec.ai_adjuvant = 'Y' THEN
            v_ai_rate_type := 'ADJUVANT';
         ELSE
            BEGIN
               SELECT   ai_rate_type
               INTO     v_ai_rate_type
               FROM     fixed_outlier_rates_ais
               WHERE    ago_ind = pur_rec.ago_ind AND 
                        unit_treated = pur_rec.unit_treated AND
                        site_type = v_site_type AND
                        chem_code = pur_rec.chem_code;
            EXCEPTION
               WHEN OTHERS THEN
                  v_ai_rate_type := 'NORMAL';
            END;
         END IF;


			/* Get the fixed outlier limits.
			 */
			BEGIN
				SELECT	log_rate1, log_rate2, log_rate3
				INTO		v_fixed1_rate, v_fixed2_rate, v_fixed3_rate
				FROM		fixed_outlier_rates
				WHERE		ago_ind = pur_rec.ago_ind AND
							unit_treated = pur_rec.unit_treated AND
							ai_rate_type = v_ai_rate_type AND
                     site_type = v_site_type;
			EXCEPTION
				WHEN OTHERS THEN
					v_fixed1_rate := NULL;
					v_fixed2_rate := NULL;
					v_fixed3_rate := NULL;
			END;

			/* Get other outlier limits.  First need the AI group number for this AI, product, site, ago_ind, and
				unit_treated.
			 */
			BEGIN
				SELECT	ai_group
				INTO		v_ai_group_rate
				FROM		ai_group_stats
				WHERE		year = &&1 AND
							chem_code = pur_rec.chem_code AND
							regno_short = pur_rec.regno_short AND
							site_general = pur_rec.site_general AND
							ago_ind = pur_rec.ago_ind AND
							unit_treated = pur_rec.unit_treated;
			EXCEPTION
				WHEN OTHERS THEN
					v_ai_group_rate := NULL;
			END;

			/* Get the outlier statistics for this application from table AI_OUTLIER_STATS.
			 */
			IF v_ai_group_rate IS NULL THEN
				/* If no statistics found for this AI, ago_ind, unit_treated, product, and site,
					then use maximum outlier limits for this AI, ago_ind, and unit_treated.
					If no statistics found for this AI, ago_ind, and unit_treated, just use fixed limits.
				 */
				BEGIN
					SELECT	SUM(num_recs), MAX(med50), MAX(med100),
								MAX(med150), MAX(med200), MAX(med250),
								MAX(med300), MAX(med400), MAX(med500),
								MAX(mean3sd), MAX(mean5sd), MAX(mean7sd),
								MAX(mean8sd), MAX(mean10sd),
								MAX(mean12sd), MAX(mean15sd),
								MAX(sd_rate), MAX(sd_rate_trim_orig), MAX(sd_rate_trim)
					INTO		v_num_recs_rate, v_med50_rate, v_med100_rate,
								v_med150_rate, v_med200_rate, v_med250_rate,
								v_med300_rate, v_med400_rate, v_med500_rate,
								v_mean3sd_rate, v_mean5sd_rate, v_mean7sd_rate,
								v_mean8sd_rate, v_mean10sd_rate,
								v_mean12sd_rate, v_mean15sd_rate,
								v_sd_rate, v_sd_trim_orig_rate, v_sd_trim_rate
					FROM		ai_outlier_stats
					WHERE		year = &&1 AND
								chem_code = pur_rec.chem_code AND
								ago_ind = pur_rec.ago_ind AND
								unit_treated = pur_rec.unit_treated;
				EXCEPTION
					WHEN OTHERS THEN
						v_num_recs_rate := NULL;
						v_med50_rate := NULL;
						v_med100_rate := NULL;
						v_med150_rate := NULL;
						v_med200_rate := NULL;
						v_med250_rate := NULL;
						v_med300_rate := NULL;
						v_med400_rate := NULL;
						v_med500_rate := NULL;
						v_mean3sd_rate := NULL;
						v_mean5sd_rate := NULL;
						v_mean7sd_rate := NULL;
						v_mean8sd_rate := NULL;
						v_mean10sd_rate := NULL;
						v_mean12sd_rate := NULL;
						v_mean15sd_rate := NULL;
						v_sd_rate := NULL;
						v_sd_trim_orig_rate := NULL;
						v_sd_trim_rate := NULL;
				END;
			ELSE -- An AI group is found for this record.
				BEGIN
					SELECT	num_recs, med50, med100,
								med150, med200, med250,
								med300, med400, med500,
								mean3sd, mean5sd, mean7sd,
								mean8sd, mean10sd,
								mean12sd, mean15sd,
								sd_rate, sd_rate_trim_orig, sd_rate_trim
					INTO		v_num_recs_rate, v_med50_rate, v_med100_rate,
								v_med150_rate, v_med200_rate, v_med250_rate,
								v_med300_rate, v_med400_rate, v_med500_rate,
								v_mean3sd_rate, v_mean5sd_rate, v_mean7sd_rate,
								v_mean8sd_rate, v_mean10sd_rate,
								v_mean12sd_rate, v_mean15sd_rate,
								v_sd_rate, v_sd_trim_orig_rate, v_sd_trim_rate
					FROM		ai_outlier_stats
					WHERE		year = &&1 AND
								chem_code = pur_rec.chem_code AND
								ai_group = v_ai_group_rate AND
								ago_ind = pur_rec.ago_ind AND
								unit_treated = pur_rec.unit_treated;
				EXCEPTION
					WHEN OTHERS THEN
						v_num_recs_rate := NULL;
						v_med50_rate := NULL;
						v_med100_rate := NULL;
						v_med150_rate := NULL;
						v_med200_rate := NULL;
						v_med250_rate := NULL;
						v_med300_rate := NULL;
						v_med400_rate := NULL;
						v_med500_rate := NULL;
						v_mean3sd_rate := NULL;
						v_mean5sd_rate := NULL;
						v_mean7sd_rate := NULL;
						v_mean8sd_rate := NULL;
						v_mean10sd_rate := NULL;
						v_mean12sd_rate := NULL;
						v_mean15sd_rate := NULL;
						v_sd_rate := NULL;
						v_sd_trim_orig_rate := NULL;
						v_sd_trim_rate := NULL;
				END;

			END IF;

			/* If the reported rate of use is greater than an outlier limit or maximum label rate, flag it.
			 */
			IF v_log_ai_rate > v_fixed1_rate THEN
				v_fixed1_rate_outlier := 'X';
				v_found_outlier := TRUE;
			END IF;

			IF v_log_ai_rate > v_fixed2_rate THEN
				v_fixed2_rate_outlier := 'X';
				v_found_outlier := TRUE;
			END IF;

			IF v_log_ai_rate > v_fixed3_rate THEN
				v_fixed3_rate_outlier := 'X';
				v_found_outlier := TRUE;
			END IF;

			IF v_num_recs_rate > v_num_recs_min  THEN
				IF v_log_ai_rate > v_med50_rate THEN
					v_med50_rate_outlier := 'X';
					v_found_outlier := TRUE;
				END IF;

				IF v_log_ai_rate > v_med100_rate THEN
					v_med100_rate_outlier := 'X';
					v_found_outlier := TRUE;
				END IF;

				IF v_log_ai_rate > v_med150_rate THEN
					v_med150_rate_outlier := 'X';
				END IF;

				IF v_log_ai_rate > v_med200_rate THEN
					v_med200_rate_outlier := 'X';
				END IF;

				IF v_log_ai_rate > v_med250_rate THEN
					v_med250_rate_outlier := 'X';
				END IF;

				IF v_log_ai_rate > v_med300_rate THEN
					v_med300_rate_outlier := 'X';
				END IF;

				IF v_log_ai_rate > v_med400_rate THEN
					v_med400_rate_outlier := 'X';
				END IF;

				IF v_log_ai_rate > v_med500_rate THEN
					v_med500_rate_outlier := 'X';
				END IF;

				IF v_log_ai_rate > v_mean3sd_rate THEN
					v_mean3sd_rate_outlier := 'X';
					v_found_outlier := TRUE;
				END IF;

				IF v_log_ai_rate > v_mean5sd_rate THEN
					v_mean5sd_rate_outlier := 'X';
					v_found_outlier := TRUE;
				END IF;

				IF v_log_ai_rate > v_mean7sd_rate THEN
					v_mean7sd_rate_outlier := 'X';
					v_found_outlier := TRUE;
				END IF;

				IF v_log_ai_rate > v_mean8sd_rate THEN
					v_mean8sd_rate_outlier := 'X';
					v_found_outlier := TRUE;
				END IF;

				IF v_log_ai_rate > v_mean10sd_rate THEN
					v_mean10sd_rate_outlier := 'X';
					v_found_outlier := TRUE;
				END IF;

				IF v_log_ai_rate > v_mean12sd_rate THEN
					v_mean12sd_rate_outlier := 'X';
					v_found_outlier := TRUE;
				END IF;

				IF v_log_ai_rate > v_mean15sd_rate THEN
					v_mean15sd_rate_outlier := 'X';
					v_found_outlier := TRUE;
				END IF;

			END IF;

         IF v_fixed2_rate_outlier = 'X' THEN
            IF pur_rec.ago_ind = 'A' AND
               pur_rec.unit_treated = 'A'
            THEN
                IF (v_ai_rate_type = 'NORMAL' AND
                    v_mean8sd_rate_outlier = 'X') OR
                   (v_ai_rate_type IN ('MEDIUM', 'HIGH', 'ADJUVANT') AND
                    v_mean5sd_rate_outlier = 'X') 
                THEN
                     v_recommend_outlier := 'X';
                END IF;
            ELSIF pur_rec.ago_ind = 'A' AND
                  pur_rec.unit_treated IN ('C', 'P', 'U')  AND
                  v_mean10sd_rate_outlier = 'X'
            THEN
                  v_recommend_outlier := 'X';
            ELSIF pur_rec.ago_ind = 'N' AND
                  pur_rec.unit_treated = 'A' AND
                  ((v_site_type = 'OTHER' AND
                    v_mean5sd_rate_outlier = 'X') OR
                   (v_site_type = 'WATER' AND
                    v_mean7sd_rate_outlier = 'X'))
            THEN
                  v_recommend_outlier := 'X';
            ELSIF pur_rec.ago_ind = 'N' AND
                  v_mean10sd_rate_outlier = 'X'
            THEN
                  v_recommend_outlier := 'X';
            END IF;
         END IF;

			/* Get the maximum label rate for products that are in table MAX_LABEL_RATES.
				Variable max_label in MAX_LABEL_RATES is the product rate of use.
			 */
			BEGIN
				SELECT   max_rate
				INTO     v_max_label_prod
				FROM     max_label_rates
				WHERE    prodno = pur_rec.prodno AND
							unit_treated = pur_rec.unit_treated;
			EXCEPTION
				WHEN OTHERS THEN
					v_max_label_prod := NULL;
			END;

			/* Set maximum rate 10% higher than actual maximum label rate.
			 */
			v_max_label := v_max_label_prod * 1.1;

			/* If the reported rate of use is greater than the maximum label rate, flag it.
			 */
			IF v_prod_rate > v_max_label THEN
				v_label_rate_outlier := 'X';
				v_found_outlier := TRUE;
			END IF;


         
			/******************************************************************************************/
			/* Get the outlier criteria from the old program.
				This will not be used in the production system, only for
				analyses.

			IF pur_rec.unit_treated = 'A' THEN
				IF pur_rec.chem_code IN (136, 233, 385, 573, 616, 970) THEN
					v_old_fixed_rate := 3;
				ELSE
					v_old_fixed_rate := 2.3;
				END IF;
			ELSE
				v_old_fixed_rate := NULL;
			END IF;

			IF v_log_ai_rate > v_old_fixed_rate THEN
				v_old_fixed_rate_outlier := 'X';
				v_found_outlier := TRUE;
			END IF;

			BEGIN
				SELECT   log(10, prd_u_50m)
				INTO     v_old_med50_rate
				FROM     usetypestats
				WHERE    year = (&&1 - 1) AND
							prodno = pur_rec.prodno AND
							site_code = pur_rec.site_code AND
							unit_treated = pur_rec.unit_treated AND
							record_id_type =
								TRANSLATE(pur_rec.record_id, 'C2G9DHAB14EF', 'NNNNNNAAAAAA');
			EXCEPTION
				WHEN OTHERS THEN
					v_old_med50_rate := NULL;
			END;

			v_log_prod_rate := log(10, v_prod_rate);
			IF v_log_prod_rate > v_old_med50_rate THEN
				v_old_med50_rate_outlier := 'X';
				v_found_outlier := TRUE;
			END IF;
			*/
		END IF;

		/*********************************************************************************
		 * Get outliers in pounds of AI per application ("nonag" records)
		 ********************************************************************************/
		IF pur_rec.record_id IN ('2', 'C') AND 
         pur_rec.unit_treated IS NULL 
      THEN
			IF pur_rec.applic_cnt > 1 THEN
				v_lbs_ai_per_app := pur_rec.lbs_ai/pur_rec.applic_cnt;
			ELSE
				v_lbs_ai_per_app := pur_rec.lbs_ai;
			END IF;

			v_log_lbs_ai_per_app := log(10, v_lbs_ai_per_app);

         IF pur_rec.site_general = 'STRUCTURAL PEST CONTROL' THEN 
            v_site_type := 'STRUCTURAL';
         ELSIF pur_rec.site_general = 'LANDSCAPE MAINTENANCE' THEN
            v_site_type := 'LANDSCAPE';
         ELSIF pur_rec.site_code = 40 THEN
            v_site_type := 'RIGHTS_OF_WAY';
         ELSE
            v_site_type := 'OTHER';
         END IF;

         IF pur_rec.ai_adjuvant = 'Y' THEN
            v_lbs_ai_app_type := 'ADJUVANT';
         ELSE
            BEGIN
               SELECT   lbs_ai_app_type
               INTO     v_lbs_ai_app_type
               FROM     fixed_outlier_lbs_app_ais
               WHERE    chem_code = pur_rec.chem_code AND
                        site_type = v_site_type;
            EXCEPTION
               WHEN OTHERS THEN
                  v_lbs_ai_app_type := NULL;
            END;
         END IF;

			/* If the reported lbs_ai_app of use is greater than the fixed outlier limit, flag it.
			 */
			BEGIN
				SELECT	log_lbs_ai_app1, log_lbs_ai_app2, log_lbs_ai_app3
				INTO		v_fixed1_lbsapp, v_fixed2_lbsapp, v_fixed3_lbsapp
				FROM		fixed_outlier_lbs_app
				WHERE		site_type = v_site_type AND
							lbs_ai_app_type = v_lbs_ai_app_type;
			EXCEPTION
				WHEN OTHERS THEN
					v_fixed1_lbsapp := NULL;
					v_fixed2_lbsapp := NULL;
					v_fixed3_lbsapp := NULL;
			END;

			/* Get other outlier limits - first need the AI group number for this AI, product, site.
			 */
			BEGIN
				SELECT	ai_group
				INTO		v_ai_group_lbsapp
				FROM		ai_group_nonag_stats
				WHERE		year = &&1 AND
							chem_code = pur_rec.chem_code AND
							regno_short = pur_rec.regno_short AND
							site_general = pur_rec.site_general;
				/*
				SELECT	ai_group
				INTO		v_ai_group_lbsapp
				FROM		ai_group_nonag_stats_byhand
				WHERE		year = &&1 AND
							chem_code = pur_rec.chem_code AND
							regno_short = pur_rec.regno_short AND
							site_general = pur_rec.site_general;
				*/
			EXCEPTION
				WHEN OTHERS THEN
					v_ai_group_lbsapp := NULL;
			END;

			/* Get the outlier statistics for this application from table ai_outlier_nonag_stats.
			 */
			IF v_ai_group_lbsapp IS NULL THEN
				/* If no statistics found for this AI, product, and site,
					then use maximum outlier limits for this AI.
					If no statistics found for this AI, just use fixed limits.
				 */
				BEGIN
					SELECT	SUM(num_recs), MAX(med50), MAX(med100),
								MAX(med150), MAX(med200), MAX(med250),
								MAX(med300), MAX(med400), MAX(med500),
								MAX(med1000), MAX(med5000), MAX(med10000),
								MAX(med50000), MAX(med100000),
								MAX(mean3sd), MAX(mean5sd), MAX(mean7sd),
								MAX(mean8sd), MAX(mean10sd),
								MAX(mean12sd), MAX(mean15sd),
								MAX(sd_rate), MAX(sd_rate_trim_orig), MAX(sd_rate_trim)
					INTO		v_num_recs_lbsapp, v_med50_lbsapp, v_med100_lbsapp,
								v_med150_lbsapp, v_med200_lbsapp, v_med250_lbsapp,
								v_med300_lbsapp, v_med400_lbsapp, v_med500_lbsapp,
								v_med1000_lbsapp, v_med5000_lbsapp, v_med10000_lbsapp,
								v_med50000_lbsapp, v_med100000_lbsapp,
								v_mean3sd_lbsapp, v_mean5sd_lbsapp, v_mean7sd_lbsapp,
								v_mean8sd_lbsapp, v_mean10sd_lbsapp,
								v_mean12sd_lbsapp, v_mean15sd_lbsapp,
								v_sd_lbsapp, v_sd_trim_orig_lbsapp, v_sd_trim_lbsapp
					FROM		ai_outlier_nonag_stats
					WHERE		year = &&1 AND
								chem_code = pur_rec.chem_code;
				EXCEPTION
					WHEN OTHERS THEN
						v_num_recs_lbsapp := NULL;
						v_med50_lbsapp := NULL;
						v_med100_lbsapp := NULL;
						v_med150_lbsapp     := NULL;
						v_med200_lbsapp 	 := NULL;
						v_med250_lbsapp 	 := NULL;
						v_med300_lbsapp 	 := NULL;
						v_med400_lbsapp 	 := NULL;
						v_med500_lbsapp 	 := NULL;
						v_med1000_lbsapp    := NULL;
						v_med5000_lbsapp    := NULL;
						v_med10000_lbsapp   := NULL;
						v_med50000_lbsapp   := NULL;
						v_med100000_lbsapp   := NULL;
						v_mean3sd_lbsapp	 := NULL;
						v_mean5sd_lbsapp	 := NULL;
						v_mean7sd_lbsapp := NULL;
						v_mean8sd_lbsapp := NULL;
						v_mean10sd_lbsapp := NULL;
						v_mean12sd_lbsapp := NULL;
						v_mean15sd_lbsapp := NULL;
						v_sd_lbsapp := NULL;
						v_sd_trim_orig_lbsapp := NULL;
						v_sd_trim_lbsapp := NULL;
				END;
			ELSE -- An AI group is found for this record.
				BEGIN
					SELECT	num_recs, med50, med100,
								med150, med200, med250,
								med300, med400, med500,
								med1000, med5000, med10000,
								med50000, med100000,
								mean3sd, mean5sd, mean7sd,
								mean8sd, mean10sd,
								mean12sd, mean15sd,
								sd_rate, sd_rate_trim_orig, sd_rate_trim
					INTO		v_num_recs_lbsapp, v_med50_lbsapp, v_med100_lbsapp,
								v_med150_lbsapp, v_med200_lbsapp, v_med250_lbsapp,
								v_med300_lbsapp, v_med400_lbsapp, v_med500_lbsapp,
								v_med1000_lbsapp, v_med5000_lbsapp, v_med10000_lbsapp,
								v_med50000_lbsapp, v_med100000_lbsapp,
								v_mean3sd_lbsapp, v_mean5sd_lbsapp, v_mean7sd_lbsapp,
								v_mean8sd_lbsapp, v_mean10sd_lbsapp,
								v_mean12sd_lbsapp, v_mean15sd_lbsapp,
								v_sd_lbsapp, v_sd_trim_orig_lbsapp, v_sd_trim_lbsapp
					FROM		ai_outlier_nonag_stats
					WHERE		year = &&1 AND
								chem_code = pur_rec.chem_code AND
								ai_group = v_ai_group_lbsapp;
				EXCEPTION
					WHEN OTHERS THEN
						v_num_recs_lbsapp := NULL;
						v_med50_lbsapp := NULL;
						v_med100_lbsapp := NULL;
						v_med150_lbsapp := NULL;
						v_med200_lbsapp := NULL;
						v_med250_lbsapp := NULL;
						v_med300_lbsapp := NULL;
						v_med400_lbsapp := NULL;
						v_med500_lbsapp := NULL;
						v_med1000_lbsapp := NULL;
						v_med5000_lbsapp := NULL;
						v_med10000_lbsapp := NULL;
						v_med50000_lbsapp := NULL;
						v_med100000_lbsapp := NULL;
						v_mean3sd_lbsapp := NULL;
						v_mean5sd_lbsapp := NULL;
						v_mean7sd_lbsapp := NULL;
						v_mean8sd_lbsapp := NULL;
						v_mean10sd_lbsapp := NULL;
						v_mean12sd_lbsapp := NULL;
						v_mean15sd_lbsapp := NULL;
						v_sd_lbsapp := NULL;
						v_sd_trim_orig_lbsapp := NULL;
						v_sd_trim_lbsapp := NULL;
				END;

			END IF;

			/* If the reported rate of use is greater than an outlier limit, flag it.
			 */
			IF v_log_lbs_ai_per_app > v_fixed1_lbsapp THEN
				v_fixed1_lbsapp_outlier := 'X';
				v_found_outlier := TRUE;
			END IF;

			IF v_log_lbs_ai_per_app > v_fixed2_lbsapp THEN
				v_fixed2_lbsapp_outlier := 'X';
				v_found_outlier := TRUE;
			END IF;

			IF v_log_lbs_ai_per_app > v_fixed3_lbsapp THEN
				v_fixed3_lbsapp_outlier := 'X';
				v_found_outlier := TRUE;
			END IF;

			IF v_num_recs_lbsapp > v_num_recs_min THEN
				IF v_log_lbs_ai_per_app > v_med50_lbsapp THEN
					v_med50_lbsapp_outlier := 'X';
					v_found_outlier := TRUE;
				END IF;

				IF v_log_lbs_ai_per_app > v_med100_lbsapp THEN
					v_med100_lbsapp_outlier := 'X';
					v_found_outlier := TRUE;
				END IF;

				IF v_log_lbs_ai_per_app > v_med150_lbsapp THEN
					v_med150_lbsapp_outlier := 'X';
					v_found_outlier := TRUE;
				END IF;

				IF v_log_lbs_ai_per_app > v_med200_lbsapp THEN
					v_med200_lbsapp_outlier := 'X';
					v_found_outlier := TRUE;
				END IF;

				IF v_log_lbs_ai_per_app > v_med250_lbsapp THEN
					v_med250_lbsapp_outlier := 'X';
					v_found_outlier := TRUE;
				END IF;

				IF v_log_lbs_ai_per_app > v_med300_lbsapp THEN
					v_med300_lbsapp_outlier := 'X';
					v_found_outlier := TRUE;
				END IF;

				IF v_log_lbs_ai_per_app > v_med400_lbsapp THEN
					v_med400_lbsapp_outlier := 'X';
					v_found_outlier := TRUE;
				END IF;

				IF v_log_lbs_ai_per_app > v_med500_lbsapp THEN
					v_med500_lbsapp_outlier := 'X';
					v_found_outlier := TRUE;
				END IF;

				IF v_log_lbs_ai_per_app > v_med1000_lbsapp THEN
					v_med1000_lbsapp_outlier := 'X';
					v_found_outlier := TRUE;
				END IF;

				IF v_log_lbs_ai_per_app > v_med5000_lbsapp THEN
					v_med5000_lbsapp_outlier := 'X';
					v_found_outlier := TRUE;
				END IF;

				IF v_log_lbs_ai_per_app > v_med10000_lbsapp THEN
					v_med10000_lbsapp_outlier := 'X';
					v_found_outlier := TRUE;
				END IF;

				IF v_log_lbs_ai_per_app > v_med50000_lbsapp THEN
					v_med50000_lbsapp_outlier := 'X';
					v_found_outlier := TRUE;
				END IF;

				IF v_log_lbs_ai_per_app > v_med100000_lbsapp THEN
					v_med100000_lbsapp_outlier := 'X';
					v_found_outlier := TRUE;
				END IF;

				IF v_log_lbs_ai_per_app > v_mean3sd_lbsapp THEN
					v_mean3sd_lbsapp_outlier := 'X';
					v_found_outlier := TRUE;
				END IF;

				IF v_log_lbs_ai_per_app > v_mean5sd_lbsapp THEN
					v_mean5sd_lbsapp_outlier := 'X';
					v_found_outlier := TRUE;
				END IF;

				IF v_log_lbs_ai_per_app > v_mean7sd_lbsapp THEN
					v_mean7sd_lbsapp_outlier := 'X';
					v_found_outlier := TRUE;
				END IF;

				IF v_log_lbs_ai_per_app > v_mean8sd_lbsapp THEN
					v_mean8sd_lbsapp_outlier := 'X';
					v_found_outlier := TRUE;
				END IF;

				IF v_log_lbs_ai_per_app > v_mean10sd_lbsapp THEN
					v_mean10sd_lbsapp_outlier := 'X';
					v_found_outlier := TRUE;
				END IF;

				IF v_log_lbs_ai_per_app > v_mean12sd_lbsapp THEN
					v_mean12sd_lbsapp_outlier := 'X';
					v_found_outlier := TRUE;
				END IF;

				IF v_log_lbs_ai_per_app > v_mean15sd_lbsapp THEN
					v_mean15sd_lbsapp_outlier := 'X';
					v_found_outlier := TRUE;
				END IF;
			END IF;

         IF v_fixed2_rate_outlier = 'X' THEN
            IF v_site_type = 'STRUCTURAL' THEN
               IF (v_lbs_ai_app_type = 'NORMAL' AND
                   v_mean7sd_lbsapp_outlier = 'X') OR
                  (v_lbs_ai_app_type = 'MEDIUM' AND
                   v_mean5sd_lbsapp_outlier = 'X') OR 
                  (v_lbs_ai_app_type = 'HIGH' AND
                   v_mean10sd_lbsapp_outlier = 'X') OR 
                  (v_lbs_ai_app_type = 'ADJUANT' AND
                   v_mean8sd_lbsapp_outlier = 'X') 
               THEN
                  v_recommend_outlier := 'X';
               END IF;
            ELSIF v_site_type = 'LANDSCAPE' AND 
               v_mean5sd_lbsapp_outlier = 'X'
            THEN
               v_recommend_outlier := 'X';
            ELSIF v_site_type = 'RIGHTS_OF_WAy' THEN
               IF (v_lbs_ai_app_type = 'NORMAL' AND
                   v_mean5sd_lbsapp_outlier = 'X') OR
                  (v_lbs_ai_app_type IN ('MEDIUM', 'HIGH', 'ADJUVANT') AND
                   v_mean5sd_lbsapp_outlier = 'X') 
               THEN
                  v_recommend_outlier := 'X';
               END IF;                  
            ELSIF v_site_type = 'OTHER' THEN
               IF (v_lbs_ai_app_type = 'NORMAL' AND
                   v_mean8sd_lbsapp_outlier = 'X') OR
                  (v_lbs_ai_app_type = 'MEDIUM' AND
                   v_mean5sd_lbsapp_outlier = 'X') OR 
                  (v_lbs_ai_app_type = 'HIGH' AND
                   v_mean12sd_lbsapp_outlier = 'X') OR 
                  (v_lbs_ai_app_type = 'ADJUANT' AND
                   v_mean5sd_lbsapp_outlier = 'X') 
               THEN
                    v_recommend_outlier := 'X';
               END IF;
            END IF;
         END IF;
		END IF;

		IF v_found_outlier THEN
			INSERT INTO pur_outlier_&&1
						(year, use_no, record_id, chem_code, ai_rate_type, site_type,
						 lbs_ai_app_type, regno_short, site_general,
						 ago_ind, unit_treated, ai_group_rate, ai_group_lbsapp, prod_adjuvant, ai_adjuvant,
						 prodno, site_code, county_cd, app_month,
						 grower_id, site_loc_id, license_no, amt_prd_used, unit_of_meas,
						 lbs_prd_used, lbs_ai, acre_treated, unit_treated_report, applic_cnt,
						 prod_rate, ai_rate, lbs_ai_per_app,
						 log_prod_rate, log_ai_rate, log_lbs_ai_per_app,
						 num_recs_rate, sd_rate, sd_trim_orig_rate, sd_trim_rate,
						 fixed1_rate, fixed2_rate, fixed3_rate,
						 med50_rate, med100_rate, med150_rate, med200_rate,
						 med250_rate, med300_rate, med400_rate, med500_rate,
						 mean3sd_rate, mean5sd_rate, mean7sd_rate, mean8sd_rate,
						 mean10sd_rate,mean12sd_rate, mean15sd_rate,
						 max_label, old_fixed_rate, old_med50_rate,
						 fixed1_rate_outlier, fixed2_rate_outlier, fixed3_rate_outlier,
						 med50_rate_outlier, med100_rate_outlier, med150_rate_outlier, med200_rate_outlier,
						 med250_rate_outlier, med300_rate_outlier, med400_rate_outlier, med500_rate_outlier,
						 mean3sd_rate_outlier, mean5sd_rate_outlier, mean7sd_rate_outlier, mean8sd_rate_outlier,
						 mean10sd_rate_outlier, mean12sd_rate_outlier, mean15sd_rate_outlier,
						 label_rate_outlier, old_fixed_rate_outlier, old_med50_rate_outlier,
						 num_recs_lbsapp, sd_lbsapp, sd_trim_orig_lbsapp, sd_trim_lbsapp,
						 fixed1_lbsapp, fixed2_lbsapp, fixed3_lbsapp,
						 med50_lbsapp, med100_lbsapp, med150_lbsapp, med200_lbsapp,
						 med250_lbsapp, med300_lbsapp, med400_lbsapp, med500_lbsapp,
						 med1000_lbsapp, med5000_lbsapp, med10000_lbsapp, med50000_lbsapp, med100000_lbsapp,
						 mean3sd_lbsapp, mean5sd_lbsapp, mean7sd_lbsapp, mean8sd_lbsapp,
						 mean10sd_lbsapp, mean12sd_lbsapp, mean15sd_lbsapp,
						 fixed1_lbsapp_outlier, fixed2_lbsapp_outlier, fixed3_lbsapp_outlier,
						 med50_lbsapp_outlier, med100_lbsapp_outlier, med150_lbsapp_outlier, med200_lbsapp_outlier,
						 med250_lbsapp_outlier, med300_lbsapp_outlier, med400_lbsapp_outlier, med500_lbsapp_outlier,
						 med1000_lbsapp_outlier, med5000_lbsapp_outlier, med10000_lbsapp_outlier,
						 med50000_lbsapp_outlier, med100000_lbsapp_outlier,
						 mean3sd_lbsapp_outlier, mean5sd_lbsapp_outlier, mean7sd_lbsapp_outlier, mean8sd_lbsapp_outlier,
						 mean10sd_lbsapp_outlier, mean12sd_lbsapp_outlier, mean15sd_lbsapp_outlier, recommend_outlier)
				VALUES(pur_rec.year, pur_rec.use_no, pur_rec.record_id, pur_rec.chem_code, v_ai_rate_type, v_site_type,
						 v_lbs_ai_app_type, pur_rec.regno_short, pur_rec.site_general,
						 pur_rec.ago_ind, pur_rec.unit_treated, v_ai_group_rate, v_ai_group_lbsapp,
						 pur_rec.prod_adjuvant, pur_rec.ai_adjuvant,
						 pur_rec.prodno, pur_rec.site_code, pur_rec.county_cd, pur_rec.app_month,
						 pur_rec.grower_id, pur_rec.site_loc_id, pur_rec.license_no, pur_rec.amt_prd_used, pur_rec.unit_of_meas,
						 pur_rec.lbs_prd_used, pur_rec.lbs_ai, pur_rec.acre_treated, pur_rec.unit_treated_report, pur_rec.applic_cnt,
						 v_prod_rate, v_ai_rate, v_lbs_ai_per_app,
						 v_log_prod_rate, v_log_ai_rate, v_log_lbs_ai_per_app,
						 v_num_recs_rate, v_sd_rate, v_sd_trim_orig_rate, v_sd_trim_rate,
						 v_fixed1_rate, v_fixed2_rate, v_fixed3_rate,
						 v_med50_rate, v_med100_rate, v_med150_rate, v_med200_rate,
						 v_med250_rate, v_med300_rate, v_med400_rate, v_med500_rate,
						 v_mean3sd_rate, v_mean5sd_rate, v_mean7sd_rate, v_mean8sd_rate,
						 v_mean10sd_rate,v_mean12sd_rate, v_mean15sd_rate,
						 v_max_label, v_old_fixed_rate, v_old_med50_rate,
						 v_fixed1_rate_outlier, v_fixed2_rate_outlier, v_fixed3_rate_outlier,
						 v_med50_rate_outlier, v_med100_rate_outlier, v_med150_rate_outlier, v_med200_rate_outlier,
						 v_med250_rate_outlier, v_med300_rate_outlier, v_med400_rate_outlier, v_med500_rate_outlier,
						 v_mean3sd_rate_outlier, v_mean5sd_rate_outlier, v_mean7sd_rate_outlier, v_mean8sd_rate_outlier,
						 v_mean10sd_rate_outlier, v_mean12sd_rate_outlier, v_mean15sd_rate_outlier,
						 v_label_rate_outlier, v_old_fixed_rate_outlier, v_old_med50_rate_outlier,
						 v_num_recs_lbsapp, v_sd_lbsapp, v_sd_trim_orig_lbsapp, v_sd_trim_lbsapp,
						 v_fixed1_lbsapp, v_fixed2_lbsapp, v_fixed3_lbsapp,
						 v_med50_lbsapp, v_med100_lbsapp, v_med150_lbsapp, v_med200_lbsapp,
						 v_med250_lbsapp, v_med300_lbsapp, v_med400_lbsapp, v_med500_lbsapp,
						 v_med1000_lbsapp, v_med5000_lbsapp, v_med10000_lbsapp, v_med50000_lbsapp, v_med100000_lbsapp,
						 v_mean3sd_lbsapp, v_mean5sd_lbsapp, v_mean7sd_lbsapp, v_mean8sd_lbsapp,
						 v_mean10sd_lbsapp, v_mean12sd_lbsapp, v_mean15sd_lbsapp,
						 v_fixed1_lbsapp_outlier, v_fixed2_lbsapp_outlier, v_fixed3_lbsapp_outlier,
						 v_med50_lbsapp_outlier, v_med100_lbsapp_outlier, v_med150_lbsapp_outlier, v_med200_lbsapp_outlier,
						 v_med250_lbsapp_outlier, v_med300_lbsapp_outlier, v_med400_lbsapp_outlier, v_med500_lbsapp_outlier,
						 v_med1000_lbsapp_outlier, v_med5000_lbsapp_outlier, v_med10000_lbsapp_outlier,
						 v_med50000_lbsapp_outlier, v_med100000_lbsapp_outlier,
						 v_mean3sd_lbsapp_outlier, v_mean5sd_lbsapp_outlier, v_mean7sd_lbsapp_outlier, v_mean8sd_lbsapp_outlier,
						 v_mean10sd_lbsapp_outlier, v_mean12sd_lbsapp_outlier, v_mean15sd_lbsapp_outlier, v_recommend_outlier);

			IF v_index > 1000 THEN
				COMMIT;
				v_index := 0;
			END IF;
			v_index := v_index + 1;
		END IF;

	END LOOP;
	COMMIT;

EXCEPTION
	WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(SQLERRM||'; use_no = '||v_use_no);
END;
/
show errors

EXIT 0



