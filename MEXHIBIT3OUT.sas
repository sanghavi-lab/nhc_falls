/**********************************************************************************************************************/
/*  Macro MEXHIBIT3OUT                                                                                                */
/*  Last updated: 10/17/2018                                                                                          */
/*  Last run:  10/22/2018                                                                                             */                                                                                   
/*  This SAS macro calculates reporting rate for J1700A-B for the denominator population of patients who fell         */
/*  outside of their NH stay. With each fall claim, we checked whether it's reported on mds entry/reentry assessment  */
/*  following hospitalization. The reporting rate is calculated for each fall item stratifying on short- vs. long-stay*/ 
/*  and race.                                                                                                         */ 
/**********************************************************************************************************************/

dm 'log;clear;output;clear;';

%macro MEXHIBIT3OUT;

*create binary indicator BH=1 if non-white BH=0 if white;
data mds_claims_fallout_stay;
set nhout.mds_claims_fallout_stay(keep=
      bene_id
	    bsf_rti
	    m_prvdrnum
      h_admsndt
      uniqueid
	    shortstay
      j1700a
      j1700b
	    primary_dx
	    majorinjury
	    dayssincehospadmit
     _1mo_post_claim
     _2to6mos_post_claim
	    DUAL_ELG_01-DUAL_ELG_12
	 );
length racename $8.
       bh nj1700a nj1700b month 3.;

month=month(h_admsndt);

if BSF_RTI=1 then racename="White";
  else if BSF_RTI=2 then racename="Black";
   else if BSF_RTI=5 then racename="Hispanic";
     else if BSF_RTI=4 then racename="Asian";
	   else racename="Other";
if BSF_RTI=1 then BH=0;
  else BH=1;

if j1700a ne "1" then nj1700a=0;
else nj1700a=1;

if j1700b ne "1" then nj1700b=0;
else nj1700b=1;

*only keep definite major injury falls;
if primary_dx=1 and majorinjury=1;
run;

*create dual indicator;
*a patient is considered a dual if he/she is a full dual in the month of hospital admission for fall;
data mds_claims_fallout_stay;
set mds_claims_fallout_stay;
length dual 3.;
array dual_elg {12} DUAL_ELG_01-DUAL_ELG_12; 
dual=0;
if dual_elg{month} in ("f") then dual=1; 
run;

proc sort data=mds_claims_fallout_stay nodupkeys;by uniqueid;run;

*calculate reporting rate separately for j1700a and j1700b;
proc sql;
create table national_claims_j1700a as
select 
"j1700a" as category,
bh,shortstay,
count(uniqueid) as nclaims,
mean(nj1700a) as  nj1700a,
sum(nj1700a) as cnj1700a
from  mds_claims_fallout_stay
where _1mo_post_claim=1
group shortstay, bh;
quit;

proc sql;
create table national_claims_j1700a as
select 
mean(nj1700a) as  nj1700a
from  mds_claims_fallout_stay
where _1mo_post_claim=1;
quit;

proc print;run;

proc sql;
create table national_claims_j1700b as
select 
"j1700b" as category,
bh,shortstay,
count(uniqueid) as nclaims,
mean(nj1700b) as  nj1700b,
sum(nj1700b) as cnj1700b
from  mds_claims_fallout_stay
where _2to6mos_post_claim=1
group shortstay, bh;
quit;

data national_claims;
set national_claims_j1700a
    national_claims_j1700b;
run;

ods csvall file="S:\Pan\NH\results\paper\final\Exhibit3\exhibit3_mdsoutside.csv";

proc print data=national_claims;
title "National reporting rates averaging 5 years stratify between long- and short- stay and race";
run;

ods csvall close;

%macro pctl(var, month);

proc sql;
create table prvdr_reporting as
select 
shortstay,
BH,
mean(&var.) as  &var.
from mds_claims_fallout_stay
where &month.=1
group by m_prvdrnum,shortstay,BH;
quit;

proc sort;
by shortstay BH;
run;

proc summary data=prvdr_reporting;
by shortstay BH;
var &var.;
output out=nhout.exhibit3_&var._pctl p25= p75= /autoname;
run;

proc print data=nhout.exhibit3_&var._pctl;
title "25th and 75th percentile for provider level reporting rate for j1700a by race and shortstay";
run;

%mend pctl;

ods csvall file="S:\Pan\NH\results\paper\final\Exhibit3\exhibit3_mdsoutside_pctl.csv";

%pctl(nj1700a, _1mo_post_claim)
%pctl(nj1700b, _2to6mos_post_claim)

ods csvall close;

%mend MEXHIBIT3OUT;
