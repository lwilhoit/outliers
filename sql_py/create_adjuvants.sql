SET pause OFF
SET pagesize 75
SET linesize 120
SET termout ON
SET feedback ON
SET document OFF
SET verify OFF
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

/*
CREATE TABLE prod_adjuvant
   (prodno		NUMBER(5),
    adjuvant   VARCHAR2(1))
	PCTUSED 95
   PCTFREE 3
   STORAGE(INITIAL 1M NEXT 1M PCTINCREASE 0)
   NOLOGGING;

CREATE TABLE chem_adjuvant
   (chem_code           NUMBER(5),
    non_adjuvant_prods  INTEGER,
    adjuvant_prods      INTEGER,
    adjuvant            VARCHAR2(1))
	PCTUSED 95
   PCTFREE 3
   STORAGE(INITIAL 1M NEXT 1M PCTINCREASE 0)
   NOLOGGING;

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


PROMPT ________________________________________________
PROMPT Create CHEM_ADJUVANT table...
DECLARE
	v_table_exists		INTEGER := 0;
BEGIN
	SELECT	COUNT(*)
	INTO		v_table_exists
	FROM		user_tables
	WHERE		table_name = 'CHEM_ADJUVANT';

	IF v_table_exists > 0 THEN
		EXECUTE IMMEDIATE 'DROP TABLE CHEM_ADJUVANT';
      print_info('Table CHEM_ADJUVANT exists, so it was deleted.', :log_level);
   ELSE
      print_info('Table CHEM_ADJUVANT does not exist.', :log_level);
   END IF;

EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/
show errors

CREATE TABLE chem_adjuvant
   (chem_code           NUMBER(5),
    non_adjuvant_prods  INTEGER,
    adjuvant_prods      INTEGER,
    adjuvant            VARCHAR2(1))
	PCTUSED 95
   PCTFREE 3
   STORAGE(INITIAL 1M NEXT 1M PCTINCREASE 0)
   NOLOGGING
   TABLESPACE pur_report;


DECLARE
   v_num_ais   INTEGER;
   v_num_recs  INTEGER;
   v_adjuvant  BOOLEAN;

   -- Get all AIs
   CURSOR chem_cur IS
      SELECT   chem_code,
               SUM(DECODE(adjuvant,'N',1)) non_adjuvant_prods,
               SUM(DECODE(adjuvant,'Y',1)) adjuvant_prods
      FROM     prod_chem JOIN prod_adjuvant USING (prodno)
      WHERE    chem_code > 0
      GROUP BY chem_code;

   -- Get all non-adjuvant products which contain this AI.
   CURSOR prod_cur(cc IN NUMBER) IS
      SELECT   prodno
      FROM     prod_chem JOIN prod_adjuvant USING (prodno)
      WHERE    adjuvant = 'N' AND
               chem_code = cc;

BEGIN
   FOR chem_rec IN chem_cur LOOP
      IF chem_rec.adjuvant_prods IS NULL THEN
         INSERT INTO chem_adjuvant VALUES
            (chem_rec.chem_code, chem_rec.non_adjuvant_prods, NULL, 'N');
      ELSE
         v_adjuvant := TRUE;

         IF chem_rec.non_adjuvant_prods IS NOT NULL THEN
            FOR prod_rec IN prod_cur(chem_rec.chem_code) LOOP
               SELECT   COUNT(DISTINCT DECODE(chem_code, 0, NULL, chem_code))
               INTO     v_num_ais
               FROM     prod_chem
               WHERE    prodno = prod_rec.prodno;

               IF v_num_ais = 1 THEN
                  v_adjuvant := FALSE;
               END IF;
            END LOOP;
         END IF;

         IF v_adjuvant THEN
            INSERT INTO chem_adjuvant VALUES
               (chem_rec.chem_code, chem_rec.non_adjuvant_prods, chem_rec.adjuvant_prods, 'Y');
         ELSE
            INSERT INTO chem_adjuvant VALUES
               (chem_rec.chem_code, chem_rec.non_adjuvant_prods, chem_rec.adjuvant_prods, 'N');
         END IF;

      END IF;

      COMMIT;

   END LOOP;

   SELECT   count(*)
   INTO     v_num_recs
   FROM     chem_adjuvant;

   print_info('Table CHEM_ADJUVANT was created, with '||v_num_recs ||' number of recrods.', :log_level);

EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/
show errors


--GRANT SELECT ON prod_adjuvant to public;
--GRANT SELECT ON chem_adjuvant to public;

PROMPT ________________________________________________

EXIT 0

