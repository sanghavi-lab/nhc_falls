/**************************************************************************************************************************/
/*  Macro MADDCASPER                                                                                                      */
/*  Last updated: 09/08/2018                                                                                              */ 
/*  Last Run: 09/06/2018                                                                                                  */                                                                                   
/*  This SAS macro merges MDS assessments with CASPER to obtain provider characteristics                                  */                      
/*  Results:98016687/100852818=97.2% of the MDS assessment is successfully merged with CASPER based on certification date */
/*          For those MDS assessments missing matched CASPER data, checked and confirmed the assessments were done before */
/*          any certification records appeared in CASPER.                                                                 */
/*  Note : usually each NH is certified yearly according to part 2 CASPER data, but the time of year for the certification*/ 
/*         date is not predictable as these certification is based on unannounced surveys;                                */                       
/**************************************************************************************************************************/
dm 'log;clear;output;clear;';

%MACRO MADDCASPER;

*extract CASPER variables;
data part2;
set capin.part2(keep=
    PRVDR_NUM            
    STATE_CD           
    GNRL_CNTL_TYPE_CD  
    CRTFCTN_DT 
	CNSUS_RSDNT_CNT
    CNSUS_MDCD_CNT
    CNSUS_MDCR_CNT
    CNSUS_OTHR_MDCD_MDCR_CNT
    CNSUS_OTHR_SA_PD_CNT
   
	
      rename=(
    STATE_CD           			= CAP_STATE_CD
    GNRL_CNTL_TYPE_CD  			= CAP_GNRL_CNTL_TYPE_CD
	CNSUS_RSDNT_CNT             = CAP_CNSUS_RSDNT_CNT
    CNSUS_MDCD_CNT			    = CAP_CNSUS_MDCD_CNT
    CNSUS_MDCR_CNT			    = CAP_CNSUS_MDCR_CNT
    CNSUS_OTHR_MDCD_MDCR_CNT	= CAP_CNSUS_OTHR_MDCD_MDCR_CNT
    CNSUS_OTHR_SA_PD_CNT		= CAP_CNSUS_OTHR_SA_PD_CNT
   ));

length cap_crtfctn_dt 4.;
format cap_crtfctn_dt date10.;
cap_crtfctn_dt = input(crtfctn_dt,anydtdte.);
drop crtfctn_dt;

if cap_crtfctn_dt > '01Jan2009'd;

*calculate percent of residents for each payer source;
if CAP_CNSUS_RSDNT_CNT > 0 then do;
   CAP_PCT_MDCD = (CAP_CNSUS_MDCD_CNT / CAP_CNSUS_RSDNT_CNT) * 100;
   CAP_PCT_MDCR = (CAP_CNSUS_MDCR_CNT / CAP_CNSUS_RSDNT_CNT) * 100;
   CAP_PCT_OTHER = (CAP_CNSUS_OTHR_MDCD_MDCR_CNT / CAP_CNSUS_RSDNT_CNT) * 100;
   CAP_PCT_OTHR_SA_PD = (CAP_CNSUS_OTHR_SA_PD_CNT / CAP_CNSUS_RSDNT_CNT) * 100;

   CAP_PCT_MDCD = round(CAP_PCT_MDCD,0.1);
   CAP_PCT_MDCR = round(CAP_PCT_MDCR,0.1);
   CAP_PCT_OTHER = round(CAP_PCT_OTHER,0.1);
   CAP_PCT_OTHR_SA_PD = round(CAP_PCT_OTHR_SA_PD,0.1);
end;
run;

*match each MDS assessment with the most recent casper data based on the casper certification date;
data part2_dt;
set part2(keep=prvdr_num cap_crtfctn_dt);
run;

proc sort data=part2_dt nodupkeys;
by prvdr_num cap_crtfctn_dt;
run;

data mds_dt(keep=prvdr_num trgt_dt);
set nhout.mds3_facility_2011_2015;
run;

proc sort data=mds_dt;
by prvdr_num trgt_dt;
run;

proc sql noprint;
create table mds_cap_dt as
  select m.prvdr_num, m.trgt_dt,c.cap_crtfctn_dt
		 from mds_dt m left join part2_dt c
	     on c.prvdr_num=m.prvdr_num and 
               (year(m.trgt_dt)=year(c.cap_crtfctn_dt) or year(m.trgt_dt)=year(c.cap_crtfctn_dt)+1 or year(m.trgt_dt)=year(c.cap_crtfctn_dt)+2)
         ;
quit;

proc contents data=mds_cap_dt;
run;

proc sort data=mds_cap_dt out=_mds_cap;
by prvdr_num trgt_dt descending cap_crtfctn_dt;
run;

proc print data=_mds_cap(obs=100);run;

*each MDS target date is matched with the closest previous casper certification date;
proc sort data=_mds_cap out=mds_cap nodupkey;
by prvdr_num trgt_dt;
run;

proc sort data=nhout.mds3_facility_2011_2015 out=mds3_fac_2011_2015;
 by prvdr_num trgt_dt;
run;

data mds3_fac_2011_2015_cap_dt;
merge mds3_fac_2011_2015(in=inm)
      mds_cap;
 by prvdr_num trgt_dt;
 if inm;
run;

proc sort data=mds3_fac_2011_2015_cap_dt;
by prvdr_num cap_crtfctn_dt;
run;

proc sort data=part2;
by prvdr_num cap_crtfctn_dt;
run;

data nhout.mds3_fac_2011_2015_cap;
merge mds3_fac_2011_2015_cap_dt(in=inm)
      part2;
by prvdr_num cap_crtfctn_dt;
if inm;
run;

proc contents data=nhout.mds3_fac_2011_2015_cap varnum;
title 'Merged 2011-2015 MDS with facility files and CASPER';
run;

%MEND MADDCASPER;


