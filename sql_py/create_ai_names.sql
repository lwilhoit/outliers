SET pause OFF
SET pagesize 75
SET linesize 148
SET termout ON
SET feedback ON
SET document OFF
SET verify OFF
SET trimspool ON
SET numwidth 11
SET SERVEROUTPUT ON
WHENEVER SQLERROR EXIT 1 ROLLBACK
WHENEVER OSERROR EXIT 1 ROLLBACK

/* Create a table with a general AI name for certain AIs that are split into different components.
	For the general ai_name, give a common ai_type (which is the most commonly type for that
	ai_name) and ai_types for each of the major crops.

	The fields chem_hyphen and ai_hyphen have the same values as chemname and ai_name, respectively,
	except that it includes Latex formatted optional hyphens.  You should use these fields when
	creating Latex files because then Latex can hyphenate long AI names in appropriate places.

	The ai_types are similar to that in table ai_categories, except that there the
	ai_types may be different for different specific AIs within an a general AI name.

	To create a new version of ai_names, use the hyphenated names and AI types from the
	previous version (which is now renamed ai_names_old).  For new AIs, you need to manually
	add the "\-" in the names.
 */
VARIABLE log_level NUMBER;

PROMPT ________________________________________________
PROMPT Creating table AI_NAMES...
DECLARE
	v_table_exists		INTEGER := 0;
BEGIN
   :log_level := &&1;

	SELECT	COUNT(*)
	INTO		v_table_exists
	FROM		user_tables
	WHERE		table_name = UPPER('ai_names_old');

	IF v_table_exists > 0 THEN
		EXECUTE IMMEDIATE 'DROP TABLE ai_names_old';
      print_info('Dropped table AI_NAMES_OLD', :log_level);
   ELSE
      print_debug('Table AI_NAMES_OLD does not exist.', :log_level);
	END IF;

	SELECT	COUNT(*)
	INTO		v_table_exists
	FROM		user_tables
	WHERE		table_name = UPPER('ai_names');

	IF v_table_exists > 0 THEN
		EXECUTE IMMEDIATE 'RENAME ai_names TO ai_names_old';
		--EXECUTE IMMEDIATE 'DROP INDEX ai_names_ndx';
		print_info('Renamed table AI_NAMES to AI_NAMES_OLD', :log_level);
   ELSE
      print_info('Table AI_NAMES does not exist', :log_level);
	END IF;

   print_info('Create table AI_NAMES now...', :log_level);
EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/
show errors

CREATE TABLE ai_names
     (chem_code         	NUMBER(5),
      chemname       		VARCHAR2(500),
      ai_name					VARCHAR2(500),
      chem_hyphen    		VARCHAR2(500),
      ai_hyphen      		VARCHAR2(500),
		ai_type					VARCHAR2(100),
      ai_type_alfalfa   	VARCHAR2(100),
      ai_type_almond    	VARCHAR2(100),
      ai_type_carrot    	VARCHAR2(100),
      ai_type_cotton    	VARCHAR2(100),
      ai_type_grape     	VARCHAR2(100),
      ai_type_lettuce   	VARCHAR2(100),
      ai_type_orange    	VARCHAR2(100),
      ai_type_peach     	VARCHAR2(100),
      ai_type_pistachio   	VARCHAR2(100),
      ai_type_rice      	VARCHAR2(100),
      ai_type_strawberry   VARCHAR2(100),
      ai_type_tomato    	VARCHAR2(100),
      ai_type_walnut    	VARCHAR2(100),
      risk              	VARCHAR2(20))
   PCTUSED 95
   PCTFREE 3
   STORAGE(INITIAL 1M NEXT 1M PCTINCREASE 0)
   NOLOGGING
   TABLESPACE pur_report;

INSERT INTO ai_names
   SELECT   chem_code,
				chemical.chemname,
            CASE  WHEN oil = 'Y' THEN
                     'OIL'
                  WHEN chemical.chemname LIKE '%BACILLUS THURINGIENSIS%' THEN
                     'BACILLUS THURINGIENSIS'
                  WHEN chemical.chemname LIKE '%AGROBACTERIUM RADIOBACTER%' THEN
                     'AGROBACTERIUM RADIOBACTER'
                  WHEN chemical.chemname LIKE '%BACILLUS SPHAERICUS%' THEN
                     'BACILLUS SPHAERICUS'
                  WHEN chemical.chemname LIKE '%BACILLUS SUBTILLUS%' THEN
                     'BACILLUS SUBTILLUS'
                  WHEN chemical.chemname LIKE '%PSEUDOMONAS FLUORESCENS%' THEN
                     'PSEUDOMONAS FLUORESCENS'
                  WHEN chemical.chemname LIKE '%PSEUDOMONAS SYRINGAE%' THEN
                     'PSEUDOMONAS SYRINGAE'
                  WHEN chemical.chemname LIKE '%GLYPHOSATE%' THEN
                     'GLYPHOSATE'
                  WHEN chemical.chemname LIKE '2,4-D,%' THEN
                     '2,4-D'
                  WHEN chemical.chemname LIKE 'DICAMBA%' THEN
                     'DICAMBA'
                  WHEN chemical.chemname LIKE 'EDTA%' THEN
                     'EDTA'
                  WHEN chemical.chemname LIKE 'ENDOTHALL%' THEN
                     'ENDOTHALL'
                  WHEN chemical.chemname LIKE 'MCPP-P%' THEN
                     'MCPP-P'
                  WHEN chemical.chemname LIKE 'MCPP,%' THEN
                     'MCPP'
                  WHEN chemical.chemname LIKE 'NAA%' THEN
                     'NAA'
                  WHEN chem_code IN
                        (60, 147, 151, 153, 154, 155, 156, 158, 159, 161, 162, 163,
                         164, 175, 714, 753, 755, 1110, 1406, 1457, 1615, 1751, 1762,
                         1778, 1789, 1826, 2108, 2231, 2235, 2479, 2480, 3117, 3118,
                         3547, 3548, 3549, 3550, 3551, 3552, 3553, 5225, 5597) THEN
                     'COPPER'
                  ELSE
                     chemical.chemname
            END, 	-- ai_name
				NVL(chem_hyphen, chemical.chemname), 	-- chem_hyphen
            CASE  WHEN oil = 'Y' THEN
                     'OIL'
                  WHEN chemical.chemname LIKE '%BACILLUS THURINGIENSIS%' THEN
                     'BACIL\-LUS THURIN\-GIEN\-SIS'
                  WHEN chemical.chemname LIKE '%AGROBACTERIUM RADIOBACTER%' THEN
                     'AGRO\-BACTER\-IUM RADIO\-BACTER'
                  WHEN chemical.chemname LIKE '%BACILLUS SPHAERICUS%' THEN
                     'BACIL\-LUS SPHAER\-ICUS'
                  WHEN chemical.chemname LIKE '%BACILLUS SUBTILLUS%' THEN
                     'BACIL\-LUS SUB\-TILLUS'
                  WHEN chemical.chemname LIKE '%PSEUDOMONAS FLUORESCENS%' THEN
                     'PSEUDO\-MONAS FLUOR\-ESCENS'
                  WHEN chemical.chemname LIKE '%PSEUDOMONAS SYRINGAE%' THEN
                     'PSEUDO\-MONAS SYRINGAE'
                  WHEN chemical.chemname LIKE '%GLYPHOSATE%' THEN
                     'GLYPHOSATE'
                  WHEN chemical.chemname LIKE '2,4-D,%' THEN
                     '2,4-D'
                  WHEN chemical.chemname LIKE 'DICAMBA%' THEN
                     'DICAMBA'
                  WHEN chemical.chemname LIKE 'EDTA%' THEN
                     'EDTA'
                  WHEN chemical.chemname LIKE 'ENDOTHALL%' THEN
                     'ENDOTHALL'
                  WHEN chemical.chemname LIKE 'MCPP-P%' THEN
                     'MCPP-P'
                  WHEN chemical.chemname LIKE 'MCPP,%' THEN
                     'MCPP'
                  WHEN chemical.chemname LIKE 'NAA%' THEN
                     'NAA'
                  WHEN chem_code IN
                        (60, 147, 151, 153, 154, 155, 156, 158, 159, 161, 162, 163,
                         164, 175, 714, 753, 755, 1110, 1406, 1457, 1615, 1751, 1762,
                         1778, 1789, 1826, 2108, 2231, 2235, 2479, 2480, 3117, 3118,
                         3547, 3548, 3549, 3550, 3551, 3552, 3553, 5225, 5597) THEN
                     'COPPER'
						WHEN ai_hyphen IS NULL THEN
							chemical.chemname
                  ELSE
                     ai_hyphen
            END,  -- ai_hyphen
            CASE  WHEN oil = 'Y' THEN
                     'INSECTICIDE'
                  WHEN chemical.chemname LIKE '%BACILLUS THURINGIENSIS%' THEN
                     'INSECTICIDE'
                  WHEN chemical.chemname LIKE '%AGROBACTERIUM RADIOBACTER%' THEN
                     'FUNGICIDE'
                  WHEN chemical.chemname LIKE '%BACILLUS SPHAERICUS%' THEN
                     'INSECTICIDE'
                  WHEN chemical.chemname LIKE '%BACILLUS SUBTILLUS%' THEN
                     'INSECTICIDE'
                  WHEN chemical.chemname LIKE '%PSEUDOMONAS FLUORESCENS%' THEN
                     'FUNGICIDE'
                  WHEN chemical.chemname LIKE '%PSEUDOMONAS SYRINGAE%' THEN
                     'FUNGICIDE'
                  WHEN chemical.chemname LIKE '%GLYPHOSATE%' THEN
                     'HERBICIDE'
                  WHEN chemical.chemname LIKE '2,4-D,%' THEN
                     'HERBICIDE'
                  WHEN chemical.chemname LIKE 'DICAMBA%' THEN
                     'HERBICIDE'
                  WHEN chemical.chemname LIKE 'EDTA%' THEN
                     'ADJUVANT'
                  WHEN chemical.chemname LIKE 'ENDOTHALL%' THEN
                     'HERBICIDE'
                  WHEN chemical.chemname LIKE 'MCPP-P%' THEN
                     'HERBICIDE'
                  WHEN chemical.chemname LIKE 'MCPP,%' THEN
                     'HERBICIDE'
                  WHEN chemical.chemname LIKE 'NAA%' THEN
                     'PLANT_GROWTH_REGULATOR'
                  WHEN chem_code IN
                        (60, 147, 151, 153, 154, 155, 156, 158, 159, 161, 162, 163,
                         164, 175, 714, 753, 755, 1110, 1406, 1457, 1615, 1751, 1762,
                         1778, 1789, 1826, 2108, 2231, 2235, 2479, 2480, 3117, 3118,
                         3547, 3548, 3549, 3550, 3551, 3552, 3553, 5225, 5597) THEN
                     'FUNGICIDE'
                  ELSE
                     ai_categories.ai_type
            END,
				CASE  WHEN oil = 'Y' THEN
							'ADJUVANT'
						WHEN chemical.chemname LIKE '%BACILLUS THURINGIENSIS%' THEN
							'INSECTICIDE'
						WHEN chemical.chemname LIKE '%AGROBACTERIUM RADIOBACTER%' THEN
							'FUNGICIDE'
						WHEN chemical.chemname LIKE '%BACILLUS SPHAERICUS%' THEN
							'INSECTICIDE'
						WHEN chemical.chemname LIKE '%BACILLUS SUBTILLUS%' THEN
							'INSECTICIDE'
						WHEN chemical.chemname LIKE '%PSEUDOMONAS FLUORESCENS%' THEN
							'FUNGICIDE'
						WHEN chemical.chemname LIKE '%PSEUDOMONAS SYRINGAE%' THEN
							'FUNGICIDE'
						WHEN chemical.chemname LIKE '%GLYPHOSATE%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE '2,4-D,%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'DICAMBA%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'EDTA%' THEN
							'ADJUVANT'
						WHEN chemical.chemname LIKE 'ENDOTHALL%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'MCPP-P%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'MCPP,%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'NAA%' THEN
							'PLANT_GROWTH_REGULATOR'
						WHEN chem_code IN
								(60, 147, 151, 153, 154, 155, 156, 158, 159, 161, 162, 163,
								 164, 175, 714, 753, 755, 1110, 1406, 1457, 1615, 1751, 1762,
								 1778, 1789, 1826, 2108, 2231, 2235, 2479, 2480, 3117, 3118,
								 3547, 3548, 3549, 3550, 3551, 3552, 3553, 5225, 5597) THEN
							'FUNGICIDE'
						ELSE
							ai_categories.ai_type_alfalfa
				END,
				CASE  WHEN oil = 'Y' THEN
							'INSECTICIDE'
						WHEN chemical.chemname LIKE '%BACILLUS THURINGIENSIS%' THEN
							'INSECTICIDE'
						WHEN chemical.chemname LIKE '%AGROBACTERIUM RADIOBACTER%' THEN
							'FUNGICIDE'
						WHEN chemical.chemname LIKE '%BACILLUS SPHAERICUS%' THEN
							'INSECTICIDE'
						WHEN chemical.chemname LIKE '%BACILLUS SUBTILLUS%' THEN
							'INSECTICIDE'
						WHEN chemical.chemname LIKE '%PSEUDOMONAS FLUORESCENS%' THEN
							'FUNGICIDE'
						WHEN chemical.chemname LIKE '%PSEUDOMONAS SYRINGAE%' THEN
							'FUNGICIDE'
						WHEN chemical.chemname LIKE '%GLYPHOSATE%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE '2,4-D,%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'DICAMBA%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'EDTA%' THEN
							'ADJUVANT'
						WHEN chemical.chemname LIKE 'ENDOTHALL%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'MCPP-P%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'MCPP,%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'NAA%' THEN
							'PLANT_GROWTH_REGULATOR'
						WHEN chem_code IN
								(60, 147, 151, 153, 154, 155, 156, 158, 159, 161, 162, 163,
								 164, 175, 714, 753, 755, 1110, 1406, 1457, 1615, 1751, 1762,
								 1778, 1789, 1826, 2108, 2231, 2235, 2479, 2480, 3117, 3118,
								 3547, 3548, 3549, 3550, 3551, 3552, 3553, 5225, 5597) THEN
							'FUNGICIDE'
						ELSE
							ai_categories.ai_type_almond
				END,
				CASE  WHEN oil = 'Y' THEN
							'ADJUVANT'
						WHEN chemical.chemname LIKE '%BACILLUS THURINGIENSIS%' THEN
							'INSECTICIDE'
						WHEN chemical.chemname LIKE '%AGROBACTERIUM RADIOBACTER%' THEN
							'FUNGICIDE'
						WHEN chemical.chemname LIKE '%BACILLUS SPHAERICUS%' THEN
							'INSECTICIDE'
						WHEN chemical.chemname LIKE '%BACILLUS SUBTILLUS%' THEN
							'INSECTICIDE'
						WHEN chemical.chemname LIKE '%PSEUDOMONAS FLUORESCENS%' THEN
							'FUNGICIDE'
						WHEN chemical.chemname LIKE '%PSEUDOMONAS SYRINGAE%' THEN
							'FUNGICIDE'
						WHEN chemical.chemname LIKE '%GLYPHOSATE%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE '2,4-D,%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'DICAMBA%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'EDTA%' THEN
							'ADJUVANT'
						WHEN chemical.chemname LIKE 'ENDOTHALL%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'MCPP-P%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'MCPP,%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'NAA%' THEN
							'PLANT_GROWTH_REGULATOR'
						WHEN chem_code IN
								(60, 147, 151, 153, 154, 155, 156, 158, 159, 161, 162, 163,
								 164, 175, 714, 753, 755, 1110, 1406, 1457, 1615, 1751, 1762,
								 1778, 1789, 1826, 2108, 2231, 2235, 2479, 2480, 3117, 3118,
								 3547, 3548, 3549, 3550, 3551, 3552, 3553, 5225, 5597) THEN
							'FUNGICIDE'
						ELSE
							ai_categories.ai_type_carrot
				END,
				CASE  WHEN oil = 'Y' THEN
							'ADJUVANT'
						WHEN chemical.chemname LIKE '%BACILLUS THURINGIENSIS%' THEN
							'INSECTICIDE'
						WHEN chemical.chemname LIKE '%AGROBACTERIUM RADIOBACTER%' THEN
							'FUNGICIDE'
						WHEN chemical.chemname LIKE '%BACILLUS SPHAERICUS%' THEN
							'INSECTICIDE'
						WHEN chemical.chemname LIKE '%BACILLUS SUBTILLUS%' THEN
							'INSECTICIDE'
						WHEN chemical.chemname LIKE '%PSEUDOMONAS FLUORESCENS%' THEN
							'FUNGICIDE'
						WHEN chemical.chemname LIKE '%PSEUDOMONAS SYRINGAE%' THEN
							'FUNGICIDE'
						WHEN chemical.chemname LIKE '%GLYPHOSATE%' THEN
							'HERBICIDE/DEFOLIANT'
						WHEN chemical.chemname LIKE '2,4-D,%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'DICAMBA%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'EDTA%' THEN
							'ADJUVANT'
						WHEN chemical.chemname LIKE 'ENDOTHALL%' THEN
							'HERBICIDE/DEFOLIANT'
						WHEN chemical.chemname LIKE 'MCPP-P%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'MCPP,%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'NAA%' THEN
							'PLANT_GROWTH_REGULATOR'
						WHEN chem_code IN
								(60, 147, 151, 153, 154, 155, 156, 158, 159, 161, 162, 163,
								 164, 175, 714, 753, 755, 1110, 1406, 1457, 1615, 1751, 1762,
								 1778, 1789, 1826, 2108, 2231, 2235, 2479, 2480, 3117, 3118,
								 3547, 3548, 3549, 3550, 3551, 3552, 3553, 5225, 5597) THEN
							'FUNGICIDE'
						ELSE
							ai_categories.ai_type_cotton
				END,
				CASE  WHEN oil = 'Y' THEN
							'INSECTICIDE'
						WHEN chemical.chemname LIKE '%BACILLUS THURINGIENSIS%' THEN
							'INSECTICIDE'
						WHEN chemical.chemname LIKE '%AGROBACTERIUM RADIOBACTER%' THEN
							'FUNGICIDE'
						WHEN chemical.chemname LIKE '%BACILLUS SPHAERICUS%' THEN
							'INSECTICIDE'
						WHEN chemical.chemname LIKE '%BACILLUS SUBTILLUS%' THEN
							'INSECTICIDE'
						WHEN chemical.chemname LIKE '%PSEUDOMONAS FLUORESCENS%' THEN
							'FUNGICIDE'
						WHEN chemical.chemname LIKE '%PSEUDOMONAS SYRINGAE%' THEN
							'FUNGICIDE'
						WHEN chemical.chemname LIKE '%GLYPHOSATE%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE '2,4-D,%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'DICAMBA%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'EDTA%' THEN
							'ADJUVANT'
						WHEN chemical.chemname LIKE 'ENDOTHALL%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'MCPP-P%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'MCPP,%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'NAA%' THEN
							'PLANT_GROWTH_REGULATOR'
						WHEN chem_code IN
								(60, 147, 151, 153, 154, 155, 156, 158, 159, 161, 162, 163,
								 164, 175, 714, 753, 755, 1110, 1406, 1457, 1615, 1751, 1762,
								 1778, 1789, 1826, 2108, 2231, 2235, 2479, 2480, 3117, 3118,
								 3547, 3548, 3549, 3550, 3551, 3552, 3553, 5225, 5597) THEN
							'FUNGICIDE'
						ELSE
							ai_categories.ai_type_grape
				END,
				CASE  WHEN oil = 'Y' THEN
							'INSECTICIDE'
						WHEN chemical.chemname LIKE '%BACILLUS THURINGIENSIS%' THEN
							'INSECTICIDE'
						WHEN chemical.chemname LIKE '%AGROBACTERIUM RADIOBACTER%' THEN
							'FUNGICIDE'
						WHEN chemical.chemname LIKE '%BACILLUS SPHAERICUS%' THEN
							'INSECTICIDE'
						WHEN chemical.chemname LIKE '%BACILLUS SUBTILLUS%' THEN
							'INSECTICIDE'
						WHEN chemical.chemname LIKE '%PSEUDOMONAS FLUORESCENS%' THEN
							'FUNGICIDE'
						WHEN chemical.chemname LIKE '%PSEUDOMONAS SYRINGAE%' THEN
							'FUNGICIDE'
						WHEN chemical.chemname LIKE '%GLYPHOSATE%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE '2,4-D,%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'DICAMBA%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'EDTA%' THEN
							'ADJUVANT'
						WHEN chemical.chemname LIKE 'ENDOTHALL%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'MCPP-P%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'MCPP,%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'NAA%' THEN
							'PLANT_GROWTH_REGULATOR'
						WHEN chem_code IN
								(60, 147, 151, 153, 154, 155, 156, 158, 159, 161, 162, 163,
								 164, 175, 714, 753, 755, 1110, 1406, 1457, 1615, 1751, 1762,
								 1778, 1789, 1826, 2108, 2231, 2235, 2479, 2480, 3117, 3118,
								 3547, 3548, 3549, 3550, 3551, 3552, 3553, 5225, 5597) THEN
							'FUNGICIDE'
						ELSE
							ai_categories.ai_type_lettuce
				END,
				CASE  WHEN oil = 'Y' THEN
							'INSECTICIDE'
						WHEN chemical.chemname LIKE '%BACILLUS THURINGIENSIS%' THEN
							'INSECTICIDE'
						WHEN chemical.chemname LIKE '%AGROBACTERIUM RADIOBACTER%' THEN
							'FUNGICIDE'
						WHEN chemical.chemname LIKE '%BACILLUS SPHAERICUS%' THEN
							'INSECTICIDE'
						WHEN chemical.chemname LIKE '%BACILLUS SUBTILLUS%' THEN
							'INSECTICIDE'
						WHEN chemical.chemname LIKE '%PSEUDOMONAS FLUORESCENS%' THEN
							'FUNGICIDE'
						WHEN chemical.chemname LIKE '%PSEUDOMONAS SYRINGAE%' THEN
							'FUNGICIDE'
						WHEN chemical.chemname LIKE '%GLYPHOSATE%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE '2,4-D,%' THEN
							'PLANT_GROWTH_REGULATOR'
						WHEN chemical.chemname LIKE 'DICAMBA%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'EDTA%' THEN
							'ADJUVANT'
						WHEN chemical.chemname LIKE 'ENDOTHALL%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'MCPP-P%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'MCPP,%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'NAA%' THEN
							'PLANT_GROWTH_REGULATOR'
						WHEN chem_code IN
								(60, 147, 151, 153, 154, 155, 156, 158, 159, 161, 162, 163,
								 164, 175, 714, 753, 755, 1110, 1406, 1457, 1615, 1751, 1762,
								 1778, 1789, 1826, 2108, 2231, 2235, 2479, 2480, 3117, 3118,
								 3547, 3548, 3549, 3550, 3551, 3552, 3553, 5225, 5597) THEN
							'FUNGICIDE'
						ELSE
							ai_categories.ai_type_orange
				END,
				CASE  WHEN oil = 'Y' THEN
							'INSECTICIDE'
						WHEN chemical.chemname LIKE '%BACILLUS THURINGIENSIS%' THEN
							'INSECTICIDE'
						WHEN chemical.chemname LIKE '%AGROBACTERIUM RADIOBACTER%' THEN
							'FUNGICIDE'
						WHEN chemical.chemname LIKE '%BACILLUS SPHAERICUS%' THEN
							'INSECTICIDE'
						WHEN chemical.chemname LIKE '%BACILLUS SUBTILLUS%' THEN
							'INSECTICIDE'
						WHEN chemical.chemname LIKE '%PSEUDOMONAS FLUORESCENS%' THEN
							'FUNGICIDE'
						WHEN chemical.chemname LIKE '%PSEUDOMONAS SYRINGAE%' THEN
							'FUNGICIDE'
						WHEN chemical.chemname LIKE '%GLYPHOSATE%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE '2,4-D,%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'DICAMBA%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'EDTA%' THEN
							'ADJUVANT'
						WHEN chemical.chemname LIKE 'ENDOTHALL%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'MCPP-P%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'MCPP,%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'NAA%' THEN
							'PLANT_GROWTH_REGULATOR'
						WHEN chem_code IN
								(60, 147, 151, 153, 154, 155, 156, 158, 159, 161, 162, 163,
								 164, 175, 714, 753, 755, 1110, 1406, 1457, 1615, 1751, 1762,
								 1778, 1789, 1826, 2108, 2231, 2235, 2479, 2480, 3117, 3118,
								 3547, 3548, 3549, 3550, 3551, 3552, 3553, 5225, 5597) THEN
							'FUNGICIDE'
						ELSE
							ai_categories.ai_type_peach
				END,
            CASE  WHEN oil = 'Y' THEN
                     'INSECTICIDE'
                  WHEN chemical.chemname LIKE '%BACILLUS THURINGIENSIS%' THEN
                     'INSECTICIDE'
                  WHEN chemical.chemname LIKE '%AGROBACTERIUM RADIOBACTER%' THEN
                     'FUNGICIDE'
                  WHEN chemical.chemname LIKE '%BACILLUS SPHAERICUS%' THEN
                     'INSECTICIDE'
                  WHEN chemical.chemname LIKE '%BACILLUS SUBTILLUS%' THEN
                     'INSECTICIDE'
                  WHEN chemical.chemname LIKE '%PSEUDOMONAS FLUORESCENS%' THEN
                     'FUNGICIDE'
                  WHEN chemical.chemname LIKE '%PSEUDOMONAS SYRINGAE%' THEN
                     'FUNGICIDE'
                  WHEN chemical.chemname LIKE '%GLYPHOSATE%' THEN
                     'HERBICIDE'
                  WHEN chemical.chemname LIKE '2,4-D,%' THEN
                     'HERBICIDE'
                  WHEN chemical.chemname LIKE 'DICAMBA%' THEN
                     'HERBICIDE'
                  WHEN chemical.chemname LIKE 'EDTA%' THEN
                     'ADJUVANT'
                  WHEN chemical.chemname LIKE 'ENDOTHALL%' THEN
                     'HERBICIDE'
                  WHEN chemical.chemname LIKE 'MCPP-P%' THEN
                     'HERBICIDE'
                  WHEN chemical.chemname LIKE 'MCPP,%' THEN
                     'HERBICIDE'
                  WHEN chemical.chemname LIKE 'NAA%' THEN
                     'PLANT_GROWTH_REGULATOR'
                  WHEN chem_code IN
                        (60, 147, 151, 153, 154, 155, 156, 158, 159, 161, 162, 163,
                         164, 175, 714, 753, 755, 1110, 1406, 1457, 1615, 1751, 1762,
                         1778, 1789, 1826, 2108, 2231, 2235, 2479, 2480, 3117, 3118,
                         3547, 3548, 3549, 3550, 3551, 3552, 3553, 5225, 5597) THEN
                     'FUNGICIDE'
                  ELSE
                     ai_categories.ai_type_pistachio
            END,
				CASE  WHEN oil = 'Y' THEN
							'ADJUVANT'
						WHEN chemical.chemname LIKE '%BACILLUS THURINGIENSIS%' THEN
							'INSECTICIDE'
						WHEN chemical.chemname LIKE '%AGROBACTERIUM RADIOBACTER%' THEN
							'FUNGICIDE'
						WHEN chemical.chemname LIKE '%BACILLUS SPHAERICUS%' THEN
							'INSECTICIDE'
						WHEN chemical.chemname LIKE '%BACILLUS SUBTILLUS%' THEN
							'INSECTICIDE'
						WHEN chemical.chemname LIKE '%PSEUDOMONAS FLUORESCENS%' THEN
							'FUNGICIDE'
						WHEN chemical.chemname LIKE '%PSEUDOMONAS SYRINGAE%' THEN
							'FUNGICIDE'
						WHEN chemical.chemname LIKE '%GLYPHOSATE%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE '2,4-D,%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'DICAMBA%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'EDTA%' THEN
							'ADJUVANT'
						WHEN chemical.chemname LIKE 'ENDOTHALL%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'MCPP-P%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'MCPP,%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'NAA%' THEN
							'PLANT_GROWTH_REGULATOR'
						WHEN chem_code IN
								(60, 147, 151, 153, 154, 155, 156, 158, 159, 161, 162, 163,
								 164, 175, 714, 753, 755, 1110, 1406, 1457, 1615, 1751, 1762,
								 1778, 1789, 1826, 2108, 2231, 2235, 2479, 2480, 3117, 3118,
								 3547, 3548, 3549, 3550, 3551, 3552, 3553, 5225, 5597) THEN
							'ALGAECIDE'
						ELSE
							ai_categories.ai_type_rice
				END,
				CASE  WHEN oil = 'Y' THEN
							'INSECTICIDE'
						WHEN chemical.chemname LIKE '%BACILLUS THURINGIENSIS%' THEN
							'INSECTICIDE'
						WHEN chemical.chemname LIKE '%AGROBACTERIUM RADIOBACTER%' THEN
							'FUNGICIDE'
						WHEN chemical.chemname LIKE '%BACILLUS SPHAERICUS%' THEN
							'INSECTICIDE'
						WHEN chemical.chemname LIKE '%BACILLUS SUBTILLUS%' THEN
							'INSECTICIDE'
						WHEN chemical.chemname LIKE '%PSEUDOMONAS FLUORESCENS%' THEN
							'FUNGICIDE'
						WHEN chemical.chemname LIKE '%PSEUDOMONAS SYRINGAE%' THEN
							'FUNGICIDE'
						WHEN chemical.chemname LIKE '%GLYPHOSATE%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE '2,4-D,%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'DICAMBA%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'EDTA%' THEN
							'ADJUVANT'
						WHEN chemical.chemname LIKE 'ENDOTHALL%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'MCPP-P%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'MCPP,%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'NAA%' THEN
							'PLANT_GROWTH_REGULATOR'
						WHEN chem_code IN
								(60, 147, 151, 153, 154, 155, 156, 158, 159, 161, 162, 163,
								 164, 175, 714, 753, 755, 1110, 1406, 1457, 1615, 1751, 1762,
								 1778, 1789, 1826, 2108, 2231, 2235, 2479, 2480, 3117, 3118,
								 3547, 3548, 3549, 3550, 3551, 3552, 3553, 5225, 5597) THEN
							'FUNGICIDE'
						ELSE
							ai_categories.ai_type_strawberry
				END,
				CASE  WHEN oil = 'Y' THEN
							'INSECTICIDE'
						WHEN chemical.chemname LIKE '%BACILLUS THURINGIENSIS%' THEN
							'INSECTICIDE'
						WHEN chemical.chemname LIKE '%AGROBACTERIUM RADIOBACTER%' THEN
							'FUNGICIDE'
						WHEN chemical.chemname LIKE '%BACILLUS SPHAERICUS%' THEN
							'INSECTICIDE'
						WHEN chemical.chemname LIKE '%BACILLUS SUBTILLUS%' THEN
							'INSECTICIDE'
						WHEN chemical.chemname LIKE '%PSEUDOMONAS FLUORESCENS%' THEN
							'FUNGICIDE'
						WHEN chemical.chemname LIKE '%PSEUDOMONAS SYRINGAE%' THEN
							'FUNGICIDE'
						WHEN chemical.chemname LIKE '%GLYPHOSATE%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE '2,4-D,%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'DICAMBA%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'EDTA%' THEN
							'ADJUVANT'
						WHEN chemical.chemname LIKE 'ENDOTHALL%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'MCPP-P%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'MCPP,%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'NAA%' THEN
							'PLANT_GROWTH_REGULATOR'
						WHEN chem_code IN
								(60, 147, 151, 153, 154, 155, 156, 158, 159, 161, 162, 163,
								 164, 175, 714, 753, 755, 1110, 1406, 1457, 1615, 1751, 1762,
								 1778, 1789, 1826, 2108, 2231, 2235, 2479, 2480, 3117, 3118,
								 3547, 3548, 3549, 3550, 3551, 3552, 3553, 5225, 5597) THEN
							'FUNGICIDE'
						ELSE
							ai_categories.ai_type_tomato
				END,
				CASE  WHEN oil = 'Y' THEN
							'INSECTICIDE'
						WHEN chemical.chemname LIKE '%BACILLUS THURINGIENSIS%' THEN
							'INSECTICIDE'
						WHEN chemical.chemname LIKE '%AGROBACTERIUM RADIOBACTER%' THEN
							'FUNGICIDE'
						WHEN chemical.chemname LIKE '%BACILLUS SPHAERICUS%' THEN
							'INSECTICIDE'
						WHEN chemical.chemname LIKE '%BACILLUS SUBTILLUS%' THEN
							'INSECTICIDE'
						WHEN chemical.chemname LIKE '%PSEUDOMONAS FLUORESCENS%' THEN
							'FUNGICIDE'
						WHEN chemical.chemname LIKE '%PSEUDOMONAS SYRINGAE%' THEN
							'FUNGICIDE'
						WHEN chemical.chemname LIKE '%GLYPHOSATE%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE '2,4-D,%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'DICAMBA%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'EDTA%' THEN
							'ADJUVANT'
						WHEN chemical.chemname LIKE 'ENDOTHALL%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'MCPP-P%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'MCPP,%' THEN
							'HERBICIDE'
						WHEN chemical.chemname LIKE 'NAA%' THEN
							'PLANT_GROWTH_REGULATOR'
						WHEN chem_code IN
								(60, 147, 151, 153, 154, 155, 156, 158, 159, 161, 162, 163,
								 164, 175, 714, 753, 755, 1110, 1406, 1457, 1615, 1751, 1762,
								 1778, 1789, 1826, 2108, 2231, 2235, 2479, 2480, 3117, 3118,
								 3547, 3548, 3549, 3550, 3551, 3552, 3553, 5225, 5597) THEN
							'FUNGICIDE'
						ELSE
							ai_categories.ai_type_walnut
				END,
				CASE  WHEN oil = 'Y' THEN
							'LOW'
						WHEN chemical.chemname LIKE '%BACILLUS THURINGIENSIS%' THEN
							'LOW'
						WHEN chemical.chemname LIKE '%AGROBACTERIUM RADIOBACTER%' THEN
							'LOW'
						WHEN chemical.chemname LIKE '%BACILLUS SPHAERICUS%' THEN
							'LOW'
						WHEN chemical.chemname LIKE '%BACILLUS SUBTILLUS%' THEN
							'LOW'
						WHEN chemical.chemname LIKE '%PSEUDOMONAS FLUORESCENS%' THEN
							'LOW'
						WHEN chemical.chemname LIKE '%PSEUDOMONAS SYRINGAE%' THEN
							'LOW'
						WHEN chemical.chemname LIKE '%GLYPHOSATE%' THEN
							'OTHER'
						WHEN chemical.chemname LIKE '2,4-D,%' THEN
							'HIGH'
						WHEN chemical.chemname LIKE 'DICAMBA%' THEN
							'OTHER'
						WHEN chemical.chemname LIKE 'EDTA%' THEN
							'OTHER'
						WHEN chemical.chemname LIKE 'ENDOTHALL%' THEN
							'OTHER'
						WHEN chemical.chemname LIKE 'MCPP-P%' THEN
							'OTHER'
						WHEN chemical.chemname LIKE 'MCPP,%' THEN
							'OTHER'
						WHEN chemical.chemname LIKE 'NAA%' THEN
							'OTHER'
						WHEN chem_code IN
								(60, 147, 151, 153, 154, 155, 156, 158, 159, 161, 162, 163,
								 164, 175, 714, 753, 755, 1110, 1406, 1457, 1615, 1751, 1762,
								 1778, 1789, 1826, 2108, 2231, 2235, 2479, 2480, 3117, 3118,
								 3547, 3548, 3549, 3550, 3551, 3552, 3553, 5225, 5597) THEN
							'OTHER'
						ELSE
							ai_categories.risk
				END
   FROM     chemical LEFT JOIN ai_names_old USING (chem_code)
							LEFT JOIN ai_categories USING (chem_code)
   WHERE    chem_code != 0;

COMMIT;

INSERT INTO ai_names
			(chem_code, chemname, ai_name, chem_hyphen, ai_hyphen, ai_type, ai_type_grape,
			 ai_type_cotton, ai_type_rice, ai_type_strawberry, ai_type_carrot, ai_type_lettuce, ai_type_almond,
			 ai_type_walnut, ai_type_peach, ai_type_alfalfa, ai_type_orange, ai_type_tomato, risk)
   VALUES(NULL, 'UNKNOWN', 'UNKNOWN', 'UNKNOWN', 'UNKNOWN', 'UNKNOWN', 'UNKNOWN',
			 'UNKNOWN', 'UNKNOWN', 'UNKNOWN', 'UNKNOWN', 'UNKNOWN', 'UNKNOWN',
			 'UNKNOWN', 'UNKNOWN', 'UNKNOWN', 'UNKNOWN', 'UNKNOWN', 'UNKNOWN');

COMMIT;

/*
CREATE INDEX ai_names_ndx ON ai_names
   (chem_code);
*/


/* Add AI types to specific AIs with general AI.  That is,
	general AIs in AI_NAMES such as oils, copper, etc. all
	have an AI type assigned, but some specific AIs have
	no AI type.  As default set the AI types for these
	specific AIs equal to the AI type for the general AI.
 */
/*
GRANT SELECT ON ai_names TO PUBLIC;

PROMPT ________________________________________________
PROMPT update table AI_CATEGORIES...

UPDATE ai_categories aic
SET ai_type = (SELECT ai_type FROM ai_names WHERE chem_code = aic.chem_code)
WHERE	ai_type IS NULL;

UPDATE ai_categories aic
SET ai_type_alfalfa = (SELECT ai_type_alfalfa FROM ai_names WHERE chem_code = aic.chem_code)
WHERE	ai_type_alfalfa IS NULL;

UPDATE ai_categories aic
SET ai_type_almond = (SELECT ai_type_almond FROM ai_names WHERE chem_code = aic.chem_code)
WHERE	ai_type_almond IS NULL;

UPDATE ai_categories aic
SET ai_type_carrot = (SELECT ai_type_carrot FROM ai_names WHERE chem_code = aic.chem_code)
WHERE	ai_type_carrot IS NULL;

UPDATE ai_categories aic
SET ai_type_cotton = (SELECT ai_type_cotton FROM ai_names WHERE chem_code = aic.chem_code)
WHERE	ai_type_cotton IS NULL;

UPDATE ai_categories aic
SET ai_type_grape = (SELECT ai_type_grape FROM ai_names WHERE chem_code = aic.chem_code)
WHERE	ai_type_grape IS NULL;

UPDATE ai_categories aic
SET ai_type_lettuce = (SELECT ai_type_lettuce FROM ai_names WHERE chem_code = aic.chem_code)
WHERE	ai_type_lettuce IS NULL;

UPDATE ai_categories aic
SET ai_type_orange = (SELECT ai_type_orange FROM ai_names WHERE chem_code = aic.chem_code)
WHERE	ai_type_orange IS NULL;

UPDATE ai_categories aic
SET ai_type_peach = (SELECT ai_type_peach FROM ai_names WHERE chem_code = aic.chem_code)
WHERE	ai_type_peach IS NULL;

UPDATE ai_categories aic
SET ai_type_pistachio = (SELECT ai_type_pistachio FROM ai_names WHERE chem_code = aic.chem_code)
WHERE	ai_type_pistachio IS NULL;

UPDATE ai_categories aic
SET ai_type_rice = (SELECT ai_type_rice FROM ai_names WHERE chem_code = aic.chem_code)
WHERE	ai_type_rice IS NULL;

UPDATE ai_categories aic
SET ai_type_strawberry = (SELECT ai_type_strawberry FROM ai_names WHERE chem_code = aic.chem_code)
WHERE	ai_type_strawberry IS NULL;

UPDATE ai_categories aic
SET ai_type_tomato = (SELECT ai_type_tomato FROM ai_names WHERE chem_code = aic.chem_code)
WHERE	ai_type_tomato IS NULL;

UPDATE ai_categories aic
SET ai_type_walnut = (SELECT ai_type_walnut FROM ai_names WHERE chem_code = aic.chem_code)
WHERE	ai_type_walnut IS NULL;

COMMIT;
*/

EXIT 0


