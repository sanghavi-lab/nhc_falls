/*****************************************************************************************************************************/
/*  Macro  MSTAYOUT                                                                                                          */
/*  Last updated: 10/21/2018;                                                                                                */
/*  Last Run: 10/21/2018;                                                                                                    */                                                                                   
/*  This SAS macro determines if a patient is short-stay or long-stay for each fall episode for those who fell outside of    */
/*  their nursing home stay. Search for a 5-day PPS assessment by looking forward 8 days from the date of entry/admission    */
/*  to nursing home after the inpatient stay. If a 5-day PPS assessment is present within those 8 days, we categorize the    */ 
/*  patient as short-stay; otherwise, we categorize the patient as long-stay.                                                */                                                                     
/*****************************************************************************************************************************/
dm 'log;clear;output;clear;';

%macro MSTAYOUT;

data nhout.mds_claims_fallout_mj;
set nhout.mds_claims_fallout_mj;
length uniqueid $30.;
uniqueid=bene_id || left(h_admsndt);
run;

*extract all mds assessments for each beneficiary within 8 days after NH admission;
*checked no missing A1600;
proc sql;
create table _mds_claims_fallout_mj as
select M.A0310B,
       M.m_trgt_dt,
	     F.uniqueid,
	     F.A1600
from  nhout.mds_claims_fallout_mj as F left join
      nhout.dmds as M
on M.bene_id=F.bene_id and F.A1600<=M.m_trgt_dt and M.m_trgt_dt-F.A1600<=8;
quit;

data _mds_claims_fallout_mj;
set _mds_claims_fallout_mj;
length shortstay 3.;
shortstay=0;
if A0310B="01" then shortstay=1; 
label shortstay="0 if bene is long stay, 1 if bene is short stay";
run;

*for each fall episode search for whether there is a 5-day pps assessment;
proc sql noprint;
create table mdsafter as
select distinct uniqueid, 
       sum(shortstay) as _shortstay
from _mds_claims_fallout_mj
group by uniqueid;
quit;

*create short-stay, long-stay indicator;
data mdsafter_last;
set mdsafter;
if _shortstay=0 then shortstay=0;
  else shortstay=1;
run;

proc sort data=nhout.mds_claims_fallout_mj out=mds_claims_fallout_mj;
by uniqueid;
run;

*merge short-stay, long-stay indicator with the sample data;
data nhout.mds_claims_fallout_stay;
merge 
    mds_claims_fallout_mj(in=inm)
    mdsafter_last;
	by uniqueid;
	if inm;
run;

proc freq data=nhout.mds_claims_fallout_stay;
title "short/long stay distribution for patients who fell outside";
tables shortstay/missing;
run;

%mend MSTAYOUT;
%MSTAYOUT

