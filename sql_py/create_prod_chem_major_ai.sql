/* Create table PROD_CHEM_MAJOR_AI, which is a subset of table PROD_CHEM containing
	only records where the percent of AI in a product is greater than 75% of the maximum
	percent AI in that product.  The reason for this is that outliers are determined by
	looking at rates of use of AIs, but minor AIs in a product will have a low rate and
	are probably not useful and even misleading for finding high rates.  This table is
	only used for the outlier scripts. It may need to be recreated occasionally to
	update it for new products.
 */
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

VARIABLE log_level NUMBER;

PROMPT ________________________________________________
PROMPT Creating PROD_CHEM_MAJOR_AI table...
DECLARE
	v_table_exists		INTEGER := 0;
BEGIN
   :log_level := &&1;

	SELECT	COUNT(*)
	INTO		v_table_exists
	FROM		user_tables
	WHERE		table_name = 'PROD_CHEM_MAJOR_AI';

   IF v_table_exists > 0 THEN
      EXECUTE IMMEDIATE 'DROP TABLE prod_chem_major_ai';
      print_info('Table PROD_CHEM_MAJOR_AI exists, so it was deleted.', :log_level);
   ELSE
      print_info('Table PROD_CHEM_MAJOR_AI does not exist.', :log_level);
   END IF;

EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/
show errors

CREATE TABLE prod_chem_major_ai
   (prodno			INTEGER,
	 chem_code		INTEGER,
	 prodchem_pct	NUMBER,
	 main_ai_pct	NUMBER)
NOLOGGING
PCTUSED 95
PCTFREE 3
STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0)
TABLESPACE pur_report;

INSERT INTO prod_chem_major_ai
	SELECT	prodno, chem_code, prodchem_pct,
				(SELECT MAX(prodchem_pct) FROM prod_chem
						WHERE prodno = pc.prodno AND chem_code BETWEEN 1 AND 90000 AND chem_code != 486)
	FROM		prod_chem pc
	WHERE		chem_code BETWEEN 1 AND 90000 AND
				chem_code != 486 AND     -- chem_code 486 is piperonyl butoxide.
				prodchem_pct >
				0.75*(SELECT MAX(prodchem_pct) FROM prod_chem
						WHERE prodno = pc.prodno AND chem_code BETWEEN 1 AND 90000 AND chem_code != 486);

COMMIT;

PROMPT ________________________________________________

EXIT 0

