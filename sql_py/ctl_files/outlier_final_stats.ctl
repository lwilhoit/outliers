-- In general, do not use OPTIONALLY ENCLOSED BY '"'
-- because this will cause two consecutive tabs to be treated as one tab
LOAD DATA
  INFILE '../../tables/outlier_final_stats.txt'
  TRUNCATE
INTO TABLE outlier_final_stats
  FIELDS TERMINATED BY X'09'
  TRAILING NULLCOLS
  (ago_ind, unit_treated, ai_rate_type, site_type, fixed2, mean_limit)



