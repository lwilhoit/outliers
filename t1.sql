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

DECLARE
   v_fixed1    NUMBER;
   v_max_label NUMBER;
BEGIN
   v_fixed1 := NULL;
   v_max_label := 6;

   --v_fixed1 := GREATEST(NVL(v_fixed1, 0), NVL(v_max_label, 0));
   v_fixed1 := COALESCE(GREATEST(v_fixed1, v_max_label), v_fixed1, v_max_label);

   IF v_fixed1 IS NOT NULL THEN
      DBMS_OUTPUT.PUT_LINE('v_fixed1 = '||v_fixed1);
   ELSE
      DBMS_OUTPUT.PUT_LINE('v_fixed1 is null');
   END IF;

EXCEPTION
	WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/
show errors

