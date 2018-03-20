update RAW_TEST_CASES
	SET FILE_DATE='06-SEP-16',
		FILE_NAME='JAMESTEST';

update RAW_TEST_CASES
	SET DOCUMENT_NO = TRUNC(DBMS_RANDOM.value(1,10000000));

update RAW_TEST_CASES
	SET CTY_REC_KEY = dbms_random.value(1,1000000000000);

truncate table OUTLIERS_NEW;

4135759

delete from OPS$PURLOAD.log where load_date >= '03-SEP-16' ;

delete from OPS$PURLOAD.raw_pur where year is null or use_no is null;
delete from OPS$PURLOAD.PUR_LOOKUP  where seq_year is null or use_no is null;



delete from OPS$PURLOAD.PUR_LOOKUP where seq_year=2015 and use_no>=4127045;
delete from OPS$PURLOAD.PUR_LOOKUP where seq_year=2016 and use_no>=2008871;

delete from OPS$PURLOAD.raw_pur where year=2015 and use_no>=4127045;
delete from OPS$PURLOAD.raw_pur where year=2016 and use_no>=2008871;

delete from pur.pur where year=2015 and use_no>=4127045;
delete from pur.pur where year=2016 and use_no>=2008871;

delete from pur.outlier where year=2015 and use_no>=4127045;
delete from pur.outlier where year=2016 and use_no>=2008871;


delete from OPS$PURLOAD.changes where year=2015 and use_no>=4127045;
delete from OPS$PURLOAD.changes where year=2016 and use_no>=2008871;


delete from OPS$PURLOAD.errors where year=2015 and use_no>=4127045;
delete from OPS$PURLOAD.errors where year=2016 and use_no>=2008871;








