/**************************************************************************************************************************/
/*  Macro  MPROVIDERSIZE                                                                                                  */
/*  Last updated: 10/21/2018;                                                                                             */
/*  Last Run: 10/21/2018;                                                                                                 */                                                                                   
/*  This SAS macro categorize providers into small, medium, and large based on the CASPER registered resident counts      */
/**************************************************************************************************************************/
dm 'log;clear;output;clear;';

%macro MPRVDRSIZE(input,output);

*investigate the distribution of provider size;
proc sql;
create table prvdr_size as
select distinct m_prvdrnum, mean(CAP_CNSUS_RSDNT_CNT) as tot_res
from nhout.&input.
group by m_prvdrnum;
quit;

proc rank data=prvdr_size out=prvdr_size_rank groups=3 ties=low;
   var tot_res;
   ranks rank_tot_res;
run;

PROC MEANS DATA=prvdr_size_rank;
  title "Provider size ranks measured by total number of residents";
        class rank_tot_res;
        VAR tot_res;
RUN;

*design the cutoff for small, medium, large providers;
*cutoff points, residents count 0-68, 68-105,105+;

proc sql;
create table prvdr_size as
select distinct m_prvdrnum, 
       CAP_CNSUS_RSDNT_CNT as tot_res,
       TRGTDT_YEAR,
       TRGTDT_Quarter 
from nhout.&input.
quit;

proc sort data = prvdr_size;
by m_prvdrnum trgtdt_year trgtdt_quarter;
run;

data prvdr_size;
set prvdr_size;
prvdr_year=m_prvdrnum||trgtdt_year;
run;

*keep the latest surveyed residents count;
data prvdr_size;
set prvdr_size;
by prvdr_year;
if tot_res<=65 then prvdrsize="s";
  else if tot_res<=105 then prvdrsize="m";
    else prvdrsize="l"; 
if last.prvdr_year;
run;

*merge provider size with data sample;
proc sql;
  create table nhout.&output. as
    select M.*,
	       S.prvdrsize
	from nhout.&input. M left join prvdr_size S 
  on M.m_prvdrnum=S.m_prvdrnum and M.trgtdt_year=S.trgtdt_year;
quit; 

proc freq data=prvdr_size;
title "prvdr size in &input.";
tables prvdrsize/missing;
run;

%mend MPRVDRSIZE;

*%MPRVDRSIZE(mdspre_samenh_claim_star,mdspre_samenh_claim_nhsize);
%MPRVDRSIZE(mdspre_claim_star,mdspre_claim_nhsize)

