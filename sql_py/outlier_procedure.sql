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


DROP TABLE regno_chem;
CREATE TABLE regno_chem
   (regno_short	VARCHAR2(20),
    mfg_firmno    INTEGER,
    label_seq_no  INTEGER,
    chem_code     INTEGER)
NOLOGGING
PCTUSED 95
PCTFREE 3
TABLESPACE pur_report;

INSERT INTO regno_chem
   SELECT   DISTINCT mfg_firmno||'-'||label_seq_no, mfg_firmno, label_seq_no, chem_code
   FROM     prod_chem_major_ai left JOIN product using (prodno);

COMMIT;


/* Add column for outlier limits as pounds of product per unit treated.
 */
DROP TABLE outlier_rate_stats;
CREATE TABLE outlier_rate_stats
   (year						INTEGER,
  	 chem_code				INTEGER,
    ai_group            INTEGER,
    --ai_rate_type        VARCHAR2(20),
    ago_ind        		VARCHAR2(1),
    --record_id           VARCHAR2(1),
    unit_treated 			VARCHAR2(1),
    unit_treated_report VARCHAR2(1),
    site_general        VARCHAR2(100),
    site_code           INTEGER,
    --site_type           VARCHAR2(20),
    regno_short			VARCHAR2(20),
    mfg_firmno          INTEGER,
    label_seq_no        INTEGER,
	 mean3sd   				NUMBER)
NOLOGGING
PCTUSED 95
PCTFREE 3
STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0)
TABLESPACE pur_report;

INSERT INTO outlier_rate_stats
   SELECT   year, chem_code, NVL(ai_group, 1), ago_ind,
            unit_treated, unit_treated_report,
            site_general, site_code, 
            mfg_firmno||'-'||label_seq_no regno_short, 
            mfg_firmno, label_seq_no.
            CASE WHEN unit_treated_report = 'S' THEN mean3sd*43560
                 WHEN unit_treated_report = 'K' THEN mean3sd/1000
                 WHEN unit_treated_report = 'T' THEN mean3sd/2000
                 ELSE mean3sd
            END
   FROM     pur_report.ai_outlier_stats aios  LEFT JOIN pur_report.ai_group_stats using (year, chem_code, ai_group, ago_ind, unit_treated)
                                   LEFT JOIN regno_chem using (regno_short)
                                   LEFT JOIN pur_site_groups using (site_general)
                                   LEFT JOIN unit_treated_table using (unit_treated);

COMMIT;

                 /*
                 CASE WHEN record_id IN ('2', 'C') OR site_code < 100 OR 
                          (site_code > 29500 AND site_code NOT IN (30000, 30005, 40008, 66000)
                      THEN 'N'
                    ELSE 'A' 
                 END ago_ind, 
                 */


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


DROP TABLE outlier_all_stats;
CREATE TABLE outlier_all_stats
   (regno_short			VARCHAR2(20),
	 ago_ind        		VARCHAR2(1),
    site_general        VARCHAR2(100),
    unit_treated 			VARCHAR2(1),
    chem_code           INTEGER,
    chemname            VARCHAR2(200), -- The AI which resulted in this product having outlier
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

DROP TABLE outlier_final_stats;
CREATE TABLE outlier_final_stats
   (ago_ind        		VARCHAR2(1),
    unit_treated 			VARCHAR2(1),
    ai_rate_type        VARCHAR2(20),
    site_type           VARCHAR2(20),
    mean_limit          VARCHAR2(20)
	 outlier   				NUMBER)
NOLOGGING
PCTUSED 95
PCTFREE 3
STORAGE (INITIAL 1M NEXT 1M PCTINCREASE 0)
TABLESPACE pur_report;


DECLARE
   v_site_type       VARCHAR2(50);
   v_ai_adjuvant     VARCHAR2(1);
   v_ai_rate_type    VARCHAR2(50);
   v_unit_treated    VARCHAR2(1);
   v_ai_group        INTEGER;

   v_rate1           NUMBER;
   v_rate2           NUMBER;
   v_rate3           NUMBER;

   v_mean5sd_rate    NUMBER;
   v_mean7sd_rate    NUMBER;
   v_mean8sd_rate    NUMBER;
   v_mean10sd_rate   NUMBER;
   v_mean12sd_rate   NUMBER;

   v_rate1_prod      NUMBER;
   v_rate2_prod      NUMBER;
   v_rate3_prod      NUMBER;

   v_mean5sd_prod    NUMBER;
   v_mean7sd_prod    NUMBER;
   v_mean8sd_prod    NUMBER;
   v_mean10sd_prod   NUMBER;
   v_mean12sd_prod   NUMBER;


   v_mean_limit_str  VARCHAR2(100);
   v_mean_limit      NUMBER;
   v_ outlier_limit        NUMBER;
   v_ outlier_limit_prod   NUMBER;
   v_ outlier_limit_min    NUMBER;

   v_ai_pct                NUMBER;
   v_ai_pct_min            NUMBER;

   CURSOR oas_cur AS
      SELECT   regno_short, ago_ind, site_general, unit_treated
      FROM     outlier_all_stats_temp;

   CURSOR ai_cur(p_regno IN VARCHAR2) AS
      SELECT   DISTINCT chem_code, prodchem_pct
      FROM     prod_chem_major_ai
      WHERE    prodno IN (SELECT prodno FROM product WHERE mfg_firmno||'-'||label_seq_no = p_regno);
BEGIN

   FOR oas_rec IN oas_cur LOOP
      IF oas_rec.ago_ind = 'N' THEN
         IF oas_rec.site_general = 'WATER_AREA' THEN
            v_site_type = 'WATER'
         ELSE
            v_site_type = 'OTHER'
         END IF;
      ELSE
         v_site_type = 'ALL'
      END IF;

      IF oas_rec.unit_treated = 'S' THEN
         v_unit_treated := 'A';
      ELSIF oas_rec.unit_treated = 'K' THEN
         v_unit_treated := 'C';
      ELSIF oas_rec.unit_treated = 'T' THEN
         v_unit_treated := 'P';
      ELSE
         v_unit_treated := oas_rec.unit_treated;
      END IF;

      v_outlier_limit_min := 1000000000;
      --v_ai_pct := 100;
      FOR ai_rec IN ai_cur(oas_rec.regno_short) LOOP
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
                        unit_treated = oas_rec.unit_treated AND
                        site_type = oas_rec.site_type AND
                        chem_code = ai_rec.chem_code;
            EXCEPTION
               WHEN OTHERS THEN
                  v_ai_rate_type := 'NORMAL';
            END;
         END IF;

         BEGIN
            SELECT   rate1, rate2, rate3
            INTO     v_rate1, v_rate2, v_rate3
            FROM     fixed_outlier_rates
            WHERE    ago_ind = oas_rec.ago_ind AND
                     unit_treated = oas_rec.unit_treated AND
                     ai_rate_type = v_ai_rate_type AND
                     site_type = oas_rec.site_type;
         EXCEPTION
            WHEN OTHERS THEN
               v_rate1 := NULL;
               v_rate2 := NULL;
               v_rate3 := NULL;
         END;


         /* Get other rate outliers.
          */
         BEGIN
            SELECT   ai_group
            INTO     v_ai_group
            FROM     pur_report.ai_group_stats
            WHERE    chem_code = oas_rec.chem_code AND
                     regno_short = oas_rec.regno_short AND
                     site_general = oas_rec.site_general AND
                     ago_ind = oas_rec.ago_ind AND
                     unit_treated = oas_rec.unit_treated;
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
               FROM		ai_outlier_stats
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

         BEGIN
            SELECT   mean_limit
            INTO     v_mean_limit_str
            FROM     outlier_final_stats
            WHERE    ago_ind = v_ago_ind AND
                     unit_treated = v_unit_treated AND
                     ai_rate_type = v_ai_rate_type AND
                     site_type = v_site_type;
         EXCEPTION
            WHEN OTHERS THEN
               v_mean_limit_str := NULL;
         END;

         IF v_mean_limit_str = 'mean5sd' THEN
            v_mean_limit := v_mean5sd_rate;
         ELSIF IF v_mean_limit_str = 'mean7sd' THEN
            v_mean_limit := v_mean7sd THEN
         ELSIF IF v_mean_limit_str = 'mean8sd' THEN
            v_mean_limit := v_mean8sd THEN
         ELSIF IF v_mean_limit_str = 'mean10sd' THEN
            v_mean_limit := v_mean10sd THEN
         ELSIF IF v_mean_limit_str = 'mean12sd' THEN
            v_mean_limit := v_mean12sd THEN
         ELSE
            v_mean_limit := NULL;
         END IF;

         v_outlier_limit := MIN(v_mean_limit, v_fixed2);

         /* Get the outlier limit for the product and
            choose the smallest outlier limit among all AIs
            for this product.
          */
         v_outlier_limit_prod := v_outlier_limit/v_ai_pct;
         IF v_outlier_limit_prod < v_outlier_limit_min THEN
            v_outlier_limit_min := v_outlier_limit_prod;
            v_ai_pct := ai_rec.prodchem_pct/100;
            v_mean5sd_prod := v_mean5sd_rate/v_ai_pct;
            --v_ai_pct_min := v_ai_pct;
         END IF;

      END LOOP;

      INSERT INTO outlier_all_stats VALUES
         (aos_rec.regno_short, oas_rec.ago_ind, oas_rec.site_general, v_unit_treated,
          v_mean5sd_prod, v_mean7sd_rate/v_ai_pct, v_mean8sd_rate/v_ai_pct, 
          v_mean10sd_rate/v_ai_pct, v_mean12sd_rate/v_ai_pct,
          v_rate1/v_ai_pct, v_rate2/v_ai_pct, v_rate3/v_ai_pct, 
          v_outlier_limit_prod);
      
      COMMIT;
   END LOOP;

EXCEPTION
	WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(SQLERRM||'; use_no = '||v_use_no);
END;
/
show errors




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
/*
   CURSOR ai_cur(mfg_firmno IN NUMBER, label_seq_no IN NUMBER) AS
      SELECT   chem_code
      FROM     regno_chem
      WHERE    regno_short = mfg_firmno||'-'||label_seq_no;
*/
   CURSOR pur_cur AS
      SELECT   record_id, mfg_firmno, label_seq_no, site_code, unit_treated,
               lbs_prd_used, acre_treated
      FROM     ai_raw_rates
      WHERE    year = 2017;

BEGIN
   FOR pur_rec IN pur_cur LOOP
      IF pur_rec.record_id IN ('2', 'C') OR pur_rec.site_code < 100 OR 
            (pur_rec.site_code > 29500 AND pur_rec.site_code NOT IN (30000, 30005, 40008, 66000)) THEN
         v_ago_ind := 'N'; 
      ELSE 
         v_ago_ind :- 'A';
      END IF;

      /* Get outlier limits as pounds of product per unit.
       */
      SELECT   mean5sd, mean8sd
      INTO     v_mean5sd, v_mean8sd
      FROM     outlier_rate_stats
      WHERE    ago_ind = v_ago_ind AND
               regno_short = pur_rec.mfg_firmno||'-'||pur_rec.label_seq_no AND
               site_code = pur_rec.site_code AND
               unit_treated = pur_rec.unit_treated;


      SELECT   fixed2
      INTO     v_fixed2
      FROM     outlier_fixed_rate_stats
      ...

      SELECT   mean_limit
      INTO     v_mean_limit_str
      FROM     outlier_final_stats
      WHERE    ago_ind = v_ago_ind AND
               unit_treated = v_unit_treated AND
               ai_rate_type = v_ai_rate_type AND
               site_type = v_site_type;

      IF v_mean_limit_str = 'mean5sd' THEN
         v_mean_limit := v_mean5sd;
      ELSIF IF v_mean_limit_str = 'mean8sd' THEN
         v_mean_limit := v_mean8sd THEN
      END IF;
      
      outlier_limit := MIN(v_mean_limit, v_fixed2);



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

         IF v_ago_ind = 'N' THEN
            IF pur_rec.site_code IN (65000, 65011, 65015, 65021, 65026, 65029, 65503, 65505) 
            THEN
               v_site_type := 'WATER_SITE';
            ELSE
               v_site_type := 'OTHER';
            END IF;
         ELSE
            v_site_type := 'ALL';
         END IF;

         FOR ai_rec IN ai_cur(pur_rec.prodno) LOOP
            v_chem_code := ai_rec.chem_code;

            BEGIN
              SELECT adjuvant
              INTO   v_ai_adjuvant
              FROM   chem_adjuvant
              WHERE  chem_code = p_chem_code;
            EXCEPTION
              WHEN OTHERS THEN
                  v_ai_adjuvant := 'N';
            END;

            /* Get the AI rate type for this AI and type of application:
             */
            IF v_ai_adjuvant = 'Y' THEN
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
               WHERE		ago_ind = v_ago_ind AND
                        unit_treated = v_unit_treated AND
                        ai_rate_type = v_ai_rate_type AND
                        site_type = v_site_type;
            EXCEPTION
               WHEN OTHERS THEN
                  v_fixed1_rate := NULL;
                  v_fixed2_rate := NULL;
                  v_fixed3_rate := NULL;
            END;


   			/* Get other outlier limits.  First need the AI group number for this AI, product, site, ago_ind, and
   				unit_treated.
   			 */
   			BEGIN
   				SELECT	ai_group
   				INTO		v_ai_group_rate
   				FROM		ai_group_stats
   				WHERE		year = &&1 AND
   							chem_code = v_chem_code AND
   							regno_short = v_regno_short AND
   							site_general = v_site_general AND
   							ago_ind = v_ago_ind AND
   							unit_treated = v_unit_treated;
   			EXCEPTION
   				WHEN OTHERS THEN
   					v_ai_group_rate := NULL;
   			END;

   			/* Get the outlier statistics for this application from table AI_OUTLIER_STATS.
   			 */
   			IF v_ai_group_rate IS NULL THEN
   				/* If no statistics found for this AI, ago_ind, unit_treated, product, and site,
   					then use maximum outlier limits for this AI, ago_ind, and unit_treated.
   					If no statistics found for this AI, ago_ind, and unit_treated, just use fixed limits.
   				 */
   				BEGIN
   					SELECT	SUM(num_recs), MAX(med50), MAX(med100),
   								MAX(med150), MAX(med200), MAX(med250),
   								MAX(med300), MAX(med400), MAX(med500),
   								MAX(mean3sd), MAX(mean5sd), MAX(mean7sd),
   								MAX(mean8sd), MAX(mean10sd),
   								MAX(mean12sd), MAX(mean15sd),
   								MAX(sd_rate), MAX(sd_rate_trim_orig), MAX(sd_rate_trim)
   					INTO		v_num_recs_rate, v_med50_rate, v_med100_rate,
   								v_med150_rate, v_med200_rate, v_med250_rate,
   								v_med300_rate, v_med400_rate, v_med500_rate,
   								v_mean3sd_rate, v_mean5sd_rate, v_mean7sd_rate,
   								v_mean8sd_rate, v_mean10sd_rate,
   								v_mean12sd_rate, v_mean15sd_rate,
   								v_sd_rate, v_sd_trim_orig_rate, v_sd_trim_rate
   					FROM		ai_outlier_stats
   					WHERE		year = &&1 AND
   								chem_code = v_chem_code AND
   								ago_ind = v_ago_ind AND
   								unit_treated = v_unit_treated;
   				EXCEPTION
   					WHEN OTHERS THEN
   						v_num_recs_rate := NULL;
   						v_med50_rate := NULL;
   						v_med100_rate := NULL;
   						v_med150_rate := NULL;
   						v_med200_rate := NULL;
   						v_med250_rate := NULL;
   						v_med300_rate := NULL;
   						v_med400_rate := NULL;
   						v_med500_rate := NULL;
   						v_mean3sd_rate := NULL;
   						v_mean5sd_rate := NULL;
   						v_mean7sd_rate := NULL;
   						v_mean8sd_rate := NULL;
   						v_mean10sd_rate := NULL;
   						v_mean12sd_rate := NULL;
   						v_mean15sd_rate := NULL;
   						v_sd_rate := NULL;
   						v_sd_trim_orig_rate := NULL;
   						v_sd_trim_rate := NULL;
   				END;
   			ELSE -- An AI group is found for this record.
   				BEGIN
   					SELECT	num_recs, med50, med100,
   								med150, med200, med250,
   								med300, med400, med500,
   								mean3sd, mean5sd, mean7sd,
   								mean8sd, mean10sd,
   								mean12sd, mean15sd,
   								sd_rate, sd_rate_trim_orig, sd_rate_trim
   					INTO		v_num_recs_rate, v_med50_rate, v_med100_rate,
   								v_med150_rate, v_med200_rate, v_med250_rate,
   								v_med300_rate, v_med400_rate, v_med500_rate,
   								v_mean3sd_rate, v_mean5sd_rate, v_mean7sd_rate,
   								v_mean8sd_rate, v_mean10sd_rate,
   								v_mean12sd_rate, v_mean15sd_rate,
   								v_sd_rate, v_sd_trim_orig_rate, v_sd_trim_rate
   					FROM		ai_outlier_stats
   					WHERE		year = &&1 AND
   								chem_code = v_chem_code AND
   								ai_group = v_ai_group_rate AND
   								ago_ind = v_ago_ind AND
   								unit_treated = v_unit_treated;
   				EXCEPTION
   					WHEN OTHERS THEN
   						v_num_recs_rate := NULL;
   						v_med50_rate := NULL;
   						v_med100_rate := NULL;
   						v_med150_rate := NULL;
   						v_med200_rate := NULL;
   						v_med250_rate := NULL;
   						v_med300_rate := NULL;
   						v_med400_rate := NULL;
   						v_med500_rate := NULL;
   						v_mean3sd_rate := NULL;
   						v_mean5sd_rate := NULL;
   						v_mean7sd_rate := NULL;
   						v_mean8sd_rate := NULL;
   						v_mean10sd_rate := NULL;
   						v_mean12sd_rate := NULL;
   						v_mean15sd_rate := NULL;
   						v_sd_rate := NULL;
   						v_sd_trim_orig_rate := NULL;
   						v_sd_trim_rate := NULL;
   				END;

   			END IF;


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
INSERT INTO unit_treated_table VALUES ('A', 'A');
INSERT INTO unit_treated_table VALUES ('A', 'S');
INSERT INTO unit_treated_table VALUES ('C', 'C');
INSERT INTO unit_treated_table VALUES ('C', 'K');
INSERT INTO unit_treated_table VALUES ('P', 'P');
INSERT INTO unit_treated_table VALUES ('P', 'T');
INSERT INTO unit_treated_table VALUES ('U', 'U');



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
        SELECT mfg_firmno||'-'||label_seq_no
        INTO   v_regno_short
        FROM   product
        WHERE  prodno = p_prodno;
      EXCEPTION
        WHEN OTHERS THEN
            v_regno_short := NULL;
      END;

    *********************************************************************************
        Get outliers in rates of use (pounds AI per unit treated).
        These includes some non-ag records when a unit treated is reported.
     ********************************************************************************
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

         IF v_ago_ind = 'N' THEN
            IF pur_rec.site_code IN (65000, 65011, 65015, 65021, 65026, 65029, 65503, 65505) 
            THEN
               v_site_type := 'WATER_SITE';
            ELSE
               v_site_type := 'OTHER';
            END IF;
         ELSE
            v_site_type := 'ALL';
         END IF;

         FOR ai_rec IN ai_cur(pur_rec.prodno) LOOP
            v_chem_code := ai_rec.chem_code;

            BEGIN
              SELECT adjuvant
              INTO   v_ai_adjuvant
              FROM   chem_adjuvant
              WHERE  chem_code = p_chem_code;
            EXCEPTION
              WHEN OTHERS THEN
                  v_ai_adjuvant := 'N';
            END;

            * Get the AI rate type for this AI and type of application:
             *
            IF v_ai_adjuvant = 'Y' THEN
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


            * Get the fixed outlier limits.
             *
            BEGIN
               SELECT	log_rate1, log_rate2, log_rate3
               INTO		v_fixed1_rate, v_fixed2_rate, v_fixed3_rate
               FROM		fixed_outlier_rates
               WHERE		ago_ind = v_ago_ind AND
                        unit_treated = v_unit_treated AND
                        ai_rate_type = v_ai_rate_type AND
                        site_type = v_site_type;
            EXCEPTION
               WHEN OTHERS THEN
                  v_fixed1_rate := NULL;
                  v_fixed2_rate := NULL;
                  v_fixed3_rate := NULL;
            END;


   			* Get other outlier limits.  First need the AI group number for this AI, product, site, ago_ind, and
   				unit_treated.
   			 *
   			BEGIN
   				SELECT	ai_group
   				INTO		v_ai_group_rate
   				FROM		ai_group_stats
   				WHERE		year = &&1 AND
   							chem_code = v_chem_code AND
   							regno_short = v_regno_short AND
   							site_general = v_site_general AND
   							ago_ind = v_ago_ind AND
   							unit_treated = v_unit_treated;
   			EXCEPTION
   				WHEN OTHERS THEN
   					v_ai_group_rate := NULL;
   			END;

   			* Get the outlier statistics for this application from table AI_OUTLIER_STATS.
   			 *
   			IF v_ai_group_rate IS NULL THEN
   				* If no statistics found for this AI, ago_ind, unit_treated, product, and site,
   					then use maximum outlier limits for this AI, ago_ind, and unit_treated.
   					If no statistics found for this AI, ago_ind, and unit_treated, just use fixed limits.
   				 *
   				BEGIN
   					SELECT	SUM(num_recs), MAX(med50), MAX(med100),
   								MAX(med150), MAX(med200), MAX(med250),
   								MAX(med300), MAX(med400), MAX(med500),
   								MAX(mean3sd), MAX(mean5sd), MAX(mean7sd),
   								MAX(mean8sd), MAX(mean10sd),
   								MAX(mean12sd), MAX(mean15sd),
   								MAX(sd_rate), MAX(sd_rate_trim_orig), MAX(sd_rate_trim)
   					INTO		v_num_recs_rate, v_med50_rate, v_med100_rate,
   								v_med150_rate, v_med200_rate, v_med250_rate,
   								v_med300_rate, v_med400_rate, v_med500_rate,
   								v_mean3sd_rate, v_mean5sd_rate, v_mean7sd_rate,
   								v_mean8sd_rate, v_mean10sd_rate,
   								v_mean12sd_rate, v_mean15sd_rate,
   								v_sd_rate, v_sd_trim_orig_rate, v_sd_trim_rate
   					FROM		ai_outlier_stats
   					WHERE		year = &&1 AND
   								chem_code = v_chem_code AND
   								ago_ind = v_ago_ind AND
   								unit_treated = v_unit_treated;
   				EXCEPTION
   					WHEN OTHERS THEN
   						v_num_recs_rate := NULL;
   						v_med50_rate := NULL;
   						v_med100_rate := NULL;
   						v_med150_rate := NULL;
   						v_med200_rate := NULL;
   						v_med250_rate := NULL;
   						v_med300_rate := NULL;
   						v_med400_rate := NULL;
   						v_med500_rate := NULL;
   						v_mean3sd_rate := NULL;
   						v_mean5sd_rate := NULL;
   						v_mean7sd_rate := NULL;
   						v_mean8sd_rate := NULL;
   						v_mean10sd_rate := NULL;
   						v_mean12sd_rate := NULL;
   						v_mean15sd_rate := NULL;
   						v_sd_rate := NULL;
   						v_sd_trim_orig_rate := NULL;
   						v_sd_trim_rate := NULL;
   				END;
   			ELSE -- An AI group is found for this record.
   				BEGIN
   					SELECT	num_recs, med50, med100,
   								med150, med200, med250,
   								med300, med400, med500,
   								mean3sd, mean5sd, mean7sd,
   								mean8sd, mean10sd,
   								mean12sd, mean15sd,
   								sd_rate, sd_rate_trim_orig, sd_rate_trim
   					INTO		v_num_recs_rate, v_med50_rate, v_med100_rate,
   								v_med150_rate, v_med200_rate, v_med250_rate,
   								v_med300_rate, v_med400_rate, v_med500_rate,
   								v_mean3sd_rate, v_mean5sd_rate, v_mean7sd_rate,
   								v_mean8sd_rate, v_mean10sd_rate,
   								v_mean12sd_rate, v_mean15sd_rate,
   								v_sd_rate, v_sd_trim_orig_rate, v_sd_trim_rate
   					FROM		ai_outlier_stats
   					WHERE		year = &&1 AND
   								chem_code = v_chem_code AND
   								ai_group = v_ai_group_rate AND
   								ago_ind = v_ago_ind AND
   								unit_treated = v_unit_treated;
   				EXCEPTION
   					WHEN OTHERS THEN
   						v_num_recs_rate := NULL;
   						v_med50_rate := NULL;
   						v_med100_rate := NULL;
   						v_med150_rate := NULL;
   						v_med200_rate := NULL;
   						v_med250_rate := NULL;
   						v_med300_rate := NULL;
   						v_med400_rate := NULL;
   						v_med500_rate := NULL;
   						v_mean3sd_rate := NULL;
   						v_mean5sd_rate := NULL;
   						v_mean7sd_rate := NULL;
   						v_mean8sd_rate := NULL;
   						v_mean10sd_rate := NULL;
   						v_mean12sd_rate := NULL;
   						v_mean15sd_rate := NULL;
   						v_sd_rate := NULL;
   						v_sd_trim_orig_rate := NULL;
   						v_sd_trim_rate := NULL;
   				END;

   			END IF;


         END LOOP;



      END IF;

   END LOOP;

EXCEPTION
	WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(SQLERRM||'; use_no = '||v_use_no);
END;
/
show errors
*/

/*

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
