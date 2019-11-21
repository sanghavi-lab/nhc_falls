/**************************************************************************************************************************/
/*  Macro MWRITESTATAFL                                                                                                   */
/*  Last updated: 10/21/2018;                                                                                             */
/*  Last Run: 10/21/2018;                                                                                                 */                                                                                   
/*  This SAS macro creates dataset containing admitting diagnosis code, 25 diagnosis codes, and 12 external cause codes   */
/*  for each fall episode to feed into STATA for NISS calculation                                                         */                                                                                                                           
/**************************************************************************************************************************/

dm 'log;clear;output;clear;';

%MACRO MWRITESTATAFL(input,instata);
proc contents data=nhout.&input. varnum;
run;

data d_icd9(drop=bene_id h_admsndt);
set nhout.&input.(keep=bene_id h_admsndt h_dschrgdt AD_DGNS DGNSCD1-DGNSCD25 DGNSECD1-DGNSECD12);
length uniqueid $30.;
uniqueid=bene_id || left(h_admsndt);
run;

proc sort data=d_icd9;
by uniqueid;
run;

**make long in order to remove duplicate icd-9 codes within a bene-hospital-admissiondt;
proc transpose data=d_icd9 out=t_icd9(drop=_NAME_ _LABEL_ rename=(COL1=icd9code));
 by uniqueid;
 var AD_DGNS DGNSCD1-DGNSCD25 DGNSECD1-DGNSECD12;
run;

data t_icd9;
set t_icd9;
if icd9code ne " ";
run;

proc sort nodupkey data=t_icd9;
 by uniqueid icd9code;
run;

**make wide again to create input file for stata program;
proc transpose data=t_icd9 out=tt&input.(drop=_NAME_) prefix=dx;
 by uniqueid;
 var icd9code;
run;

proc print data=tt&input.(obs=20);
 title "tt_icd9";
run;

proc contents varnum;
run;

*export diagnosis codes to stata files;
*checked diagnosis codes values are all numbers;
proc export data=tt&input.
   outfile="S:\Pan\NH\datasets\stata\final\NISS\&instata..dta"
   dbms=stata
   replace;
run;

%MEND MWRITESTATAFL;

*%mwritestatafl(mdspre_samenh_claim, mdspre_samenh_claim_issin);
%mwritestatafl(mdspre_claim, mdspre_claim_issin)

             

