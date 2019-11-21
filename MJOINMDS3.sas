/**********************************************************************************************************************/
/*  Macro MJOINMDS3                                                                                                   */
/*  Last updated: 04/04/2018                                                                                          */
/*  Last run:  09/05/2018                                                                                             */                                                                                   
/*  This SAS macro merges MDS3 assessments with LTCfocus facility files to obtain provider basic information          */
/*  and provider number                                                                                               */       
/**********************************************************************************************************************/
dm 'log;clear;output;clear;';

%macro MJOINMDS3;
data mds3_2011_2015;
   set mdsout.mds3_2011 
       mdsout.mds3_2012 
       mdsout.mds3_2013 
       mdsout.mds3_2014
	   mdsout.mds3_2015;
   if bene_id^='';
run;

*change A1600_ENTRY_DT from char to num date9.;
data mds3_2011_2015;
   set mds3_2011_2015 (rename=(A1600_ENTRY_DT=_A1600_ENTRY_DT));
   length A1600_ENTRY_DT 4.
          FAC_INT_ID_STATE    $12.
          p 
          pp	$10.;
   format A1600_ENTRY_DT date9.;
   A1600_ENTRY_DT = input(_A1600_ENTRY_DT, anydtdte10.); 
   drop _A1600_ENTRY_DT;
   p = put(FAC_PRVDR_INTRNL_ID,10.); 
   pp = put(input(p,best10.),z10.);

*concatenate FAC_PRVDR_INTRNL_ID and STATE_CD to create new variable FAC_INT_ID_STATE;
   FAC_INT_ID_STATE = pp || STATE_CD; 
   drop p pp fac_prvdr_intrnl_id;

run;

*read LTCfocus facility file;
data facility; 
    set mdsfac.facility;

length FAC_INT_ID_STATE    $12.
       p 
       pp	$10.;

p = put(FACILITY_INTERNAL_ID,10.); 
pp = put(input(p,best10.),z10.);

*concatenate FACILITY_INTERNAL_ID and STATE_ID to create new variable FAC_INT_ID_STATE;
FAC_INT_ID_STATE = pp || STATE_ID; 
drop p pp FACILITY_INTERNAL_ID;

run;

proc sort data=facility nodupkey;
 by fac_int_id_state;
run;

*merge facility file with mds assessments based on matching FAC_INT_ID_STATE;
proc sql;
 create table mds3_facility_2011_2015 as select
   M.*,
   P.FAC_INT_ID_STATE,
   P.MCARE_ID            as PRVDR_NUM,
   P.NAME                as PRVDR_NAME,
   P.ADDRESS             as PRVDR_ADDRESS,
   P.FAC_CITY            as PRVDR_CITY,
   P.STATE_ID            as PRVDR_STATE_CD,
   P.FAC_ZIP             as PRVDR_ZIP,
   P.CATEGORY            as PRVDR_CTGRY,
   P.CLOSEDDATE          as PRVDR_CLOSE_DT

 from mds3_2011_2015 as M,
      facility as P
 where (M.FAC_INT_ID_STATE = P.FAC_INT_ID_STATE); 
quit;

proc sort data=mds3_facility_2011_2015 out=nhout.mds3_facility_2011_2015; 
 by bene_id trgt_dt a1600_entry_dt;
run;

*check invalid provider numbers;
data invalid_prvdrnum(keep=prvdr_num);
  set nhout.mds3_facility_2011_2015;
  if verify(trim(left(prvdr_num)), '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ')>0 or length(prvdr_num) ne 6 then output invalid_prvdrnum;
run;

proc freq data=invalid_prvdrnum;
tables prvdr_num;
run;

*drop assessments with invalid provider numbers;
data nhout.mds3_facility_2011_2015;
  set nhout.mds3_facility_2011_2015;
  if verify(trim(left(prvdr_num)), '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ')>0 or length(prvdr_num) ne 6 then delete;
run;

%mend MJOINMDS3;





