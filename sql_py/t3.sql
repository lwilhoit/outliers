SET pause OFF
SET pagesize 75
SET linesize 120
SET termout ON
SET feedback ON
SET document ON
SET verify ON
SET trimspool ON
SET numwidth 11

variable comment1 VARCHAR2(10)
variable comment2 VARCHAR2(10)

DECLARE
BEGIN

   EXECUTE IMMEDIATE('UPDATE temp SET rate1 = 1');
   COMMIT;

EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/
show errors


--EXIT

/*
   --:comment1 := '&&1';
   --:comment2 := '&&2';

:comment1
SELECT   *
FROM     county
WHERE    county_cd < '10' 
ORDER BY county_cd;
:comment2

SELECT   *
FROM     county
&&1 WHERE    county_cd < '10' &&2
ORDER BY county_cd;

SELECT   *
FROM     county
 WHERE    county_cd < '10' 
ORDER BY county_cd;
*/


