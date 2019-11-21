/**************************************************************************************************************************/
/*  Macro  MREGION                                                                                                        */
/*  Last updated: 10/21/2018;                                                                                             */
/*  Last Run: 10/21/2018;                                                                                                 */                                                                                   
/*  This SAS macro categorize provider geographical locations into northeast, midwest, south, west based on the           */
/*  provider's FIPS state code.                                                                                           */
/**************************************************************************************************************************/
dm 'log;clear;output;clear;';

%Macro MREGION(input, output);

*import the crosswalk file that maps each state name abbreviations with the FIPS state code;
proc import datafile="S:\Pan\NH\data\statexwalk\statecode.csv"
     out=statecode
     dbms=csv
     replace;
     getnames=yes;
run;

data statecode;
set statecode;
statecode = put(state_code,2.);
drop state_code;
run;

*extract provider id, provider FIPS state code from sample dataset to create mapping;
proc sql;
create table mdsinside_statecd as
select distinct m_prvdrnum, prvdr_state_cd as state from nhout.&input.;
quit;

proc sort data=mdsinside_statecd nodupkeys;
by m_prvdrnum;
run;

proc sort data=mdsinside_statecd;
by state;
run;

proc sort data=statecode;
by state;
run;
 
data mdsinside_statecd;
merge mdsinside_statecd(in=inm)
      statecode;
by state;
if m_prvdrnum^="";
run;

*categorize state FIPS code into regions;
*the mapping now has provider number, its FIPS state code, and the region;
data mdsinside_region;
set mdsinside_statecd;
label region="NH region as determined by state code: northeast, midwest, south, west";
if statecode in (" 9", "23", "25", "33", "44" ,"50", "34" ,"36", "42") then region="northeast";
  else if statecode in ("18", "17", "26", "39", "55", "19", "20", "27", "29", "31", "38", "46")then region="midwest";
    else if statecode in ("10", "11", "12", "13", "24", "37", "45", "51", "54", " 1", "21", "28", "47", " 5", "22", "40", "48") then region="south";
	  else if statecode in (" 4", " 8", "16", "35", "30", "49", "32", "56", " 2", " 6", "15", "41","53") then region="west";
run;

proc sort data=nhout.&input. out=&input.;
by m_prvdrnum;
run;

proc sort data=mdsinside_region;
by m_prvdrnum;
run;

*merge mapping back to sample data; 
data nhout.&output.;
merge &input.(in=inm)
      mdsinside_region;
by m_prvdrnum;
if inm;
run;

proc freq;
table region/missing;run;

%mend MREGION;

*%MREGION(mdspre_samenh_claim_nhsize, mdspre_samenh_claim_region);
%MREGION(mdspre_claim_nhsize, mdspre_claim_region)

