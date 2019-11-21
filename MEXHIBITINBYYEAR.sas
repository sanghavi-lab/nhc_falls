/**********************************************************************************************************************/
/*  Macro MEXHIBITINBYYEAR                                                                                            */
/*  Last updated: 11/21/2018                                                                                          */
/*  Last run:  11/21/2018                                                                                             */                                                                                   
/*  This SAS macro partition the sample data into 5 years. THe most recent star rating and CASPER data for provider   */
/*  characteristics are kept. Reporting rates and claims-based long-stay fall rate (weighted and unweighted)for each  */
/*  providr are calculated for each year.                                                                             */
/**********************************************************************************************************************/

dm 'log;clear;output;clear;';
/*
data nhout.mdsinside_final(rename=(nj1800=max_nj1800 nj1900a=max_nj1900a nj1900b=max_nj1900b nj1900c=max_nj1900c));
set nhout.mdsinside_final;
run;
*/

%macro MEXHIBITINBYYEAR(output,YYEAR);

data mdsinside_final;
set nhout.mdsinside_final;
run;


*Only keep the most recent star rating in each year;
proc sql;
create table starrating as 
select m_prvdrnum, overall_rating,quality_rating,TRGTDT_QUARTER,TRGTDT_YEAR
from mdsinside_final;
quit;

proc sort data=starrating nodupkeys;
by m_prvdrnum TRGTDT_YEAR TRGTDT_QUARTER;
run;

data starrating;
set starrating;
prvdryear=m_prvdrnum || TRGTDT_YEAR;
run;

proc sort data=starrating ;
by prvdryear TRGTDT_YEAR TRGTDT_QUARTER;
run;

data starrating(drop=prvdryear trgtdt_quarter);
set starrating;
by prvdryear;
if trgtdt_year=&YYEAR.;
if last.prvdryear;
run;

*calculate provider-level reporting rate within each year;
proc sql;
create table mdsinside_prvdr&YYEAR. as
select 
distinct m_prvdrnum,
count(uniqueid) as nclaims,
mean(nj1800) as  nj1800,
mean(nj1900a) as nj1900a,
mean(nj1900b) as nj1900b,
mean(nj1900c) as nj1900c
from mdsinside_final
where trgtdt_year=&YYEAR.
group by m_prvdrnum;
quit;
/*
proc sql;
create table longstay_fall&YYEAR. as
select 
distinct m_prvdrnum,
count(uniqueid) as nclaims,
shortstay
from mdsinside_final
where trgtdt_year=&YYEAR. and shortstay=0
group by m_prvdrnum;
quit;
*/
proc sort data=mdsinside_prvdr&YYEAR. nodup;
by m_prvdrnum;
run;

*every provider has a mean reporting rate each year and the most recent star rating within that year;
data mdsinside_prvdr&YYEAR.;
merge mdsinside_prvdr&YYEAR. (in=inm)
      starrating;
by m_prvdrnum;
if inm;
run;

*keep the latest capser data in each year for each provider;
proc sql;
create table capres as 
select m_prvdrnum, CAP_CNSUS_RSDNT_CNT as tot_res,CAP_PCT_MDCD, CAP_GNRL_CNTL_TYPE_CD, TRGTDT_QUARTER,TRGTDT_YEAR
from mdsinside_final;
quit;

proc sort data=capres nodupkeys;
by m_prvdrnum trgtdt_year trgtdt_quarter ;
run;

data capres;
set capres;
prvdryear=m_prvdrnum || TRGTDT_YEAR;
run;

proc sort data=capres ;
by prvdryear TRGTDT_YEAR TRGTDT_QUARTER;
run;

data capres&YYEAR.(drop=prvdryear trgtdt_quarter);
set capres;
by prvdryear;
if trgtdt_year=&YYEAR.;
if last.prvdryear;
run;

*every provider has a mean reporting rate each year and the most recent star rating and Casper data in that year;
data mdsinside_prvdr&YYEAR.;
merge mdsinside_prvdr&YYEAR. (in=inm)
      capres&YYEAR.;
by m_prvdrnum;
if inm;
run;

*calculate provider-level claims-based fall rate as the number of fall claims identified within that year over the total number of
*registered residents within that year;
data mdsinside_prvdr&YYEAR.;
 set mdsinside_prvdr&YYEAR.;
 fallrate=nclaims/tot_res;
 fallrate100=nclaims/tot_res*100;
run;

proc sort data=mdsinside_prvdr&YYEAR. nodupkeys;
by m_prvdrnum;
run;

data mdsinside_final_&YYEAR.;
set mdsinside_final;
if TRGTDT_YEAR=&YYEAR.;
run;

proc sort data=mdsinside_final_&YYEAR.;
by m_prvdrnum;
run;

*create weights for claims-based fall rates;
*weight=total number of registered residents count/the sum of all registered residents count for all providers in that year;
proc sql noprint;
select sum(tot_res) into: res_sum
from mdsinside_prvdr&YYEAR.;
quit;

data mdsinside_prvdr&YYEAR.;
set mdsinside_prvdr&YYEAR.;
nh_weight=tot_res/&res_sum.;
fallrate_weighted=nclaims*nh_weight;
fallratew100=nclaims*nh_weight*100;
run;

data nhout.&output.;
merge mdsinside_final_&YYEAR.(in=inm)
      mdsinside_prvdr&YYEAR.;
by m_prvdrnum;
if inm;
run;


%mend MEXHIBITINBYYEAR;

%MEXHIBITINBYYEAR(mdsinside2015,2015)
%MEXHIBITINBYYEAR(mdsinside2014,2014)
%MEXHIBITINBYYEAR(mdsinside2013,2013)
%MEXHIBITINBYYEAR(mdsinside2012,2012)
%MEXHIBITINBYYEAR(mdsinside2011,2011)


