-- In general, do not use OPTIONALLY ENCLOSED BY '"'
-- because this will cause two consecutive tabs to be treated as one tab
LOAD DATA
  INFILE '../../tables/fixed_outlier_rates.txt'
  TRUNCATE
INTO TABLE fixed_outlier_rates
  FIELDS TERMINATED BY X'09'
  TRAILING NULLCOLS
  (ago_ind, unit_treated, ai_rate_type, site_type, rate1, rate2, rate3, log_rate1, log_rate2, log_rate3)



