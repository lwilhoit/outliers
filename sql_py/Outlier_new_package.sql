/* Package Outlier_new_package should replace Package Outlier.
	These procedure determine what, if any, values to replace when
   outlier in rate of use is found.

 */
SET pause OFF
SET pagesize 75
SET linesize 120
SET termout ON
SET feedback ON
SET document OFF
SET verify OFF
SET trimspool ON
SET numwidth 11
SET serveroutput on size 1000000 format word_wrapped

CREATE OR REPLACE PACKAGE Outlier_new_package AS

   FUNCTION Wrong_unit
      (p_ago_ind IN VARCHAR2, p_regno_short IN VARCHAR2,
       p_site_general IN VARCHAR2, p_site_code IN NUMBER, 
       p_lbs_prd_used IN NUMBER,
		 p_acre_planted IN NUMBER, p_unit_planted IN VARCHAR2,
       p_acre_treated IN NUMBER, p_unit_treated IN OUT VARCHAR2,
		 p_replace_type OUT VARCHAR2)
   RETURN BOOLEAN;

   FUNCTION Wrong_acres
      (p_ago_ind IN VARCHAR2, p_site_code IN NUMBER,
       p_lbs_prd_used IN NUMBER, p_med_rate IN NUMBER,
       p_acre_planted IN VARCHAR2, p_unit_planted IN VARCHAR2,
       p_acre_treated IN OUT VARCHAR2, p_unit_treated IN VARCHAR2,
		 p_replace_type OUT VARCHAR2)
   RETURN BOOLEAN;

   PROCEDURE Wrong_lbs
      (p_prod_rate IN NUMBER, p_med_rate IN NUMBER, p_prodchem_pct IN NUMBER, p_amount_treated IN NUMBER,
		 p_lbs_prd_used IN OUT NUMBER, p_amt_prd_used IN OUT NUMBER,
		 p_replace_type OUT VARCHAR2);

   PROCEDURE Wrong_lbs_app
      (p_prod_rate IN NUMBER, p_med_rate IN NUMBER, p_prodchem_pct IN NUMBER, p_applic_cnt IN NUMBER,
       p_lbs_prd_used IN OUT NUMBER, p_amt_prd_used IN OUT NUMBER,
       p_replace_type OUT VARCHAR2);

END Outlier_new_package;
/
show errors

CREATE OR REPLACE PACKAGE BODY Outlier_new_package AS

   /* First see if unit_treated is unusual for this type of application--
      if so, and using the usual unit makes the rate reasonable,
      change unit.

		For Ag records:
      Nearly all prod ag records use unit = A, except for site_codes in this set
         (30, 90, 91, 99, 100, 151-156, 16003, 28078, 40011-62000, 68000-77000).

         If changing unit to A makes the rate less than the outlier limit and
			acres_treated <= acres_planted, then estimate unit = A.

		For non-ag:
		If changing unit treated to A makes the rate less than outlier change unit
		only for the following site codes, which primarily use A:
		(30, 40, 154, 28035, 28045, 28509, 29143, 30000, 30005, 66000, 67000).

		I had thought of just change S to A, C to K, and P to T, but this
		adds complications and aoplies very few records, these are
		just guesses, and the rate is probably better adjusted using acre treated
		in the next routine (Wrong_acres).

		Change S to A for site_codes in
			(10 - 40, 100, 152, 154, 156, 11001 - 13008, 23001, 28000, 28035, 28045, 29143, 30000, 30005, 33008, 65000 - 67000)

		Change C to K for site_codes in
			(10002 - 14011, 29111)

		Change P to T for site_codes in
			(90, 2000 - 2012, 14013, 28072, 29121)

     */
   FUNCTION Wrong_unit
      (p_ago_ind IN VARCHAR2, p_regno_short IN VARCHAR2,
       p_site_general IN VARCHAR2, p_site_code IN NUMBER, 
       p_lbs_prd_used IN NUMBER,
		 p_acre_planted IN NUMBER, p_unit_planted IN VARCHAR2,
       p_acre_treated IN NUMBER, p_unit_treated IN OUT VARCHAR2,
		 p_replace_type OUT VARCHAR2)
   RETURN BOOLEAN IS
      v_prod_rate_new 		NUMBER;
      v_outlier_limit      NUMBER;

		v_gen_acres_planted	NUMBER := NULL;

   BEGIN
		IF p_acre_treated > 0 THEN
			--DBMS_OUTPUT.PUT_LINE('In Wrong_unit()');

			/* v_ai_rate_new is the rate using the originally reported area or amount treated
				with unit_treated = A, S, C, K, P, T, or U.
			 */
			IF	(p_ago_ind = 'A' AND p_unit_treated <> 'A' AND
				 p_site_code NOT IN (30, 90, 91, 99, 100, 16003, 28078) AND
				 p_site_code NOT BETWEEN 151 AND 156 AND
				 p_site_code NOT BETWEEN 40011 AND 62000 AND
				 p_site_code NOT BETWEEN 68000 AND 77000) OR
				(p_ago_ind = 'N' AND p_unit_treated <> 'A' AND
				 p_site_code IN (30, 40, 154, 28035, 28045, 28509, 29143, 30000, 30005, 66000, 67000))
			THEN
				v_prod_rate_new := p_lbs_prd_used/p_acre_treated;
				--DBMS_OUTPUT.PUT_LINE('v_ai_rate_new = ' || v_ai_rate_new);

				/* If we made unit_treated = A, would the acres treated be
					greater than the acres planted? If yes, do not change
					unit_treated.
				 */
				IF p_unit_planted = 'A' THEN
					v_gen_acres_planted := p_acre_planted;
				ELSIF p_unit_planted = 'S' THEN
					v_gen_acres_planted := p_acre_planted/43560;
				ELSE
					v_gen_acres_planted := NULL;
				END IF;

				IF v_gen_acres_planted IS NOT NULL AND p_acre_treated > v_gen_acres_planted
				THEN
					--DBMS_OUTPUT.PUT_LINE('p_acre_treated > p_acre_planted');
					p_replace_type := 'SAME';
					RETURN FALSE;
				END IF;

				/* If we make unit_treated = A, would the new rate of use be less
					than all the outlier limits? If yes, change unit_treated.
				 */
            BEGIN
               SELECT   outlier_limit
               INTO     v_outlier_limit
               FROM     outlier_all_stats
               WHERE    regno_short = p_regno_short AND
                        site_general = p_site_general AND
                        ago_ind = p_ago_ind AND
                        unit_treated = 'A';

            EXCEPTION
               WHEN OTHERS THEN
                  v_outlier_limit := NULL;
            END;

				IF v_prod_rate_new < v_outlier_limit THEN
					--DBMS_OUTPUT.PUT_LINE('p_replace_type := ESTIMATE.');
					p_unit_treated := 'A';
					p_replace_type := 'ESTIMATE';
					RETURN TRUE;
				ELSE
					p_replace_type := 'SAME';
					RETURN FALSE;
				END IF;
			ELSE
				p_replace_type := 'SAME';
				RETURN FALSE;
			END IF;
		ELSE
			p_replace_type := 'SAME';
			RETURN FALSE;
		END IF;

   EXCEPTION
      WHEN OTHERS THEN
			p_replace_type := NULL;
         RETURN FALSE;
   END Wrong_unit;

   /* For situations with low value for acre_treated (nursery, greenhouse,
      and a few other uses can have low areas treated so ignore those),
      calculate a new value for acre_treated from the lbs_prd_used
      and the median rate for this product on this site.
      If the new value for acre_treated is less than acre_planted then
      use the new value as an estimate of acre_treated.

		Since acre_planted is used only for ag records, we can ignore
		nonag records.  For ag records, there are no records with units = P or T.
		Also, for units = C, K, U, the reported acres varies so much,
		it is not worth trying to determine limits.

		Low acre site_codes:
		< 1000, 1000, 2000, 3000, 4000, 5000, 6000,
		2005, 6006, 6012, 6030, 8000 - 8049, 10010, 10015 - 11001, 13004, 13009 - 13015, 13022 - 13027,
		13055 - 13509, 14004, 14005, 14010, 14014, 14015, 14023, 15015, 16003, 28008, 28012, 28024,
		29008, 29109, 29123, 29126, 29137, 30005, 60000 - 65021, 67000 - 77000)

		Note: in IF THEN statement cannot have expression such as:
		p_site_code NOT IN (SELECT site_code FROM low_acre_sites)
    */
   FUNCTION Wrong_acres
      (p_ago_ind IN VARCHAR2, p_site_code IN NUMBER,
       p_lbs_prd_used IN NUMBER, p_med_rate IN NUMBER,
       p_acre_planted IN VARCHAR2, p_unit_planted IN VARCHAR2,
       p_acre_treated IN OUT VARCHAR2, p_unit_treated IN VARCHAR2,
		 p_replace_type OUT VARCHAR2)
   RETURN BOOLEAN IS
      v_estimated_acres_treated	NUMBER := NULL;
      v_acres_planted            NUMBER := NULL;
      v_acres_treated            NUMBER := NULL;
      v_median_rate		         NUMBER := NULL;
      v_prod_rate                NUMBER := NULL;
   BEGIN
      IF p_ago_ind = 'A' AND
         p_acre_treated < 1.0 AND
         p_acre_treated > 0.0 AND
         p_acre_planted IS NOT NULL AND
         p_unit_treated IN ('A','S') AND
         p_unit_planted IN ('A','S') AND
         (p_site_code NOT IN
					(1000, 1000, 2000, 3000, 4000, 5000, 6000,
					 2005, 6006, 6012, 6030, 10010, 13004, 14004, 14005, 14010,
					 14014, 14015, 14023, 15015, 16003, 28008, 28012, 28024,
                29008, 29109, 29123, 29126, 29137, 30005) AND
				p_site_code NOT BETWEEN 8000 AND 8049 AND
				p_site_code NOT BETWEEN 10015 AND 11001 AND
				p_site_code NOT BETWEEN 13009 AND 13015 AND
				p_site_code NOT BETWEEN 13022 AND 13027 AND
				p_site_code NOT BETWEEN 13055 AND 13509 AND
				p_site_code NOT BETWEEN 60000 AND 65021 AND
				p_site_code NOT BETWEEN 67000 AND 77000)
      THEN
			-- The median rate uses specific unit_treated, so need to convert sq ft to acres.
			IF p_unit_planted = 'A' THEN
            v_acres_planted := p_acre_planted;
         ELSIF p_unit_planted = 'S' THEN
            v_acres_planted := p_acre_planted/43560;
         END IF;

			IF p_unit_treated = 'A' THEN
            v_acres_treated := p_acre_treated;
            v_median_rate := p_med_rate;
         ELSIF p_unit_treated = 'S' THEN
            v_acres_treated := p_acre_treated/43560;
            v_median_rate := p_med_rate*43560;
         END IF;

			IF v_median_rate < 0.000001 THEN
				v_median_rate := 0.000001;
			END IF;

			IF v_median_rate > 0 THEN
				v_estimated_acres_treated := p_lbs_prd_used/v_median_rate;
			ELSE
				v_estimated_acres_treated := NULL;
			END IF;

			IF v_estimated_acres_treated <= v_acres_planted AND 
            v_acres_treated > 0 
         THEN
            v_prod_rate := p_lbs_prd_used/v_acres_treated;

				/* Sometimes the median rate is actually more than the reported rate;
					in this case using the median as an estimate of the correct rate
					is inappropriate since doing so will only increase the rate.
				 */
				IF v_median_rate < v_prod_rate THEN
					IF p_unit_treated = 'A' THEN
						p_acre_treated := v_estimated_acres_treated;
					ELSE
						p_acre_treated := v_estimated_acres_treated * 43560;
					END IF;

					p_replace_type := 'ESTIMATE';
				ELSE
					p_replace_type := 'SAME';
				END IF;

				RETURN TRUE;
			ELSE
				p_replace_type := 'SAME';
				RETURN FALSE;
			END IF;
		ELSE
			p_replace_type := 'SAME';
			RETURN FALSE;
      END IF;

   EXCEPTION
      WHEN OTHERS THEN
			p_replace_type := NULL;
         RETURN FALSE;
   END Wrong_acres;

   /* If the unit_treated and acre_treated seem ok, then assume lbs_prd_used and
		amt_prd_used are incorrect and make estimates for these.
	 */
   PROCEDURE Wrong_lbs
      (p_prod_rate IN NUMBER, p_med_rate IN NUMBER, p_prodchem_pct IN NUMBER, p_amount_treated IN NUMBER,
		 p_lbs_prd_used IN OUT NUMBER, p_amt_prd_used IN OUT NUMBER,
		 p_replace_type OUT VARCHAR2)
   IS
      v_old_lbs_prd_used   NUMBER;

   BEGIN
		v_old_lbs_prd_used := p_lbs_prd_used;

		/* Sometimes the median rate is actually more than the reported rate;
			in this case using the median as an estimate of the correct rate
			is inappropriate since doing so will only increase the rate.
		 */
		IF p_med_rate < p_prod_rate THEN
			p_replace_type := 'ESTIMATE';

			p_lbs_prd_used := p_med_rate * p_amount_treated * 100/p_prodchem_pct;
			p_amt_prd_used := p_amt_prd_used * p_lbs_prd_used / v_old_lbs_prd_used;

			IF p_lbs_prd_used < 0.0001 THEN
				p_lbs_prd_used := 0.0001;
			END IF;

			IF p_amt_prd_used < 0.0001 THEN
				p_amt_prd_used := 0.0001;
			END IF;

			--DBMS_OUTPUT.PUT_LINE('; lbsprd '||p_lbs_prd_used||'; amt_treated '||p_amount_treated||'; med '||p_med_rate);
		ELSE
			p_replace_type := 'SAME';
		END IF;

   EXCEPTION
      WHEN OTHERS THEN
			p_replace_type := NULL;
   END Wrong_lbs;

   /* For rate as pounds product per application, lbs_prd_used and amt_prd_used are incorrect and 
      make estimates for these.
    */
   PROCEDURE Wrong_lbs_app
      (p_prod_rate IN NUMBER, p_med_rate IN NUMBER, p_prodchem_pct IN NUMBER, p_applic_cnt IN NUMBER,
       p_lbs_prd_used IN OUT NUMBER, p_amt_prd_used IN OUT NUMBER,
       p_replace_type OUT VARCHAR2)
   IS
      v_old_lbs_prd_used   NUMBER;

   BEGIN
      v_old_lbs_prd_used := p_lbs_prd_used;

      /* Sometimes the median rate is actually more than the reported rate;
         in this case using the median as an estimate of the correct rate
         is inappropriate since doing so will only increase the rate.
       */
      IF p_med_rate < p_prod_rate THEN
         p_replace_type := 'ESTIMATE';

         p_lbs_prd_used := p_med_rate * p_applic_cnt * 100/p_prodchem_pct;
         p_amt_prd_used := p_amt_prd_used * p_lbs_prd_used / v_old_lbs_prd_used;

         IF p_lbs_prd_used < 0.0001 THEN
            p_lbs_prd_used := 0.0001;
         END IF;

         IF p_amt_prd_used < 0.0001 THEN
            p_amt_prd_used := 0.0001;
         END IF;

         --DBMS_OUTPUT.PUT_LINE('; lbsprd '||p_lbs_prd_used||'; applic_cnt '||p_applic_cnt||'; med '||p_med_rate);
      ELSE
         p_replace_type := 'SAME';
      END IF;

   EXCEPTION
      WHEN OTHERS THEN
         p_replace_type := NULL;
   END Wrong_lbs_app;


END Outlier_new_package;
/
show errors



