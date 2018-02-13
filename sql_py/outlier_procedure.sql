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


CREATE TABLE ai_outlier_stats
   (year						INTEGER,
  	 chem_code				INTEGER,
	 ai_group				INTEGER,
    ago_ind        		VARCHAR2(1),
    unit_treated 			VARCHAR2(1),
	 num_recs     			INTEGER,
	 num_recs_trim			INTEGER,
	 median_rate			NUMBER,
	 mean_rate				NUMBER,
	 mean_rate_trim		NUMBER,
	 sd_rate		     		NUMBER,
	 sd_rate_trim_orig 	NUMBER,
	 sd_rate_trim     	NUMBER,
	 sum_sq_rate_trim		NUMBER,
	 med50     				NUMBER,
	 med100    				NUMBER,
	 med150    				NUMBER,
	 med200    				NUMBER,
	 med250    				NUMBER,
	 med300    				NUMBER,
	 med400    				NUMBER,
	 med500    				NUMBER,
	 mean3sd   				NUMBER,
	 mean5sd   				NUMBER,
	 mean7sd   				NUMBER,
	 mean8sd   				NUMBER,
	 mean10sd  				NUMBER,
	 mean12sd  				NUMBER,
	 mean15sd  				NUMBER)
NOLOGGING
PCTUSED 95
PCTFREE 3
STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0)
TABLESPACE pur_report;


CREATE TABLE outlier_stats
   (year						INTEGER,
  	 chem_code				INTEGER,
	 ai_group				INTEGER,
	 ai_adjuvant			VARCHAR2(1),
    ai_rate_type        VARCHAR2(20),
	 site_general			VARCHAR2(100),
    site_code           INTEGER,
    site_type           VARCHAR2(20),
	 regno_short			VARCHAR2(20),
    prodno              INTEGER,
    ago_ind        		VARCHAR2(1),
    unit_treated 			VARCHAR2(1),
    unit_treated_report VARCHAR2(1),
	 num_recs     			INTEGER,
	 median_rate			NUMBER,
	 mean3sd   				NUMBER,
	 mean5sd   				NUMBER,
	 mean7sd   				NUMBER,
	 mean8sd   				NUMBER,
	 mean10sd  				NUMBER,
	 mean12sd  				NUMBER,
	 mean15sd  				NUMBER)
NOLOGGING
PCTUSED 95
PCTFREE 3
STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0)
TABLESPACE pur_report;

DROP TABLE ago_ind_table;
CREATE TABLE ago_ind_table
   (ago_ind    VARCHAR2(1),
    record_id  VARCHAR2(1))
NOLOGGING
PCTUSED 95
PCTFREE 3
TABLESPACE pur_report;

INSERT INTO ago_ind_table VALUES ('A', 'A');
INSERT INTO ago_ind_table VALUES ('A', 'B');
INSERT INTO ago_ind_table VALUES ('N', 'C');
COMMIT;

CREATE TABLE unit_treated_table
   (unit_treated           VARCHAR2(1),
    unit_treated_report     VARCHAR2(1))
NOLOGGING
PCTUSED 95
PCTFREE 3
TABLESPACE pur_report;

INSERT INTO unit_treated_table VALUES ('A', 'A');
INSERT INTO unit_treated_table VALUES ('A', 'S');
INSERT INTO unit_treated_table VALUES ('C', 'C');
INSERT INTO unit_treated_table VALUES ('C', 'K');
INSERT INTO unit_treated_table VALUES ('P', 'P');
INSERT INTO unit_treated_table VALUES ('P', 'T');
INSERT INTO unit_treated_table VALUES ('U', 'U');
COMMIT;

CREATE TABLE site_type_table
   (site_type     VARCHAR2(20),
    site_code     INTEGER)
NOLOGGING
PCTUSED 95
PCTFREE 3
TABLESPACE pur_report;

INSERT INTO site_type_table VALUES('WATER', 65000);
INSERT INTO site_type_table VALUES('WATER', 65011);
INSERT INTO site_type_table VALUES('WATER', 65015);
INSERT INTO site_type_table VALUES('WATER', 65021);
INSERT INTO site_type_table VALUES('WATER', 65026);
INSERT INTO site_type_table VALUES('WATER', 65029);
INSERT INTO site_type_table VALUES('WATER', 65503);
INSERT INTO site_type_table VALUES('WATER', 65505);
COMMIT;


DROP TABLE site_type_table2;
CREATE TABLE site_type_table2
   (site_type     VARCHAR2(20),
    site_code     INTEGER)
NOLOGGING
PCTUSED 95
PCTFREE 3
TABLESPACE pur_report;

INSERT INTO site_type_table2
   SELECT   CASE WHEN site_code IN (65000, 65011, 65015, 65021, 65026, 65029, 65503, 65505) THEN 'WATER' 
               ELSE 'OTHER' END, site_code
   FROM     pur_site
   WHERE    extra IS NULL;

COMMIT;


DROP TABLE outlier_rate_stats;
CREATE TABLE outlier_rate_stats
   (year						INTEGER,
  	 chem_code				INTEGER,
    ai_group            INTEGER,
    ago_ind        		VARCHAR2(1),
    record_id           VARCHAR2(1),
    unit_treated 			VARCHAR2(1),
    unit_treated_report VARCHAR2(1),
    site_general        VARCHAR2(100),
    site_code           INTEGER,
    regno_short			VARCHAR2(20),
    prodno              INTEGER,
	 mean3sd   				NUMBER)
NOLOGGING
PCTUSED 95
PCTFREE 3
STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0)
TABLESPACE pur_report;

INSERT INTO outlier_rate_stats
   SELECT   year, chem_code, NVL(ai_group, 1), ago_ind, record_id, unit_treated, unit_treated_report,
            site_general, site_code, regno_short, prodno, 
            CASE WHEN unit_treated_report = 'S' THEN mean3sd*43560
                 WHEN unit_treated_report = 'K' THEN mean3sd/1000
                 WHEN unit_treated_report = 'T' THEN mean3sd/2000
                 ELSE mean3sd
            END
   FROM     pur_report.ai_outlier_stats aios  LEFT JOIN pur_report.ai_group_stats using (year, chem_code, ai_group, ago_ind, unit_treated)
                                   LEFT JOIN pur_site_groups using (site_general)
                                   LEFT JOIN product ON regno_short = mfg_firmno||'-'||label_seq_no
                                   LEFT JOIN ago_ind_table using (ago_ind)
                                   LEFT JOIN unit_treated_table using (unit_treated)                             
;

COMMIT;


DROP TABLE outlier_rate_stats;
CREATE TABLE outlier_rate_stats
   (year						INTEGER,
  	 chem_code				INTEGER,
    ai_group            INTEGER,
    ago_ind        		VARCHAR2(1),
    record_id           VARCHAR2(1),
    unit_treated 			VARCHAR2(1),
    unit_treated_report VARCHAR2(1),
    site_general        VARCHAR2(100),
    site_code           INTEGER,
    regno_short			VARCHAR2(20),
    prodno              INTEGER,
	 mean3sd   				NUMBER)
NOLOGGING
PCTUSED 95
PCTFREE 3
STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0)
TABLESPACE pur_report;

DECLARE
   v_unit_factor        NUMBER;
   v_unit_treated       VARCHAR2(1);

   v_ago_ind            VARCHAR2(1);
   v_ai_group_rate      INTEGER := NULL;
   v_ai_group_lbsapp    INTEGER := NULL;
   v_ai_rate_type       VARCHAR2(100);
   v_lbs_ai_app_type    VARCHAR2(100);
   v_site_type          VARCHAR2(100);
   v_ai_adjuvant        VARCHAR2(1);

   v_regno_short        VARCHAR2(100);
   v_site_general       VARCHAR2(50);
   v_chem_code          INTEGER;


   CURSOR pur_cur AS
      SELECT   DISTINCT record_id, prodno, site_code, unit_treated
      FROM     pur_rates_2017;

   CURSOR ai_cur(p_prodno IN NUMBER) AS
      SELECT   chem_code
      FROM     prod_chem_major_ai
      WHERE    prodno = p_prodno;
BEGIN
   FOR pur_rec IN pur_cur LOOP

      IF pur_rec.record_id IN ('2', 'C') OR pur_rec.site_code < 100 OR 
            (pur_rec.site_code > 29500 AND pur_rec.site_code NOT IN (30000, 30005, 40008, 66000)) THEN
         v_ago_ind := 'N'; 
      ELSE 
         v_ago_ind :- 'A';
      END IF;

      BEGIN
        SELECT site_general
        INTO   v_site_general
        FROM   pur_site_groups
        WHERE  site_code = p_site_code;
      EXCEPTION
        WHEN OTHERS THEN
            v_site_general := NULL;
      END;

      BEGIN
        SELECT adjuvant
        INTO   v_ai_adjuvant
        FROM   chem_adjuvant
        WHERE  chem_code = p_chem_code;
      EXCEPTION
        WHEN OTHERS THEN
            v_ai_adjuvant := 'N';
      END;

      BEGIN
        SELECT mfg_firmno||'-'||label_seq_no
        INTO   v_regno_short
        FROM   product
        WHERE  prodno = p_prodno;
      EXCEPTION
        WHEN OTHERS THEN
            v_regno_short := NULL;
      END;

    /*********************************************************************************
        Get outliers in rates of use (pounds AI per unit treated).
        These includes some non-ag records when a unit treated is reported.
     ********************************************************************************/
      IF pur_rec.acre_treated > 0 AND pur_rec.unit_treated IS NOT NULL THEN
         IF pur_rec.unit_treated = 'S' THEN
            v_unit_treated := 'A';
            v_unit_factor := 43560;
         ELSE IF pur_rec.unit_treated = 'K' THEN
            v_unit_treated := 'C';
            v_unit_factor := 1/1000;
         ELSE IF pur_rec.unit_treated = 'T' THEN
            v_unit_treated := 'P';
            v_unit_factor := 1/2000;
         ELSE 
            v_unit_treated := pur_rec.unit_treated;
            v_unit_factor := 1;
         END IF;

         FOR ai_rec IN ai_cur(pur_rec.prodno) LOOP
            v_chem_code := ai_rec.chem_code;

            /* Get the AI rate type for this AI and type of application:
             */
            IF pur_rec.ai_adjuvant = 'Y' THEN
               v_ai_rate_type := 'ADJUVANT';
            ELSE
               BEGIN
                  SELECT   ai_rate_type
                  INTO     v_ai_rate_type
                  FROM     fixed_outlier_rates_ais
                  WHERE    ago_ind = v_ago_ind AND 
                           unit_treated = v_unit_treated AND
                           site_type = v_site_type AND
                           chem_code = v_chem_code;
               EXCEPTION
                  WHEN OTHERS THEN
                     v_ai_rate_type := 'NORMAL';
               END;
            END IF;


            /* Get the fixed outlier limits.
             */
            BEGIN
               SELECT	log_rate1, log_rate2, log_rate3
               INTO		v_fixed1_rate, v_fixed2_rate, v_fixed3_rate
               FROM		fixed_outlier_rates
               WHERE		ago_ind = pur_rec.ago_ind AND
                        unit_treated = pur_rec.unit_treated AND
                        ai_rate_type = v_ai_rate_type AND
                        site_type = v_site_type;
            EXCEPTION
               WHEN OTHERS THEN
                  v_fixed1_rate := NULL;
                  v_fixed2_rate := NULL;
                  v_fixed3_rate := NULL;
            END;

         END LOOP;



      END IF;

   END LOOP;

EXCEPTION
	WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(SQLERRM||'; use_no = '||v_use_no);
END;
/
show errors


   CURSOR aios_cur AS
      SELECT   *
      FROM     ai_outlier_stats;

   CURSOR ors_cur AS
      SELECT   *
      FROM     outlier_rate_stats;


SELECT   *
FROM     outlier_rate_stats
ORDER BY chem_code, ai_group, ago_ind, unit_treated, site_general, regno_short, prodno, record_id, unit_treated_report;


DROP TABLE outlier_fixed_rate_stats;
CREATE TABLE outlier_fixed_rate_stats
   (chem_code				INTEGER,
    ai_rate_type        VARCHAR2(20),
    ago_ind        		VARCHAR2(1),
    record_id           VARCHAR2(1),
    unit_treated 			VARCHAR2(1),
    unit_treated_report VARCHAR2(1),
    site_type           VARCHAR2(20),
    site_code           INTEGER,
    prodno              INTEGER,
	 rate2   				NUMBER)
NOLOGGING
PCTUSED 95
PCTFREE 3
STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0)
TABLESPACE pur_report;

INSERT INTO outlier_fixed_rate_stats
   SELECT   chem_code, ai_rate_type, ago_ind, record_id, unit_treated, unit_treated_report,
            site_type, site_code, prodno,
            CASE WHEN unit_treated_report = 'S' THEN rate2*43560
                 WHEN unit_treated_report = 'K' THEN rate2/1000
                 WHEN unit_treated_report = 'T' THEN rate2/2000
                 ELSE rate2
            END
   FROM     fixed_outlier_rates LEFT JOIN ago_ind_table using (ago_ind)
                                LEFT JOIN unit_treated_table using (unit_treated)
                                LEFT JOIN site_type_table USING (site_type)
                                LEFT JOIN fixed_outlier_rates_ais USING (ai_rate_type, ago_ind, unit_treated, site_type)
                                left JOIN prod_chem_major_ai using (chem_code);
                                
COMMIT;

SELECT   *
FROM     outlier_fixed_rate_stats
ORDER BY chem_code, ai_rate_type, ago_ind, unit_treated, site_type, record_id, unit_treated_report, site_code, prodno;

/* Some records in outlier_fixed_rate_stats have NULL chem_code; I don't know why.
 */
SELECT   *
FROM     fixed_outlier_rates_ais left JOIN prod_chem_major_ai using (chem_code)
ORDER BY chem_code, prodno;

SELECT   *
FROM     fixed_outlier_rates LEFT JOIN fixed_outlier_rates_ais using (ai_rate_type, ago_ind, unit_treated, site_type)
                             left JOIN prod_chem_major_ai using (chem_code)
ORDER BY chem_code, prodno;



/* Examples of how to use this table:
 */
SELECT   *
FROM     outlier_fixed_rate_stats 
WHERE    prodno = 591 AND
         record_id = 'C' AND
         unit_treated_report = 'A' AND
         site_type = 
            CASE WHEN record_id = 'C' THEN 
               CASE WHEN site_code IN (SELECT site_code FROM site_type_table) THEN 'WATER' 
                  ELSE 'OTHER' END
               ELSE 'ALL'
            END;

SELECT   *
FROM     outlier_fixed_rate_stats 
WHERE    prodno = 63665 AND
         record_id = 'B' AND
         unit_treated_report = 'S' AND
         site_type = 
            CASE WHEN record_id = 'C' THEN 
               CASE WHEN site_code IN (SELECT site_code FROM site_type_table) THEN 'WATER' 
                  ELSE 'OTHER' END
               ELSE 'ALL'
            END;



/* Same as above but using site_type_table2, which has listed all sites.
   This creates a very large table - nearly 18 million records.
 */
DROP TABLE outlier_fixed_rate_stats2;
CREATE TABLE outlier_fixed_rate_stats2
   (chem_code				INTEGER,
    ai_rate_type        VARCHAR2(20),
    ago_ind        		VARCHAR2(1),
    record_id           VARCHAR2(1),
    unit_treated 			VARCHAR2(1),
    unit_treated_report VARCHAR2(1),
    site_type           VARCHAR2(20),
    site_code           INTEGER,
    prodno              INTEGER,
	 rate2   				NUMBER)
NOLOGGING
PCTUSED 95
PCTFREE 3
STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0)
TABLESPACE pur_report;

INSERT INTO outlier_fixed_rate_stats2
   SELECT   chem_code, ai_rate_type, ago_ind, record_id, unit_treated, unit_treated_report,
            site_type, site_code, prodno,
            CASE WHEN unit_treated_report = 'S' THEN rate2*43560
                 WHEN unit_treated_report = 'K' THEN rate2/1000
                 WHEN unit_treated_report = 'T' THEN rate2/2000
                 ELSE rate2
            END
   FROM     fixed_outlier_rates LEFT JOIN ago_ind_table using (ago_ind)
                                LEFT JOIN unit_treated_table using (unit_treated)
                                LEFT JOIN site_type_table2 USING (site_type)
                                LEFT JOIN fixed_outlier_rates_ais USING (ai_rate_type, ago_ind, unit_treated, site_type)
                                left JOIN prod_chem_major_ai using (chem_code);
                                
COMMIT;

SELECT   *
FROM     outlier_fixed_rate_stats2
ORDER BY chem_code, ai_rate_type, ago_ind, unit_treated, site_type, record_id, unit_treated_report, site_code, prodno;








/*
DROP TABLE outlier_rate_stats1;
CREATE TABLE outlier_rate_stats1
   (year						INTEGER,
  	 chem_code				INTEGER,
    ai_group            INTEGER,
    ago_ind        		VARCHAR2(1),
    unit_treated 			VARCHAR2(1),
    site_general        VARCHAR2(20),
    regno_short			VARCHAR2(20),
	 mean3sd   				NUMBER)
NOLOGGING
PCTUSED 95
PCTFREE 3
STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0)
TABLESPACE pur_report;

INSERT INTO outlier_rate_stats1
   SELECT   year, chem_code, ai_group, ago_ind, unit_treated,
            site_general, regno_short, mean3sd
   FROM     ai_outlier_stats aios  LEFT JOIN ai_group_stats using (year, chem_code, ai_group, ago_ind, unit_treated);

COMMIT;

SELECT   *
FROM     outlier_rate_stats1
ORDER BY chem_code, ai_group, ago_ind, unit_treated, site_general, regno_short;


DROP TABLE outlier_rate_stats2;
CREATE TABLE outlier_rate_stats2
   (year						INTEGER,
  	 chem_code				INTEGER,
    ai_group            INTEGER,
    ago_ind        		VARCHAR2(1),
    unit_treated 			VARCHAR2(1),
    site_general        VARCHAR2(20),
    site_code           INTEGER,
    regno_short			VARCHAR2(20),
	 mean3sd   				NUMBER)
NOLOGGING
PCTUSED 95
PCTFREE 3
STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0)
TABLESPACE pur_report;

INSERT INTO outlier_rate_stats2
   SELECT   year, chem_code, ai_group, ago_ind, unit_treated,
            site_general, site_code, regno_short, prodno, mean3sd
   FROM     ai_outlier_stats aios  LEFT JOIN ai_group_stats using (year, chem_code, ai_group, ago_ind, unit_treated)
                                   LEFT JOIN pur_site_groups using (site_general)
;

COMMIT;

DROP TABLE outlier_rate_stats3;
CREATE TABLE outlier_rate_stats3
   (year						INTEGER,
  	 chem_code				INTEGER,
    ai_group            INTEGER,
    ago_ind        		VARCHAR2(1),
    unit_treated 			VARCHAR2(1),
    site_general        VARCHAR2(20),
    site_code           INTEGER,
    regno_short			VARCHAR2(20),
    prodno              INTEGER,
	 mean3sd   				NUMBER)
NOLOGGING
PCTUSED 95
PCTFREE 3
STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0)
TABLESPACE pur_report;

INSERT INTO outlier_rate_stats3
   SELECT   year, chem_code, ai_group, ago_ind, unit_treated,
            site_general, site_code, regno_short, prodno, mean3sd
   FROM     ai_outlier_stats aios  LEFT JOIN ai_group_stats using (year, chem_code, ai_group, ago_ind, unit_treated)
                                   LEFT JOIN pur_site_groups using (site_general)
                                   LEFT JOIN product ON regno_short = mfg_firmno||'-'||label_seq_no
;

COMMIT;

SELECT   *
FROM     outlier_rate_stats3
ORDER BY chem_code, ai_group, ago_ind, unit_treated, site_general, regno_short, prodno, record_id, unit_treated_report;

DROP TABLE outlier_rate_stats4;
CREATE TABLE outlier_rate_stats4
   (year						INTEGER,
  	 chem_code				INTEGER,
    ai_group            INTEGER,
    ago_ind        		VARCHAR2(1),
    record_id           VARCHAR2(1),
    unit_treated 			VARCHAR2(1),
    unit_treated_report VARCHAR2(1),
    site_general        VARCHAR2(20),
    site_code           INTEGER,
    regno_short			VARCHAR2(20),
    prodno              INTEGER,
	 mean3sd   				NUMBER)
NOLOGGING
PCTUSED 95
PCTFREE 3
STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0)
TABLESPACE pur_report;

INSERT INTO outlier_rate_stats4
   SELECT   year, chem_code, ai_group, ago_ind, record_id, unit_treated, unit_treated_report,
            site_general, site_code, regno_short, prodno, mean3sd
   FROM     ai_outlier_stats aios  LEFT JOIN ai_group_stats using (year, chem_code, ai_group, ago_ind, unit_treated)
                                   LEFT JOIN pur_site_groups using (site_general)
                                   LEFT JOIN product ON regno_short = mfg_firmno||'-'||label_seq_no
                                    LEFT JOIN ago_ind_table using (ago_ind)
                                    LEFT JOIN unit_treated_table using (unit_treated)                             
;

COMMIT;

SELECT   *
FROM     outlier_rate_stats4
ORDER BY chem_code, ai_group, ago_ind, unit_treated, site_general, regno_short, prodno, record_id, unit_treated_report;



These scripts are wrong:
INSERT INTO outlier_rate_stats
   SELECT   year, chem_code, ai_group, ago_ind, record_id, unit_treated, unit_treated_report,
            site_general, site_code, mfg_firmno||'-'||label_seq_no regno_short, prodno, mean3sd
   FROM     ai_outlier_stats aios LEFT JOIN ago_ind_table using (ago_ind)
                             LEFT JOIN unit_treated_table using (unit_treated)
                             LEFT JOIN ai_group_stats using (year, chem_code, ai_group, ago_ind, unit_treated)
                             LEFT JOIN pur_site_groups using (site_general )
                             LEFT JOIN prod_chem_major_ai using (chem_code)
                             LEFT JOIN product using (prodno);

COMMIT;

SELECT   *
FROM     outlier_rate_stats
ORDER BY chem_code, ai_group, ago_ind, record_id, unit_treated, unit_treated_report, site_general, site_code, regno_short, prodno;

CREATE TABLE outlier_stats_temp
   (year						INTEGER,
  	 chem_code				INTEGER,
    ai_rate_type        VARCHAR2(20),
    ago_ind        		VARCHAR2(1),
    record_id           VARCHAR2(1),
    unit_treated 			VARCHAR2(1),
    unit_treated_report VARCHAR2(1),
    site_type           VARCHAR2(20),
    site_code           INTEGER,
	 mean3sd   				NUMBER)
NOLOGGING
PCTUSED 95
PCTFREE 3
STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0)
TABLESPACE pur_report;

INSERT INTO outlier_stats_temp
   SELECT   year, chem_code, ai_rate_type, ago_ind, record_id, unit_treated, unit_treated_report,
            'OTHER', NULL, mean3sd
   FROM     ai_outlier_stats JOIN ago_ind_table using (ago_ind)
                             JOIN unit_treated_table using (unit_treated)
                             JOIN fixed_outlier_rates_ais using (chem_code, ago_ind, unit_treated, site_type);

COMMIT;

INSERT INTO outlier_stats_temp
   SELECT   year, chem_code, ago_ind, record_id, unit_treated, unit_treated_report, site_type, site_code, mean3sd
   FROM     ai_outlier_stats JOIN ago_ind_table using (ago_ind)
                             JOIN unit_treated_table using (unit_treated)
                             JOIN site_type_table USING (site_code)
   WHERE    ago_ind = 'N';

COMMIT;



DECLARE
   CURSOR aios_cur AS
      SELECT   *
      FROM     ai_outlier_stats;

   CURSOR aig_cur AS
      SELECT   chem_code, ai_group, site_general, regno_short, ago_ind,
               unit_treated
      FROM     pur_report.ai_group_stats;
   
BEGIN
   FOR aios_rec IN aios_cur LOOP
      IF v_unit_treated = 'A' THEN
         INSERT INTO os_unit VALUES (chem_code, ai_group, ago_id, unit_treated, 'A', mean3sd);
         INSERT INTO os_unit VALUES (chem_code, ai_group, ago_id, unit_treated, 'S', mean3sd);

      END IF;
      FOR v_unit_treated IN ('A', 'C', 'P', 'U') LOOP

      END LOOP;

   END LOOP;

   
   FOR aig_rec IN aig_cur LOOP

   END LOOP;
   FOR v_unit_treated IN ('A', 'C', 'P', 'U') LOOP

   END LOOP;

EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(SQLERRM||'; use_no = '||v_use_no);
END;
/
show errors


*/
