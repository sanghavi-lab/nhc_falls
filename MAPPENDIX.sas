/**********************************************************************************************************************/
/*  Macro MAPPENDIX                                                                                                   */
/*  Last updated: 11/21/2018                                                                                          */
/*  Last run:  11/21/2018                                                                                             */                                                                                   
/*  This SAS macro calculates patient and nursing home characteristics stratigying between short vs. long-stay        */
/*  for appendix eTable 4. Characteristics of Major Injury Denominator Population                                     */
/**********************************************************************************************************************/
dm 'log;clear;output;clear;';

data nhout.mdsinside_model_final;
set nhout.mdsinside_model_final;
if asian=. then asian=0;
if white=. then white=0;
if black=. then black=0;
if hispanic=. then hispanic=0;
if other=. then other=0;
niss1=(niss_catg=1);
niss2=(niss_catg=2);
niss3=(niss_catg=3);
niss4=(niss_catg=4);
run;

proc sql;
create table nhout.patient_characteristics as
select shortstay,
       mean(bsf_age) as mean_age,
       std(bsf_age) as std_age,
       mean(female) as prop_female,
	   std(female) as std_female,
	   mean(niss) as mean_niss,
	   std(niss) as std_niss,
	   mean(combinedscore) as mean_comorb,
	   std(combinedscore) as std_comorb,
	   mean(disability) as prop_disability,
	   std(disability) as std_disability,
	   mean(dual) as prop_dual,
	   std(dual) as std_dual,
       mean(asian) as mean_asian,
	   std(asian) as std_asian,
       mean(white) as mean_white,
	   std(white) as std_white,
       mean(black) as mean_black,
	   std(black) as std_black,
       mean(hispanic) as mean_hispanic,
	   std(hispanic) as std_hispanic,
	   std(niss1) as std_niss1,
	   std(niss2) as std_niss2,
	   std(niss3) as std_niss3,
	   std(niss4) as std_niss4
from nhout.mdsinside_model_final
where year=2014
group by shortstay;
quit;

proc print;run;

proc sql;
create table mdsinside_model_final as
select l.* , r.trgtdt_quarter from nhout.mdsinside_model_final l left join nhout.mdsinside_final r
on l.uniqueid=r.uniqueid and l.m_prvdrnum=r.m_prvdrnum;
quit;

proc sql;
create table prvdr_short as
select distinct m_prvdrnum,trgtdt_quarter, overall_rating, quality_rating, prvdrsize, PER_MDCD, region, cap_ownership, meandual, pasian,pblack,phispanic,pother ,fallrate
from mdsinside_model_final
where shortstay=1 and year=2014;
quit;

proc sql;
create table prvdr_long as
select distinct m_prvdrnum,trgtdt_quarter, overall_rating, quality_rating, prvdrsize, PER_MDCD, region, cap_ownership, meandual, pasian,pblack,phispanic,pother,fallrate
from mdsinside_model_final
where shortstay=0 and year=2014;
quit;

proc sort data=prvdr_long;
by m_prvdrnum trgtdt_quarter;run;

data prvdr_long;
set prvdr_long;
by m_prvdrnum;
if last.m_prvdrnum;
south=(region="south");
midwest=(region="midwest");
northeast=(region="northeast");
west=(region="west");
large=(prvdrsize="l");
medium=(prvdrsize="m");
small=(prvdrsize="s");
forprofit=(CAP_OWNERSHIP="For-Profit");
government=(CAP_OWNERSHIP="Government");
nonprofit=(CAP_OWNERSHIP="Non-Profit");
otherprof=(CAP_OWNERSHIP="Other");
run;

proc sort data=prvdr_short;
by m_prvdrnum trgtdt_quarter;run;

data prvdr_short;
set prvdr_short;
by m_prvdrnum;
if last.m_prvdrnum;
south=(region="south");
midwest=(region="midwest");
northeast=(region="northeast");
west=(region="west");
large=(prvdrsize="l");
medium=(prvdrsize="m");
small=(prvdrsize="s");
forprofit=(CAP_OWNERSHIP="For-Profit");
government=(CAP_OWNERSHIP="Government");
nonprofit=(CAP_OWNERSHIP="Non-Profit");
otherprof=(CAP_OWNERSHIP="Other");
run;

proc sql;
create table nhout.nh_characteristics_short as
select
       mean(meandual) as prop_dual,
       std(meandual) as std_dual,
	   mean(pasian) as prop_asian,
       std(pasian) as std_asian,
	   mean(pblack) as prop_black,
       std(pblack) as std_black,
	   mean(phispanic) as prop_hispanic,
       std(phispanic) as std_hispanic,
	   mean(pother) as prop_other,
       std(pother) as std_other,
	   mean(fallrate) as prop_fallrate,
       std(fallrate) as std_fallrate,
       mean(overall_rating) as mean_overallrating,
	   std(overall_rating) as std_overallrating,
	   mean(quality_rating) as mean_qualityrating,
	   std(quality_rating) as std_qualityrating,
	   mean(south) as mean_south,
	   std(south) as std_south,
	   mean(midwest) as mean_midwest,
	   std(midwest) as std_midweset,
	   mean(northeast) as mean_northeast,
	   std(northeast) as std_northeast,
	   mean(west) as mean_west,
	   std(west) as std_west,
	   mean(large) as mean_large,
	   std(large) as std_large,
	   mean(medium) as mean_medium,
	   std(medium) as std_medium,
	   mean(small) as mean_small,
	   std(small) as std_small,
	   mean(forprofit) as mean_forprofit,
	   std(forprofit) as std_forprofit,
	   mean(government) as mean_government,
	   std(government) as std_government,
	   mean(nonprofit) as mean_nonprofit,
	   std(nonprofit) as std_nonprofit,
	   mean(otherprof) as mean_otherprof,
	   std(otherprof) as std_otherprof
from prvdr_short
quit;


proc sql;
create table nhout.nh_characteristics_long as
select
       mean(per_mdcd) as mean_mdcd,
       std(per_mdcd) as std_per_mdcd,
       mean(meandual) as prop_dual,
       std(meandual) as std_dual,
	   mean(pasian) as prop_asian,
       std(pasian) as std_asian,
	   mean(pblack) as prop_black,
       std(pblack) as std_black,
	   mean(phispanic) as prop_hispanic,
       std(phispanic) as std_hispanic,
	   mean(pother) as prop_other,
       std(pother) as std_other,
	   mean(fallrate) as prop_fallrate,
       std(fallrate) as std_fallrate,
	   mean(overall_rating) as mean_overallrating,
	   std(overall_rating) as std_overallrating,
	   mean(quality_rating) as mean_qualityrating,
	   std(quality_rating) as std_qualityrating,
	   mean(south) as mean_south,
	   std(south) as std_south,
	   mean(midwest) as mean_midwest,
	   std(midwest) as std_midweset,
	   mean(northeast) as mean_northeast,
	   std(northeast) as std_northeast,
	   mean(west) as mean_west,
	   std(west) as std_west,
	   mean(large) as mean_large,
	   std(large) as std_large,
	   mean(medium) as mean_medium,
	   std(medium) as std_medium,
	   mean(small) as mean_small,
	   std(small) as std_small,
	   mean(forprofit) as mean_forprofit,
	   std(forprofit) as std_forprofit,
	   mean(government) as mean_government,
	   std(government) as std_government,
	   mean(nonprofit) as mean_nonprofit,
	   std(nonprofit) as std_nonprofit,
	   mean(otherprof) as mean_otherprof,
	   std(otherprof) as std_otherprof

from prvdr_long
quit;

ods csvall file="S:\Pan\NH\results\paper\final\appendix\patient_nh_characteristics.csv";

proc print data=nhout.patient_characteristics;
title "patient characteristics in final sample";
run;

proc print data=nhout.nh_characteristics_short;
title "nursing home characteristics in final sample for shortstay";
run;

proc print data=nhout.nh_characteristics_long;
title "nursing home characteristics in final sample for longstay";
run;

ods csvall close;
