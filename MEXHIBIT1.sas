
/**********************************************************************************************************************/
/*  Macro MEXHIBIT1                                                                                                   */
/*  Last updated: 10/17/2018                                                                                          */
/*  Last run:  10/22/2018                                                                                             */                                                                                   
/*  This SAS macro calculates counts for Flowchart of denominator populations for fall-related MDS items including    */
/*  1)  The number of MedPAR claims used in analysis                                                                  */
/*  2)  The number of fall episodes                                                                                   */ 
/*  Note that each fall episode has a uniqueid created by concatenating beneficiary ID and the date of IP admission   */
/**********************************************************************************************************************/
dm 'log;clear;output;clear;';

%macro MEXHIBIT1;

*count number of MedPAR claims;
proc sql;
create table medpar as 
select count(*) as count from mpar.medpar_all_file_2011;
select count(*) as count from mpar.medpar_all_file_2012;
select count(*) as count from mpar.medpar_all_file_2013;
select count(*) as count from mpar.medpar_all_file_2014;
select count(*) as count from mpar.medpar_all_file_2015_001;
select count(*) as count from mpar.medpar_all_file_2015_002;
select count(*) as count from mpar.medpar_all_file_2015_003;
select count(*) as count from mpar.medpar_all_file_2015_004;
quit;

proc sql noprint;
   select sum(count) into: n_medpar_claims from medpar; 
quit;	

*select fall claims identified from MedPAR and create uniqueid for each fall espisode;
*keep definite fals;
data allprimaryfall;
  length uniqueid $30.;
  set nhout.medpar_fall_mbsf_2011
      nhout.medpar_fall_mbsf_2012
      nhout.medpar_fall_mbsf_2013
      nhout.medpar_fall_mbsf_2014
      nhout.medpar_fall_mbsf_2015;
  if primary_dx=1;
  uniqueid=bene_id || left(ADMSNDT);
run;

*count the number of fall episodes identified as definite falls;
proc sql;
select count(distinct uniqueid) into: n_primaryfalls from allprimaryfall ;
quit;


*count number of fall episodes in left branch of flowchart;
proc sql;
select count(distinct uniqueid) into: n_fallin  from nhout.mds_claims_fallin;
select count(distinct uniqueid) into: n_fallin_notback from nhout.claims_fallin_notback;
select count(distinct uniqueid) into: n_fallin_back from nhout.mdspre_back ;
select count(distinct bene_id) into: n_fallin_backsame from nhout.mdspre_same_nh ;
select count(distinct uniqueid) into: n_fallin_backdiff from nhout.mdspost_different_nh;
select count(distinct uniqueid) into: n_fallin_backsame_mj from nhout.mdspre_samenh_claim_stay where majorinjury=1;
quit;


*count number of fall episodes in middle branch of flowchart;
proc sql;
select count(distinct uniqueid) into: n_fallin_nd from nhout.mds_claims_fallin_nodschrg;
select count(distinct uniqueid) into: n_fallin_nd_notback from nhout.getmdspost_fallin_notback_nd;
select count(distinct uniqueid) into: n_fallin_nd_back from nhout.getmdspost_fallin_back_nd;
select count(distinct uniqueid) into: n_fallin_nd_backdiff from nhout.mdspost_different_nh_nd;
select count(distinct uniqueid) into: n_fallin_nd_backsame from nhout.mdspost_same_nh_nd;
quit;

*count number of fall episodes in right branch of flowchart;
proc sql;
select count(distinct uniqueid) into: n_fallout from nhout.mds_claims_fallout_stay where primary_dx=1;
select count(distinct uniqueid) into: n_fallout_1mo from nhout.mds_claims_fallout_stay where _1MO_POST_CLAIM=1 and primary_dx=1;
select count(distinct uniqueid) into: n_fallout_2to6mo from nhout.mds_claims_fallout_stay where _2TO6MOS_POST_CLAIM=1 and primary_dx=1;
select count(distinct uniqueid) into: n_fallout_1mo_mj from nhout.mds_claims_fallout_stay where _1MO_POST_CLAIM=1 and primary_dx=1 and majorinjury=1;
select count(distinct uniqueid) into: n_fallout_2to6mo_mj from nhout.mds_claims_fallout_stay where _2TO6MOS_POST_CLAIM=1 and primary_dx=1 and majorinjury=1;
quit;

*create dataset flowchart to store counts;
proc sql noprint;
create table flowchart
(
no_medpar_claims num 3,
no_primaryfalls num 3,
no_fallin num 3,
no_fallin_notback num 3,
no_fallin_back num 3,
no_fallin_backsame num 3,
no_fallin_backdiff num 3,
no_fallin_backsame_mj num 3,
no_fallin_nd num 3,
no_fallin_nd_notback num 3,
no_fallin_nd_back num 3,
no_fallin_nd_backdiff num 3,
no_fallin_nd_backsame num 3,
no_fallout num 3,
no_fallout_1mo num 3,
no_fallout_2to6mo num 3,
no_fallout_1mo_mj num 3,
no_fallout_2to6mo_mj num 3,
 );
quit;

proc sql;
   insert into flowchart
      set 
          no_medpar_claims=&n_medpar_claims.,
          no_primaryfalls=&n_primaryfalls.,
          no_fallin=&n_fallin.,
		  no_fallin_notback=&n_fallin_notback.,
          no_fallin_back=&n_fallin_back.;
          no_fallin_backsame=&n_fallin_backsame.;
          no_fallin_backdiff=&n_fallin_backdiff.;
          no_fallin_backsame_mj=&n_fallin_backsame_mj.;
          no_fallin_nd=&n_fallin_nd.;
          no_fallin_nd_notback=&n_fallin_nd_notback.;
          no_fallin_nd_back=&n_fallin_nd_back.;
          no_fallin_nd_backdiff=&n_fallin_nd_backdiff.;
          no_fallin_nd_backsame=&n_fallin_nd_backsame.;
          no_fallout=&n_fallout.;
          no_fallout_1mo=&n_fallout_1mo.;
          no_fallout_2to6mo=&n_fallout_2to6mo.;
          no_fallout_1mo_mj=&n_fallout_1mo_mj.;
          no_fallout_2to6mo_mj=&n_fallout_2to6mo_mj.;

quit;

data nhout.flowchart;
set flowchart;
run;

%mend MEXHIBIT1;



