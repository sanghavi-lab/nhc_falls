/***************************************************************************************************************************/
/*  Macro MCLAIMS20105                                                                                                     */
/*  Last updated: 09/04/2017                                                                                               */
/*  Last run:     09/04/2017                                                                                               */                                                                                         
/************************************************************************************************************************  */
/*  This SAS macro performs the following:                                                                                 */
/*   1. Split 2015 MedPar dataset into two parts: admission dates prior to Sep 30th and admission dates after Sep 30th     */
/*   2. Get rid of claims with missing discharge date in dataset medpar_2015_Jan_Sept and output those claims              */
/*      into medpar_2015_Jan_Sept_dschrg. Output claims with missing discharge date into dataset medpar_2015_missing_dschrg*/
/*  Background: Due to HR 4302, ICD-10 will now go into effect on October 1, 2015.Use ICD-9 diagnosis codes for all claims */
/*    of service until September 30, 2015. Section files based on discharge date: Inpatient claims will always have a      */
/*    discharge date. SNF claims could have a zero date.;                                                                  */
/*  Note: Are there icd10 code in medpar_2015_jan_sept? No--->output to medpar_2015_jan_sept_icd10                         */
/*		    Are there missing values for code version indicators?--->output to medpar_2015_jan_sept_missing_cdver            */
/*        There are values of 0, 9, blank for CDNG_E_VERSN_CD_{}                                                           */
/*  All diagnosis codes in MedPAR 2015 before October are ICD9 codes and none of the claims have missing discharge dates.  */
/***************************************************************************************************************************/
dm 'log;clear;output;clear;';

%macro MCLAIMS20105;

*check version of diagnosis code;
%macro code_ver(medpar_part, ver, ICD);

proc print data=&medpar_part. (obs=100);
   var ADMSN_DT 
       DSCHRG_DT	
       DGNS_E_VRSN_CD
       DGNS_E_VRSN_CD_1-DGNS_E_VRSN_CD_12
       DGNS_VRSN_CD
       DGNS_VRSN_CD_1-DGNS_VRSN_CD_12
       ;
   title "Check Admission Date Values and Diagnosis Code Versions for &medpar_part."; 
run;

data error_code_ver;

set &medpar_part.;
array dx_ver{26}
      DGNS_E_VRSN_CD
      DGNS_E_VRSN_CD_1-DGNS_E_VRSN_CD_12
      DGNS_VRSN_CD
      DGNS_VRSN_CD_1-DGNS_VRSN_CD_12;

if "&ver" in dx_ver then output error_code_ver; 

run;

proc sql noprint;
   select count(*)
   into :OBSCOUNT
from error_code_ver;
quit;

%put There are &OBSCOUNT. number of observations in &medpar_part. with &ICD.;

%mend code_ver;


data medpar_all_file_2015;
set mpar.medpar_all_file_2015_001
    mpar.medpar_all_file_2015_002
	mpar.medpar_all_file_2015_003
	mpar.medpar_all_file_2015_004;
run;

data medpar_2015_Jan_Sept;
   set medpar_all_file_2015;
   if DSCHRG_DT le '30SEP2015'd;
run;

%code_ver(medpar_2015_Jan_Sept, 0, ICD-10);

data medpar_2015_Oct_Dec;
   set medpar_all_file_2015;
   if DSCHRG_DT gt '30SEP2015'd;
run;

%code_ver(medpar_2015_Oct_Dec, 9, ICD-9);

*check whether discharge dates are missing;
%macro miss_dschrg(medpar_work, medpar_out);

proc contents data=&medpar_out. varnum;
run;

data &medpar_work. nhout.medpar_2015_missing_dschrg;
   set &medpar_out.;
   if DSCHRG_DT ne . then output &medpar_work.;
     else output nhout.medpar_2015_missing_dschrg;
run;

proc sql noprint;
   select count(*)
   into :MissingDis
from nhout.medpar_2015_missing_dschrg;
quit;

%put There are &MissingDis. number of observations in &medpar_nhout. with missing discharge dates;

proc contents data=nhout.medpar_2015_missing_dschrg(keep=DSCHRG_DT) varnum;
run;

data nhout.medpar_2015_Jan_Sept_dschrg;
   set &medpar_work.;
run;

proc contents data=nhout.medpar_2015_Jan_Sept_dschrg varnum;
run;

%mend miss_dschrg;

%miss_dschrg(medpar_2015_Jan_Sept_update,nhout.medpar_2015_Jan_Sept);


%macro sanity_check;

proc sql;
create table medpar_2015_jan_sept_cdversion (label='The E code version in medpar_2015_jan_sept') as

select distinct(DGNS_E_VRSN_CD)
from nhout.medpar_2015_jan_sept

union

select distinct(DGNS_E_VRSN_CD_1)
from nhout.medpar_2015_jan_sept

union

select distinct(DGNS_E_VRSN_CD_2)
from nhout.medpar_2015_jan_sept

union

select distinct(DGNS_E_VRSN_CD_3)
from nhout.medpar_2015_jan_sept

union

select distinct(DGNS_E_VRSN_CD_4)
from nhout.medpar_2015_jan_sept

union

select distinct(DGNS_E_VRSN_CD_5)
from nhout.medpar_2015_jan_sept

union

select distinct(DGNS_E_VRSN_CD_6)
from nhout.medpar_2015_jan_sept

union

select distinct(DGNS_E_VRSN_CD_7)
from nhout.medpar_2015_jan_sept

union

select distinct(DGNS_E_VRSN_CD_8)
from nhout.medpar_2015_jan_sept

union

select distinct(DGNS_E_VRSN_CD_9)
from nhout.medpar_2015_jan_sept

union

select distinct(DGNS_E_VRSN_CD_10)
from nhout.medpar_2015_jan_sept

union

select distinct(DGNS_E_VRSN_CD_11)
from nhout.medpar_2015_jan_sept

union

select distinct(DGNS_E_VRSN_CD_12)
from nhout.medpar_2015_jan_sept;

quit;

*Only includes cd version of E codes;
data nhout.medpar_2015_jan_sept_cd_version;
   set medpar_2015_jan_sept_cdversion;
run;

proc sql;
create table medpar_2015_jan_sept_checkdschrg (label='Check dschrg dates in medpar_2015_jan_sept') as

select 'The number of obs with missing dschrg dates ',
     count(*) 
from nhout.medpar_2015_jan_sept
where dschrg_dt=.

union 

select 'The number of obs with dschrg_dt=0 ',
     count(*) 
from nhout.medpar_2015_jan_sept
where dschrg_dt=0

union 

select 'The number of obs with dschrg_dt>sept302015 ',
     count(*) 
from nhout.medpar_2015_jan_sept
where dschrg_dt gt '30SEP2015'd;

data nhout.medpar_2015_jan_sept_checkdschrg;
   set medpar_2015_jan_sept_checkdschrg;
run;

proc sql;
select count(*) from 
  nhout.medpar_2015_Jan_Sept_dschrg
where dschrg_dt=.;
quit;

%mend sanity_check;

%sanity_check;

%macro codever(medpar_part, medpar9, medpar10, ver);

data &medpar9. &medpar10.;

set &medpar_part.;
array dx_ver{26}
      DGNS_E_VRSN_CD
      DGNS_E_VRSN_CD_1-DGNS_E_VRSN_CD_12
      DGNS_VRSN_CD
      DGNS_VRSN_CD_1-DGNS_VRSN_CD_12
      ;

if "&ver" in dx_ver then output &medpar10.; 
    else output &medpar9.; 

run;

proc sql;

create table medpar_2015_jan_sept_cdver (label='Check icd version in medpar_2015_jan_sept_dschrg')as

select 'The number of obs with icd9 codes ',
  count(*) from
  medpar_2015_Jan_Sept_icd9

union

select 'The number of obs with icd10 codes ',
  count(*) from
  medpar_2015_Jan_Sept_icd10;

quit;

data medpar_2015_jan_sept_cdver;
set medpar_2015_jan_sept_cdver;
run;

proc sql noprint;
   select count(*)
   into :OBSCOUNT10
from &medpar10.;

   select count(*)
   into :OBSCOUNT9
from &medpar9.;

quit;

%put There are &OBSCOUNT10. number of observations in &medpar_part. with at least one ICD10 codes among the 26 diagnosis code version indicator variables;
%put There are &OBSCOUNT9. number of observations in &medpar_part. with all ICD9 codes; 

%mend codever;

%codever(medpar_2015_Jan_Sept_dschrg, 
         medpar_2015_Jan_Sept_icd9,
		 medpar_2015_Jan_Sept_icd10,0);

*output MedPAR 2015 claims with ICD9 codes;
data nhout.medpar_2015_Jan_Sept_icd9;
set medpar_2015_Jan_Sept_dschrg;
run;

%mend MCLAIMS20105;






