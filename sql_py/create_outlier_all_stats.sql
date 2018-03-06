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

/*
   This query takes about one hour to run.
*/

/*
DROP TABLE regno_table;
CREATE TABLE regno_table
   (regno_short	VARCHAR2(20),
    ago_ind       VARCHAR2(1))
NOLOGGING
PCTUSED 95
PCTFREE 3
TABLESPACE pur_report;

INSERT INTO regno_table
   SELECT   DISTINCT regno_short, ago_ind
   FROM     pur_rates_2017;

COMMIT;

DROP TABLE site_general_table;
CREATE TABLE site_general_table
   (site_general  VARCHAR2(50))
NOLOGGING
PCTUSED 95
PCTFREE 3
TABLESPACE pur_report;

INSERT INTO site_general_table
   SELECT   DISTINCT site_general
   FROM     pur_site_groups;

COMMIT;


DROP TABLE unit_treated_table;
CREATE TABLE unit_treated_table
   (unit_treated  VARCHAR2(1))
NOLOGGING
PCTUSED 95
PCTFREE 3
TABLESPACE pur_report;

INSERT INTO unit_treated_table VALUES ('A');
INSERT INTO unit_treated_table VALUES ('C');
INSERT INTO unit_treated_table VALUES ('P');
INSERT INTO unit_treated_table VALUES ('S');
INSERT INTO unit_treated_table VALUES ('K');
INSERT INTO unit_treated_table VALUES ('T');
INSERT INTO unit_treated_table VALUES ('U');
COMMIT;

DROP TABLE outlier_final_stats;
CREATE TABLE outlier_final_stats
   (ago_ind        		VARCHAR2(1),
    unit_treated 			VARCHAR2(1),
    ai_rate_type        VARCHAR2(20),
    site_type           VARCHAR2(20),
    fixed2              NUMBER,
	 mean_limit   			VARCHAR2(20))
NOLOGGING
PCTUSED 95
PCTFREE 3
STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0)
TABLESPACE pur_report;


DROP TABLE outlier_all_stats_temp;
CREATE TABLE outlier_all_stats_temp
   (regno_short			VARCHAR2(20),
	 ago_ind        		VARCHAR2(1),
    site_general        VARCHAR2(100),
    unit_treated 			VARCHAR2(1))
NOLOGGING
PCTUSED 95
PCTFREE 3
STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0)
TABLESPACE pur_report;

INSERT INTO outlier_all_stats_temp (regno_short, ago_ind, site_general, unit_treated)
   SELECT   regno_short, ago_ind, site_general, unit_treated
   FROM     regno_table CROSS JOIN site_general_table
                        CROSS JOIN unit_treated_table;

COMMIT;
*/
/*

CREATE TABLE prodno_regno_short
   (prodno        		INTEGER,
    regno_short			VARCHAR2(20))
NOLOGGING
PCTUSED 95
PCTFREE 3
STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0)
TABLESPACE pur_report;

INSERT INTO prodno_regno_short
   SELECT   prodno, mfg_firmno||'-'||label_seq_no
   FROM     product;

COMMIT;

CREATE INDEX prodno_regno_short1_ndx ON prodno_regno_short
	(regno_short)
   PCTFREE 2
   STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0);

CREATE INDEX prodno_regno_short2_ndx ON prodno_regno_short
	(prodno)
   PCTFREE 2
   STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0);
*/

/*
   Max product rates every found in PUR ag or nonag (or RAW_PUR after 1999):
   A: 5,100,000
   S:   358,000 (next highest was 20,000, then 6,000)
   C:     5,500
   K:   161,000 (next highest was 16,000)
   P:     1,200
   T:    38,000
   U: 2,100,000 (in raw 2017, next highest was 440,000)

   Set maximum rates:
   A: 50,000,000
   S:    500,000 
   C:     50,000
   K:  1,000,000 
   P:     10,000
   T:    500,000
   U:  5,000,000 

*/
DROP TABLE outlier_all_stats;
CREATE TABLE outlier_all_stats
   (regno_short			VARCHAR2(20),
    ago_ind             VARCHAR2(1),
    site_general        VARCHAR2(100),
    site_type           VARCHAR2(100),
    unit_treated 			VARCHAR2(1),
    chem_code           INTEGER,
    chemname            VARCHAR2(200), -- The AI which resulted in this product having outlier
    ai_group            INTEGER,
    prodchem_pct        NUMBER,
    ai_rate_type        VARCHAR2(50),
    median              NUMBER,
    mean5sd   				NUMBER,
    mean7sd   				NUMBER,
    mean8sd   				NUMBER,
    mean10sd   			NUMBER,
    mean12sd   			NUMBER,
    fixed1              NUMBER,
    fixed2              NUMBER,
    fixed3              NUMBER,
    outlier_limit       NUMBER,
    outlier_limit_prod  NUMBER,
    median_ai           NUMBER,
    mean5sd_ai   			NUMBER,
    mean7sd_ai   			NUMBER,
    mean8sd_ai   			NUMBER,
    mean10sd_ai   		NUMBER,
    mean12sd_ai   		NUMBER,
    fixed1_ai           NUMBER,
    fixed2_ai           NUMBER,
    fixed3_ai           NUMBER,
    outlier_limit_ai    NUMBER,
    max_rate            NUMBER,
    unit_conversion     NUMBER,
    mean_limit_prod_str VARCHAR2(100))
NOLOGGING
PCTUSED 95
PCTFREE 3
STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0)
TABLESPACE pur_report;


DECLARE
   v_site_type             VARCHAR2(50);
   v_ai_adjuvant           VARCHAR2(1);
   v_ai_rate_type          VARCHAR2(50);
   v_gen_unit_treated      VARCHAR2(1);
   v_ai_group              INTEGER;

   v_fixed1_ai             NUMBER;
   v_fixed2_ai             NUMBER;
   v_fixed3_ai             NUMBER;

   v_median_ai             NUMBER;
   v_mean5sd_ai            NUMBER;
   v_mean7sd_ai            NUMBER;
   v_mean8sd_ai            NUMBER;
   v_mean10sd_ai           NUMBER;
   v_mean12sd_ai           NUMBER;

   v_fixed1_prod           NUMBER;
   v_fixed2_prod           NUMBER;
   v_fixed3_prod           NUMBER;

   v_median_prod           NUMBER;
   v_mean5sd_prod          NUMBER;
   v_mean7sd_prod          NUMBER;
   v_mean8sd_prod          NUMBER;
   v_mean10sd_prod         NUMBER;
   v_mean12sd_prod         NUMBER;

   v_mean_limit_ai_str     VARCHAR2(100);
   v_mean_limit_prod_str   VARCHAR2(100);
   v_mean_limit_ai         NUMBER;
   v_outlier_limit_ai      NUMBER;
   v_outlier_limit_prod    NUMBER;
   v_outlier_limit_prod_min     NUMBER;

   v_max_rate              NUMBER;

   v_ai_pct                NUMBER;
   v_unit_conversion       NUMBER;
   v_chemname              VARCHAR2(200);
   v_chem_code             INTEGER;

   v_index                 INTEGER;
   v_num_stat_recs         INTEGER;
   v_outlier_stats_exist   BOOLEAN;

   CURSOR oas_cur IS
      SELECT   regno_short, ago_ind, site_general, unit_treated
      FROM     outlier_all_stats_temp
      WHERE    regno_short = '100-1093'
      ORDER BY regno_short, ago_ind, site_general, unit_treated
      ;

--   WHERE    regno_short = '100-1000' AND site_general = 'ANIMALS'
/*
   WHERE    regno_short = '67986-1' AND
   ago_ind = 'A' AND
   unit_treated = 'A' AND
   site_general = 'CITRUS'
*/
   CURSOR ai_cur(p_regno IN VARCHAR2) IS
      SELECT   DISTINCT chem_code, prodchem_pct, chemname
      FROM     prod_chem_major_ai left JOIN chemical using (chem_code)
                                  left JOIN prodno_regno_short using (prodno)
      WHERE    regno_short = p_regno;
     
      --WHERE    prodno IN (SELECT prodno FROM product WHERE mfg_firmno||'-'||label_seq_no = p_regno);
BEGIN
   v_index := 0;
   FOR oas_rec IN oas_cur LOOP
      --DBMS_OUTPUT.PUT_LINE('********************************');
      --DBMS_OUTPUT.PUT_LINE('v_index = '||v_index);
      ----DBMS_OUTPUT.PUT_LINE('oas_rec.regno_short = '||oas_rec.regno_short);
      ----DBMS_OUTPUT.PUT_LINE('oas_rec.unit_treated = '||oas_rec.unit_treated);
      ----DBMS_OUTPUT.PUT_LINE('oas_rec.ago_ind = '||oas_rec.ago_ind);
      ----DBMS_OUTPUT.PUT_LINE('oas_rec.site_general = '||oas_rec.site_general);

      IF oas_rec.ago_ind = 'N' THEN
         IF oas_rec.site_general = 'WATER_AREA' THEN
            v_site_type := 'WATER';
         ELSE
            v_site_type := 'OTHER';
         END IF;
      ELSE
         v_site_type := 'ALL';
      END IF;
      --DBMS_OUTPUT.PUT_LINE('v_site_type = '||v_site_type);

      IF oas_rec.unit_treated = 'S' THEN
         v_gen_unit_treated := 'A';
         v_unit_conversion := 1/43560;
      ELSIF oas_rec.unit_treated = 'K' THEN
         v_gen_unit_treated := 'C';
         v_unit_conversion := 1000;
      ELSIF oas_rec.unit_treated = 'T' THEN
         v_gen_unit_treated := 'P';
         v_unit_conversion := 2000;
      ELSE
         v_gen_unit_treated := oas_rec.unit_treated;
         v_unit_conversion := 1;
      END IF;

      --DBMS_OUTPUT.PUT_LINE('oas_rec.unit_treated = '||oas_rec.unit_treated);
      --DBMS_OUTPUT.PUT_LINE('v_gen_unit_treated = '||v_gen_unit_treated);
      --DBMS_OUTPUT.PUT_LINE('v_unit_conversion = '||v_unit_conversion);

      v_outlier_limit_prod_min := 1000000000000;
      v_outlier_stats_exist := FALSE;
      FOR ai_rec IN ai_cur(oas_rec.regno_short) LOOP
         --DBMS_OUTPUT.PUT_LINE('ai_rec.chem_code = '||ai_rec.chem_code);

         /* Get fixed rate outliers.
          */
         BEGIN
            SELECT   adjuvant
            INTO     v_ai_adjuvant
            FROM     chem_adjuvant
            WHERE    chem_code = ai_rec.chem_code;
         EXCEPTION
            WHEN OTHERS THEN
               v_ai_adjuvant := 'N';
         END;

         IF v_ai_adjuvant = 'Y' THEN
            v_ai_rate_type := 'ADJUVANT';
         ELSE
            BEGIN
               SELECT   ai_rate_type
               INTO     v_ai_rate_type
               FROM     fixed_outlier_rates_ais
               WHERE    ago_ind = oas_rec.ago_ind AND 
                        unit_treated = v_gen_unit_treated AND
                        site_type = v_site_type AND
                        chem_code = ai_rec.chem_code;
            EXCEPTION
               WHEN OTHERS THEN
                  v_ai_rate_type := 'NORMAL';
            END;
         END IF;

         --DBMS_OUTPUT.PUT_LINE('v_ai_rate_type from FIXED_OUTLIER_RATES_AIS = '||v_ai_rate_type);

         BEGIN
            SELECT   rate1, rate2, rate3
            INTO     v_fixed1_ai, v_fixed2_ai, v_fixed3_ai
            FROM     fixed_outlier_rates
            WHERE    ago_ind = oas_rec.ago_ind AND
                     unit_treated = v_gen_unit_treated AND
                     ai_rate_type = v_ai_rate_type AND
                     site_type = v_site_type;
         EXCEPTION
            WHEN OTHERS THEN
               v_fixed1_ai := NULL;
               v_fixed2_ai := NULL;
               v_fixed3_ai := NULL;
         END;

         --DBMS_OUTPUT.PUT_LINE('v_fixed2_ai from FIXED_OUTLIER_RATES = '||v_fixed2_ai);

         /* Get other rate outliers, but first check that outlier stats
            exist for this situation.
          */
         SELECT   count(*)
         INTO     v_num_stat_recs
         FROM		pur_report.ai_outlier_stats
         WHERE		chem_code = ai_rec.chem_code AND
                  ago_ind = oas_rec.ago_ind AND
                  unit_treated = v_gen_unit_treated;

         --DBMS_OUTPUT.PUT_LINE('v_num_stat_recs in AI_OUTLIER_STATS = '||v_num_stat_recs);

         IF v_num_stat_recs = 0 AND v_fixed2_ai IS NULL THEN
            --DBMS_OUTPUT.PUT_LINE('No stats exist for for ago_ind = '||oas_rec.ago_ind ||' and unit = '||v_gen_unit_treated);
            CONTINUE;
         ELSIF v_num_stat_recs = 0 AND v_fixed2_ai > 0 THEN
            --DBMS_OUTPUT.PUT_LINE('Only fixed stats exist for for ago_ind = '||oas_rec.ago_ind ||' and unit = '||v_gen_unit_treated);
            v_outlier_stats_exist := TRUE;

            v_median_ai := NULL;
            v_mean5sd_ai := NULL;
            v_mean7sd_ai := NULL;
            v_mean8sd_ai := NULL;
            v_mean10sd_ai := NULL;
            v_mean12sd_ai := NULL;

            v_outlier_limit_ai := v_fixed2_ai;
         ELSE
            --DBMS_OUTPUT.PUT_LINE('Both fixed and outlier_stats exist for for ago_ind = '||oas_rec.ago_ind ||' and unit = '||v_gen_unit_treated);
            v_outlier_stats_exist := TRUE;

            BEGIN
               SELECT   ai_group
               INTO     v_ai_group
               FROM     pur_report.ai_group_stats
               WHERE    chem_code = ai_rec.chem_code AND
                        regno_short = oas_rec.regno_short AND
                        site_general = oas_rec.site_general AND
                        ago_ind = oas_rec.ago_ind AND
                        unit_treated = v_gen_unit_treated;
            EXCEPTION
               WHEN OTHERS THEN
                  v_ai_group := NULL;
            END;
            --DBMS_OUTPUT.PUT_LINE('v_ai_group = '||v_ai_group);

            IF v_ai_group IS NULL THEN
               /* If no statistics found for this AI, ago_ind, unit_treated, product, and site,
                  then use maximum outlier limits for this AI, ago_ind, and unit_treated.
                  If no statistics found for this AI, ago_ind, and unit_treated, just use fixed limits.
                */
               BEGIN
                  SELECT	MAX(median_rate), MAX(mean5sd), MAX(mean7sd), MAX(mean8sd), MAX(mean10sd), MAX(mean12sd)
                  INTO		v_median_ai, v_mean5sd_ai, v_mean7sd_ai, v_mean8sd_ai, v_mean10sd_ai, v_mean12sd_ai
                  FROM		pur_report.ai_outlier_stats
                  WHERE		chem_code = ai_rec.chem_code AND
                           ago_ind = oas_rec.ago_ind AND
                           unit_treated = v_gen_unit_treated;
               EXCEPTION
                  WHEN OTHERS THEN
                     v_median_ai := NULL;
                     v_mean5sd_ai := NULL;
                     v_mean7sd_ai := NULL;
                     v_mean8sd_ai := NULL;
                     v_mean10sd_ai := NULL;
                     v_mean12sd_ai := NULL;
               END;
            ELSE -- An AI group is found for this record.
               BEGIN
                  SELECT	median_rate, mean5sd, mean7sd, mean8sd, mean10sd, mean12sd
                  INTO		v_median_ai, v_mean5sd_ai, v_mean7sd_ai, v_mean8sd_ai, v_mean10sd_ai, v_mean12sd_ai
                  FROM		pur_report.ai_outlier_stats
                  WHERE		chem_code = ai_rec.chem_code AND
                           ai_group = v_ai_group AND
                           ago_ind = oas_rec.ago_ind AND
                           unit_treated = v_gen_unit_treated;
               EXCEPTION
                  WHEN OTHERS THEN
                     v_median_ai := NULL;
                     v_mean5sd_ai := NULL;
                     v_mean7sd_ai := NULL;
                     v_mean8sd_ai := NULL;
                     v_mean10sd_ai := NULL;
                     v_mean12sd_ai := NULL;
               END;

            END IF;

            --DBMS_OUTPUT.PUT_LINE('log(v_mean5sd_ai) = '||TO_CHAR(v_mean5sd_ai, 'FM9,999.9999'));
            --DBMS_OUTPUT.PUT_LINE('log(v_mean8sd_ai) = '||TO_CHAR(v_mean8sd_ai, 'FM9,999.9999'));

            v_median_ai := power(10, LEAST(v_median_ai, 15));
            v_mean5sd_ai := power(10, LEAST(v_mean5sd_ai, 15));
            v_mean7sd_ai := power(10, LEAST(v_mean7sd_ai, 15));
            v_mean8sd_ai := power(10, LEAST(v_mean8sd_ai, 15));
            v_mean10sd_ai := power(10, LEAST(v_mean10sd_ai, 15));
            v_mean12sd_ai := power(10, LEAST(v_mean12sd_ai, 15));

            --DBMS_OUTPUT.PUT_LINE('v_mean5sd_ai = '||TO_CHAR(v_mean5sd_ai, 'FM9,999.9999999999'));
            --DBMS_OUTPUT.PUT_LINE('v_mean8sd_ai = '||TO_CHAR(v_mean8sd_ai, 'FM9,999.9999999999'));

            BEGIN
               SELECT   mean_limit
               INTO     v_mean_limit_ai_str
               FROM     outlier_final_stats
               WHERE    ago_ind = oas_rec.ago_ind AND
                        unit_treated = v_gen_unit_treated AND
                        ai_rate_type = v_ai_rate_type AND
                        site_type = v_site_type;
            EXCEPTION
               WHEN OTHERS THEN
                  v_mean_limit_ai_str := NULL;
            END;

            --DBMS_OUTPUT.PUT_LINE('v_mean_limit_ai_str = '||v_mean_limit_ai_str);

            IF v_mean_limit_ai_str = 'MEAN5SD' THEN
               v_mean_limit_ai := v_mean5sd_ai;
            ELSIF v_mean_limit_ai_str = 'MEAN7SD' THEN
               v_mean_limit_ai := v_mean7sd_ai;
            ELSIF v_mean_limit_ai_str = 'MEAN8SD' THEN
               v_mean_limit_ai := v_mean8sd_ai;
            ELSIF v_mean_limit_ai_str = 'MEAN10SD' THEN
               v_mean_limit_ai := v_mean10sd_ai;
            ELSIF v_mean_limit_ai_str = 'MEAN12SD' THEN
               v_mean_limit_ai := v_mean12sd_ai;
            ELSE
               v_mean_limit_ai := NULL;
            END IF;

            --DBMS_OUTPUT.PUT_LINE('v_mean_limit_ai = '||TO_CHAR(v_mean_limit_ai, 'FM9,999.999999'));
            --DBMS_OUTPUT.PUT_LINE('v_fixed2_ai = '||v_fixed2_ai);

            v_outlier_limit_ai := LEAST(v_mean_limit_ai, v_fixed2_ai);

            --DBMS_OUTPUT.PUT_LINE('v_outlier_limit_ai (min mean_limit and fixed2) = '||TO_CHAR(v_outlier_limit_ai, 'FM9,999.999999'));

         END IF;

         /* Get the outlier limit for the product and
            choose the smallest outlier limit among all AIs
            for this product. This procedure may be called
            with unit_treated = S, K, or T which need to
            be converted to A, C, or P which are the units
            in the outlier tables.
          */
         v_ai_pct := ai_rec.prodchem_pct/100;
         ----DBMS_OUTPUT.PUT_LINE('v_ai_pct = '||v_ai_pct);
         IF v_ai_pct > 0 THEN
            v_outlier_limit_prod := v_outlier_limit_ai*v_unit_conversion/v_ai_pct;
         ELSE
            v_outlier_limit_prod := NULL;
         END IF;

         --DBMS_OUTPUT.PUT_LINE('v_ai_pct = '||TO_CHAR(v_ai_pct, 'FM9,999.9999999'));
         --DBMS_OUTPUT.PUT_LINE('v_unit_conversion = '||v_unit_conversion);
         --DBMS_OUTPUT.PUT_LINE('v_outlier_limit_prod = v_outlier_limit_ai * v_unit_conversion / v_ai_pct');
         --DBMS_OUTPUT.PUT_LINE('v_outlier_limit_prod = '||TO_CHAR(v_outlier_limit_prod, 'FM9,999,999,999.99'));
         --DBMS_OUTPUT.PUT_LINE('v_outlier_limit_prod_min = '||TO_CHAR(v_outlier_limit_prod_min, 'FM9,999,999,999,999,999'));

         IF v_outlier_limit_prod < v_outlier_limit_prod_min THEN
            --DBMS_OUTPUT.PUT_LINE('v_outlier_limit_prod < v_outlier_limit_prod_min');
            v_outlier_limit_prod_min := v_outlier_limit_prod;
            v_chem_code := ai_rec.chem_code;
            v_chemname := ai_rec.chemname;

            IF v_ai_pct > 0 THEN
               v_median_prod := v_median_ai*v_unit_conversion/v_ai_pct;
               v_mean5sd_prod := v_mean5sd_ai*v_unit_conversion/v_ai_pct;
               v_mean7sd_prod := v_mean7sd_ai*v_unit_conversion/v_ai_pct;
               v_mean8sd_prod := v_mean8sd_ai*v_unit_conversion/v_ai_pct;
               v_mean10sd_prod := v_mean10sd_ai*v_unit_conversion/v_ai_pct;
               v_mean12sd_prod := v_mean12sd_ai*v_unit_conversion/v_ai_pct;
               v_fixed1_prod := v_fixed1_ai*v_unit_conversion/v_ai_pct;
               v_fixed2_prod := v_fixed2_ai*v_unit_conversion/v_ai_pct;
               v_fixed3_prod := v_fixed3_ai*v_unit_conversion/v_ai_pct;
               v_mean_limit_prod_str := v_mean_limit_ai_str;
            ELSE
               v_median_prod := NULL;
               v_mean5sd_prod := NULL;
               v_mean7sd_prod := NULL;
               v_mean8sd_prod := NULL;
               v_mean10sd_prod := NULL;
               v_mean12sd_prod := NULL;
               v_fixed1_prod := NULL;
               v_fixed2_prod := NULL;
               v_fixed3_prod := NULL;
               v_mean_limit_prod_str := NULL;
            END IF;

            --DBMS_OUTPUT.PUT_LINE('v_mean5sd_prod = '||TO_CHAR(v_mean5sd_prod, 'FM9,999,999,999.99'));
            --DBMS_OUTPUT.PUT_LINE('v_fixed2_prod = '||TO_CHAR(v_fixed2_prod, 'FM9,999,999,999.99'));

         END IF;

      END LOOP;

      /*
         Set maximum rates:
         A: 50,000,000
         S:    500,000 
         C:     50,000
         K:  1,000,000 
         P:     10,000
         T:    500,000
         U:  5,000,000 
      */
      v_max_rate := 
         CASE oas_rec.unit_treated
            WHEN 'A' THEN 50000000
            WHEN 'S' THEN 500000
            WHEN 'C' THEN 50000 
            WHEN 'K' THEN 1000000
            WHEN 'P' THEN 10000
            WHEN 'T' THEN 500000
            WHEN 'U' THEN 5000000
         END;
      --DBMS_OUTPUT.PUT_LINE('v_max_rate = '||TO_CHAR(v_max_rate, 'FM9,999,999,999.99'));

      v_mean5sd_prod := LEAST(v_mean5sd_prod, v_max_rate);
      v_mean7sd_prod := LEAST(v_mean7sd_prod, v_max_rate);
      v_mean8sd_prod := LEAST(v_mean8sd_prod, v_max_rate);
      v_mean10sd_prod := LEAST(v_mean10sd_prod, v_max_rate);
      v_mean12sd_prod := LEAST(v_mean12sd_prod, v_max_rate);
      v_fixed1_prod := LEAST(v_fixed1_prod, v_max_rate);
      v_fixed2_prod := LEAST(v_fixed2_prod, v_max_rate);
      v_fixed3_prod := LEAST(v_fixed3_prod, v_max_rate);
      v_outlier_limit_prod_min := LEAST(v_outlier_limit_prod_min, v_max_rate);

      --DBMS_OUTPUT.PUT_LINE('Get min of max_rate and mean5sd_prod:');
      --DBMS_OUTPUT.PUT_LINE('v_mean5sd_prod = '||TO_CHAR(v_mean5sd_prod, 'FM9,999,999,999.99'));

      --DBMS_OUTPUT.PUT_LINE('Get min of max_rate and fixed2_prod:');
      --DBMS_OUTPUT.PUT_LINE('v_fixed2_prod = '||TO_CHAR(v_fixed2_prod, 'FM9,999,999,999.99'));

      IF v_outlier_stats_exist THEN
         INSERT INTO outlier_all_stats VALUES
            (oas_rec.regno_short, oas_rec.ago_ind, oas_rec.site_general, v_site_type, 
             oas_rec.unit_treated, v_chem_code, v_chemname, v_ai_group, v_ai_pct*100, v_ai_rate_type,
             v_median_prod, v_mean5sd_prod, v_mean7sd_prod, v_mean8sd_prod, 
             v_mean10sd_prod, v_mean12sd_prod,
             v_fixed1_prod, v_fixed2_prod, v_fixed3_prod, 
             v_outlier_limit_prod_min, v_outlier_limit_prod, 
             v_median_ai, v_mean5sd_ai, v_mean7sd_ai, v_mean8sd_ai, 
             v_mean10sd_ai, v_mean12sd_ai,
             v_fixed1_ai, v_fixed2_ai, v_fixed3_ai, 
             v_outlier_limit_ai, v_max_rate, v_unit_conversion, v_mean_limit_prod_str);

         v_index := v_index + 1;
         IF v_index > 100 THEN
            COMMIT;
            v_index := 0;
         END IF;
      END IF;

   END LOOP;

   COMMIT;

EXCEPTION
	WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/
show errors



/* Examples of how to use this table:
 */
/*
SELECT   *
FROM     outlier_all_stats 
WHERE    regno_short = '352-00729' AND
         ago_ind = 'A' AND
         unit_treated = 'A' AND
         site_type = 
            CASE WHEN record_id = 'C' THEN 
               CASE WHEN site_code IN (SELECT site_code FROM site_type_table) THEN 'WATER' 
                  ELSE 'OTHER' END
               ELSE 'ALL'
            END;

SELECT   *
FROM     outlier_all_stats 
WHERE    prodno = 63665 AND
         record_id = 'B' AND
         unit_treated_report = 'S' AND
         site_type = 
            CASE WHEN record_id = 'C' THEN 
               CASE WHEN site_code IN (SELECT site_code FROM site_type_table) THEN 'WATER' 
                  ELSE 'OTHER' END
               ELSE 'ALL'
            END;
*/

