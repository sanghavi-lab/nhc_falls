/***************************************************************************************************************************/
/*  Macro MDSCHRGADDCLAIM                                                                                                  */
/*  Last updated: 10/21/2018;                                                                                              */
/*  Last Run: 10/21/2018;                                                                                                  */                                                                                   
/*  This SAS macro merges fall claims with pre-hospitalization mds assessments for those who went back to same nursing home*/                                          
/***************************************************************************************************************************/

dm 'log;clear;output;clear;';

%macro MDSCHRGADDCLAIM;

*for patients who fell during their nh stay and went back to same nh;
*merge fall claims with discharge assessments;
proc sql;
 create table nhout.mdspre_samenh_claim as select
   P.*,
   C.*
 from nhout.mdspre_same_nh(drop=N_CLAIMS_MDS r) as P,
      nhout.hosprecord(drop=sortdt r uniqueid) as C
 where (P.BENE_ID = C.BENE_ID and P._N_CLAIMS_MDS = C.N_CLAIMS_MDS-1);
quit;

*for patients who fell during their nh stay;
*merge fall claims with discharge assessments;
proc sql;
 create table nhout.mdspre_claim as select
   P.*,
   C.*
 from nhout.getmdspre as P,
      nhout.hosprecord(drop=sortdt r uniqueid) as C
 where (P.BENE_ID = C.BENE_ID and P.N_CLAIMS_MDS = C.N_CLAIMS_MDS-1);
quit;

data nhout.mdspre_claim;
set nhout.mdspre_claim;
length uniqueid $30.;
uniqueid=bene_id || left(h_admsndt);
run;
*merge fall claims with post-hospitalization mds assessments;

/*
*locate fall claim from post-hospitalization mds assessments;
data mdspost_same_nh;
set nhout.mdspost_same_nh;
get1_n_claims_mds = get_n_claims_mds - 1; 
get2_n_claims_mds = get_n_claims_mds - 2; 
get3_n_claims_mds = get_n_claims_mds - 3; 
run;

*merge fall claims with entry/reentry assessments;
proc sql;
 create table mdspost_samenh_claim as select
   P.*,
   C.*
 from mdspost_same_nh(drop=N_CLAIMS_MDS r) as P left join
      nhout.hosprecord(drop=sortdt r) as C
 on (P.uniqueid = C.uniqueid) and (P.GET1_N_CLAIMS_MDS = C.N_CLAIMS_MDS or P.GET2_N_CLAIMS_MDS = C.N_CLAIMS_MDS or P.GET3_N_CLAIMS_MDS = C.N_CLAIMS_MDS);
quit;

*for post-hospitalization mds assessments;
*calculate the number of days elapsed since hospital admission;
*allow flexibility: if time elapsed>245, then remove from our sample;
data nhout.mdspost_samenh_claim;
set mdspost_claim_samenh;
length dayssincehospadmit 3.
       mo_post_claim 3.;
dayssincehospadmit = m_trgt_dt - h_admsndt;
by uniqueid;
if first.uniqueid then do;
 if dayssincehospadmit ne . then do;
   if -2<=dayssincehospadmit<=31 then do; mo_post_claim=1; _1mo_post_claim=1; end;
   else if 31<dayssincehospadmit<=190 then do; mo_post_claim=26; _2to6mos_post_claim=1; end;
	     else if 190 <=dayssincehospadmit< 245 then do; mo_post_claim=int(dayssincehospadmit/30); end;
		    else if dayssincehospadmit > 245 then delete;
   end;
end;
run;
*/

%mend MDSCHRGADDCLAIM;

