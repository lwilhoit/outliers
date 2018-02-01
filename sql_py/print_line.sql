

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

CREATE OR REPLACE PROCEDURE print_debug(line_str IN VARCHAR2, log_level IN NUMBER) AS
BEGIN
   IF log_level = 10 THEN
      DBMS_OUTPUT.PUT_LINE(line_str);
   END IF;
END;
/

CREATE OR REPLACE PROCEDURE print_info(line_str IN VARCHAR2, log_level IN NUMBER) AS
BEGIN
   IF log_level BETWEEN 10 AND 20 THEN
      DBMS_OUTPUT.PUT_LINE(line_str);
   END IF;
END;
/

CREATE OR REPLACE PROCEDURE print_warning(line_str IN VARCHAR2, log_level IN NUMBER) AS
BEGIN
   IF log_level BETWEEN 10 AND 30 THEN
      DBMS_OUTPUT.PUT_LINE(line_str);
   END IF;
END;
/

CREATE OR REPLACE PROCEDURE print_error(line_str IN VARCHAR2, log_level IN NUMBER) AS
BEGIN
   IF log_level BETWEEN 10 AND 40 THEN
      DBMS_OUTPUT.PUT_LINE(line_str);
   END IF;
END;
/

CREATE OR REPLACE PROCEDURE print_critical(line_str IN VARCHAR2, log_level IN NUMBER) AS
BEGIN
   IF log_level BETWEEN 10 AND 50 THEN
      DBMS_OUTPUT.PUT_LINE(line_str);
   END IF;
END;
/

show errors

  
/*
DECLARE
   line_str    VARCHAR2(100) := 'test2';
   log_level   INTEGER := 10;

  */
