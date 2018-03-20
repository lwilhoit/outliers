DECLARE
    file_name_in VARCHAR2(10);
	callingWebserver VARCHAR2(10);
	asyncURL VARCHAR2(10);
	
	res_val NUMBER;
	ecode NUMBER(38);
    numRows NUMBER;
    thisproc constant VARCHAR2(50) := 'Load_raw';
    emesg VARCHAR2(250);
    response VARCHAR2(2000);
    inputfile xmltype;
    numEdits NUMBER; -- WST 10/31/11
    
    checkCountRaw NUMBER; -- MWW 11/22/11
    checkCountEdit NUMBER; -- MWW 11/22/11
    
    checkCountAllRaw NUMBER; -- JYU 07/02/12
    checkCountAllEdit NUMBER; -- JYU 07/02/12    
    curr_year NUMBER; -- JYU 07/02/12  current year 
    year_in  NUMBER; -- JYU 07/02/12  move from input argument to variable

  BEGIN
    file_name_in := 'Outlier';
	callingWebserver := 'Outlier';
	asyncURL := 'Outlier';
    PUR_XML_LOAD.logInsert('PUR_XML_LOAD.LOAD_RAW',file_name_in,'XML Loader stored proceedure initialized.');
    res_val := 0; -- set return value to "good"
    
    -----------------------------------------------------------
    -- CHECK INTERMEDIATE TABLES FOR VALUES BEFORE PROCEEDING
    -----------------------------------------------------------
    SELECT COUNT(*) INTO checkCountRaw
      FROM RAW_I;

    SELECT COUNT(*) INTO checkCountEdit
      FROM EDIT_I;

    -----------------------------------------------------------
    -- JYU 07-02-12 CHECK RAW_ALL_I and EDIT_RAW_I INTERMEDIATE TABLES FOR VALUES BEFORE PROCEEDING
    -----------------------------------------------------------
    SELECT COUNT(*) INTO checkCountAllRaw
      FROM RAW_ALL_I;

    SELECT COUNT(*) INTO checkCountAllEdit
      FROM EDIT_ALL_I;


    IF checkCountRaw = 0 AND checkCountEdit = 0 AND checkCountAllRaw = 0 AND checkCountAllEdit = 0 THEN
      -----------------
      -- LOCK IF EMPTY
      -----------------
      LOCK TABLE RAW_I IN EXCLUSIVE MODE;
      LOCK TABLE EDIT_I IN EXCLUSIVE MODE;
      -----------------
      -- JYU 07-02-12 LOCK IF EMPTY
      -----------------      
      LOCK TABLE RAW_ALL_I IN EXCLUSIVE MODE;
      LOCK TABLE EDIT_ALL_I IN EXCLUSIVE MODE;

      -- DOUBLE CHECK COUNT TO ENSURE THAT NO ROWS WERE ENTERED BEFORE LOCKING
      SELECT COUNT(*) INTO checkCountRaw
        FROM RAW_I;

      SELECT COUNT(*) INTO checkCountEdit
        FROM EDIT_I;
        
       -- JYU 07-02-12 
      SELECT COUNT(*) INTO checkCountAllRaw
        FROM RAW_ALL_I;

      SELECT COUNT(*) INTO checkCountAllEdit
       FROM EDIT_ALL_I;       

      IF checkCountRaw = 0 AND checkCountEdit = 0 AND checkCountAllRaw = 0 AND checkCountAllEdit = 0 THEN
        
        -- JYU 07-02-12 set curr_year
        select TO_CHAR(sysdate,'YYYY') into curr_year from dual;
        
        --======================================================================
        -- PERFORM PROCESSING - OLD CODE IN HERE
        --======================================================================

        -- LOAD INTERMEDIATE RAW TABLE FROM THE NEW FILE 
		/*
        inputfile := xmltype(bfilename('PPUR_XML_DIR',   file_name_in || '-new.xml'),   nls_charset_id('AL32UTF8'));
        countRows(inputfile,numRows);
        IF numRows >= 1 THEN
         readXML('RAW_ALL_I',inputfile);
        END IF;

		
        -- LOAD INTERMEDIATE EDIT TABLE FROM THE EDIT FILE
        inputfile := xmltype(bfilename('PPUR_XML_DIR',   file_name_in || '-edit.xml'),   nls_charset_id('AL32UTF8'));
        countRows(inputfile,numRows);
        IF numRows >= 1 THEN
          readXMLEdit('EDIT_ALL_I',inputfile);
        END IF;
		*/

INSERT INTO EDIT_ALL_I(YEAR,
USE_NO,
RECORD_ID,
PROCESS_MT,
PROCESS_YR,
BATCH_NO,
NURSERY_IND,
COUNTY_CD,
SECTION,
TOWNSHIP,
TSHIP_DIR,
RANGE,
RANGE_DIR,
BASE_LN_MER,
AER_GND_IND,
GROWER_ID,
CEDTS_IND,
SITE_LOC_ID,
ACRE_PLANTED,
UNIT_PLANTED,
APPLIC_DT,
SITE_CODE,
QUALIFY_CD,
PLANTING_SEQ,
ACRE_TREATED,
UNIT_TREATED,
MFG_FIRMNO,
LABEL_SEQ_NO,
REVISION_NO,
REG_FIRMNO,
AMT_PRD_USED,
UNIT_OF_MEAS,
DOCUMENT_NO,
SUMMARY_CD,
APPLIC_CNT,
APPLIC_TIME,
LICENSE_NO,
FILE_DATE,
FILE_NAME,
FUME_CD,
CTY_REC_KEY)
select 
YEAR,
USE_NO,
RECORD_ID,
PROCESS_MT,
PROCESS_YR,
BATCH_NO,
NURSERY_IND,
COUNTY_CD,
SECTION,
TOWNSHIP,
TSHIP_DIR,
RANGE,
RANGE_DIR,
BASE_LN_MER,
AER_GND_IND,
GROWER_ID,
CEDTS_IND,
SITE_LOC_ID,
ACRE_PLANTED,
UNIT_PLANTED,
APPLIC_DT,
SITE_CODE,
QUALIFY_CD,
PLANTING_SEQ,
ACRE_TREATED,
UNIT_TREATED,
MFG_FIRMNO,
LABEL_SEQ_NO,
REVISION_NO,
REG_FIRMNO,
AMT_PRD_USED,
UNIT_OF_MEAS,
DOCUMENT_NO,
SUMMARY_CD,
APPLIC_CNT,
APPLIC_TIME,
LICENSE_NO,
FILE_DATE,
FILE_NAME,
FUME_CD,
CTY_REC_KEY
from RAW_TEST_CASES ;


		
        --======================================================================
        -- JYU 0702 - Add for loop to process each year individually. It loops from curr_year-5 because we want to loop the past 6 years
        --======================================================================        
        
        for year_in in curr_year-5..curr_year loop
           PUR_XML_LOAD.logInsert('PUR_XML_LOAD.LOAD_RAW',file_name_in,'Process Year ' ||year_in );
           if year_in=curr_year then
             SELECT COUNT(*) INTO checkCountAllRaw
             FROM RAW_ALL_I;

             SELECT COUNT(*) INTO checkCountAllEdit
             FROM EDIT_ALL_I;             
             
             if checkCountAllRaw = 0 AND checkCountAllEdit = 0 THEN
                continue;
             else
                 INSERT INTO RAW_I SELECT * FROM  RAW_ALL_I;
                 INSERT INTO EDIT_I SELECT * FROM  EDIT_ALL_I;
                 DELETE FROM RAW_ALL_I;        
                 DELETE FROM EDIT_ALL_I;        
                 commit;
             end if;
           
           else

             SELECT COUNT(*) INTO checkCountAllRaw
             FROM RAW_ALL_I where substr(applic_dt,5,2) + 2000 =year_in;

             SELECT COUNT(*) INTO checkCountAllEdit
             FROM EDIT_ALL_I where substr(applic_dt,5,2) + 2000 = year_in;    

             if checkCountAllRaw = 0 AND checkCountAllEdit = 0 THEN
                continue;
             else
                 INSERT INTO RAW_I SELECT * FROM  RAW_ALL_I where substr(applic_dt,5,2) + 2000 = year_in;    
                 INSERT INTO EDIT_I SELECT * FROM  EDIT_ALL_I where substr(applic_dt,5,2) + 2000 = year_in;
                 DELETE FROM RAW_ALL_I where substr(applic_dt,5,2) + 2000 = year_in;        
                 DELETE FROM EDIT_ALL_I where substr(applic_dt,5,2) + 2000 = year_in;
                 commit;             
             end if;                
                        
           end if;
           
    
           -- START NEW CODE HERE!!  WST 10/31/11 ############################################
           select count(*) into numEdits
           from edit_i;
     
           IF numEdits >= 1 THEN
             PUR_XML_LOAD.logInsert('PUR_XML_LOAD.LOAD_RAW',file_name_in,'Edit_i values found. Processing edits...');
             for editRow in 
             (
              select * 
              from edit_i e
              where e.done IS NULL
             )
             LOOP
                -- Delete existing data for the edit record using the fully-pathed stored procedure in the PUR EDIT schema
                puredit.PUR_DELETE.deleteEntry(editRow.year, editRow.use_no, file_name_in, res_val);
             
                -- Insert the edit record into raw_i to be processed like a new record
                INSERT 
                INTO raw_i
                values(
                  NULL,  -- WILL NEED NEW YEAR, POPULATED BY STORED PROC
                  NULL,  -- WILL NEED NEW USE_NO, POPULATED BY STORED PROC
                  editRow.RECORD_ID,
                  editRow.PROCESS_MT,
                  editRow.PROCESS_YR,
                  editRow.BATCH_NO,
                  editRow.NURSERY_IND,
                  editRow.COUNTY_CD,
                  editRow.SECTION,
                  editRow.TOWNSHIP,
                  editRow.TSHIP_DIR,
                  editRow.RANGE,
                  editRow.RANGE_DIR,
                  editRow.BASE_LN_MER,
                  editRow.AER_GND_IND,
                  editRow.GROWER_ID,
                  editRow.CEDTS_IND,
                  editRow.SITE_LOC_ID,
                  editRow.ACRE_PLANTED,
                  editRow.UNIT_PLANTED,
                  editRow.APPLIC_DT,
                  editRow.SITE_CODE,
                  editRow.QUALIFY_CD,
                  editRow.PLANTING_SEQ,
                  editRow.ACRE_TREATED,
                  editRow.UNIT_TREATED,
                  editRow.MFG_FIRMNO,
                  editRow.LABEL_SEQ_NO,
                  editRow.REVISION_NO,
                  editRow.REG_FIRMNO,
                  editRow.AMT_PRD_USED,
                  editRow.UNIT_OF_MEAS,
                  editRow.DOCUMENT_NO,
                  editRow.SUMMARY_CD,
                  editRow.APPLIC_CNT,
                  editRow.APPLIC_TIME,
                  editRow.LICENSE_NO,
                  editRow.FILE_DATE,
                  editRow.FILE_NAME,
                  editRow.FUME_CD,
                  editRow.CTY_REC_KEY
                );
             
                -- Delete record from edit_i
                DELETE
                FROM edit_i
                WHERE edit_i.year = editRow.year AND edit_i.use_no = editRow.use_no;
             END LOOP;
             PUR_XML_LOAD.logInsert('PUR_XML_LOAD.LOAD_RAW',file_name_in,'Finished processing Edit_i values.');
           END IF;
    
           -- END NEW CODE HERE!! WST 10/31/11 ############################################
        
           -- NEW CODE insert log table!!  James Yu 06/15/12 ############
           INSERT INTO log
              (year, file_name, file_date, load_date, num_of_records, start_use_no, end_use_no)
           SELECT   year_in, file_name, file_date, SYSDATE, count(*), min(use_no), max(use_no) 
              FROM     raw_i
              GROUP BY file_name, file_date; 
           PUR_XML_LOAD.logInsert('PUR_XML_LOAD.LOAD_RAW',file_name_in,'Log record created');    
    
           co_error.check_records(year_in);
           PUR_XML_LOAD.logInsert('PUR_XML_LOAD.LOAD_RAW',file_name_in,'co_error.check_records ran');
        
           -- NEW CODE update log table!!  James Yu 06/15/12 ############
           UPDATE log SET  (start_use_no, end_use_no) =
              (SELECT min(use_no), max(use_no)
              FROM   raw_i)
              WHERE  file_name = file_name_in AND year = year_in;
           PUR_XML_LOAD.logInsert('PUR_XML_LOAD.LOAD_RAW',file_name_in,'Log record updated');  
        
           PUR_XML_load.move_intermediates(res_val);
           PUR_XML_LOAD.logInsert('PUR_XML_LOAD.LOAD_RAW',file_name_in,'move_intermediates ran');
        
           -- NEW CODE create nass file!!  James Yu 06/15/12 ############
           -- Renove nass file creation James Yu 09/15/2014
           /* nassfilecreate(year_in,file_name_in); */
           
        end loop;
        PUR_XML_LOAD.logInsert('TESTING',file_name_in,'callingWebserver: ' || callingWebserver || 'callback2.cfm?filename=' || file_name_in || 'asyncurl=' || asyncURL);
        PUR_XML_LOAD.logInsert('PUR_XML_LOAD.LOAD_RAW',file_name_in,'Callback ' || callingWebserver || ' URL requested');

        --======================================================================
        -- END PROCESSING
        --======================================================================
      ELSE
        ----------------------------------------------
        -- TABLE(S) NOT EMPTY, THROW CUSTOM EXCEPTION
        ----------------------------------------------
        IF checkCountRaw > 0 THEN 
          PUR_XML_LOAD.logInsert('PUR_XML_LOAD.LOAD_RAW', file_name_in, 'RAW_I table is not empty.  Processing aborted.');
        END IF;
        
        IF checkCountEdit > 0 THEN
          PUR_XML_LOAD.logInsert('PUR_XML_LOAD.LOAD_RAW', file_name_in, 'EDIT_I table is not empty.  Processing aborted.');        
        END IF;
        
        raise_application_error(-20001, 'RAW_I or EDIT_I table is not empty.  Processing aborted.');        
      END IF;
    
    ELSE
      ----------------------------------------------
      -- TABLE(S) NOT EMPTY, THROW CUSTOM EXCEPTION
      ----------------------------------------------
      IF checkCountRaw > 0 THEN 
        PUR_XML_LOAD.logInsert('PUR_XML_LOAD.LOAD_RAW', file_name_in, 'RAW_I table is not empty.  Processing aborted.');
      END IF;
      
      IF checkCountEdit > 0 THEN
        PUR_XML_LOAD.logInsert('PUR_XML_LOAD.LOAD_RAW', file_name_in, 'EDIT_I table is not empty.  Processing aborted.');        
      END IF;
      
      raise_application_error(-20001, 'RAW_I or EDIT_I table is not empty.  Processing aborted.');        
    END IF;
    

  EXCEPTION
    WHEN others THEN
      res_val := -1;
      -- set return value to "fail"
      PUR_XML_LOAD.logInsert('PUR_XML_LOAD.LOAD_RAW.EXCEPTION',NULL,'Error Code: '|| SQLCODE ||' Error Msg: '|| substr(SQLERRM, 1, 200));

      RAISE;
  END ;
/  
