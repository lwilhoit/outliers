SET pause OFF
SET pagesize 75
SET linesize 120
SET termout ON
SET feedback ON
SET document ON
SET verify ON
SET trimspool ON
SET numwidth 11
SET SERVEROUTPUT ON
WHENEVER SQLERROR EXIT 1 ROLLBACK
WHENEVER OSERROR EXIT 1 ROLLBACK

/*
   Table prod_adjuvant is a list of all products, and
   a indicator of whether it is an adjuvant or not.

   Table chem_adjuvant is a list of all AIs and whether they
   can be considered adjuvants or not.  An AI is considered
   an adjuvant if it occurs in at least one product that is
   an adjuvant, but is not the sole AI in any non-adjuvant product.

	Also created are copies of these tables with the creation date
	added to the end of their names.  Both are needed because
	different standard queries use one or the other of these names.

 */

VARIABLE log_level NUMBER;

PROMPT ________________________________________________
PROMPT Create PROD_ADJUVANT table...
DECLARE
	v_table_exists		INTEGER := 0;
BEGIN
   :log_level := &&1;

   SELECT	COUNT(*)
	INTO		v_table_exists
	FROM		user_tables
	WHERE		table_name = 'PROD_ADJUVANT';

	IF v_table_exists > 0 THEN
		EXECUTE IMMEDIATE 'DROP TABLE PROD_ADJUVANT';
      print_info('Table PROD_ADJUVANT exists, so it was deleted.', :log_level);
   ELSE
      print_info('Table PROD_ADJUVANT does not exist.', :log_level);
   END IF;

EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/
show errors

CREATE TABLE prod_adjuvant
   (prodno		NUMBER(5),
    adjuvant   VARCHAR2(1))
	PCTUSED 95
   PCTFREE 3
   STORAGE(INITIAL 1M NEXT 1M PCTINCREASE 0)
   NOLOGGING
   TABLESPACE pur_report;


INSERT INTO prod_adjuvant
   SELECT   prodno, 'N'
   FROM     product;

UPDATE prod_adjuvant
SET   adjuvant = 'Y'
WHERE prodno IN
      (SELECT  prodno
       FROM    prod_type_pesticide
       WHERE   typepest_cd = 'A0');

COMMIT;

GRANT SELECT ON prod_adjuvant to public;

PROMPT ________________________________________________

EXIT 0

