SET pause OFF
SET pagesize 75
SET linesize 120
SET termout ON
SET feedback ON
SET document ON
SET verify ON
SET trimspool ON
SET numwidth 11

SELECT   *
FROM     county
&&1 WHERE    county_cd < '10' &&2
ORDER BY county_cd;

-- EXIT

/*
SELECT   *
FROM     county
 WHERE    county_cd < '10' 
ORDER BY county_cd;
*/


