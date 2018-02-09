SET pause OFF
SET pagesize 75
SET linesize 148
SET termout ON
SET feedback ON
SET document OFF
SET verify OFF
SET trimspool ON
SET numwidth 11
SET SERVEROUTPUT ON SIZE 1000000 FORMAT WORD_WRAPPED
WHENEVER SQLERROR EXIT 1 ROLLBACK
WHENEVER OSERROR EXIT 1 ROLLBACK

UPDATE pur_rates_&&1 pur
	SET	ai_group =
	(SELECT	ai_group
	 FROM 	ai_group_stats
	 WHERE	chem_code = pur.chem_code AND
				site_general = pur.site_general AND
				regno_short = pur.regno_short AND
				ago_ind = pur.ago_ind AND
				unit_treated = pur.unit_treated)
	WHERE use_no < 200000;

COMMIT;

UPDATE pur_rates_&&1 pur
	SET	ai_group =
	(SELECT	ai_group
	 FROM 	ai_group_stats
	 WHERE	chem_code = pur.chem_code AND
				site_general = pur.site_general AND
				regno_short = pur.regno_short AND
				ago_ind = pur.ago_ind AND
				unit_treated = pur.unit_treated)
	WHERE use_no BETWEEN 200001 AND 500000;

COMMIT;


UPDATE pur_rates_&&1 pur
	SET	ai_group =
	(SELECT	ai_group
	 FROM 	ai_group_stats
	 WHERE	chem_code = pur.chem_code AND
				site_general = pur.site_general AND
				regno_short = pur.regno_short AND
				ago_ind = pur.ago_ind AND
				unit_treated = pur.unit_treated)
	WHERE use_no BETWEEN 500001 AND 1000000;

COMMIT;


UPDATE pur_rates_&&1 pur
	SET	ai_group =
	(SELECT	ai_group
	 FROM 	ai_group_stats
	 WHERE	chem_code = pur.chem_code AND
				site_general = pur.site_general AND
				regno_short = pur.regno_short AND
				ago_ind = pur.ago_ind AND
				unit_treated = pur.unit_treated)
	WHERE use_no BETWEEN 1000001 AND 1500000;

COMMIT;

UPDATE pur_rates_&&1 pur
	SET	ai_group =
	(SELECT	ai_group
	 FROM 	ai_group_stats
	 WHERE	chem_code = pur.chem_code AND
				site_general = pur.site_general AND
				regno_short = pur.regno_short AND
				ago_ind = pur.ago_ind AND
				unit_treated = pur.unit_treated)
	WHERE use_no BETWEEN 1500001 AND 2000000;

COMMIT;


UPDATE pur_rates_&&1 pur
	SET	ai_group =
	(SELECT	ai_group
	 FROM 	ai_group_stats
	 WHERE	chem_code = pur.chem_code AND
				site_general = pur.site_general AND
				regno_short = pur.regno_short AND
				ago_ind = pur.ago_ind AND
				unit_treated = pur.unit_treated)
	WHERE use_no BETWEEN 2000001 AND 2500000;

COMMIT;

UPDATE pur_rates_&&1 pur
	SET	ai_group =
	(SELECT	ai_group
	 FROM 	ai_group_stats
	 WHERE	chem_code = pur.chem_code AND
				site_general = pur.site_general AND
				regno_short = pur.regno_short AND
				ago_ind = pur.ago_ind AND
				unit_treated = pur.unit_treated)
	WHERE use_no BETWEEN 2500001 AND 3000000;

COMMIT;



UPDATE pur_rates_&&1 pur
	SET	ai_group =
	(SELECT	ai_group
	 FROM 	ai_group_stats
	 WHERE	chem_code = pur.chem_code AND
				site_general = pur.site_general AND
				regno_short = pur.regno_short AND
				ago_ind = pur.ago_ind AND
				unit_treated = pur.unit_treated)
	WHERE use_no BETWEEN 3000001 AND 3500000;

COMMIT;

UPDATE pur_rates_&&1 pur
	SET	ai_group =
	(SELECT	ai_group
	 FROM 	ai_group_stats
	 WHERE	chem_code = pur.chem_code AND
				site_general = pur.site_general AND
				regno_short = pur.regno_short AND
				ago_ind = pur.ago_ind AND
				unit_treated = pur.unit_treated)
	WHERE use_no BETWEEN 3500001 AND 4000000;

COMMIT;

UPDATE pur_rates_&&1 pur
	SET	ai_group =
	(SELECT	ai_group
	 FROM 	ai_group_stats
	 WHERE	chem_code = pur.chem_code AND
				site_general = pur.site_general AND
				regno_short = pur.regno_short AND
				ago_ind = pur.ago_ind AND
				unit_treated = pur.unit_treated)
	WHERE use_no > 4000000;

COMMIT;


EXIT 0

/*
SELECT	chem_code, site_general, regno_short, ago_ind, unit_treated, COUNT(*)
FROM		ai_group_stats
GROUP BY chem_code, site_general, regno_short, ago_ind, unit_treated
HAVING	COUNT(*) > 1;

select ai_group, count(*) from pur_rates_2012 group by ai_group;


*/
