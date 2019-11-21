/***************************************************************************************************************************/
/*  Macro  MSTAYIN                                                                                                         */
/*  Last updated: 10/21/2018;                                                                                              */
/*  Last Run: 10/21/2018;                                                                                                  */                                                                                   
/*  This SAS macro determines if a patient is short-stay or long-stay for each fall episode for those who fell during their*/
/*  nursing home stay. We search for a 5-day PPS assessment by looking back 101 days from the date of discharge to the     */
/*  hospital for the fall. If a 5-day PPS assessment is present in that look-back period, we categorize the stay as        */
/*  short-stay; otherwise, we categorize the stay as long-stay                                                             */                                                                     
/***************************************************************************************************************************/
dm 'log;clear;output;clear;';

%macro MSTAYIN;

*extract from all mds assessments for each beneficiary before the fall discharge assessment within 101 days prior;
*checked all target date equals discharge date a2000 in sample data;
proc sql;
create table _mdspre_samenh_claim_qmfall as
select M.A0310B, 
       M.m_trgt_dt,
	   M.bene_id,
	   F.uniqueid,
	   F.h_admsndt
from nhout.mdspre_samenh_claim_qmfall as F, 
     nhout.dmds as M         
where M.bene_id=F.bene_id and M.m_trgt_dt<=F.m_trgt_dt and F.m_trgt_dt-M.m_trgt_dt<=101;
quit;

proc sort data=_mdspre_samenh_claim_qmfall;
by uniqueid;
run;

*for each fall episode search for whether there is a 5-day pps assessment;
data _mdspre_samenh_claim_qmfall;
set _mdspre_samenh_claim_qmfall;
length shortstay 3.;
shortstay=0;
if A0310B="01" then shortstay=1; 
label shortstay="0 if bene is long stay, 1 if bene is short stay";
run;

proc sql noprint;
create table mdsbefore_los as
select distinct uniqueid, 
       sum(shortstay) as _shortstay
from _mdspre_samenh_claim_qmfall
group by uniqueid;
quit;

*create short-stay, long-stay indicator;
data mdsbefore_last;
set mdsbefore_los;
if _shortstay=0 then shortstay=0;
  else shortstay=1;
run;
 
*merge short-stay, long-stay indicator with the sample data;
proc sort data=nhout.mdspre_samenh_claim_qmfall out=mdspre_samenh_claim_qmfall;
by uniqueid;
run;

data nhout.mdspre_samenh_claim_stay;
merge mdsbefore_last
    mdspre_samenh_claim_qmfall(in=inm);
	by uniqueid;
	if inm;
run;

proc freq data=nhout.mdspre_samenh_claim_stay;
title "short/long stay distribution in mdsinside";
tables shortstay/missing;
run;

%mend MSTAYIN;

%MSTAYIN


