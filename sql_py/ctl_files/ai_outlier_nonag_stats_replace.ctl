-- In general, do not use OPTIONALLY ENCLOSED BY '"'
-- because this will cause two consecutive tabs to be treated as one tab
LOAD DATA
  INFILE '../../tables/ai_outlier_nonag_stats.txt'
  TRUNCATE
INTO TABLE ai_outlier_nonag_stats
  FIELDS TERMINATED BY X'09'
  TRAILING NULLCOLS
  (year, chem_code, ai_group, num_recs, num_recs_trim, median_rate, mean_rate, mean_rate_trim, sd_rate, sd_rate_trim_orig, sd_rate_trim, sum_sq_rate_trim, med50, med100, med150, med200, med250, med300, med400, med500, med1000, med5000, med10000, med50000, med100000, mean3sd, mean5sd, mean7sd, mean8sd, mean10sd, mean12sd, mean15sd)


