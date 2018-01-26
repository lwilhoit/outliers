-- In general, do not use OPTIONALLY ENCLOSED BY '"'
-- because this will cause two consecutive tabs to be treated as one tab
LOAD DATA
  INFILE '../../tables/pur_site_groups.txt'
  TRUNCATE
INTO TABLE pur_site_groups
  FIELDS TERMINATED BY X'09'
  TRAILING NULLCOLS
  (site_code, site_name, site_general, site_general1, site_general_ag)



