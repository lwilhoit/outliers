/* This code should replace the call to Check_value_new.Outliers() in
	file co_error.sql in the PUR loader program, which loads
	data from from the counties through CalAgPermits and checks
	the data for errors.

	This code checks for outliers	in rates of use in pounds of AI
	per unit treated and	rates in pounds of AI per application.

	It uses 4 tables, AI_GROUP_STATS, AI_OUTLIER_STATS, AI_GROUP_NONAG_STATS,
	AI_OUTLIER_NONAG_STATS which have statistics on outlier limits
	for different properties of a pesticide application, such as AI, product,
	site treated, record type (ago_ind), unit treated.

	These four tables are created in create_ai_groups_ai_outlier_stats.sql,
	outlier_stats.py, create_ai_groups_ai_outlier_stats_nonag.sql, and
	outlier_stats_nonag.py

	Another outlier limit comes from the maximum rate of use on the pesticide label.
	Currently, we have maximum label rates for only a few products. These
	data are in table MAX_LABEL_RATES.

	Previous table OUTLIER will be replaced with outliers_new.

	For situations (AI, ago_ind, unit_treated) where the total number of PUR records
	in previous years was <= 4, use only the fixed outlier limit.  I consider
	that 4 or fewer records are too few to use as a basis for determining typical uses.
	This value is set with the parameter v_num_recs_min.

	PMAP will recreate these 4 outlier statstics table every year with updated statistics.

*/
CREATE OR REPLACE PACKAGE Co_error_new AS
   v_loader_name     VARCHAR2(20) := 'LOADER 5';

   PROCEDURE Check_records(p_year IN NUMBER);

   PROCEDURE Log_error
      (p_year IN NUMBER,
		 p_use_no IN NUMBER,
		 p_error_code IN INTEGER,
		 p_error_type IN VARCHAR2,
       p_who IN VARCHAR2,
		 p_comments IN VARCHAR2,
		 p_error_id OUT INTEGER);

   PROCEDURE Log_change
      (p_year IN NUMBER,
		 p_use_no IN NUMBER,
		 p_field_name IN VARCHAR2,
		 p_old_value IN VARCHAR2,
		 p_new_value IN VARCHAR2,
		 p_replace_type IN VARCHAR2,
       p_who IN VARCHAR2,
		 p_comments IN VARCHAR2,
		 p_error_id IN INTEGER);

END Co_error_new;
/
show errors

--CREATE OR REPLACE PACKAGE BODY OPS$PURLOAD."CO_ERROR" AS
CREATE OR REPLACE PACKAGE BODY Co_error_new AS

   PROCEDURE Check_records(p_year IN NUMBER)
   AS
      v_use_no               NUMBER(8);

      v_record_id            VARCHAR2(1);
      v_batch_no             NUMBER(4);
      v_process_mt           NUMBER(2);
      v_process_yr           NUMBER(4);
      v_county_cd            VARCHAR2(2);
      v_site_code            NUMBER(6);
      v_applic_month         NUMBER(2);
      v_applic_day           NUMBER(2);
      v_applic_year          NUMBER(4);
      v_applic_dt            DATE;
      v_document_no          NUMBER(8);
      v_summary_cd           NUMBER(4);
      v_site_loc_id          VARCHAR2(8);
      v_cedts_ind            VARCHAR2(1);
      v_qualify_cd           NUMBER(2);
      v_planting_seq         NUMBER(1);

      v_section              VARCHAR2(2);
      v_township             VARCHAR2(2);
      v_tship_dir            VARCHAR2(1);
      v_range                VARCHAR2(2);
      v_range_dir            VARCHAR2(1);
      v_base_ln_mer          VARCHAR2(1);
      v_ca_mtrs_acres        NUMBER(10,2);
      v_aer_gnd_ind          VARCHAR2(1);
      v_applic_time          VARCHAR2(4);
      v_grower_id            VARCHAR2(11);
      v_license_no           VARCHAR2(13);

      v_mfg_firmno           NUMBER(7);
      v_label_seq_no         NUMBER(5);
      v_revision_no          VARCHAR2(2);
      v_reg_firmno           NUMBER(7);
      v_new_revision_no      VARCHAR2(2);
      v_new_reg_firmno       NUMBER(7);
      v_other_product        VARCHAR2(500);
      v_reported_product     VARCHAR2(500);
      v_estimated_product    VARCHAR2(500);
      v_amt_prd_used         NUMBER(12,4);
      v_amt_prd_used_old     NUMBER(12,4);
      v_unit_of_meas         VARCHAR2(2);
      v_spec_gravity         NUMBER(6,4);
      v_formula_cd           VARCHAR2(2);
      v_prodno               NUMBER(6);
      v_lbs_prd_used         NUMBER(14,4);
      v_lbs_prd_used_old     NUMBER(14,4);
      v_acre_treated         NUMBER(10,2);
      v_acre_treated_old     NUMBER(10,2);
      v_unit_treated         VARCHAR2(1);
      v_unit_treated_old     VARCHAR2(1);
      v_acre_planted         NUMBER(10,2);
      v_acre_planted_old     NUMBER(10,2);
      v_unit_planted         VARCHAR2(1);
      v_unit_planted_old     VARCHAR2(1);
      v_units_incompatible   BOOLEAN;

      v_applic_cnt           NUMBER(6);


      v_reg_num_parts        INTEGER;
      v_one_reg_no           BOOLEAN;
      v_valid_site           BOOLEAN;
      v_valid_site_other     BOOLEAN;
      v_valid_spec_gravity   BOOLEAN;
      v_valid_reg_date       BOOLEAN;
      v_item                 INTEGER;

      v_comments             VARCHAR2(2000);
      v_estimated_field      VARCHAR2(20);
      v_estimated_date       DATE;
      v_error_code           INTEGER := 0;
      v_error_type           VARCHAR2(20);
      v_replace_type         VARCHAR2(20);
      v_error_id             INTEGER;

      v_get_sequence_stmt    VARCHAR2(2000);

      v_outlier_exits        INTEGER;
      v_fume_code            INTEGER; /* 002 */

		v_fixed1_rate_outlier		VARCHAR2(1);
		v_fixed2_rate_outlier		VARCHAR2(1);
		v_fixed3_rate_outlier		VARCHAR2(1);
		v_mean5sd_rate_outlier		VARCHAR2(1);
		v_mean7sd_rate_outlier		VARCHAR2(1);
		v_mean8sd_rate_outlier		VARCHAR2(1);
		v_mean10sd_rate_outlier		VARCHAR2(1);
		v_mean12sd_rate_outlier		VARCHAR2(1);
      v_max_label_outlier        VARCHAR2(1);
      v_limit_rate_outlier       VARCHAR2(1);

		v_fixed1_lbsapp_outlier		VARCHAR2(1);
		v_fixed2_lbsapp_outlier		VARCHAR2(1);
		v_fixed3_lbsapp_outlier		VARCHAR2(1);
		v_mean3sd_lbsapp_outlier	VARCHAR2(1);
		v_mean5sd_lbsapp_outlier	VARCHAR2(1);
		v_mean7sd_lbsapp_outlier	VARCHAR2(1);
		v_mean8sd_lbsapp_outlier	VARCHAR2(1);
		v_mean10sd_lbsapp_outlier	VARCHAR2(1);
		v_mean12sd_lbsapp_outlier	VARCHAR2(1);
      v_limit_lbsapp_outlier     VARCHAR2(1);

      /*
      CURSOR record_cur IS
      SELECT    *
      FROM         raw_i
      FOR UPDATE OF year, use_no
      NOWAIT;
      */

      /* ***********************
       For batch PUR processing use:
      */
      CURSOR record_cur IS
         SELECT    *
         FROM     ai_raw_rates
         WHERE    year = 2016 AND
                  use_no > 3000000;

      /*
      CURSOR record_cur IS
         SELECT    *
         FROM     ai_raw_rates
         WHERE    year = 2016 AND
                  use_no < 1000000;

      CURSOR record_cur IS
         SELECT    *
         FROM     ai_raw_rates
         WHERE    year = 2016 AND
                  use_no BETWEEN 1000001 AND 3000000;

      CURSOR record_cur IS
         SELECT    *
         FROM      ai_raw_rates_test;
      */
      /*******************************************************************************************
       * Remove this cursor, which is not needed in the the version of co_error.sql.
		CURSOR ai_cur(p_prodno IN NUMBER) IS
			SELECT	chem_code, prodchem_pct
			FROM		prod_chem
			WHERE		prodno = p_prodno AND
						chem_code > 0
			ORDER BY prodchem_pct DESC;
       ********************************************************************************************/

   BEGIN
      FOR raw_rec IN record_cur LOOP
         v_acre_planted := raw_rec.acre_planted;
         v_aer_gnd_ind := raw_rec.aer_gnd_ind;
         v_applic_cnt := raw_rec.applic_cnt;
         v_applic_dt := raw_rec.applic_dt;
         v_county_cd := raw_rec.county_cd;
         v_license_no := raw_rec.license_no;
         v_prodno := raw_rec.prodno;
         v_record_id := raw_rec.record_id;
         v_site_code := raw_rec.site_code;
         v_site_loc_id := raw_rec.site_loc_id;
         v_unit_of_meas := raw_rec.unit_of_meas;
         v_unit_planted := raw_rec.unit_planted;
         v_use_no := raw_rec.use_no;

         v_unit_treated := raw_rec.unit_treated_report;
         v_acre_treated := raw_rec.acre_treated;
         v_lbs_prd_used := raw_rec.lbs_prd_used;
         v_amt_prd_used := raw_rec.amt_prd_used;

         v_unit_treated_old := v_unit_treated;
         v_acre_treated_old := v_acre_treated;
         v_lbs_prd_used_old := v_lbs_prd_used;
         v_amt_prd_used_old := v_amt_prd_used;
   		/*******************************************************************************************
   		 * Start of section to replace previous code in co_error.sql.
   		 ********************************************************************************************/
         Check_value_new.outliers
          (v_record_id, v_prodno, v_site_code,
           v_lbs_prd_used, v_amt_prd_used, v_acre_treated, v_unit_treated,
           v_acre_planted, v_unit_planted, v_applic_cnt,
           v_fixed1_rate_outlier, v_fixed2_rate_outlier, v_fixed3_rate_outlier,
           v_mean5sd_rate_outlier, v_mean7sd_rate_outlier, v_mean8sd_rate_outlier,
           v_mean10sd_rate_outlier, v_mean12sd_rate_outlier, 
           v_max_label_outlier, v_limit_rate_outlier,
           v_fixed1_lbsapp_outlier, v_fixed2_lbsapp_outlier, v_fixed3_lbsapp_outlier,
           v_mean3sd_lbsapp_outlier, v_mean5sd_lbsapp_outlier, v_mean7sd_lbsapp_outlier,
           v_mean8sd_lbsapp_outlier, v_mean10sd_lbsapp_outlier, v_mean12sd_lbsapp_outlier,
           v_limit_lbsapp_outlier, 
           v_comments, v_estimated_field, v_error_code, v_error_type, v_replace_type);

    		/*******************************************************************************************
   		 * End of section to replace previous code in co_error.sql.
   		 ********************************************************************************************/

         --DBMS_OUTPUT.PUT_LINE('v_error_type =  '||v_error_type||'; v_replace_type = '||v_replace_type);
         IF v_error_type != 'N' THEN
            IF v_replace_type != 'CORRECT' THEN
               --DBMS_OUTPUT.PUT_LINE('Call Log_error() with use_no '||v_use_no);

               Log_error
                  (p_year, v_use_no, v_error_code, v_error_type,
                   v_loader_name, v_comments, v_error_id);

               /* If outlier record exists for this record then
                  update outlier table with this outlier;
                  if no outlier record exists,
                  insert record.
                */
               SELECT	COUNT(*)
               INTO		v_outlier_exits
               FROM		outliers_new
               WHERE		year = p_year AND
                        use_no = v_use_no;

               IF v_outlier_exits > 0 THEN
                  UPDATE outliers_new
                    SET fixed1_rate_outlier = v_fixed1_rate_outlier,
                        fixed2_rate_outlier = v_fixed2_rate_outlier,
                        fixed3_rate_outlier = v_fixed3_rate_outlier,
                        mean5sd_rate_outlier = v_mean5sd_rate_outlier,
                        mean7sd_rate_outlier = v_mean7sd_rate_outlier,
                        mean8sd_rate_outlier = v_mean8sd_rate_outlier,
                        mean10sd_rate_outlier = v_mean10sd_rate_outlier,
                        mean12sd_rate_outlier = v_mean12sd_rate_outlier,
                        max_label_outlier = v_max_label_outlier,
                        limit_rate_outlier = v_limit_rate_outlier,
                        fixed1_lbsapp_outlier = v_fixed1_lbsapp_outlier,
                        fixed2_lbsapp_outlier = v_fixed2_lbsapp_outlier,
                        fixed3_lbsapp_outlier = v_fixed3_lbsapp_outlier,
                        mean3sd_lbsapp_outlier = v_mean3sd_lbsapp_outlier,
                        mean5sd_lbsapp_outlier = v_mean5sd_lbsapp_outlier,
                        mean7sd_lbsapp_outlier = v_mean7sd_lbsapp_outlier,
                        mean8sd_lbsapp_outlier = v_mean8sd_lbsapp_outlier,
                        mean10sd_lbsapp_outlier = v_mean10sd_lbsapp_outlier,
                        mean12sd_lbsapp_outlier = v_mean12sd_lbsapp_outlier,
                        limit_lbsapp_outlier = v_limit_lbsapp_outlier
                     WHERE	year = p_year AND use_no = v_use_no;
               ELSE
                  INSERT INTO outliers_new
                  VALUES
                     (p_year, v_use_no,
                      v_fixed1_rate_outlier, v_fixed2_rate_outlier, v_fixed3_rate_outlier,
                      v_mean5sd_rate_outlier, v_mean7sd_rate_outlier, v_mean8sd_rate_outlier,
                      v_mean10sd_rate_outlier, v_mean12sd_rate_outlier,
                      v_max_label_outlier, v_limit_rate_outlier,
                      v_fixed1_lbsapp_outlier, v_fixed2_lbsapp_outlier, v_fixed3_lbsapp_outlier,
                      v_mean3sd_lbsapp_outlier, v_mean5sd_lbsapp_outlier, v_mean7sd_lbsapp_outlier,
                      v_mean8sd_lbsapp_outlier, v_mean10sd_lbsapp_outlier, v_mean12sd_lbsapp_outlier,
                      v_limit_lbsapp_outlier);
               END IF;
               --COMMIT;
            END IF;

            IF v_replace_type != 'SAME' THEN
               IF v_estimated_field = 'UNIT_TREATED' THEN
                  --DBMS_OUTPUT.PUT_LINE('Call Log_change() with use_no '||v_use_no);
                  Log_change
                     (p_year, v_use_no,
                      'UNIT_TREATED', v_unit_treated_old, v_unit_treated, v_replace_type,
                      v_loader_name, NULL, v_error_id);

               ELSIF v_estimated_field = 'ACRE_TREATED' THEN
                  --DBMS_OUTPUT.PUT_LINE('Call Log_change() with use_no '||v_use_no);
                  Log_change
                     (p_year, v_use_no,
                      'ACRE_TREATED', v_acre_treated_old, v_acre_treated, v_replace_type,
                      v_loader_name, NULL, v_error_id);

               ELSIF v_estimated_field = 'LBS_PRD_USED' THEN
                  --DBMS_OUTPUT.PUT_LINE('Call Log_change() with use_no '||v_use_no);
                  Log_change
                     (p_year, v_use_no,
                      'LBS_PRD_USED', v_lbs_prd_used_old, v_lbs_prd_used, v_replace_type,
                      v_loader_name, NULL, v_error_id);

                  Log_change
                     (p_year, v_use_no,
                      'AMT_PRD_USED', v_amt_prd_used_old, v_amt_prd_used,v_replace_type,
                      v_loader_name, NULL, v_error_id);

               END IF;
            END IF;
         END IF;

         INSERT INTO
            pur_test(year, use_no, record_id, 
                    county_cd, site_code, applic_dt, 
                    site_loc_id, amt_prd_used, unit_of_meas,
                    prodno, lbs_prd_used, acre_treated, unit_treated,
                    acre_planted, unit_planted, applic_cnt,
                    aer_gnd_ind, license_no)
            VALUES(p_year, v_use_no, v_record_id, 
                   v_county_cd, v_site_code, v_applic_dt, 
                   trim(v_site_loc_id), v_amt_prd_used, v_unit_of_meas,
                   v_prodno, v_lbs_prd_used, v_acre_treated, v_unit_treated,
                   v_acre_planted, v_unit_planted, v_applic_cnt,
                   v_aer_gnd_ind, trim(v_license_no));
         COMMIT;
      END LOOP;

   EXCEPTION
      WHEN OTHERS THEN
         DBMS_OUTPUT.PUT_LINE(SQLERRM);
         --Other_exceptions(v_use_no, v_error_code);
         --General_exceptions;
   END Check_records;


   /* Record information in the errors and/or changes table.
    */
   PROCEDURE Log_error
      (p_year IN NUMBER,
       p_use_no IN NUMBER,
       p_error_code IN INTEGER,
       p_error_type IN VARCHAR2,
       p_who IN VARCHAR2,
       p_comments IN VARCHAR2,
       p_error_id OUT INTEGER)
   AS
      v_get_errors_seq_stmt     VARCHAR2(500);

   BEGIN
      /*************************
         For normal PUR processing use:  errors_i
         For batch PUR processing use:  errors.
      */
      --DBMS_OUTPUT.PUT_LINE('In Log_error() with use_no '||p_use_no);
      /*
      v_get_errors_seq_stmt :=
         'BEGIN SELECT errors_seq_' || p_year || '.NextVal INTO :b_errors_seq FROM dual; END;';
      */
      v_get_errors_seq_stmt :=
         'BEGIN SELECT errors_seq_test_' || p_year || '.NextVal INTO :b_errors_seq FROM dual; END;';

      EXECUTE IMMEDIATE v_get_errors_seq_stmt USING OUT p_error_id;

      INSERT INTO errors_i
         (error_id, error_code, year, use_no, error_type,
          who, found_date, comments)
      VALUES
         (p_error_id, p_error_code, p_year, p_use_no, p_error_type,
          p_who, SYSDATE, p_comments);

      COMMIT;

   EXCEPTION
      WHEN OTHERS THEN
         DBMS_OUTPUT.PUT_LINE(SQLERRM);
         -- Other_exceptions(p_use_no, p_error_code);
   END Log_error;


   /* Record information in the errors and/or changes table.
    */
   PROCEDURE Log_change
      (p_year IN NUMBER,
       p_use_no IN NUMBER,
       p_field_name IN VARCHAR2,
       p_old_value IN VARCHAR2,
       p_new_value IN VARCHAR2,
       p_replace_type IN VARCHAR2,
       p_who IN VARCHAR2,
       p_comments IN VARCHAR2,
       p_error_id IN INTEGER)
   AS
      v_get_changes_seq_stmt  VARCHAR2(500);
        v_change_id                    INTEGER;
   BEGIN
      /*************************
       For normal PUR processing use:  changes_i
       For batch PUR processing use:  changes.
       */
      --DBMS_OUTPUT.PUT_LINE('In Log_change() with use_no '||p_use_no);
      /*
      v_get_changes_seq_stmt :=
         'BEGIN SELECT changes_seq_' || p_year ||
         '.NextVal INTO :b_changes_seq FROM dual; END;';
      */

      v_get_changes_seq_stmt :=
         'BEGIN SELECT changes_seq_test_' || p_year ||
         '.NextVal INTO :b_changes_seq FROM dual; END;';

      EXECUTE IMMEDIATE v_get_changes_seq_stmt USING OUT v_change_id;

      INSERT INTO changes_i
         (change_id, year, use_no,
          field_name, old_value, new_value,
          action_taken, action_date, who, error_id,
          county_validated, comments)
      VALUES
         (v_change_id, p_year, p_use_no,
          p_field_name, p_old_value, p_new_value,
          p_replace_type, SYSDATE, p_who, p_error_id,
          'N', p_comments);
      --COMMIT;

   EXCEPTION
      WHEN OTHERS THEN
         DBMS_OUTPUT.PUT_LINE(SQLERRM);
         --Other_exceptions(p_use_no, p_error_id);
   END Log_change;


END Co_error_new;
/
show errors
