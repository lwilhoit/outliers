/* This code should replace the call to Check_value.Outliers() in
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

CREATE OR REPLACE PACKAGE BODY OPS$PURLOAD."CO_ERROR" AS

   PROCEDURE Check_records(p_year IN NUMBER)
   AS
      v_use_no               NUMBER(8);
      v_error_code           BINARY_INTEGER := 0;
      v_error_type           VARCHAR2(20);
      v_replace_type         VARCHAR2(20);
      v_require_type         VARCHAR2(20);

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

      v_estimated_field      VARCHAR2(20);
      v_estimated_date       DATE;

      v_use_no_array         Check_value.use_no_array_type;
      v_applic_time_array    Check_value.applic_time_array_type;
      v_error_duplicate      BOOLEAN;

      v_reg_num_parts        INTEGER;
      v_one_reg_no           BOOLEAN;
      v_valid_site           BOOLEAN;
      v_valid_site_other     BOOLEAN;
      v_valid_spec_gravity   BOOLEAN;
      v_valid_reg_date       BOOLEAN;
      v_item                 INTEGER;

      v_error_id             INTEGER;
      v_comments             VARCHAR2(2000);

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

		v_fixed1_lbsapp_outlier		VARCHAR2(1);
		v_fixed2_lbsapp_outlier		VARCHAR2(1);
		v_fixed3_lbsapp_outlier		VARCHAR2(1);
		v_mean3sd_lbsapp_outlier	VARCHAR2(1);
		v_mean5sd_lbsapp_outlier	VARCHAR2(1);
		v_mean7sd_lbsapp_outlier	VARCHAR2(1);
		v_mean8sd_lbsapp_outlier	VARCHAR2(1);
		v_mean10sd_lbsapp_outlier	VARCHAR2(1);
		v_mean12sd_lbsapp_outlier	VARCHAR2(1);

      CURSOR record_cur IS
      SELECT    *
      FROM         raw_i
      FOR UPDATE OF year, use_no
      NOWAIT;

   BEGIN
      FOR raw_rec IN record_cur LOOP

         Check_value.outliers
          (v_record_id, v_prodno, v_site_code,
           v_lbs_prd_used, v_amt_prd_used, v_acre_treated, v_unit_treated,
           v_acre_planted, v_unit_planted, v_applic_cnt,
           v_comments, v_estimated_field, v_error_code, v_error_type, v_replace_type,
           v_fixed1_rate_outlier, v_fixed2_rate_outlier, v_fixed3_rate_outlier,
           v_mean5sd_rate_outlier, v_mean7sd_rate_outlier, v_mean8sd_rate_outlier,
           v_mean10sd_rate_outlier, v_mean12sd_rate_outlier,
           v_fixed1_lbsapp_outlier, v_fixed2_lbsapp_outlier, v_fixed3_lbsapp_outlier,
           v_mean3sd_lbsapp_outlier, v_mean5sd_lbsapp_outlier, v_mean7sd_lbsapp_outlier,
           v_mean8sd_lbsapp_outlier, v_mean10sd_lbsapp_outlier, v_mean12sd_lbsapp_outlier);

         Outliers_test
          (raw_rec.record_id, raw_rec.prodno, raw_rec.site_code, 
           raw_rec.lbs_prd_used, raw_rec.amt_prd_used, raw_rec.acre_treated, raw_rec.unit_treated_report, 
           raw_rec.acre_planted, raw_rec.unit_planted, raw_rec.applic_cnt, 
           v_fixed1, v_fixed2, v_fixed3, 
           v_mean5, v_mean7, v_mean8, v_mean10, v_mean12, v_max_label, v_outlier_limit, 
           v_comments, v_estimated_field, v_error_code, v_error_type, v_replace_type,
           v_median_prod, v_fixed1_prod, v_fixed2_prod, v_fixed3_prod,
           v_mean5sd_prod, v_mean7sd_prod, v_mean8sd_prod, v_mean10sd_prod, v_mean12sd_prod, 
           v_max_label_prod, v_prod_rate, v_ai_rate);


         IF v_error_type != 'N' THEN
            IF v_replace_type != 'CORRECT' THEN
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
                        fixed1_lbsapp_outlier = v_fixed1_lbsapp_outlier,
                        fixed2_lbsapp_outlier = v_fixed2_lbsapp_outlier,
                        fixed3_lbsapp_outlier = v_fixed3_lbsapp_outlier,
                        mean3sd_lbsapp_outlier = v_mean3sd_lbsapp_outlier,
                        mean5sd_lbsapp_outlier = v_mean5sd_lbsapp_outlier,
                        mean7sd_lbsapp_outlier = v_mean7sd_lbsapp_outlier,
                        mean8sd_lbsapp_outlier = v_mean8sd_lbsapp_outlier,
                        mean10sd_lbsapp_outlier = v_mean10sd_lbsapp_outlier,
                        mean12sd_lbsapp_outlier = v_mean12sd_lbsapp_outlier
                     WHERE	year = p_year AND use_no = v_use_no;
               ELSE
                  INSERT INTO outliers_new
                  VALUES
                     (p_year, v_use_no,
                      v_fixed1_rate_outlier, v_fixed2_rate_outlier, v_fixed3_rate_outlier,
                      v_mean5sd_rate_outlier, v_mean7sd_rate_outlier, v_mean8sd_rate_outlier,
                      v_mean10sd_rate_outlier, v_mean12sd_rate_outlier,
                      v_fixed1_lbsapp_outlier, v_fixed2_lbsapp_outlier, v_fixed3_lbsapp_outlier,
                      v_mean3sd_lbsapp_outlier, v_mean5sd_lbsapp_outlier, v_mean7sd_lbsapp_outlier,
                      v_mean8sd_lbsapp_outlier, v_mean10sd_lbsapp_outlier, v_mean12sd_lbsapp_outlier);
               END IF;
               --COMMIT;
            END IF;

            IF v_replace_type != 'SAME' THEN
               IF v_estimated_field = 'UNIT_TREATED' THEN
                  Log_change
                     (p_year, v_use_no,
                      'UNIT_TREATED', v_unit_treated_old, v_unit_treated, v_replace_type,
                      v_loader_name, NULL, v_error_id);

               ELSIF v_estimated_field = 'ACRE_TREATED' THEN
                  Log_change
                     (p_year, v_use_no,
                      'ACRE_TREATED', v_acre_treated_old, v_acre_treated, v_replace_type,
                      v_loader_name, NULL, v_error_id);

               ELSIF v_estimated_field = 'LBS_PRD_USED' THEN
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

            EXIT; -- This code loops through all AIs in a product, starting with AI with the
                  -- highest percent. If we reached here, an outlier is found, so exit
                  -- this PUR records and go to next record.
         END IF;

		p_year := pur_rec.year;
		v_use_no := pur_rec.use_no;
		--DBMS_OUTPUT.PUT_LINE('________________________________________________');
		--DBMS_OUTPUT.PUT_LINE('v_use_no = '||v_use_no);

		v_record_id := pur_rec.record_id;
		v_site_code := pur_rec.site_code;
		v_prodno := pur_rec.prodno;
		v_amt_prd_used := pur_rec.amt_prd_used;
		v_lbs_prd_used := pur_rec.lbs_prd_used;
		v_acre_treated := pur_rec.acre_treated;
		v_unit_treated := pur_rec.unit_treated;
		v_acre_planted := pur_rec.acre_planted;
		v_unit_planted := pur_rec.unit_planted;
		v_applic_cnt := pur_rec.applic_cnt;

		v_amt_prd_used_old := v_amt_prd_used;
		v_lbs_prd_used_old := v_lbs_prd_used;
		v_acre_treated_old := v_acre_treated;
		v_unit_treated_old := v_unit_treated;

		/*******************************************************************************************
		 * Start of section to replace previous code in co_error.sql.
		 ********************************************************************************************/
		/* Put these declarations in the DECLARE section:
		v_fixed1_rate_outlier		VARCHAR2(1);
		v_fixed2_rate_outlier		VARCHAR2(1);
		v_fixed3_rate_outlier		VARCHAR2(1);
		v_mean5sd_rate_outlier		VARCHAR2(1);
		v_mean7sd_rate_outlier		VARCHAR2(1);
		v_mean8sd_rate_outlier		VARCHAR2(1);
		v_mean10sd_rate_outlier		VARCHAR2(1);
		v_mean12sd_rate_outlier		VARCHAR2(1);

		v_fixed1_lbsapp_outlier		VARCHAR2(1);
		v_fixed2_lbsapp_outlier		VARCHAR2(1);
		v_fixed3_lbsapp_outlier		VARCHAR2(1);
		v_mean3sd_lbsapp_outlier	VARCHAR2(1);
		v_mean5sd_lbsapp_outlier	VARCHAR2(1);
		v_mean7sd_lbsapp_outlier	VARCHAR2(1);
		v_mean8sd_lbsapp_outlier	VARCHAR2(1);
		v_mean10sd_lbsapp_outlier	VARCHAR2(1);
		v_mean12sd_lbsapp_outlier	VARCHAR2(1);

		CURSOR ai_cur(p_prodno IN NUMBER) IS
			SELECT	chem_code, prodchem_pct
			FROM		prod_chem
			WHERE		prodno = p_prodno AND
						chem_code > 0
			ORDER BY prodchem_pct DESC;
		*/

      Check_value_outliers_new
       (p_year, v_use_no, v_record_id, v_prodno, ai_rec.chem_code,
        ai_rec.prodchem_pct, v_site_code,
        v_amt_prd_used, v_lbs_prd_used, v_acre_treated, v_unit_treated,
        v_acre_planted, v_unit_planted, v_applic_cnt,
        v_comments, v_estimated_field, v_error_code, v_error_type, v_replace_type,
        v_fixed1_rate_outlier, v_fixed2_rate_outlier, v_fixed3_rate_outlier,
        v_mean5sd_rate_outlier, v_mean7sd_rate_outlier, v_mean8sd_rate_outlier,
        v_mean10sd_rate_outlier, v_mean12sd_rate_outlier,
        v_fixed1_lbsapp_outlier, v_fixed2_lbsapp_outlier, v_fixed3_lbsapp_outlier,
        v_mean3sd_lbsapp_outlier, v_mean5sd_lbsapp_outlier, v_mean7sd_lbsapp_outlier,
        v_mean8sd_lbsapp_outlier, v_mean10sd_lbsapp_outlier, v_mean12sd_lbsapp_outlier);

      IF v_error_type != 'N' THEN
         IF v_replace_type != 'CORRECT' THEN
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
                     fixed1_lbsapp_outlier = v_fixed1_lbsapp_outlier,
                     fixed2_lbsapp_outlier = v_fixed2_lbsapp_outlier,
                     fixed3_lbsapp_outlier = v_fixed3_lbsapp_outlier,
                     mean3sd_lbsapp_outlier = v_mean3sd_lbsapp_outlier,
                     mean5sd_lbsapp_outlier = v_mean5sd_lbsapp_outlier,
                     mean7sd_lbsapp_outlier = v_mean7sd_lbsapp_outlier,
                     mean8sd_lbsapp_outlier = v_mean8sd_lbsapp_outlier,
                     mean10sd_lbsapp_outlier = v_mean10sd_lbsapp_outlier,
                     mean12sd_lbsapp_outlier = v_mean12sd_lbsapp_outlier
                  WHERE	year = p_year AND use_no = v_use_no;
            ELSE
               INSERT INTO outliers_new
               VALUES
                  (p_year, v_use_no,
                   v_fixed1_rate_outlier, v_fixed2_rate_outlier, v_fixed3_rate_outlier,
                   v_mean5sd_rate_outlier, v_mean7sd_rate_outlier, v_mean8sd_rate_outlier,
                   v_mean10sd_rate_outlier, v_mean12sd_rate_outlier,
                   v_fixed1_lbsapp_outlier, v_fixed2_lbsapp_outlier, v_fixed3_lbsapp_outlier,
                   v_mean3sd_lbsapp_outlier, v_mean5sd_lbsapp_outlier, v_mean7sd_lbsapp_outlier,
                   v_mean8sd_lbsapp_outlier, v_mean10sd_lbsapp_outlier, v_mean12sd_lbsapp_outlier);
            END IF;
            COMMIT;
         END IF;

         IF v_replace_type != 'SAME' THEN
            IF v_estimated_field = 'UNIT_TREATED' THEN
               Log_change
                  (p_year, v_use_no,
                   'UNIT_TREATED', v_unit_treated_old, v_unit_treated, v_replace_type,
                   v_loader_name, NULL, v_error_id);

            ELSIF v_estimated_field = 'ACRE_TREATED' THEN
               Log_change
                  (p_year, v_use_no,
                   'ACRE_TREATED', v_acre_treated_old, v_acre_treated, v_replace_type,
                   v_loader_name, NULL, v_error_id);

            ELSIF v_estimated_field = 'LBS_PRD_USED' THEN
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
		END LOOP;
		/*******************************************************************************************
		 * End of section to replace previous code in co_error.sql.
		 ********************************************************************************************/

END Co_error;
/

