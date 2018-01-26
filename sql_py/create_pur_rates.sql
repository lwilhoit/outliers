SET pause OFF
SET pagesize 75
SET linesize 120
SET termout ON
SET feedback ON
SET document OFF
SET verify OFF
SET trimspool ON
SET numwidth 11
SET SERVEROUTPUT ON SIZE 1000000 FORMAT WORD_WRAPPED
WHENEVER SQLERROR EXIT 1 ROLLBACK
WHENEVER OSERROR EXIT 1 ROLLBACK

PROMPT ________________________________________________
PROMPT Creating PUR_RATES_&&1 table...
DECLARE
	v_table_exists		INTEGER := 0;
BEGIN
	SELECT	COUNT(*)
	INTO		v_table_exists
	FROM		user_tables
	WHERE		table_name = 'PUR_RATES_&&1';

	IF v_table_exists > 0 THEN
		EXECUTE IMMEDIATE 'DROP TABLE pur_rates_&&1';
	END IF;
EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/
show errors

CREATE TABLE pur_rates_&&1
   (years			VARCHAR2(20),
	 year				INTEGER,
	 use_no			INTEGER,
	 ago_ind			VARCHAR2(1),
	 chem_code		INTEGER,
	 chemname		VARCHAR2(500),
	 ai_name			VARCHAR2(500),
	 ai_adjuvant	VARCHAR2(1),
	 prodno			INTEGER,
	 regno_short	VARCHAR2(20),
	 product_name	VARCHAR2(200),
	 site_code		INTEGER,
	 site_general	VARCHAR2(200),
	 unit_treated	VARCHAR2(1),
	 ai_rate			NUMBER,
	 log_ai_rate	NUMBER,
	 ai_group		INTEGER)
NOLOGGING
PCTUSED 95
PCTFREE 3
STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0)
TABLESPACE pur_report;

DECLARE
	v_num_years		INTEGER;
BEGIN
	FOR v_num_years IN 1..(&&2) LOOP

		INSERT INTO pur_rates_&&1
			(years, year, use_no, ago_ind, chem_code, chemname, ai_name, ai_adjuvant,
			 prodno, regno_short, product_name, site_code, site_general,
			 unit_treated, ai_rate, log_ai_rate)
		SELECT	(&&1 - &&2 + 1) ||'-'||(&&1), year, use_no,
					CASE WHEN record_id IN ('2', 'C') OR site_code < 100 OR site_code > 29500
						  THEN 'N' ELSE 'A' END,
					pcma.chem_code, chemname, ai_name, NVL(adjuvant, 'N'),
					prodno, mfg_firmno||'-'||label_seq_no, product_name,
					NVL(site_code, -1), NVL(site_general, 'UNKNOWN'),
					CASE
						WHEN pur.unit_treated = 'A' THEN 'A'
						WHEN pur.unit_treated = 'S' THEN 'A'
						WHEN pur.unit_treated = 'C' THEN 'C'
						WHEN pur.unit_treated = 'K' THEN 'C'
						WHEN pur.unit_treated = 'P' THEN 'P'
						WHEN pur.unit_treated = 'T' THEN 'P'
						ELSE 'U'
					END,
					lbs_prd_used*prodchem_pct/
							(100*CASE
									WHEN pur.unit_treated = 'A' THEN acre_treated
									WHEN pur.unit_treated = 'S' THEN acre_treated/43560
									WHEN pur.unit_treated = 'C' THEN acre_treated
									WHEN pur.unit_treated = 'K' THEN acre_treated*1000
									WHEN pur.unit_treated = 'P' THEN acre_treated
									WHEN pur.unit_treated = 'T' THEN acre_treated*2000
									ELSE acre_treated
								END),
					log(10, lbs_prd_used*prodchem_pct/
							(100*CASE
									WHEN pur.unit_treated = 'A' THEN acre_treated
									WHEN pur.unit_treated = 'S' THEN acre_treated/43560
									WHEN pur.unit_treated = 'C' THEN acre_treated
									WHEN pur.unit_treated = 'K' THEN acre_treated*1000
									WHEN pur.unit_treated = 'P' THEN acre_treated
									WHEN pur.unit_treated = 'T' THEN acre_treated*2000
									ELSE acre_treated
								END))
		FROM		pur LEFT JOIN prod_chem_major_ai pcma USING (prodno)
						 LEFT JOIN product USING (prodno)
						 LEFT JOIN ai_names ain ON pcma.chem_code = ain.chem_code
						 LEFT JOIN chem_adjuvant ca ON pcma.chem_code = ca.chem_code
						 LEFT JOIN pur_site_groups USING (site_code)
						 JOIN ai_num_recs_sum_&&1 anrs
										ON pcma.chem_code = anrs.chem_code AND
											CASE WHEN record_id IN ('2', 'C') OR site_code < 100 OR site_code > 29500
													THEN 'N' ELSE 'A' END = anrs.ago_ind AND
											CASE
												WHEN pur.unit_treated = 'A' THEN 'A'
												WHEN pur.unit_treated = 'S' THEN 'A'
												WHEN pur.unit_treated = 'C' THEN 'C'
												WHEN pur.unit_treated = 'K' THEN 'C'
												WHEN pur.unit_treated = 'P' THEN 'P'
												WHEN pur.unit_treated = 'T' THEN 'P'
												ELSE 'U'
											END = anrs.unit_treated
		WHERE		year BETWEEN (&&1 - v_num_years + 1) AND &&1 AND
					acre_treated > 0 AND
					lbs_prd_used > 0 AND
					pur.unit_treated IN ('A', 'S', 'C', 'K', 'P', 'T', 'U') AND
					num_years = v_num_years;

		COMMIT;
	END LOOP;

EXCEPTION
	WHEN OTHERS THEN
		DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/
show errors

EXIT 0

