SET pause OFF
SET pagesize 75
SET linesize 120
SET termout ON
SET feedback ON
SET document OFF
SET verify OFF
SET trimspool ON
SET numwidth 11

DROP INDEX prod_chem_major_ai1_ndx;
CREATE INDEX prod_chem_major_ai1_ndx ON prod_chem_major_ai
	(prodno)
   PCTFREE 2
   STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0);

DROP INDEX prod_chem_major_ai2_ndx;
CREATE INDEX prod_chem_major_ai2_ndx ON prod_chem_major_ai
	(chem_code)
   PCTFREE 2
   STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0);



DROP INDEX pur_site_groups_ndx;
CREATE INDEX pur_site_groups_ndx ON pur_site_groups
	(site_code)
   PCTFREE 2
   STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0);


DROP INDEX ai_group_stats_ndx;
CREATE INDEX ai_group_stats_ndx ON ai_group_stats
	(year, chem_code, regno_short, site_general, ago_ind, unit_treated)
   PCTFREE 2
   STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0);

DROP INDEX ai_group_nonag_stats_ndx;
CREATE INDEX ai_group_nonag_stats_ndx ON ai_group_nonag_stats
	(year, chem_code, regno_short, site_general)
   PCTFREE 2
   STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0);


DROP INDEX ai_outlier_stats1_ndx;
CREATE INDEX ai_outlier_stats1_ndx ON ai_outlier_stats
	(year, chem_code, ago_ind, unit_treated)
   PCTFREE 2
   STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0);

DROP INDEX ai_outlier_stats2_ndx;
CREATE INDEX ai_outlier_stats2_ndx ON ai_outlier_stats
	(year, chem_code, ai_group, ag_ind, unit_treated)
   PCTFREE 2
   STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0);


DROP INDEX ai_outlier_nonag_stats1_ndx;
CREATE INDEX ai_outlier_nonag_stats1_ndx ON ai_outlier_nonag_stats
	(year, chem_code)
   PCTFREE 2
   STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0);

DROP INDEX ai_outlier_nonag_stats2_ndx;
CREATE INDEX ai_outlier_nonag_stats2_ndx ON ai_outlier_nonag_stats
	(year, chem_code, ai_group)
   PCTFREE 2
   STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0);


DROP INDEX outlier_all_stats1_ndx;
CREATE INDEX outlier_all_stats1_ndx ON outlier_all_stats
	(regno_short, ago_ind, site_general, unit_treated)
   PCTFREE 2
   STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0);






DROP INDEX fixout_lbsapp_ais1_ndx;
CREATE INDEX fixout_lbsapp_ais1_ndx ON fixed_outlier_lbs_app_ais
	(site_type, chem_code)
   PCTFREE 2
   STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0);

DROP INDEX fixout_lbsapp_ais_ndx;
CREATE INDEX fixout_lbsapp_ais_ndx ON fixed_outlier_lbs_app_ais
	(lbs_ai_app_type, chem_code)
   PCTFREE 2
   STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0);


DROP INDEX fixout_lbsapp_ndx;
CREATE INDEX fixout_lbsapp_ndx ON fixed_outlier_lbs_app
	(lbs_ai_app_type)
   PCTFREE 2
   STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0);

DROP INDEX fixout_lbsapp1_ndx;
CREATE INDEX fixout_lbsapp1_ndx ON fixed_outlier_lbs_app
	(lbs_ai_app_type, site_type)
   PCTFREE 2
   STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0);


DROP INDEX fixout_rates_ais_ndx;
CREATE INDEX fixout_rates_ais_ndx ON fixed_outlier_rates_ais
	(ago_ind, unit_treated, site_type, chem_code)
   PCTFREE 2
   STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0);

DROP INDEX fixout_rates_ndx;
CREATE INDEX fixout_rates_ndx ON fixed_outlier_rates
	(ago_ind, unit_treated, ai_rate_type, site_type)
   PCTFREE 2
   STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0);

DROP INDEX outlier_final_stats_ndx;
CREATE INDEX outlier_final_stats_ndx ON outlier_final_stats
	(ago_ind, unit_treated, ai_rate_type, site_type)
   PCTFREE 2
   STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0);



DROP INDEX prod_adjuvant_ndx;
CREATE INDEX prod_adjuvant_ndx ON prod_adjuvant
	(prodno)
   PCTFREE 2
   STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0);

DROP INDEX chem_adjuvant_ndx;
CREATE INDEX chem_adjuvant_ndx ON chem_adjuvant
	(chem_code)
   PCTFREE 2
   STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0);


DROP INDEX pur_outlier_2016_ndx;
CREATE INDEX pur_outlier_2016_ndx ON pur_outlier_2016/*changed to 2016 - kim*/
	(use_no, chem_code)
   PCTFREE 2
   STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0);

DROP INDEX co_ai_high_list_ndx;
CREATE INDEX co_ai_high_list_ndx ON co_ai_high_list
	(county_cd, ag_ind, chem_code)
   PCTFREE 2
   STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0);

DROP INDEX pur_lbs_percentiles_2016_ndx;
CREATE INDEX pur_lbs_percentiles_2016_ndx ON pur_lbs_percentiles_2016/*changed to 2016 - kim*/
	(county_cd, ag_ind, chem_code)
   PCTFREE 2
   STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0);


DROP INDEX co_ai_stats_ndx;
CREATE INDEX co_ai_stats_ndx ON co_ai_stats
	(county_cd, ag_ind, chem_code)
   PCTFREE 2
   STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0);

EXIT 0

