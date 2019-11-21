/*****************************************************************************************************/
/*  Macro  MANALYSIS                                                                                 */
/*  Last updated: 11/21/2018                                                                         */
/*  Last run:  11/21/2018                                                                            */                                                                                   
/*  This SAS macro creates analysis sample for running linear mixed effect regression in stata       */
/*  1) subset variables needed for regression                                                        */
/*  2) get rid of obs with missing values                                                            */ 
/*  3) create categorical variables for niss, ownership type                                         */
/*  4) create variables for race mix and dual compositions                                           */
/******************************************************************************************************/
dm 'log;clear;output;clear;';

%macro MANALYSIS;

*extract cliaims-based fall rates from the yearly analytic files;
data nhout.mdsinside_2011_2015;
set nhout.mdsinside2015
nhout.mdsinside2014
nhout.mdsinside2013
nhout.mdsinside2012
nhout.mdsinside2011;
run;

data fallrate;
set nhout.mdsinside_2011_2015(keep=m_prvdrnum trgtdt_year fallrate fallrate100);
run;

proc sort data=fallrate nodupkeys;
by m_prvdrnum trgtdt_year fallrate;
run;

proc sort data=nhout.mdsinside_final out=mdsinside;
by m_prvdrnum trgtdt_year;
run;

* merge claims-based fall rate with the final analysis sample;
data nhout.mdsinside;
merge mdsinside (in=inm)
      fallrate;
by m_prvdrnum trgtdt_year;
if inm;
run;

*subset variables in the analysis sample;
data mdsinside_model;
set nhout.mdsinside(keep=uniqueid
BENE_ID 
BSF_AGE
BSF_RTI
BSF_SEX
BSF_CREC
DUAL
NISS
trgtdt_year 
Shortstay
primary_dx
majorinjury
combinedscore

M_PRVDRNUM
CAP_GNRL_CNTL_TYPE_CD
CAP_PCT_MDCD
Region
prvdrsize

OVERALL_RATING
QUALITY_RATING

nj1900c 

fallrate
fallrate100
rename=(trgtdt_year=year
        nj1900c=max_nj1900c)
);
run;


*get rid obs with missing values in the analysis sample;
proc sql;
create table  mdsinside_model_nomissing as 
select * from mdsinside_model where 
bene_id is not missing and 
BSF_AGE is not missing and 
BSF_RTI is not missing and 
BSF_SEX is not missing and 
BSF_CREC is not missing and 
NISS is not missing and 
Shortstay is not missing and
fallrate is not missing and 
primary_dx is not missing and
combinedscore is not missing and

M_PRVDRNUM is not missing and 
CAP_GNRL_CNTL_TYPE_CD is not missing and 
CAP_PCT_MDCD is not missing and
Region is not missing and 
prvdrsize is not missing and 

OVERALL_RATING is not missing and 
QUALITY_RATING is not missing and 

year is not missing and 
max_nj1900c is not missing; 
quit;

*create categorical variables for niss, nursing home ownership type, and disability;
data   mdsinside_model_final;
length niss_catg 3.
	     cap_ownership $10.
	     female 3.
	  ;
set  mdsinside_model_nomissing;
  
*create niss categorical variable;
if 0<=niss<=15 then niss_catg=1; 
  else if 15<niss<=24 then niss_catg=2; 
    else if 24<niss<=40 then niss_catg=3;
	  else if niss>40 then niss_catg=4;
	
*create ownership type categorical variable;
if CAP_GNRL_CNTL_TYPE_CD in ('01','02','03') then cap_ownership="For-Profit";
  else if CAP_GNRL_CNTL_TYPE_CD in ('04','05','06') then cap_ownership="Non-Profit";
    else if CAP_GNRL_CNTL_TYPE_CD in ('07','08','09','10','11','12') then cap_ownership="Government";
	  else cap_ownership="Other";

*create disability indicator;
disability=(bsf_crec="1");
*create binary sex indicator;
female=(bsf_sex=2);
*convert percent medicaid to a percentage variable;
PER_MDCD=CAP_PCT_MDCD/100;
drop CAP_PCT_MDCD;
if overall_rating in (7,9) then delete;
run;

proc sort data=mdsinside_model_final nodupkeys;
by uniqueid;
run;

data mdsinside_model_final;
set mdsinside_model_final;
length white black hispanic asian 3.;
if BSF_RTI=1 then do; racename="White"; white=1;end;
  else if BSF_RTI=2 then do; racename="Black"; black=1;end;
   else if BSF_RTI=5 then do; racename="Hispanic"; hispanic=1;end;
     else if BSF_RTI=4 then do; racename="Asian"; asian=1;end;
	   else do;racename="Other"; other=1;end;
if BSF_RTI=1 then BH=0;
     else BH=1;
if niss_catg=1 then niss1=1;
  else if niss_catg=2 then niss2=1;
    else if niss_catg=3 then niss3=1;
      else if niss_catg=4 then niss4=1;
run;
 
*calculate racial mix (proportions of asian, white, black, hispanic and others);
*calculate proportion of nonwhite-->meanBH;
*calculate proportion of duals within each provider-->meanDual;
proc sql;
create table prvdr as 
select distinct m_prvdrnum,
       mean(BH) as meanBH,
       mean(dual) as meanDual,
       mean(female) as meanfemale,
       mean(bsf_age) as meanage,
       mean(NISS) as meanniss,
       mean(disability) as meandisability,
       mean(combinedscore) as meancombinedscore,
	   sum(asian)/count(distinct uniqueid) as pasian,
       sum(white)/count(distinct uniqueid) as pwhite,
       sum(black)/count(distinct uniqueid) as pblack,
       sum(hispanic)/count(distinct uniqueid) as phispanic,
       sum(other)/count(distinct uniqueid) as pother,
       sum(niss1)/count(distinct uniqueid) as pniss1,
       sum(niss2)/count(distinct uniqueid) as pniss2,
       sum(niss3)/count(distinct uniqueid) as pniss3,
       sum(niss4)/count(distinct uniqueid) as pniss4
       
from mdsinside_model_final
group by m_prvdrnum
;
quit;

proc sort data=prvdr nodupkey;
by m_prvdrnum;
run;

proc sql;
create table nhout.mdsinside_model_final as
select  
    C.*,
    B.meanBH,
	  B.meanDual,
	  B.pasian,
    B.pwhite,
	  B.pblack,
	  B.phispanic,
	  B.pother,
    B.meanfemale,
    B.meanage,
    B.meanniss,
    B.meandisability,
    B.meancombinedscore,
    B.pniss1,
    B.pniss2,
    B.pniss3,
    B.pniss4
 from mdsinside_model_final C left join 
      prvdr B
 on C.m_prvdrnum= B.m_prvdrnum;
quit;

*construct race_deviation and dual_deviation variable;
*have proportions of race/ethnicity adds up to 1 for each provider;
data nhout.mdsinside_model_final;
set nhout.mdsinside_model_final;
bh_dm=BH-meanBH;
dual_dm=dual-meanDual;
female_dm=female-meanfemale;
age_dm=bsf_age-meanage;
niss_dm=niss-meanniss;
disability_dm=disability-meandisability;
combinedscore_dm=combinedscore-meancombinedscore;
if pasian=. then pasian=0;
if pwhite=. then pwhite=0;
if pblack=. then pblack=0;
if phispanic=. then phispanic=0;
if pother=. then pother=0;
run;

/*
*test pearson correlation between percent medicaid and other variables of interest;
data corr_mdsinside_model;
set nhout.mdsinside_model_final (keep=per_mdcd disability meanbh dual bh_dm);
run;
ods csvall file="S:\Pan\NH\results\paper\final\Exhibit4\corr_permdcd.csv";
ods graphics on;
proc corr data=corr_mdsinside_model plots=matrix(histogram);
run;
ods graphics off;
ods csvall close;
*/


*export analysis sample to stata dataset;
proc export data=nhout.mdsinside_model_final 
   outfile="S:\Pan\NH\datasets\stata\final\linprob\exhibit4_11212018.dta"
   dbms=stata
   replace;
run;

*obtain distribution of age to create linear age splines;
PROC SUMMARY data=nhout.mdsinside_model_final  PRINT Q1 MEDIAN Q3; 
  VAR bsf_age;
  RUN;

%mend MANALYSIS;
%MANALYSIS
