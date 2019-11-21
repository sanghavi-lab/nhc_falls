/**********************************************************************************************************************/
/*  Macro MMDSCLAIMS                                                                                                  */
/*  Last updated: 09/05/2018                                                                                          */
/*  Last run:  09/05/2018                                                                                             */                                                                                   
/*  This SAS macro creates a dataset that concatenates fall claims and MDS assessments for those patients whom we     */
/*  identified experienced a fall                                                                                     */
/**********************************************************************************************************************/
dm 'log;clear;output;clear;';

%macro MMDSCLAIMS;
*make a dataset for all five years of MedPAR fall claims;
data medpar_fall_mbsf_2011_2015;
   set nhout.medpar_fall_mbsf_2011
       nhout.medpar_fall_mbsf_2012
       nhout.medpar_fall_mbsf_2013
       nhout.medpar_fall_mbsf_2014
       nhout.medpar_fall_mbsf_2015;
run;

*make a dataset of bene_ids with a fall claim, and merge fall claims with MDS records for these benes;
data h_target_benes;
set  medpar_fall_mbsf_2011_2015(keep=bene_id);
run;

proc sort nodupkey data=h_target_benes;
 by bene_id;
run;

*make a dataset of bene_ids with an mds record, and merge mds assessments with fall claims for these benes;
data m_target_benes;
set nhout.mds3_fac_2011_2015_cap(keep=bene_id); 
run;

proc sort nodupkey data=m_target_benes;
 by bene_id;
run;

*create dataset that contains mds assessments for patients who had a fall claim;
proc sql;
 create table mdsdata as select
   M.*,
   T.*
 from nhout.mds3_fac_2011_2015_cap as M,
      h_target_benes as T
 where (M.BENE_ID = T.BENE_ID);
quit;

*create dataset that contains fall claims for patients who had mds assessments;
proc sql;
 create table claimsdata as select
   H.*,
   T.*
 from medpar_fall_mbsf_2011_2015 as H,
      m_target_benes as T
 where (H.BENE_ID = T.BENE_ID);
quit;

**concatenate the above two datasets, and sort by date: target date if mds, admission date if fall claim;
data mdsclaims;
set 
      mdsdata(rename=(
	     trgt_dt	 =m_trgt_dt
	     prvdr_num	 =m_prvdrnum 
	     dschrg		 =m_idschrg)
       in=inm)

      claimsdata(rename=(
	     age_cnt	=h_age_cnt
	     admsndt	=h_admsndt
	     dschrgdt	=h_dschrgdt
	     loscnt		=h_loscnt    
	     prvdr_num	=h_prvdrnum  
         dstntncd	=h_dstntncd 
	     dschrgcd	=h_dschrgcd 
          ) 
      in=inh);

length sortdt 4.;
format sortdt date10.;

*create date variable for sorting: for MDS records, use target dates, for hospital records, use admission dates;
if inm then sortdt=m_trgt_dt;
else if inh then sortdt=h_admsndt;

*create these variables to use in sorting when dates are a tie;
if A0310E_FIRST_SINCE_ADMSN_sCD="1" and A0310F_ENTRY_DSCHRG_CD="99" then m_a0310e=-1; else m_a0310e=0; 
if m_idschrg=1 then m_idschrg=-1; else m_idschrg=0; 

run;

proc sort data=mdsclaims;
 by bene_id sortdt m_a0310e m_idschrg ;
run;

data nhout.mdsclaims;
set mdsclaims;
run;


proc contents data=nhout.mdsclaims;
title "Concatenated MDS (with facility, CASPER) +MedPAR claims";
run;

proc print data=mdsclaims (obs=50);
 title 'Merged and Sorted MDS+CLAIMS';
 var bene_id 
     M_TRGT_DT
	   H_ADMSNDT
     A0310F_ENTRY_DSCHRG_CD
     A2000_DSCHRG_DT
     A2100_DSCHRG_STUS_CD
	 m_a0310e
	 m_idschrg
	 ;
run;

%mend MMDSCLAIMS;

