-- In general, do not use OPTIONALLY ENCLOSED BY '"'
-- because this will cause two consecutive tabs to be treated as one tab
LOAD DATA
  INFILE '../../tables/fixed_outlier_lbs_app.txt'
  TRUNCATE
INTO TABLE fixed_outlier_lbs_app
  FIELDS TERMINATED BY X'09'
  TRAILING NULLCOLS
  (lbs_ai_app_type, site_type, lbs_ai_app1, lbs_ai_app2, lbs_ai_app3, log_lbs_ai_app1, log_lbs_ai_app2, log_lbs_ai_app3)



