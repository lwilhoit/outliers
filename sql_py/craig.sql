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


DROP TABLE wiconst;
CREATE TABLE wiconst 
   (well    INTEGER,
	 depth   NUMBER)
NOLOGGING
PCTUSED 95
PCTFREE 3
STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0)
TABLESPACE pur_report;

INSERT INTO wiconst VALUES (1, 10);
INSERT INTO wiconst VALUES (2, 20);
INSERT INTO wiconst VALUES (3, NULL);
INSERT INTO wiconst VALUES (4, 30);
INSERT INTO wiconst VALUES (5, NULL);
INSERT INTO wiconst VALUES (6, 40);

CREATE TABLE new_const  
   (well    INTEGER,
	 depth   NUMBER)
NOLOGGING
PCTUSED 95
PCTFREE 3
STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0)
TABLESPACE pur_report;

INSERT INTO new_const  VALUES (1, 100);
INSERT INTO new_const  VALUES (2, 200);
INSERT INTO new_const  VALUES (3, 300);
INSERT INTO new_const  VALUES (4, 400);
INSERT INTO new_const  VALUES (5, 500);
INSERT INTO new_const  VALUES (6, 600);


UPDATE wiconst wc
   SET   wc.depth = (SELECT nc.depth FROM new_const nc WHERE nc.well = wc.well)
   WHERE wc.depth IS NULL;




