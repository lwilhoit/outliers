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

DROP TABLE outlier_all_stats;
CREATE TABLE outlier_all_stats
   (regno_short			VARCHAR2(20),
    ago_ind             VARCHAR2(1),
    site_general        VARCHAR2(100),
    site_type           VARCHAR2(100),
    unit_treated 			VARCHAR2(1),
    chem_code           INTEGER,
    chemname            VARCHAR2(200), -- The AI which resulted in this product having outlier
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
    outlier_limit       NUMBER)
NOLOGGING
PCTUSED 95
PCTFREE 3
STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0)
TABLESPACE pur_report;

*/

DECLARE
   v_site_type             VARCHAR2(50);
   v_ai_adjuvant           VARCHAR2(1);
   v_ai_rate_type          VARCHAR2(50);
   v_unit_treated          VARCHAR2(1);
   v_ai_group              INTEGER;

   v_fixed1                NUMBER;
   v_fixed2                NUMBER;
   v_fixed3                NUMBER;

   v_mean5sd_rate          NUMBER;
   v_mean7sd_rate          NUMBER;
   v_mean8sd_rate          NUMBER;
   v_mean10sd_rate         NUMBER;
   v_mean12sd_rate         NUMBER;

   v_fixed1_prod           NUMBER;
   v_fixed2_prod           NUMBER;
   v_fixed3_prod           NUMBER;

   v_mean5sd_prod          NUMBER;
   v_mean7sd_prod          NUMBER;
   v_mean8sd_prod          NUMBER;
   v_mean10sd_prod         NUMBER;
   v_mean12sd_prod         NUMBER;

   v_mean_limit_str        VARCHAR2(100);
   v_mean_limit            NUMBER;
   v_outlier_limit         NUMBER;
   v_outlier_limit_prod    NUMBER;
   v_outlier_limit_min     NUMBER;

   v_ai_pct                NUMBER;
   v_ai_pct_min            NUMBER;
   v_unit_conversion       NUMBER;
   v_chemname              VARCHAR2(200);
   v_chem_code             INTEGER;

   v_index                 INTEGER;
   v_num_stat_recs         INTEGER;
   v_outlier_stats_exist   BOOLEAN;

   CURSOR oas_cur IS
      SELECT   regno_short, ago_ind, site_general, unit_treated
      FROM     outlier_all_stats_temp
      WHERE    regno_short > '11415-50001'
      ORDER BY regno_short, ago_ind, site_general, unit_treated;

--   WHERE    regno_short = '100-1000' AND site_general = 'ANIMALS'

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
      --DBMS_OUTPUT.PUT_LINE('oas_rec.regno_short = '||oas_rec.regno_short);
      --DBMS_OUTPUT.PUT_LINE('oas_rec.unit_treated = '||oas_rec.unit_treated);
      --DBMS_OUTPUT.PUT_LINE('oas_rec.ago_ind = '||oas_rec.ago_ind);
      IF oas_rec.ago_ind = 'N' THEN
         IF oas_rec.site_general = 'WATER_AREA' THEN
            v_site_type := 'WATER';
         ELSE
            v_site_type := 'OTHER';
         END IF;
      ELSE
         v_site_type := 'ALL';
      END IF;

      IF oas_rec.unit_treated = 'S' THEN
         v_unit_treated := 'A';
         v_unit_conversion := 1/43560;
      ELSIF oas_rec.unit_treated = 'K' THEN
         v_unit_treated := 'C';
         v_unit_conversion := 1000;
      ELSIF oas_rec.unit_treated = 'T' THEN
         v_unit_treated := 'P';
         v_unit_conversion := 2000;
      ELSE
         v_unit_treated := oas_rec.unit_treated;
         v_unit_conversion := 1;
      END IF;

      --DBMS_OUTPUT.PUT_LINE('v_unit_conversion = '||v_unit_conversion);
      --DBMS_OUTPUT.PUT_LINE('v_unit_treated = '||v_unit_treated);

      v_outlier_limit_min := 1000000000000;
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
                        unit_treated = v_unit_treated AND
                        site_type = v_site_type AND
                        chem_code = ai_rec.chem_code;
            EXCEPTION
               WHEN OTHERS THEN
                  v_ai_rate_type := 'NORMAL';
            END;
         END IF;

         BEGIN
            SELECT   rate1, rate2, rate3
            INTO     v_fixed1, v_fixed2, v_fixed3
            FROM     fixed_outlier_rates
            WHERE    ago_ind = oas_rec.ago_ind AND
                     unit_treated = v_unit_treated AND
                     ai_rate_type = v_ai_rate_type AND
                     site_type = v_site_type;
         EXCEPTION
            WHEN OTHERS THEN
               v_fixed1 := NULL;
               v_fixed2 := NULL;
               v_fixed3 := NULL;
         END;


         /* Get other rate outliers, but first check that outlier stats
            exist for this situation.
          */
         SELECT   count(*)
         INTO     v_num_stat_recs
         FROM		pur_report.ai_outlier_stats
         WHERE		chem_code = ai_rec.chem_code AND
                  ago_ind = oas_rec.ago_ind AND
                  unit_treated = v_unit_treated;

         IF v_num_stat_recs = 0 AND v_fixed2 IS NULL THEN
            --DBMS_OUTPUT.PUT_LINE('No stats exist for for ago_ind = '||oas_rec.ago_ind ||' and unit = '||v_unit_treated);
            v_outlier_stats_exist := FALSE;
            CONTINUE;
         ELSIF v_num_stat_recs = 0 AND v_fixed2 > 0 THEN
            --DBMS_OUTPUT.PUT_LINE('Only fixed stats exist for for ago_ind = '||oas_rec.ago_ind ||' and unit = '||v_unit_treated);
            v_outlier_stats_exist := TRUE;

            v_mean5sd_prod := NULL;
            v_mean7sd_prod := NULL;
            v_mean8sd_prod := NULL;
            v_mean10sd_prod := NULL;
            v_mean12sd_prod := NULL;

            v_ai_pct := ai_rec.prodchem_pct/100;
            --DBMS_OUTPUT.PUT_LINE('v_ai_pct = '||v_ai_pct);
            IF v_ai_pct > 0 THEN
               v_fixed1_prod := v_fixed1*v_unit_conversion/v_ai_pct;
               v_fixed2_prod := v_fixed2*v_unit_conversion/v_ai_pct;
               v_fixed3_prod := v_fixed3*v_unit_conversion/v_ai_pct;
               v_outlier_limit_min := v_fixed2_prod;
            ELSE
               v_fixed1_prod := NULL;
               v_fixed2_prod := NULL;
               v_fixed3_prod := NULL;
               v_outlier_limit_min := NULL;
            END IF;

            --DBMS_OUTPUT.PUT_LINE('v_outlier_limit_min = '||v_outlier_limit_min);
         ELSE
            --DBMS_OUTPUT.PUT_LINE('Both fixed and outliersstats exist for for ago_ind = '||oas_rec.ago_ind ||' and unit = '||v_unit_treated);
            v_outlier_stats_exist := TRUE;

            BEGIN
               SELECT   ai_group
               INTO     v_ai_group
               FROM     pur_report.ai_group_stats
               WHERE    chem_code = ai_rec.chem_code AND
                        regno_short = oas_rec.regno_short AND
                        site_general = oas_rec.site_general AND
                        ago_ind = oas_rec.ago_ind AND
                        unit_treated = v_unit_treated;
            EXCEPTION
               WHEN OTHERS THEN
                  v_ai_group := NULL;
            END;

            IF v_ai_group IS NULL THEN
               /* If no statistics found for this AI, ago_ind, unit_treated, product, and site,
                  then use maximum outlier limits for this AI, ago_ind, and unit_treated.
                  If no statistics found for this AI, ago_ind, and unit_treated, just use fixed limits.
                */
               BEGIN
                  SELECT	MAX(mean5sd), MAX(mean7sd), MAX(mean8sd), MAX(mean10sd), MAX(mean12sd)
                  INTO		v_mean5sd_rate, v_mean7sd_rate, v_mean8sd_rate, v_mean10sd_rate, v_mean12sd_rate
                  FROM		pur_report.ai_outlier_stats
                  WHERE		chem_code = ai_rec.chem_code AND
                           ago_ind = oas_rec.ago_ind AND
                           unit_treated = v_unit_treated;
               EXCEPTION
                  WHEN OTHERS THEN
                     v_ai_group := 1;
                     v_mean5sd_rate := NULL;
                     v_mean7sd_rate := NULL;
                     v_mean8sd_rate := NULL;
                     v_mean10sd_rate := NULL;
                     v_mean12sd_rate := NULL;
               END;
            ELSE -- An AI group is found for this record.
               BEGIN
                  SELECT	mean5sd, mean7sd, mean8sd, mean10sd, mean12sd
                  INTO		v_mean5sd_rate, v_mean7sd_rate, v_mean8sd_rate, v_mean10sd_rate, v_mean12sd_rate
                  FROM		pur_report.ai_outlier_stats
                  WHERE		chem_code = ai_rec.chem_code AND
                           ai_group = v_ai_group AND
                           ago_ind = oas_rec.ago_ind AND
                           unit_treated = v_unit_treated;
               EXCEPTION
                  WHEN OTHERS THEN
                     v_mean5sd_rate := NULL;
                     v_mean7sd_rate := NULL;
                     v_mean8sd_rate := NULL;
                     v_mean10sd_rate := NULL;
                     v_mean12sd_rate := NULL;
               END;

            END IF;

            --DBMS_OUTPUT.PUT_LINE('log(v_mean5sd_rate) = '||v_mean5sd_rate);

            v_mean5sd_rate := power(10, LEAST(v_mean5sd_rate, 15));
            v_mean7sd_rate := power(10, LEAST(v_mean7sd_rate, 15));
            v_mean8sd_rate := power(10, LEAST(v_mean8sd_rate, 15));
            v_mean10sd_rate := power(10, LEAST(v_mean10sd_rate, 15));
            v_mean12sd_rate := power(10, LEAST(v_mean12sd_rate, 15));

            BEGIN
               SELECT   mean_limit
               INTO     v_mean_limit_str
               FROM     outlier_final_stats
               WHERE    ago_ind = oas_rec.ago_ind AND
                        unit_treated = v_unit_treated AND
                        ai_rate_type = v_ai_rate_type AND
                        site_type = v_site_type;
            EXCEPTION
               WHEN OTHERS THEN
                  v_mean_limit_str := NULL;
            END;

            IF v_mean_limit_str = 'MEAN5SD' THEN
               v_mean_limit := v_mean5sd_rate;
            ELSIF v_mean_limit_str = 'MEAN7SD' THEN
               v_mean_limit := v_mean7sd_rate;
            ELSIF v_mean_limit_str = 'MEAN8SD' THEN
               v_mean_limit := v_mean8sd_rate;
            ELSIF v_mean_limit_str = 'MEAN10SD' THEN
               v_mean_limit := v_mean10sd_rate;
            ELSIF v_mean_limit_str = 'MEAN12SD' THEN
               v_mean_limit := v_mean12sd_rate;
            ELSE
               v_mean_limit := NULL;
            END IF;

            v_outlier_limit := LEAST(v_mean_limit, v_fixed2);

            --DBMS_OUTPUT.PUT_LINE('v_outlier_limit = '||v_outlier_limit);

            /* Get the outlier limit for the product and
               choose the smallest outlier limit among all AIs
               for this product. This procedure may be called
               with unit_treated = S, K, or T which need to
               be converted to A, C, or P which are the units
               in the outlier tables.
             */
            v_ai_pct := ai_rec.prodchem_pct/100;
            --DBMS_OUTPUT.PUT_LINE('v_ai_pct = '||v_ai_pct);
            IF v_ai_pct > 0 THEN
               v_outlier_limit_prod := v_outlier_limit*v_unit_conversion/v_ai_pct;
            ELSE
               v_outlier_limit_prod := NULL;
            END IF;

            --DBMS_OUTPUT.PUT_LINE('v_outlier_limit_prod = '||v_outlier_limit_prod);
            IF v_outlier_limit_prod < v_outlier_limit_min THEN
               v_outlier_limit_min := v_outlier_limit_prod;
               v_chem_code := ai_rec.chem_code;
               v_chemname := ai_rec.chemname;

               IF v_ai_pct > 0 THEN
                  v_mean5sd_prod := v_mean5sd_rate*v_unit_conversion/v_ai_pct;
                  v_mean7sd_prod := v_mean7sd_rate*v_unit_conversion/v_ai_pct;
                  v_mean8sd_prod := v_mean8sd_rate*v_unit_conversion/v_ai_pct;
                  v_mean10sd_prod := v_mean10sd_rate*v_unit_conversion/v_ai_pct;
                  v_mean12sd_prod := v_mean12sd_rate*v_unit_conversion/v_ai_pct;
                  v_fixed1_prod := v_fixed1*v_unit_conversion/v_ai_pct;
                  v_fixed2_prod := v_fixed2*v_unit_conversion/v_ai_pct;
                  v_fixed3_prod := v_fixed3*v_unit_conversion/v_ai_pct;
               ELSE
                  v_mean5sd_prod := NULL;
                  v_mean7sd_prod := NULL;
                  v_mean8sd_prod := NULL;
                  v_mean10sd_prod := NULL;
                  v_mean12sd_prod := NULL;
                  v_fixed1_prod := NULL;
                  v_fixed2_prod := NULL;
                  v_fixed3_prod := NULL;
               END IF;
            END IF;
         END IF;

      END LOOP;

      IF v_outlier_stats_exist THEN
         INSERT INTO outlier_all_stats VALUES
            (oas_rec.regno_short, oas_rec.ago_ind, oas_rec.site_general, v_site_type, 
             oas_rec.unit_treated, v_chem_code, v_chemname, v_ai_rate_type,
             v_mean5sd_prod, v_mean7sd_prod, v_mean8sd_prod, 
             v_mean10sd_prod, v_mean12sd_prod,
             v_fixed1_prod, v_fixed2_prod, v_fixed3_prod, 
             v_outlier_limit_min);

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

