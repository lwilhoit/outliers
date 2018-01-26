-- In general, do not use OPTIONALLY ENCLOSED BY '"'
-- because this will cause two consecutive tabs to be treated as one tab
LOAD DATA
  INFILE '../../tables/ai_group_stats.txt'
  TRUNCATE
INTO TABLE ai_group_stats
  FIELDS TERMINATED BY X'09'
  TRAILING NULLCOLS
  (chem_code, ai_group, site_general, regno_short, ago_ind, unit_treated, chemname, ai_name, ai_adjuvant, mean_trim, mean, median, sd_rate_trim, sd_rate_trim_orig, sd_rate, sum_sq_rate_trim, num_recs, num_recs_trim, year)



