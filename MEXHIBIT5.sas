/**********************************************************************************************************************/
/*  Macro MEXHIBIT5                                                                                                   */
/*  Last updated: 11/21/2018                                                                                          */
/*  Last run:  11/21/2018                                                                                             */                                                                                   
/*  This SAS macro generates exhibit 5 cross-tabulation of inpatient claim-based fall rates with the distribution of  */
/*  quality measure, and star ratings (overall and quality ratings). Only year 2014 of the sample data is used.       */                                                                                                  
/**********************************************************************************************************************/

dm 'log;clear;output;clear;';

%macro MEXHIBIT5(input);
*drop star rating that is missing or populated with 7 and 9 (confirmed only small percentage around 1%) and drop observations with missing quality measure;
data &input.(keep=m_prvdrnum fallrate fallrate100 mjfall quality_rating overall_rating TRGTDT_QUARTER
             rename=(MJFALL=QMFall));
set nhout.&input.;
if quality_rating in (7,9) or overall_rating in (7,9) or overall_rating=. or quality_rating=. or mjfall=. or fallrate=. then delete;
run;

*rank macro generates percentiles for relevant measures we want;
*we created quintiles for weighted claims-based fall rate;
%macro rank(dataset,var,group,opt);

data test&var.(keep=m_prvdrnum &var.);
set all;
run;

proc sort data=test&var.;
by &opt. &var.;
run;

data test&var.; 
   set test&var. nobs=numobs; 
   length  rank_&var. 3.;
   rank_&var.=floor(_n_*&group./(numobs+1))+1; 
run;

data test&var.; 
   set test&var.(keep=m_prvdrnum rank_&var.);  
run;

proc sort data=test&var.;
by m_prvdrnum;
run;

data all;
merge all
      test&var.;
by m_prvdrnum;
run;

PROC MEANS DATA=all;
        class rank_&var.;
        VAR &var.;
		title "For falls inside NH in 2014 Quintiles for &var.";
RUN;

%mend rank;

proc sort data=&input. out=all nodup;
by m_prvdrnum TRGTDT_QUARTER;
run;

data all;
set all;
by m_prvdrnum trgtdt_quarter;
if last.m_prvdrnum;
run;

data all;
set all(keep=m_prvdrnum quality_rating overall_rating fallrate qmfall fallrate100);
run;

%rank(all,fallrate,5,descending)

*macro crosstab generate crosstabulation of desired variables with claims-based fall rate rankings;
%macro crosstab(var);

proc freq data=all;
title "For falls inside NH in 2014 cross tabulate weighted fall rate and &var.";
tables rank_fallrate*&var./nofreq NOPERCENT nocol;
run; 

%mend crosstab;

*calculate average reporting rate, star ratings, and quality measure within each quintiles of claims-based fall rate;
proc sql;
create table fall_weight as 
select rank_fallrate,
	   mean(overall_rating) as avg_overall_rating,
	   mean(quality_rating) as avg_quality_rating,
	   mean(qmfall) as avg_qmfall
from all
group by rank_fallrate;
quit;


ods csv file="S:\Pan\NH\results\paper\final\Exhibit5\exhibit5_11192018.csv";

%crosstab (overall_rating);
%crosstab (quality_rating);

proc print data=fall_weight;
title "average star rating and reporting rate within each quintile of weighted fall rate";
run;

*display mean, min, and max for the weighted fall rate within each quintile;
proc means data=all;
title "Weighted fallrate quintiles mean fall rate";
class rank_fallrate;
var fallrate100;
run;

proc means data=all p10 p90;
title "Weighted fallrate quintiles 10th and 90th percentile fall rate";
class rank_fallrate;
var fallrate100;
run;

ods csvall close;

%mend MEXHIBIT5;

%MEXHIBIT5(mdsinside2014);
*%MEXHIBIT5(mdsinsideall2014);


*calculate correlation of star ratings and fall quality measure;

data mdsinside_corr (keep=m_prvdrnum TRGTDT_YEAR TRGTDT_QUARTER overall_rating quality_rating mjfall fallrate nj1900c);
set nhout.mdsinside2015
nhout.mdsinside2014
nhout.mdsinside2013
nhout.mdsinside2012
nhout.mdsinside2011;
if quality_rating in (7,9) or overall_rating in (7,9) or overall_rating=. or quality_rating=. or mjfall=. or fallrate=. or nj1900c=. then delete;
run;

proc sort nodupkeys;
by m_prvdrnum TRGTDT_YEAR TRGTDT_QUARTER;run;

proc print data=mdsinside_corr(obs=100);run;

data mdsinside_corr(keep=overall_rating quality_rating mjfall fallrate nj1900c);
set mdsinside_corr;
run;

*test pearson correlation: overall rating, quality rating, quality measure;
ods csvall file="S:\Pan\NH\results\paper\final\Exhibit5\corr_star_qm.csv";
ods graphics on;
proc corr data=mdsinside_corr plots=matrix(histogram);
run;
ods graphics off;
ods csvall close;

