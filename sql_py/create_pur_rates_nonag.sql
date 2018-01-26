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
PROMPT Creating PUR_RATES_NONAG_&&1 table...
DECLARE
	v_table_exists		INTEGER := 0;
BEGIN
	SELECT	COUNT(*)
	INTO		v_table_exists
	FROM		user_tables
	WHERE		table_name = 'PUR_RATES_NONAG_&&1';

	IF v_table_exists > 0 THEN
		EXECUTE IMMEDIATE 'DROP TABLE pur_rates_nonag_&&1';
	END IF;
EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/
show errors

CREATE TABLE pur_rates_nonag_&&1
   (years				VARCHAR2(20),
	 year					INTEGER,
	 use_no				INTEGER,
	 chem_code			INTEGER,
	 chemname			VARCHAR2(500),
	 ai_name				VARCHAR2(500),
	 prod_adjuvant		VARCHAR2(1),
	 ai_adjuvant		VARCHAR2(1),
	 prodno				INTEGER,
	 regno_short		VARCHAR2(20),
	 site_code			INTEGER,
	 site_general		VARCHAR2(200),
	 lbs_ai				NUMBER,
	 log_lbs_ai			NUMBER,
	 lbs_ai_app			NUMBER,
	 log_lbs_ai_app	NUMBER,
	 ai_group			INTEGER)
NOLOGGING
PCTUSED 95
PCTFREE 3
STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0)
TABLESPACE pur_report;

DECLARE
	v_num_years		INTEGER;
BEGIN
	FOR v_num_years IN 1..(&&2) LOOP

		INSERT INTO pur_rates_nonag_&&1
			(years, year, use_no, chem_code, chemname, ai_name, prod_adjuvant, ai_adjuvant,
			 prodno, regno_short, site_code, site_general,
			 lbs_ai, log_lbs_ai, lbs_ai_app, log_lbs_ai_app)
		SELECT	(&&1 - &&2 + 1) ||'-'||(&&1), year, use_no,
					pcma.chem_code, chemname, ai_name, NVL(pa.adjuvant, 'N'), NVL(ca.adjuvant, 'N'),
					prodno, mfg_firmno||'-'||label_seq_no,
					NVL(site_code, -1), NVL(site_general, 'UNKNOWN'),
					lbs_prd_used*prodchem_pct/100,
					log(10, lbs_prd_used*prodchem_pct/100),
					lbs_prd_used*prodchem_pct/
						(100*CASE WHEN applic_cnt IS NULL OR applic_cnt = 0 THEN 1 ELSE applic_cnt END),
					log(10, lbs_prd_used*prodchem_pct/
						(100*CASE WHEN applic_cnt IS NULL OR applic_cnt = 0 THEN 1 ELSE applic_cnt END))
		FROM		pur LEFT JOIN prod_chem_major_ai pcma USING (prodno)
						 LEFT JOIN product USING (prodno)
						 LEFT JOIN prod_adjuvant pa USING (prodno)
						 LEFT JOIN ai_names ain ON pcma.chem_code = ain.chem_code
						 LEFT JOIN chem_adjuvant ca ON pcma.chem_code = ca.chem_code
						 LEFT JOIN pur_site_groups USING (site_code)
						 JOIN ai_num_recs_nonag_sum_&&1 anrs ON pcma.chem_code = anrs.chem_code
		WHERE		year BETWEEN (&&1 - v_num_years + 1) AND &&1 AND
					record_id IN ('2', 'C') AND
					lbs_prd_used > 0 AND
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

