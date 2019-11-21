/**************************************************************************************************************************/
/*  Macro MQMFALL                                                                                                         */
/*  Last updated: 10/21/2018;                                                                                             */
/*  Last Run: 10/21/2018;                                                                                                 */          
/*  This SAS macro merges in NHC quality measure: Percent of Residents Experiencing One or More Falls with Major Injury   */
/*  for Long-Stay based on provider number and year                                                                       */
/*  The NHC quality measure data is available from year 2013 to 2017                                                      */
/*  Note: After merging with MDS assessments, among 5.6% of the MDS assessments in the sample in year 2013-2015 have missing*/
/*  values for the quality measure                                                                                        */ 
/**************************************************************************************************************************/

dm 'log;clear;output;clear;';

%macro MQMFALL(input, output);

data qm_fall(keep=YEAR _410 PROVNUM rename=(_410=mjfall provnum=m_prvdrnum year=trgtdt_year));
set mdsstar.qm_ratings_2013_2017;
if YEAR<=2015;
run;

*check how much percentage of the quality measure are missing;
proc sql;
select count (*)/(select count(*) from qm_fall) from qm_fall where mjfall=. ;quit;

proc sort data=qm_fall nodupkeys;
by m_prvdrnum trgtdt_year;
run;

proc sort data=nhout.&input. out=&input.;
by m_prvdrnum trgtdt_year;
run;

*merges quality measure with sample data;
data nhout.&output.;
merge &input.(in=inm)
    qm_fall;
by m_prvdrnum trgtdt_year;
if inm;
run;

proc sql;
select count (uniqueid)/(select count (uniqueid) from nhout.&output. where trgtdt_year>=2013) from nhout.&output. where mjfall=. and trgtdt_year>=2013;quit;

%mend MQMFALL;

*%MQMFALL(mdspre_samenh_claim_region,mdspre_samenh_claim_qmfall);
%MQMFALL(mdspre_claim_region,mdspre_claim_qmfall)

