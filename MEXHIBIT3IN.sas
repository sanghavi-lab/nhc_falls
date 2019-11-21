/**********************************************************************************************************************/
/*  Macro MEXHIBIT3IN                                                                                                 */
/*  Last updated: 10/29/2018                                                                                          */
/*  Last run:  11/02/2018                                                                                             */                                                                                   
/*  This SAS macro calculates reporting rate for J1800, J1900A-C for the denominator population of patients who fell  */
/*  during their NH stay and went back to the same NH. With each fall claim, we checked whether it's reported on      */
/*  discharge assessment or up to three mds assessment following hospitalization. The reporting rate is calculated for*/ 
/*  each fall item stratifying on short- vs. long-stay and race.                                                      */
/**********************************************************************************************************************/

dm 'log;clear;output;clear;';

%macro MEXHIBIT3IN;

*create binary indicator BH=1 if non-white BH=0 if white;
data pre;

set nhout.mdspre_samenh_claim_stay;

length racename $8.
       bh month 3.;
if h_admsndt^=.;
if BSF_RTI=1 then racename="White";
  else if BSF_RTI=2 then racename="Black";
   else if BSF_RTI=5 then racename="Hispanic";
     else if BSF_RTI=4 then racename="Asian";
	   else racename="Other";
if BSF_RTI=1 then BH=0;
  else BH=1;

month=month(h_admsndt);

*keep definite major injury falls;
if primary_dx=1 and majorinjury=1;

if j1800 ne "1" then nj1800=0;
else nj1800=1;

if j1900a not in("1" "2") then nj1900a=0;
else nj1900a=1;

if j1900b not in("1" "2") then nj1900b=0;
else nj1900b=1;

if j1900c not in("1" "2") then nj1900c=0;
else nj1900c=1;

run;

*create dual indicator;
*a patient is considered a dual if he/she is a full dual in the month of hospital admission for fall;
data pre;
set pre;
array dual_elg {12} DUAL_ELG_01-DUAL_ELG_12; 
length  dual 3.;
dual=0;
if dual_elg{month}="f" then dual=1; 
run;

*check duplicates for fall episodes;
proc sort data=pre nodupkeys;by uniqueid;run;

*include the first post-hospitalization mds assessment since hospital discharge without limitation on type and dates;
data post;
set nhout.mdspost_same_nh(keep=
      bene_id
	  uniqueid
	  m_prvdrnum
	  m_trgt_dt
     J1800
     J1900A
     J1900B
     J1900C
	 a0310f
	 a0310a
	 a0310e
rename=(
     J1800	=post_J1800
     J1900A	=post_J1900A
     J1900B	=post_J1900B
     J1900C	=post_J1900C
     m_trgt_dt=post_m_trgt_dt));

if post_j1800 ne "1" then npost_j1800=0;
else npost_j1800=1;

if post_j1900a not in("1" "2") then npost_j1900a=0;
else npost_j1900a=1;

if post_j1900b not in("1" "2") then npost_j1900b=0;
else npost_j1900b=1;

if post_j1900c not in("1" "2") then npost_j1900c=0;
else npost_j1900c=1;
run;

proc sort data=post;by uniqueid post_m_trgt_dt;run;

*keep the first post-hospitalization mds assessment;
data post_first;
set post;
by uniqueid;
if first.uniqueid;
run;

*check how many post-hospitalization first assessment are of entry type and within one day of hospital discharge;
proc sql;
 create table post_first_days as
  select a.*,b.h_dschrgdt from post_first a inner join pre b
  on a.uniqueid=b.uniqueid;
quit;
 
*create indicator d1 for entry/reentry assessments within one day of hospital discharge;
data post_first_days;
set post_first_days;
d=post_m_trgt_dt-h_dschrgdt;
d1=(d<=1 and a0310f="01");
run;

proc freq;
tables d1/missing;
run;
*93.57%;

*keep the first two post-hospitalization mds assessment;
data post_firsttwo;
set post;
by uniqueid;
if not last.uniqueid;
run;

*final sample only includes those residents who had a readmission to NH within one day of hospital discharge;
data nhout.mdsinside_final;
      merge pre(in=ind)
            post_first;
 by uniqueid;
 if ind;
run;

data nhout.mdsinside_final;
set nhout.mdsinside_final;
d=post_m_trgt_dt-h_dschrgdt;
 if d<=1 and a0310f="01";
run;

*calculate reporting rate on only discharge assessments for the final sample;
proc sql;
create table national_claims_discharge as
select 
shortstay,
BH,
count(uniqueid) as nclaims,
mean(nj1800) as  rnj1800,
mean(nj1900a) as rnj1900a,
mean(nj1900b) as rnj1900b,
mean(nj1900c) as rnj1900c,
sum(nj1800) as  cnj1800,
sum(nj1900a) as cnj1900a,
sum(nj1900b) as cnj1900b,
sum(nj1900c) as cnj1900c
from nhout.mdsinside_final
group by shortstay,BH;
quit;

*generate pooled reporting rate for manuscript;
*1. by short- and long- stay;
*2. by race;
*3. overall;

proc sql;
create table national_claims_discharge_stay as
select 
shortstay,
mean(nj1900c) as rnj1900c
from nhout.mdsinside_final
group by shortstay;
quit;

proc print data=national_claims_discharge_stay;run;

proc sql;
create table national_claims_discharge_race as
select 
BH,
mean(nj1900c) as rnj1900c
from nhout.mdsinside_final
group by BH;
quit;

proc print data=national_claims_discharge_race;run;

proc sql;
create table national_claims_discharge_all as
select 
mean(nj1800) as rnj1800,
mean(nj1900c) as rnj1900c
from nhout.mdsinside_final;
quit;

proc print data=national_claims_discharge_all;run;

*generate 25th and 75th percentile for reporting rate stratifying by race and short- vs. long- stay;
proc sql;
create table prvdr_claims_discharge as
select 
distinct m_prvdrnum,
shortstay,
BH,
count(uniqueid) as nclaims,
mean(nj1800) as  rnj1800,
mean(nj1900a) as rnj1900a,
mean(nj1900b) as rnj1900b,
mean(nj1900c) as rnj1900c
from nhout.mdsinside_final
group by m_prvdrnum,shortstay,BH;
quit;

proc sort data=prvdr_claims_discharge;
by shortstay BH;
run;

proc summary data=prvdr_claims_discharge;
by shortstay BH;
var rnj1800 rnj1900a rnj1900b rnj1900c ;
output out=nhout.exhibit3_pctl p25= p75= /autoname;
run;

ods csvall file="S:\Pan\NH\results\paper\final\Exhibit3\exhibit3_mdsinside_pctl.csv";

proc print data=nhout.exhibit3_pctl;
title "25th and 75th percentile for provider level reporting rate by race and shortstay";
run;

ods csvall close;

*narrow down the discharge assessment to include only those who were readmitted within one day of hospital discharge;
*merge these discharges with up to 3 post-hospitalization assessments to check reporting for sensitivity analysis;

proc sql;
create table pre_res as select * from pre where uniqueid in 
(select uniqueid from nhout.mdsinside_final);
quit;

*merge discharge assessments with 1,2,and up to 3post-hostpitalization mds assessment and check overal reporting rate;
%macro merge(no,po);

data mdsinside_&no.;
      merge pre_res(in=ind)
            &po.;
 by uniqueid;
 if ind;
max_nj1800 = max(of nj1800 npost_j1800);
max_nj1900a = max(of nj1900a npost_j1900a);
max_nj1900b = max(of nj1900b npost_j1900b);
max_nj1900c = max(of nj1900c npost_j1900c);
run;

*if fall reported on discharge assessment or additional up to three post-hospitalization assessment, mark it as reported;
proc sql;
create table mdsinside_&no._sum as 
select distinct uniqueid, 
       sum(max_nj1800) as sum_nj1800, 
       sum(max_nj1900a) as sum_nj1900a, 
       sum(max_nj1900b) as sum_nj1900b, 
       sum(max_nj1900c) as sum_nj1900c
       from mdsinside_&no
       group by uniqueid;
quit;

data mdsinside_&no._updated;
      merge mdsinside_&no.(in=ind)
            mdsinside_&no._sum;
 by uniqueid;
 if ind;
run;

data mdsinside_&no._updated;
  set mdsinside_&no._updated;
  by uniqueid;
  if first.uniqueid;
  max_nj1800=(sum_nj1800>0);
  max_nj1900a=(sum_nj1900a>0);
  max_nj1900b=(sum_nj1900b>0);
  max_nj1900c=(sum_nj1900c>0);
run;

*check assessment type for post-hostpitalization assessments for those who went back to same nursing home;
proc sql;
create table &po._nores as select * from &po. where uniqueid in 
(select uniqueid from pre);
quit;

proc freq data=&po._nores;
title "Examine all &no. post-hospitalization mds assessment record type";
tables a0310f a0310a a0310e/missing;
run;

*check assessment type for post-hostpitalization assessments for those who were readmitted within one-day of hospital discharge;
proc sql;
create table &po._res as select * from &po. where uniqueid in 
(select uniqueid from nhout.mdsinside_final);
quit;

proc freq data=&po._res;
title "Examine &no. post-hospitalization mds assessment record type for patients who were readmitted within one day";
tables a0310f a0310a a0310e/missing;
run;

%mend merge;

*this macro compares reporting rate for including post-hospitalization assessment versus reporting rate on only discharge;
%macro compare(no);

*calculate national average reporting rate stratifying by short- vs. long-stay and race;
proc sql;
create table national_claims as
select 
shortstay,
BH,
mean(max_nj1800) as  _nj1800,
mean(max_nj1900a) as _nj1900a,
mean(max_nj1900b) as _nj1900b,
mean(max_nj1900c) as _nj1900c,
sum(max_nj1800) as  _cnj1800,
sum(max_nj1900a) as _cnj1900a,
sum(max_nj1900b) as _cnj1900b,
sum(max_nj1900c) as _cnj1900c
from mdsinside_&no._updated
group by shortstay,BH;
quit;

*calculate difference in reporting rate compared to just using discharge assessment;
data diff;
merge national_claims_discharge national_claims;
by shortstay bh;
run;

data diff;
set diff;
diff_nj1800=rnj1800-_nj1800;
diff_nj1900a=rnj1900a-_nj1900a;
diff_nj1900b=rnj1900b-_nj1900b;
diff_nj1900c=rnj1900c-_nj1900c;
diff_cnj1800=cnj1800-_cnj1800;
diff_cnj1900a=cnj1900a-_cnj1900a;
diff_cnj1900b=cnj1900b-_cnj1900b;
diff_cnj1900c=cnj1900c-_cnj1900c;
run;

proc print data=national_claims;
title "National reporting rates combining discharge assessments and &no. post-hospitalization assessment";
run;

proc print data=diff;
title "National reporting rates differences combining discharge assessments and &no. post-hospitalization assessment compared to using only discharge assessment";
run;

%mend compare;


ods csvall file="S:\Pan\NH\results\paper\final\Exhibit3\exhibit3_mdsinside11022018.csv";

proc print data=national_claims_discharge;
title "National reporting rates on just discharge assessments";
run;

%merge(1,post_first)
%merge(2,post_firsttwo)
%merge(3,post)

%compare(1)
%compare(2)
%compare(3)

ods csvall close;

%mend MEXHIBIT3IN;

%MEXHIBIT3IN






