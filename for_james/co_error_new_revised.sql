CREATE OR REPLACE PACKAGE BODY OPS$PURLOAD."CO_ERROR" AS
/* Forward declarations of private procedures
 */
   PROCEDURE Other_exceptions(p_use_no IN NUMBER, p_error_code IN BINARY_INTEGER);
   --PROCEDURE General_exceptions;

/* Check for errors in each column of all records in raw_i
 */
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
      v_ai_a_1000_200        VARCHAR2(1);
      v_prd_u_50m            VARCHAR2(1);
      v_nn4                  VARCHAR2(1);
      v_fume_code            INTEGER; /* 002 */

       /*************************
       For normal PUR processing use:
       */
         CURSOR record_cur IS
         SELECT    *
         FROM         raw_i
         FOR UPDATE OF year, use_no
         NOWAIT;

       /*************************
       For testing:
       */
       /*
      CURSOR record_cur IS
         SELECT    *
         FROM         raw_i;
         */
      /* ***********************
       For batch PUR processing use:
      CURSOR record_cur IS
         SELECT    *
         FROM         raw_pur;
      */

		/* JYU 2016-08-25 Replace by new Outliers procedure provided by Larry W */
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


   BEGIN
      FOR raw_rec IN record_cur LOOP

         /*************************
          For normal PUR processing use:
            */
         v_get_sequence_stmt :=
            'BEGIN SELECT pur_seq_' || p_year || '.NextVal INTO :b_use_no FROM dual; END;';

         EXECUTE IMMEDIATE v_get_sequence_stmt USING OUT v_use_no;

         /* ***********************
          For batch PUR processing use:
         v_use_no := raw_rec.use_no;
         */

         /* For testing...
          */
         --DBMS_OUTPUT.PUT_LINE('1: use_no = '||v_use_no);

         /* Error code 1: Record_id
          */
         Check_value.Record_id
            (v_use_no, raw_rec.record_id, v_record_id,
             v_error_code, v_error_type, v_replace_type, v_require_type);

         IF v_error_type <> 'N' THEN
                IF v_replace_type != 'CORRECT' THEN
                    Log_error
                        (p_year, v_use_no,
                         v_error_code, v_error_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

                IF v_replace_type != 'SAME' THEN
                    Log_change
                        (p_year, v_use_no,
                         'RECORD_ID', raw_rec.record_id, v_record_id, v_replace_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

         END IF;

         /* For testing...
          */
         --DBMS_OUTPUT.PUT_LINE('2: use_no = '||v_use_no);

         /* Error code 2: batch_no
          */
         Check_value.Batch_no
            (v_use_no, raw_rec.batch_no, v_batch_no,
             v_error_code, v_error_type, v_replace_type, v_require_type);

         IF v_error_type <> 'N' THEN
                IF v_replace_type != 'CORRECT' THEN
                    Log_error
                        (p_year, v_use_no,
                         v_error_code, v_error_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

                IF v_replace_type != 'SAME' THEN
                    Log_change
                        (p_year, v_use_no,
                         'BATCH_NO', raw_rec.batch_no, v_batch_no, v_replace_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

         END IF;

         /* Error code 3: process_mt
          */
         Check_value.Process_mt
            (v_use_no, raw_rec.process_mt, v_process_mt,
             v_error_code, v_error_type, v_replace_type, v_require_type);

            IF v_error_type <> 'N' THEN
                IF v_replace_type != 'CORRECT' THEN
                    Log_error
                        (p_year, v_use_no,
                         v_error_code, v_error_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

                IF v_replace_type != 'SAME' THEN
                    Log_change
                        (p_year, v_use_no,
                         'PROCESS_MT', raw_rec.process_mt, v_process_mt, v_replace_type,
                         v_loader_name, NULL, v_error_id);
                END IF;


         END IF;

         /* Error code 4: process_yr
          */
         Check_value.Process_yr
            (v_use_no, raw_rec.process_yr, p_year, v_process_yr,
             v_error_code, v_error_type, v_replace_type, v_require_type);

         IF v_error_type <> 'N' THEN
                IF v_replace_type != 'CORRECT' THEN
                    Log_error
                        (p_year, v_use_no,
                         v_error_code, v_error_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

                IF v_replace_type != 'SAME' THEN
                    Log_change
                        (p_year, v_use_no,
                         'PROCESS_YR', raw_rec.process_yr, v_process_yr, v_replace_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

         END IF;

         /* Error code 5: county_cd
          */
         Check_value.County_cd
            (v_use_no, raw_rec.county_cd, v_county_cd,
             v_error_code, v_error_type, v_replace_type, v_require_type);

         IF v_error_type <> 'N' THEN
                IF v_replace_type != 'CORRECT' THEN
                    Log_error
                        (p_year, v_use_no,
                         v_error_code, v_error_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

                IF v_replace_type != 'SAME' THEN
                    Log_change
                        (p_year, v_use_no,
                         'COUNTY_CD', raw_rec.county_cd, v_county_cd, v_replace_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

         END IF;

         /* Error code 13, 14: site_code
          */
         Check_value.Site_code
            (v_use_no, raw_rec.site_code, p_year, v_site_code,
             v_error_code, v_error_type, v_replace_type, v_require_type);

         IF v_error_type <> 'N' THEN
                IF v_replace_type != 'CORRECT' THEN
                    Log_error
                        (p_year, v_use_no,
                         v_error_code, v_error_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

                IF v_replace_type != 'SAME' THEN
                    Log_change
                        (p_year, v_use_no,
                         'SITE_CODE', raw_rec.site_code, v_site_code, v_replace_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

         END IF;

         /* Error code 15: applic_month
          */
         Check_value.Applic_month
            (v_use_no, SUBSTR(raw_rec.applic_dt, 1, 2), v_applic_month,
             v_error_code, v_error_type, v_replace_type, v_require_type);

         IF v_error_type <> 'N' THEN
                IF v_replace_type != 'CORRECT' THEN
                    Log_error
                        (p_year, v_use_no,
                         v_error_code, v_error_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

                IF v_replace_type != 'SAME' THEN
                    Log_change
                        (p_year, v_use_no,
                         'APPLIC_DT', raw_rec.applic_dt, NULL, v_replace_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

         END IF;

         /* Error code 16: applic_day
          */
         Check_value.Applic_day
            (v_use_no, SUBSTR(raw_rec.applic_dt, 3, 2), v_applic_day,
             v_error_code, v_error_type, v_replace_type, v_require_type);

         IF v_error_type <> 'N' THEN
                IF v_replace_type != 'CORRECT' THEN
                    Log_error
                        (p_year, v_use_no,
                         v_error_code, v_error_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

                IF v_replace_type != 'SAME' THEN
                    Log_change
                        (p_year, v_use_no,
                         'APPLIC_DT', raw_rec.applic_dt, NULL, v_replace_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

         END IF;

         /* Error code 17: applic_year
          */
          /* Updated by James Yu 05-02-12: Remove error 17 and estimated date (set it as null). Add error 21
          */
         Check_value.Applic_year
            (v_use_no, SUBSTR(raw_rec.applic_dt, 5, 2), v_applic_month, v_applic_day,
             p_year, v_applic_year, v_estimated_date,
             v_error_code, v_error_type, v_replace_type, v_require_type);

         IF v_error_type <> 'N' THEN
                IF v_replace_type != 'CORRECT' THEN
                    Log_error
                        (p_year, v_use_no,
                         v_error_code, v_error_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

                IF v_replace_type != 'SAME' THEN
                    Log_change
                        (p_year, v_use_no,
                         'APPLIC_DT', raw_rec.applic_dt, NULL, v_replace_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

         END IF;

         /* Error code 51: applic_dt
          */
         Check_value.Applic_dt
            (v_use_no, v_applic_month, v_applic_day, v_applic_year,
             raw_rec.applic_dt, v_estimated_date, v_applic_dt, v_error_code,
             v_error_type, v_replace_type, v_require_type);

         IF v_error_type <> 'N' THEN
                IF v_replace_type != 'CORRECT' THEN
                    Log_error
                        (p_year, v_use_no,
                         v_error_code, v_error_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

                IF v_replace_type != 'SAME' THEN
                    Log_change
                        (p_year, v_use_no,
                         'APPLIC_DT', raw_rec.applic_dt, v_applic_dt, v_replace_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

         END IF;

         /* Error code 34: check document_no
          */
         Check_value.Document_no
            (v_use_no, v_record_id, v_applic_day, raw_rec.document_no,
             v_document_no, v_error_code, v_error_type,
             v_replace_type, v_require_type);

         IF v_error_type <> 'N' THEN
                IF v_replace_type != 'CORRECT' THEN
                    Log_error
                        (p_year, v_use_no,
                         v_error_code, v_error_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

                IF v_replace_type != 'SAME' THEN
                    Log_change
                        (p_year, v_use_no,
                         'DOCUMENT_NO', raw_rec.document_no, v_document_no, v_replace_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

         END IF;

         /* Error code 35: summary_cd
          */
         Check_value.Summary_cd
            (v_use_no, raw_rec.summary_cd, v_summary_cd,
             v_error_code, v_error_type, v_replace_type, v_require_type);

         IF v_error_type <> 'N' THEN
                IF v_replace_type != 'CORRECT' THEN
                    Log_error
                        (p_year, v_use_no,
                         v_error_code, v_error_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

                IF v_replace_type != 'SAME' THEN
                    Log_change
                        (p_year, v_use_no,
                         'SUMMARY_CD', raw_rec.summary_cd, v_summary_cd, v_replace_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

         END IF;

         /* Error code 62: site_loc_id
          */
         Check_value.Site_loc_id
            (v_use_no, v_record_id, raw_rec.site_loc_id, v_site_loc_id,
             v_error_code, v_error_type, v_replace_type, v_require_type);

         IF v_error_type <> 'N' THEN
                IF v_replace_type != 'CORRECT' THEN
                    Log_error
                        (p_year, v_use_no,
                         v_error_code, v_error_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

                IF v_replace_type != 'SAME' THEN
                    Log_change
                        (p_year, v_use_no,
                         'SITE_LOC_ID', raw_rec.site_loc_id, v_site_loc_id, v_replace_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

         END IF;

         /* Error code 64: cedts_ind
          */
         Check_value.Cedts_ind
            (v_use_no, raw_rec.cedts_ind, v_cedts_ind,
             v_error_code, v_error_type, v_replace_type, v_require_type);

         IF v_error_type <> 'N' THEN
                IF v_replace_type != 'CORRECT' THEN
                    Log_error
                        (p_year, v_use_no,
                         v_error_code, v_error_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

                IF v_replace_type != 'SAME' THEN
                    Log_change
                        (p_year, v_use_no,
                         'CEDTS_IND', raw_rec.cedts_ind, v_cedts_ind, v_replace_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

         END IF;

         /* Error code 65: qualify_cd
          */
         Check_value.Qualify_cd
            (v_use_no, raw_rec.qualify_cd, v_qualify_cd,
             v_error_code, v_error_type, v_replace_type, v_require_type);

         IF v_error_type <> 'N' THEN
                IF v_replace_type != 'CORRECT' THEN
                    Log_error
                        (p_year, v_use_no,
                         v_error_code, v_error_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

                IF v_replace_type != 'SAME' THEN
                    Log_change
                        (p_year, v_use_no,
                         'QUALIFY_CD', raw_rec.qualify_cd, v_qualify_cd, v_replace_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

         END IF;

         /* Error code 66: planting_seq
          */
         Check_value.Planting_seq
            (v_use_no, v_record_id, raw_rec.planting_seq, v_planting_seq,
             v_error_code, v_error_type, v_replace_type, v_require_type);

         IF v_error_type <> 'N' THEN
                IF v_replace_type != 'CORRECT' THEN
                    Log_error
                        (p_year, v_use_no,
                         v_error_code, v_error_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

                IF v_replace_type != 'SAME' THEN
                    Log_change
                        (p_year, v_use_no,
                         'PLANTING_SEQ', raw_rec.planting_seq, v_planting_seq, v_replace_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

         END IF;

         /* Error code 6: section
          */
         Check_value.Section
            (v_use_no, v_record_id, raw_rec.section, v_section,
             v_error_code, v_error_type, v_replace_type, v_require_type);

         IF v_error_type <> 'N' THEN
                IF v_replace_type != 'CORRECT' THEN
                    Log_error
                        (p_year, v_use_no,
                         v_error_code, v_error_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

                IF v_replace_type != 'SAME' THEN
                    Log_change
                        (p_year, v_use_no,
                         'SECTION', raw_rec.section, v_section, v_replace_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

         END IF;

         /* Error code 7: township
          */
         Check_value.Township
            (v_use_no, v_record_id, raw_rec.township, v_township,
             v_error_code, v_error_type, v_replace_type, v_require_type);

         IF v_error_type <> 'N' THEN
                IF v_replace_type != 'CORRECT' THEN
                    Log_error
                        (p_year, v_use_no,
                         v_error_code, v_error_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

                IF v_replace_type != 'SAME' THEN
                    Log_change
                        (p_year, v_use_no,
                         'TOWNSHIP', raw_rec.township, v_township, v_replace_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

         END IF;

         /* Error code 8: tship_dir
          */
         Check_value.Tship_dir
            (v_use_no, v_record_id, raw_rec.tship_dir, v_tship_dir,
             v_error_code, v_error_type, v_replace_type, v_require_type);

         IF v_error_type <> 'N' THEN
                IF v_replace_type != 'CORRECT' THEN
                    Log_error
                        (p_year, v_use_no,
                         v_error_code, v_error_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

                IF v_replace_type != 'SAME' THEN
                    Log_change
                        (p_year, v_use_no,
                         'TSHIP_DIR', raw_rec.tship_dir, v_tship_dir, v_replace_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

         END IF;

         /* Error code 9: range
          */
         Check_value.Range
            (v_use_no, v_record_id, raw_rec.range, v_range,
             v_error_code, v_error_type, v_replace_type, v_require_type);

         IF v_error_type <> 'N' THEN
                IF v_replace_type != 'CORRECT' THEN
                    Log_error
                        (p_year, v_use_no,
                         v_error_code, v_error_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

                IF v_replace_type != 'SAME' THEN
                    Log_change
                        (p_year, v_use_no,
                         'RANGE', raw_rec.range, v_range, v_replace_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

         END IF;

         /* Error code 10: range_dir
          */
         Check_value.Range_dir
            (v_use_no, v_record_id, raw_rec.range_dir, v_range_dir,
             v_error_code, v_error_type, v_replace_type, v_require_type);

         IF v_error_type <> 'N' THEN
                IF v_replace_type != 'CORRECT' THEN
                    Log_error
                        (p_year, v_use_no,
                         v_error_code, v_error_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

                IF v_replace_type != 'SAME' THEN
                    Log_change
                        (p_year, v_use_no,
                         'RANGE_DIR', raw_rec.range_dir, v_range_dir, v_replace_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

         END IF;

         /* Error code 11: base_ln_mer
          */
         Check_value.Base_ln_mer
            (v_use_no, v_record_id, raw_rec.base_ln_mer, v_base_ln_mer,
             v_error_code, v_error_type, v_replace_type, v_require_type);

         IF v_error_type <> 'N' THEN
                IF v_replace_type != 'CORRECT' THEN
                    Log_error
                        (p_year, v_use_no,
                         v_error_code, v_error_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

                IF v_replace_type != 'SAME' THEN
                    Log_change
                        (p_year, v_use_no,
                         'BASE_LN_MER', raw_rec.base_ln_mer, v_base_ln_mer, v_replace_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

         END IF;

         /* Error code 67: mtrs
          */
         Check_value.Mtrs
            (v_use_no, v_record_id, v_base_ln_mer, v_township, v_tship_dir, v_range,
             v_range_dir, v_section, v_ca_mtrs_acres,
             v_error_code, v_error_type, v_replace_type, v_require_type);


         IF v_error_type <> 'N' AND v_replace_type != 'CORRECT' THEN
                Log_error
                    (p_year, v_use_no,
                     v_error_code, v_error_type,
                     v_loader_name, NULL, v_error_id);
         END IF;

            /* This check never makes changes to any PUR fields.
                Previously, if this was an error, it was considered an invalid
                error, but this is not right, because error could be in
                the MTRS_ACRES table.  Also, leaving the reported value
                in PUR may be useful for someone using the data.
             */

         /* Error code 48: comtrs
          */
         Check_value.Comtrs
            (v_use_no, v_record_id, v_county_cd, v_base_ln_mer, v_township, v_tship_dir, v_range,
             v_range_dir, v_section,
             v_error_code, v_error_type, v_replace_type, v_require_type);

         IF v_error_type <> 'N' AND v_replace_type != 'CORRECT' THEN
                Log_error
                    (p_year, v_use_no,
                     v_error_code, v_error_type,
                     v_loader_name, NULL, v_error_id);
         END IF;

            /* This check never makes changes to any PUR fields.
             */

         /* Error code 12: aer_gnd_ind
          */
         Check_value.Aer_gnd_ind
            (v_use_no, v_record_id, raw_rec.aer_gnd_ind, v_aer_gnd_ind,
             v_error_code, v_error_type, v_replace_type, v_require_type);

         IF v_error_type <> 'N' THEN
                IF v_replace_type != 'CORRECT' THEN
                    Log_error
                        (p_year, v_use_no,
                         v_error_code, v_error_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

                IF v_replace_type != 'SAME' THEN
                    Log_change
                        (p_year, v_use_no,
                         'AER_GND_IND', raw_rec.aer_gnd_ind, v_aer_gnd_ind, v_replace_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

         END IF;

         /* Error code 68: applic_time.
          */
         Check_value.Applic_time
            (v_use_no, v_record_id, raw_rec.applic_time, v_applic_time,
             v_error_code, v_error_type, v_replace_type, v_require_type);

         IF v_error_type <> 'N' THEN
                IF v_replace_type != 'CORRECT' THEN
                    Log_error
                        (p_year, v_use_no,
                         v_error_code, v_error_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

                IF v_replace_type != 'SAME' THEN
                    Log_change
                        (p_year, v_use_no,
                         'APPLIC_TIME', raw_rec.applic_time, v_applic_time, v_replace_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

         END IF;

         /* Error code 43: grower_id
          */
         Check_value.Grower_id
            (v_use_no, v_record_id, v_county_cd, raw_rec.license_no, p_year,
             raw_rec.grower_id, v_grower_id, v_error_code, v_error_type,
             v_replace_type, v_require_type);

         IF v_error_type <> 'N' THEN
                IF v_replace_type != 'CORRECT' THEN
                    Log_error
                        (p_year, v_use_no,
                         v_error_code, v_error_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

                IF v_replace_type != 'SAME' THEN
                    Log_change
                        (p_year, v_use_no,
                         'GROWER_ID', raw_rec.grower_id, v_grower_id, v_replace_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

         END IF;

         /* Error code 69: license_no
          */
         Check_value.License_no
            (v_use_no, v_record_id, v_grower_id, raw_rec.license_no, p_year,
             v_license_no, v_error_code, v_error_type,
             v_replace_type, v_require_type);

         IF v_error_type <> 'N' THEN
                IF v_replace_type != 'CORRECT' THEN
                    Log_error
                        (p_year, v_use_no,
                         v_error_code, v_error_type,
                         v_loader_name, NULL, v_error_id);
                END IF;
         END IF;

            IF v_replace_type != 'SAME' THEN
                Log_change
                    (p_year, v_use_no,
                     'LICENSE_NO', raw_rec.license_no, v_license_no, v_replace_type,
                     v_loader_name, NULL, v_error_id);
            END IF;


         /* Error code 31: amt_prd_used
          */
         Check_value.Amt_prd_used
            (v_use_no, raw_rec.amt_prd_used, v_amt_prd_used,
             v_error_code, v_error_type, v_replace_type, v_require_type);

         IF v_error_type <> 'N' THEN
                IF v_replace_type != 'CORRECT' THEN
                    Log_error
                        (p_year, v_use_no,
                         v_error_code, v_error_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

                IF v_replace_type != 'SAME' THEN
                    Log_change
                        (p_year, v_use_no,
                         'AMT_PRD_USED', raw_rec.amt_prd_used, v_amt_prd_used, v_replace_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

         END IF;

         /* Error code 32: unit_of_meas
          */
         Check_value.Unit_of_meas
            (v_use_no, raw_rec.unit_of_meas, v_unit_of_meas,
             v_error_code, v_error_type, v_replace_type, v_require_type);

         IF v_error_type <> 'N' THEN
                IF v_replace_type != 'CORRECT' THEN
                    Log_error
                        (p_year, v_use_no,
                         v_error_code, v_error_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

                IF v_replace_type != 'SAME' THEN
                    Log_change
                        (p_year, v_use_no,
                         'UNIT_OF_MEAS', raw_rec.unit_of_meas, v_unit_of_meas, v_replace_type,
                         v_loader_name, NULL, v_error_id);
                END IF;


         END IF;

         /* Error code 24: mfg_firmno
          */
         Check_value.Mfg_firmno
            (v_use_no, raw_rec.mfg_firmno, v_mfg_firmno,
             v_error_code, v_error_type, v_replace_type, v_require_type);

         IF v_error_type <> 'N' THEN
                IF v_replace_type != 'CORRECT' THEN
                    Log_error
                        (p_year, v_use_no,
                         v_error_code, v_error_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

                IF v_replace_type != 'SAME' THEN
                    Log_change
                        (p_year, v_use_no,
                         'MFG_FIRMNO', raw_rec.mfg_firmno, v_mfg_firmno, v_replace_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

         END IF;

            /* I am not sure best way to handle this error because mfg_firmno
                is not a field in the PUR. If there is an error here, then
                prodno is NULL, so we could record prodno = NULL in CHANGES table;
                if label_seq_no was also invalid and we recorded that error
                in CHANGES as prodno = NULL, then we would have two records
                with same change.  We could record this change during
                error code 37, but then that would have wrong error code.

                We could just not record anything in CHANGES, but it would be
                nice for user to see orignal submitted value of mfg_firmno,
                so I think easiest to just record this in CHANGES here,
                even though mfg_firmno is not a PUR field.

             */

         /* Error code 25: label_seq_no
          */
         Check_value.Label_seq_no
            (v_use_no, raw_rec.label_seq_no, v_label_seq_no,
             v_error_code, v_error_type, v_replace_type, v_require_type);

         IF v_error_type <> 'N' THEN
                IF v_replace_type != 'CORRECT' THEN
                    Log_error
                        (p_year, v_use_no,
                         v_error_code, v_error_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

                IF v_replace_type != 'SAME' THEN
                    Log_change
                        (p_year, v_use_no,
                         'LABEL_SEQ_NO', raw_rec.label_seq_no, v_label_seq_no, v_replace_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

         END IF;
         /* revision_no
            Previously had Error code 26, but does not generate error now
            because if there is error in revision_no or reg_firmno,
            this program (in function Check_value.Prodno) will search
            for valid product with given mfg_firmno and label_seq_no.
            We still call this function to replace value with null
            if it is invalid value.
          */
         Check_value.Revision_no
            (v_use_no, raw_rec.revision_no, v_revision_no,
             v_error_code, v_error_type, v_replace_type, v_require_type);

         /* reg_firmno
            (Previously had Error code 27)
          */
         Check_value.Reg_firmno
            (v_use_no, raw_rec.reg_firmno, v_reg_firmno,
             v_error_code, v_error_type, v_replace_type, v_require_type);

         /* Error code 37: prodno
            No value for prodno is given in the county files.
            This value is found from the label database using the
            registration numbers.  Only the 3-part reg numbers
            are consistently given; defaults are often used for the
            revision_no so these may be wrong.

          */
         Check_value.Prodno
            (v_use_no, v_mfg_firmno, v_label_seq_no, v_revision_no, v_reg_firmno,
             v_site_code, v_unit_of_meas, v_applic_dt, v_county_cd, v_prodno, v_new_revision_no,
         v_new_reg_firmno, v_reg_num_parts, v_one_reg_no, v_valid_site,
         v_valid_spec_gravity, v_valid_reg_date, v_error_code, v_error_type,
         v_replace_type, v_require_type);

         IF v_error_type <> 'N' AND v_replace_type != 'CORRECT' THEN

                IF v_reg_firmno IS NULL THEN
                    v_reported_product :=
                        v_mfg_firmno||'-'||v_label_seq_no||'-'||v_revision_no;
                ELSE
                    v_reported_product :=
                        v_mfg_firmno||'-'||v_label_seq_no||'-'||v_revision_no||'-'||v_reg_firmno;
                END IF;

                IF v_new_reg_firmno IS NULL THEN
                    v_estimated_product :=
                        v_mfg_firmno||'-'||v_label_seq_no||'-'||v_new_revision_no;
                ELSE
                    v_estimated_product :=
                        v_mfg_firmno||'-'||v_label_seq_no||'-'||v_new_revision_no||'-'||v_new_reg_firmno;
                END IF;

                IF v_replace_type = 'ESTIMATE' THEN

                    IF v_reg_num_parts = 3 AND v_one_reg_no THEN

                        v_comments :=
                            'No product found that matched the reported 4-part registration number but did '||
                            'find one product that matched the 3-part registration number; reported reg num was '||
                            v_reported_product||'; product found was '||v_estimated_product||' '||
                            '(prodno = '||v_prodno||').';

                    ELSE
                        v_item := 0;

                        IF v_reg_num_parts = 2 THEN
                            v_comments :=
                                'No product found that matched the reported 4-part registration number or '||
                                'the 3-part registration number, but did find one or more products '||
                                'that matched the 2-part registration number; the reported reg num was '||
                                v_reported_product||'. The product chosen had:';
                        ELSIF v_reg_num_parts = 3 THEN
                            v_comments :=
                                'No product found that matched the reported 4-part registration number but did '||
                                'find more than one product that matched the 3-part registration number; '||
                                'the reported reg num was '||v_reported_product||'. The product chosen had:';
                        END IF;

                        IF v_valid_site THEN
                            v_item := v_item + 1;
                            v_comments := v_comments ||' '|| v_item ||
                                ') the reported site on its label ';
                        END IF;

                        IF v_valid_spec_gravity THEN
                            v_item := v_item + 1;
                            v_comments := v_comments ||' '|| v_item ||
                                ') a specific gravity value consistent with reported unit_of_meas';
                        END IF;

                        IF v_valid_reg_date THEN
                            v_item := v_item + 1;
                            v_comments := v_comments ||' '|| v_item ||
                                ') was registered at the time of application';
                        END IF;

                        v_comments := v_comments ||
                            '. This product was '||v_estimated_product||' '||
                            '(prodno = '||v_prodno||').';

                    END IF;

                ELSIF v_replace_type = 'NULL' OR v_error_type IS NULL THEN

                    v_comments :=
                    'No product found that matched the reported 4-part, 3-part, or 2-part registration number; '||
                    'reported reg num was '||v_reported_product||'.';
                ELSE
                    v_comments := NULL;
                END IF;

            Log_error
               (p_year, v_use_no,
                     v_error_code, v_error_type,
                     v_loader_name, v_comments, v_error_id);

            END IF;

            IF v_error_type <> 'N' AND v_replace_type != 'SAME' THEN
            Log_change
               (p_year, v_use_no,
                     'PRODNO', NULL, v_prodno, v_replace_type,
                     v_loader_name, NULL, v_error_id);

            END IF;


         /* Error code 39: Prod_site: check if site is on label for prodno.
          */

          /* 06/09/15 James Yu - Only runCheck_value.Prod_site if it is not pre-plant.i.e raw_rec.nursery_ind not equal Y  */
         IF raw_rec.nursery_ind is null or UPPER(raw_rec.nursery_ind) <> 'Y' THEN

         Check_value.Prod_site
            (v_use_no, v_prodno, v_site_code, v_mfg_firmno, v_county_cd, v_label_seq_no,
             v_new_reg_firmno, v_other_product, v_error_code, v_error_type,
         v_replace_type, v_require_type);

         IF v_error_type <> 'N' THEN

                IF v_new_reg_firmno IS NULL THEN
                    v_reported_product :=
                        v_mfg_firmno||'-'||v_label_seq_no||'-'||v_new_revision_no;
                ELSE
                    v_reported_product :=
                        v_mfg_firmno||'-'||v_label_seq_no||'-'||v_new_revision_no||'-'||v_new_reg_firmno;
                END IF;

                IF v_error_type = 'POSSIBLE' THEN

                    v_comments :=
                        'The reported site, '||v_site_code||', was not on the label for this pesticide product, '||
                         v_reported_product||' '||
                        '(prodno = '||v_prodno||'); however, the site was on another label which matched the '||
                        'reported product''s 2 or 3-part registration number. The other product with '||
                        'this site on its label is '||v_other_product||'.';

                ELSIF v_error_type = 'INCONSISTENT' THEN

                    v_comments :=
                        'The reported site, '||v_site_code||', was not on the label for this pesticide product, '||
                         v_reported_product||' '||
                        '(prodno = '||v_prodno||'), and was not on any other product which matched the '||
                        'product''s 2 or 3-part registration number.';
                ELSE

                    v_comments := NULL;
                END IF;

            Log_error
               (p_year, v_use_no,
                     v_error_code, v_error_type,
                     v_loader_name, v_comments, v_error_id);

         END IF;

            /* No changes are made for error code 39.
             */
         END IF;


         /* Error code 52: Spec_gravity: check if there is valid specific gravity
            value for prodno.  This is a check for DPR's label database, not
            for PUR data entry.
          */
         Check_value.Spec_gravity
            (v_use_no, v_prodno, v_unit_of_meas, v_spec_gravity, v_formula_cd,
             v_error_code, v_error_type, v_replace_type, v_require_type);

         IF v_error_type <> 'N' AND v_replace_type != 'CORRECT' THEN
                Log_error
                    (p_year, v_use_no,
                     v_error_code, v_error_type,
                     v_loader_name, NULL, v_error_id);
         END IF;


         /* Error code 38: second unit_of_meas check
          */
         Check_value.Unit_of_meas2
            (v_use_no, v_unit_of_meas, v_formula_cd,
             v_error_code, v_error_type, v_replace_type, v_require_type);

         IF v_error_type <> 'N' AND v_replace_type != 'CORRECT' THEN
                Log_error
                    (p_year, v_use_no,
                     v_error_code, v_error_type,
                     v_loader_name, NULL, v_error_id);
         END IF;

         /* No Error code: Calculate lbs_prd_used.  If error occurs it must
            be an "other" error, error code = 0.
          */
         Check_value.Lbs_prd_used
            (v_use_no, v_prodno, v_amt_prd_used, v_unit_of_meas, v_formula_cd,
             v_spec_gravity, v_lbs_prd_used,
             v_error_code, v_error_type, v_replace_type, v_require_type);

         IF v_error_type <> 'N' THEN
                IF v_replace_type != 'CORRECT' THEN
                    Log_error
                        (p_year, v_use_no,
                         v_error_code, v_error_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

                IF v_replace_type != 'SAME' THEN
                    Log_change
                        (p_year, v_use_no,
                         'LBS_PRD_USED', v_lbs_prd_used, v_lbs_prd_used, v_replace_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

         END IF;

         /* Error code 18: acre_treated
          */
         Check_value.Acre_treated
            (v_use_no, v_record_id, v_site_code, raw_rec.acre_treated, v_acre_treated,
             v_error_code, v_error_type, v_replace_type, v_require_type);

         IF v_error_type <> 'N' THEN
                IF v_replace_type != 'CORRECT' THEN
                    Log_error
                        (p_year, v_use_no,
                         v_error_code, v_error_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

                IF v_replace_type != 'SAME' THEN
                    Log_change
                        (p_year, v_use_no,
                         'ACRE_TREATED', raw_rec.acre_treated, v_acre_treated, v_replace_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

         END IF;

         /* Error code 19: unit_treated
          */
         Check_value.Unit_treated
            (v_use_no, v_record_id, v_site_code, raw_rec.unit_treated, v_unit_treated,
             v_error_code, v_error_type, v_replace_type, v_require_type);

         IF v_error_type <> 'N' THEN
                IF v_replace_type != 'CORRECT' THEN
                    Log_error
                        (p_year, v_use_no,
                         v_error_code, v_error_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

                IF v_replace_type != 'SAME' THEN
                    Log_change
                        (p_year, v_use_no,
                         'UNIT_TREATED', raw_rec.unit_treated, v_unit_treated, v_replace_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

         END IF;

         /* Error code 20: previously reported as either error code 18 or 19:
                acre_treated, unit_treated both present when optional

         */
         Check_value.Acre_unit_treated
           (v_use_no, v_record_id, v_site_code, v_acre_treated, v_unit_treated,
            v_error_code, v_error_type, v_replace_type, v_require_type);

         IF v_error_type <> 'N' AND v_replace_type != 'CORRECT' THEN
                Log_error
                    (p_year, v_use_no,
                     v_error_code, v_error_type,
                     v_loader_name, NULL, v_error_id);
         END IF;


         /* Error code 23: acre_treated  > area of its section?
         */
         v_acre_treated_old :=  v_acre_treated;
         Check_value.Acre_treated_section
           (v_use_no, v_record_id, v_site_code, v_ca_mtrs_acres, v_acre_treated, v_unit_treated,
            v_grower_id, v_site_loc_id, p_year, v_error_code, v_error_type, v_replace_type,
            v_require_type);

         IF v_error_type <> 'N' THEN
                IF v_replace_type != 'CORRECT' THEN
                    Log_error
                        (p_year, v_use_no,
                         v_error_code, v_error_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

                IF v_replace_type != 'SAME' THEN
                    Log_change
                        (p_year, v_use_no,
                         'ACRE_TREATED', v_acre_treated_old, v_acre_treated, v_replace_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

         END IF;

         /* Error code 22: area treated greater than 700 acres or equals 999999 square feet for non production ag?
         */
         v_unit_treated_old :=  v_unit_treated;
         Check_value.Acre_treated_nonag
           (v_use_no, v_record_id, v_site_code, v_acre_treated, v_unit_treated,
            v_error_code, v_error_type, v_replace_type, v_require_type);

         IF v_error_type <> 'N' THEN
                IF v_replace_type != 'CORRECT' THEN
                    Log_error
                        (p_year, v_use_no,
                         v_error_code, v_error_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

                IF v_replace_type != 'SAME' THEN
                    Log_change
                        (p_year, v_use_no,
                         'UNIT_TREATED', v_unit_treated_old, v_unit_treated, v_replace_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

         END IF;

         /* Error code 44: acre_planted
         */
         Check_value.Acre_planted
           (v_use_no, v_record_id, raw_rec.acre_planted, v_acre_planted,
            v_error_code, v_error_type, v_replace_type, v_require_type);

         IF v_error_type <> 'N' THEN
                IF v_replace_type != 'CORRECT' THEN
                    Log_error
                        (p_year, v_use_no,
                         v_error_code, v_error_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

                IF v_replace_type != 'SAME' THEN
                    Log_change
                        (p_year, v_use_no,
                         'ACRE_PLANTED', raw_rec.acre_planted, v_acre_planted, v_replace_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

         END IF;

         /* Error code 45: unit_planted
         */
         Check_value.Unit_planted
           (v_use_no, v_record_id, raw_rec.unit_planted, v_unit_planted,
            v_error_code, v_error_type, v_replace_type, v_require_type);

         IF v_error_type <> 'N' THEN
                IF v_replace_type != 'CORRECT' THEN
                    Log_error
                        (p_year, v_use_no,
                         v_error_code, v_error_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

                IF v_replace_type != 'SAME' THEN
                    Log_change
                        (p_year, v_use_no,
                         'UNIT_PLANTED', raw_rec.unit_planted, v_unit_planted, v_replace_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

         END IF;

         /* Error code 60: acre_planted  > area of its section?
         */
         v_acre_planted_old := v_acre_planted;
         Check_value.Acre_planted_section
                (v_use_no, v_site_code, v_ca_mtrs_acres, v_acre_planted, v_unit_planted,
                 v_grower_id, v_site_loc_id, p_year, v_error_code, v_error_type, v_replace_type,
                 v_require_type);

         IF v_error_type <> 'N' THEN
                IF v_replace_type != 'CORRECT' THEN
                    Log_error
                        (p_year, v_use_no,
                         v_error_code, v_error_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

                IF v_replace_type != 'SAME' THEN
                    Log_change
                        (p_year, v_use_no,
                         'ACRE_PLANTED', v_acre_planted_old, v_acre_planted, v_replace_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

         END IF;

         /* Error code 47: acre_treated > acre_planted?
         */
         v_acre_planted_old := v_acre_planted;
         v_unit_treated_old := v_unit_treated;

         Check_value.Acre_treated_planted
                (v_use_no, v_unit_planted, v_unit_treated, v_acre_planted, v_acre_treated,
                 v_error_code, v_error_type, v_replace_type, v_require_type);

         IF v_error_type <> 'N' THEN
                IF v_replace_type != 'CORRECT' THEN
                    Log_error
                        (p_year, v_use_no,
                         v_error_code, v_error_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

                IF v_replace_type != 'SAME' THEN
                    IF NVL(v_acre_planted, 0) != NVL(v_acre_planted_old, 0) THEN
                        Log_change
                            (p_year, v_use_no,
                             'ACRE_PLANTED', v_acre_planted_old, v_acre_planted, v_replace_type,
                             v_loader_name, NULL, v_error_id);

                    ELSIF NVL(v_unit_treated, ' ') != NVL(v_unit_treated_old, ' ') THEN
                        Log_change
                            (p_year, v_use_no,
                             'UNIT_TREATED', v_unit_treated_old, v_unit_treated, v_replace_type,
                             v_loader_name, NULL, v_error_id);

                    END IF;
                END IF;

         END IF;

         /* Error code 61: unit_treated and unit_planted consistent?
         */

         Check_value.Unit_treated_planted
          (v_use_no, v_acre_treated, v_acre_planted, v_unit_treated, v_unit_planted,
           v_units_incompatible, v_error_code, v_error_type, v_replace_type, v_require_type);

         IF v_error_type <> 'N' AND v_replace_type != 'CORRECT' THEN
                Log_error
                    (p_year, v_use_no,
                     v_error_code, v_error_type,
                     v_loader_name, NULL, v_error_id);
         END IF;

         /* Error code 30: applic_cnt
         */
         Check_value.Applic_cnt
          (v_use_no, v_record_id, raw_rec.applic_cnt, v_applic_cnt,
           v_error_code, v_error_type, v_replace_type, v_require_type);

         IF v_error_type <> 'N' THEN
                IF v_replace_type != 'CORRECT' THEN
                    Log_error
                        (p_year, v_use_no,
                         v_error_code, v_error_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

                IF v_replace_type != 'SAME' THEN
                    Log_change
                        (p_year, v_use_no,
                         'APPLIC_CNT', raw_rec.applic_cnt, v_applic_cnt, v_replace_type,
                         v_loader_name, NULL, v_error_id);
                END IF;

         END IF;

         /* Error code 80: Check for duplicate records that appear to be
            errors.
            Here, only one record from a error duplicate set is recorded
            in the pur table, though all duplicates from the raw_pur table
            are flagged in the raw_pur table.
            Thus, if current record is a duplicate of another record
            already in pur, do not insert the current record into pur.
          */
         Check_value.Duplicates
          (v_use_no, v_record_id, v_county_cd, v_grower_id, v_site_loc_id,
           v_site_code, v_qualify_cd, v_prodno, v_amt_prd_used, v_unit_of_meas,
           v_acre_treated, v_unit_treated, v_acre_planted, v_unit_planted,
           v_applic_dt, v_applic_time, p_year, v_units_incompatible, v_use_no_array, v_applic_time_array,
       v_error_code, v_error_type, v_replace_type, v_require_type);

         IF v_error_type <> 'N' THEN
            v_error_duplicate := TRUE;
            Log_duplicates
             (v_use_no, v_use_no_array, v_error_code,
              v_error_type, v_replace_type,
              v_loader_name, NULL, p_year);
         ELSE
            v_error_duplicate := FALSE;
         END IF;

         IF NOT v_error_duplicate THEN
            /*
            v_field_id := NULL;
            IF v_record_id IN ('1','4','A','B') THEN
               v_this_mtrs :=  mtrs_type(v_base_ln_mer, v_township, v_tship_dir,
                                         v_range, v_range_dir, v_section);
            ELSE
               v_this_mtrs := NULL;
            END IF;
            */

            /* Error code 75 or 72: outlier flagged by criteria 1, 2, or 4
            */
            v_unit_treated_old := v_unit_treated;
            v_acre_treated_old := v_acre_treated;
            v_lbs_prd_used_old := v_lbs_prd_used;
            v_amt_prd_used_old := v_amt_prd_used;

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

		FOR ai_rec IN ai_cur(v_prodno) LOOP
			Check_value.outliers
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
		END LOOP;


			/* JYU 2016-08-25 Replace by new Outliers procedure provided by Larry W
            Check_value.Outliers
             (v_use_no, v_record_id, v_prodno, v_site_code, v_amt_prd_used,
              v_lbs_prd_used, v_acre_treated, v_unit_treated, v_acre_planted,
              v_unit_planted, p_year, v_estimated_field, v_comments,
              v_error_code, v_error_type, v_replace_type, v_require_type);


                IF v_error_type <> 'N' THEN
                    IF v_replace_type != 'CORRECT' THEN
                        Log_error
                            (p_year, v_use_no,
                             v_error_code, v_error_type,
                             v_loader_name, v_comments, v_error_id); */

                        /* If outlier record exists for this record then
                            update outlier table with this outlier;
                            if no outlier record exists,
                            insert record.
                         */
				/* JYU 2016-08-25 Replace by new Outliers procedure provided by Larry W
                        SELECT    count(*)
                        INTO        v_outlier_exits
                        FROM        pur.outlier
                        WHERE        year = p_year AND
                                    use_no = v_use_no;

                        IF INSTR(v_comments, 'criterion 1') > 0 THEN
                            v_ai_a_1000_200 := 'Y';
                        ELSE
                            v_ai_a_1000_200 := 'N';
                        END IF;

                        IF INSTR(v_comments, 'criterion 2') > 0 THEN
                            v_prd_u_50m := 'Y';
                        ELSE
                            v_prd_u_50m := 'N';
                        END IF;

                        IF INSTR(v_comments, 'criterion 4') > 0 THEN
                            v_nn4 := 'Y';
                        ELSE
                            v_nn4 := 'N';
                        END IF;

                        IF v_outlier_exits > 0 THEN
                            UPDATE pur.outlier
                                SET ai_a_1000_200 = v_ai_a_1000_200,
                                     prd_u_50m = v_prd_u_50m,
                                     nn4 = v_nn4
                                WHERE    year = p_year AND use_no = v_use_no;
                        ELSE
                            INSERT INTO pur.outlier
                                        (year, use_no, ai_a_1000_200, prd_u_50m, nn4)
                                VALUES(p_year, v_use_no, v_ai_a_1000_200, v_prd_u_50m, v_nn4);
                        END IF;
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

                END IF; */

            /* Error code 72: rate of use > neural network outlier value.
             I suggest to call this after Outliers() to flag only records
             not flagged by other criteria.

                 Now this is incorporated into previous procedure

            Check_value.Outliers_nn
             (v_use_no, v_record_id, v_prodno, v_site_code, v_lbs_prd_used,
              v_acre_treated, v_unit_treated, p_year,
              v_error_code, v_error_type, v_replace_type, v_require_type);


                IF v_error_type <> 'N' THEN
                    IF v_replace_type != 'CORRECT' THEN
                        Log_error
                            (p_year, v_use_no,
                             v_error_code, v_error_type,
                             v_loader_name, NULL, v_error_id);
                    END IF;

                END IF;
                */
         END IF; --v_error_duplicate

         /*** START 002 START ***/
         /* Error code 85: fume_code */
         Check_value.Fumigation_code
          (v_use_no, raw_rec.fume_cd, v_aer_gnd_ind, v_fume_code,
           v_error_code, v_error_type, v_replace_type, v_require_type);

                    IF v_error_type <> 'N' THEN
                        IF v_replace_type != 'CORRECT' THEN
                            Log_error
                            (p_year, v_use_no,
                            v_error_code, v_error_type,
                            v_loader_name, NULL, v_error_id);
                        END IF;

                        IF v_replace_type != 'SAME' THEN
                            Log_change
                            (p_year, v_use_no,
                            'FUME_CODE', raw_rec.fume_cd, v_fume_code, v_replace_type,
                            v_loader_name, NULL, v_error_id);
                        END IF;

                    END IF;
         /*** END 002 END ***/

         /*************************
         For normal PUR processing use:
            */

         UPDATE   raw_i
            SET   year = p_year, use_no = v_use_no
            WHERE CURRENT OF record_cur;

         /*************************
         For batch PUR processing comment out above update.
         */

         IF NOT v_error_duplicate THEN
                /* Note we no longer use fields corr_cntr, grwr_fut_suf, qc_flag1, qc_flag2
                 */
            INSERT INTO
            pur(year, use_no, record_id, batch_no, process_mt, process_yr,
                       county_cd, site_code, applic_dt, document_no, summary_cd,
                       site_loc_id, cedts_ind, qualify_cd, amt_prd_used, unit_of_meas,
                       prodno, lbs_prd_used, acre_treated, unit_treated,
                       acre_planted, unit_planted, applic_cnt,
                       planting_seq, section, township, tship_dir, range, range_dir,
                       base_ln_mer, aer_gnd_ind, applic_time,
                       grower_id, license_no, last_up_dt, fume_cd, nursery_ind)
            VALUES(p_year, v_use_no, v_record_id, v_batch_no, v_process_mt, v_process_yr,
                   v_county_cd, v_site_code, v_applic_dt, v_document_no, v_summary_cd,
                   trim(v_site_loc_id), v_cedts_ind, v_qualify_cd, v_amt_prd_used, v_unit_of_meas,
                   v_prodno, v_lbs_prd_used, v_acre_treated, v_unit_treated,
                   v_acre_planted, v_unit_planted, v_applic_cnt,
                   v_planting_seq, v_section, v_township, v_tship_dir, v_range, v_range_dir,
                   v_base_ln_mer, v_aer_gnd_ind, v_applic_time,
                   trim(v_grower_id), trim(v_license_no), SYSDATE, v_fume_code, UPPER(raw_rec.nursery_ind));
            --COMMIT;

         END IF;
      END LOOP;

      COMMIT;

   EXCEPTION
      WHEN OTHERS THEN
         Other_exceptions(v_use_no, v_error_code);
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

        v_get_errors_seq_stmt :=
            'BEGIN SELECT errors_seq_' || p_year || '.NextVal INTO :b_errors_seq FROM dual; END;';

        EXECUTE IMMEDIATE v_get_errors_seq_stmt USING OUT p_error_id;

        INSERT INTO errors_i
            (error_id, error_code, year, use_no, error_type,
             who, found_date, comments)
        VALUES
            (p_error_id, p_error_code, p_year, p_use_no, p_error_type,
             p_who, SYSDATE, p_comments);

        --COMMIT;

   EXCEPTION
      WHEN OTHERS THEN
         Other_exceptions(p_use_no, p_error_code);
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
        v_get_changes_seq_stmt :=
            'BEGIN SELECT changes_seq_' || p_year ||
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
         Other_exceptions(p_use_no, p_error_id);
   END Log_change;


/* Record information about error duplicates.  Record both in errors and changes.
   We record in changes because all but one duplicate records from raw_pur are
   not recorded in the PUR.
 */
   PROCEDURE Log_duplicates
      (p_use_no IN NUMBER,
         p_use_no_array IN Check_value.use_no_array_type,
       p_error_code IN INTEGER,
         p_error_type IN VARCHAR2,
       p_replace_type IN VARCHAR2,
       p_who IN VARCHAR2,
         p_comments IN VARCHAR2,
         p_year IN NUMBER)
   IS
      v_dup_set_seq_stmt      VARCHAR(500);
      v_get_errors_seq_stmt   VARCHAR2(500);
      v_get_changes_seq_stmt  VARCHAR2(500);
        v_error_id                    INTEGER;
        v_change_id                    INTEGER;

        v_new_duplicate_set_no  INTEGER;
      v_old_duplicate_set_no  INTEGER;
      v_new_duplicate_set     BOOLEAN := FALSE;
      v_dup_no                INTEGER;

   BEGIN
      /* First, check if there is already a duplicate set which
         the current record belongs to.
       */
      /******************************
         For normal PUR processing use both errors and errorsi;
         For batch processing use only errors.
       */
      BEGIN

         SELECT duplicate_set
         INTO   v_old_duplicate_set_no
         FROM   errors
         WHERE  use_no = p_use_no_array(1) AND
                error_code = p_error_code AND
                     year = p_year;

      EXCEPTION
         WHEN OTHERS THEN
            v_new_duplicate_set := TRUE;
      END;

      IF v_new_duplicate_set THEN
         BEGIN
            SELECT duplicate_set
            INTO   v_old_duplicate_set_no
            FROM   errors_i
            WHERE  use_no = p_use_no_array(1) AND
                   error_code = p_error_code;

            v_new_duplicate_set := FALSE;
         EXCEPTION
            WHEN OTHERS THEN
               v_new_duplicate_set := TRUE;
         END;
      END IF;

      /* If this record is not in a previous duplicate set,
         make an error record using a new duplicate set number.
         Otherwise, make an error record using the previous
         duplicate set's number.
       */
      IF v_new_duplicate_set THEN
         v_dup_set_seq_stmt :=
                'BEGIN SELECT dup_set_seq_' || p_year || '.NextVal INTO :ds1 FROM dual; END;';

         EXECUTE IMMEDIATE v_dup_set_seq_stmt USING OUT v_new_duplicate_set_no;

         /* Record error for each record in the duplicate set; the last record
            in the array is the current array and this record is not inserted
            in the PUR but the other records are--note that replace_type is set to 'SAME'.
          */

         /*************************
          For normal PUR processing use:  errors_i and changes_i in all inserts below;
          for batch processing use errors and changes.
          */

         FOR v_dup_no IN 1..(p_use_no_array.LAST - 1) LOOP
                v_get_errors_seq_stmt :=
                    'BEGIN SELECT errors_seq_' || p_year || '.NextVal INTO :b_errors_seq FROM dual; END;';

                EXECUTE IMMEDIATE v_get_errors_seq_stmt USING OUT v_error_id;

                INSERT INTO errors_i
                    (error_id, error_code, year, use_no,
                     error_type, duplicate_set, who, found_date, comments)
                VALUES
                    (v_error_id, p_error_code, p_year, p_use_no_array(v_dup_no),
                     p_error_type, v_new_duplicate_set_no, p_who, SYSDATE, p_comments);

            --COMMIT;
         END LOOP;

         /* Only the current record is not recorded in the PUR,
            so report this in ERRORS table (note that p_replace_type 'delete') and
            as a change from what is in the raw_pur table.
            (Note that p_use_no is the same as p_use_no_array(p_use_no_array.LAST))
          */
            v_get_errors_seq_stmt :=
                'BEGIN SELECT errors_seq_' || p_year || '.NextVal INTO :b_errors_seq FROM dual; END;';

            EXECUTE IMMEDIATE v_get_errors_seq_stmt USING OUT v_error_id;

            INSERT INTO errors_i
                (error_id, error_code, year, use_no, error_type,
                 duplicate_set, who, found_date, comments)
            VALUES
                (v_error_id, p_error_code, p_year, p_use_no, p_error_type,
                 v_new_duplicate_set_no, p_who, SYSDATE, p_comments);
         --COMMIT;

            v_get_changes_seq_stmt :=
                'BEGIN SELECT changes_seq_' || p_year || '.NextVal INTO :b_changes_seq FROM dual; END;';

            EXECUTE IMMEDIATE v_get_changes_seq_stmt USING OUT v_change_id;

            INSERT INTO changes_i
            (change_id, year, use_no,
                 action_taken, action_date, who, error_id,
                 county_validated, comments)
         VALUES
            (v_change_id, p_year, p_use_no,
                 p_replace_type, SYSDATE, p_who, v_error_id,
                 'N', p_comments);

         --COMMIT;

      ELSE
            v_get_errors_seq_stmt :=
                'BEGIN SELECT errors_seq_' || p_year || '.NextVal INTO :b_errors_seq FROM dual; END;';

            EXECUTE IMMEDIATE v_get_errors_seq_stmt USING OUT v_error_id;

            INSERT INTO errors_i
                (error_id, error_code, year, use_no, error_type,
                 duplicate_set, who, found_date, comments)
            VALUES
                (v_error_id, p_error_code, p_year, p_use_no, p_error_type,
                 v_old_duplicate_set_no, p_who, SYSDATE, p_comments);
         --COMMIT;

            v_get_changes_seq_stmt :=
                'BEGIN SELECT changes_seq_' || p_year || '.NextVal INTO :b_changes_seq FROM dual; END;';

            EXECUTE IMMEDIATE v_get_changes_seq_stmt USING OUT v_change_id;

            INSERT INTO changes_i
            (change_id, year, use_no,
                 action_taken, action_date, who, error_id,
                 county_validated, comments)
         VALUES
            (v_change_id, p_year, p_use_no,
                 p_replace_type, SYSDATE, p_who, v_error_id,
                 'N', p_comments);
         --COMMIT;

      END IF;

   EXCEPTION
      WHEN OTHERS THEN
         Other_exceptions(p_use_no, p_error_code);
   END Log_duplicates;


/* Print out error message...
 */
   PROCEDURE Other_exceptions(p_use_no IN NUMBER, p_error_code IN BINARY_INTEGER)
   IS
   BEGIN
      DBMS_OUTPUT.PUT_LINE('Co_error: Other error for error code '||p_error_code||
       ' and use_no '||p_use_no||  ': ' || SQLERRM);
   END;

/* Print out error message...
   PROCEDURE General_exceptions
   IS
   BEGIN
      DBMS_OUTPUT.PUT_LINE('Other Error from Co_error2002: ' || SQLERRM);
   END;
 */

END Co_error;
/