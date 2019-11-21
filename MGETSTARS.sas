*--------------------------------------------------------------------------------------------------------------------;
**Macro MGETSTARS
**Macro within: getstarfall
**Date created:12/07/2017
**Last edited: 10/21/2018
**Last run: 10/21/2018
**Incorporate mds star ratings;
*Document Reference:NHC_LongitudinalFiles_2008-2011_Readme
*PROC FORMAT;
*VALUE $stars 
* '10'='*'
* '20'='**'
* '30'='***'
* '40'='****'
* '50'='*****'
* '70' = 'Too New to Rate'
* '90' = 'Data Not available'
*;
*--------------------------------------------------------------------------------------------------------------------;
dm 'log;clear;output;clear;';

%MACRO MGETSTARS;

**Check provnum in star rating files;
**Results: All provnum are valid in star rating files;
/*%macro check_prvdrnum(star, star_invalid);

data &star_invalid(keep=provnum);
  set &star.;
  if verify(trim(left(provnum)), '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ')>0 or length(provnum) ne 6 then output &star._invalid;
run;

proc sql noprint;
select count (provnum) into: inv_provnum from &star._invalid;
quit;

%put There are &inv_provnum. invalid provnums in &star.;

%mend check_prvdrnum;

%check_prvdrnum(mdsstar.ratings_2014,ratings_2014_inv);
%check_prvdrnum(mdsstar.ratings_2015,ratings_2015_inv);
%check_prvdrnum(mdsstar.ratings_2009_2013,ratings_2009_2013_inv);
*/

*format star ratings files for year 2014-2015;
%macro rating(YYEAR);
data ratings_&YYEAR._long;
  set mdsstar.ratings_&YYEAR.;
  length 
     year 3.
    quarter 3.;
  year=year(FILEDATE);
  quarter=qtr(FILEDATE);
run;
/*
proc contents data=ratings_&YYEAR._longvarnum;run;
proc print data=ratings_&YYEAR._long(keep=provnum filedate year quarter overall_rating overall_rating_fn QUALITY_RATING QUALITY_RATING_fn STAFFING_RATING SURVEY_RATING obs=100);run;
*/

proc sort data=ratings_&YYEAR._long nodupkey;
  by provnum year quarter;
run;

proc transpose data=ratings_&YYEAR._long out=ratings_&YYEAR._wide prefix=quarter;
  by provnum year;
  id quarter;
  var overall_rating QUALITY_RATING STAFFING_RATING SURVEY_RATING rn_staffing_rating;
run;

proc transpose data=ratings_&YYEAR._wide out=ratings_&YYEAR.;
  by provnum year;
  id _name_;
  var quarter1 quarter2 quarter3 quarter4;
run;

data ratings_&YYEAR.(drop=_quarter _name_);
set ratings_&YYEAR.;
length _quarter $1.
       quarter 3.;
_quarter=substr(_name_,8,1);
quarter=input(_quarter,3.);
run;

%mend rating;
%rating(2014)
%rating(2015)

*format star rating files for year 2009-2013;
*these star ratings are available monthly, change them to quarterly star ratings to match format in year 2014-2015;
proc contents data=mdsstar.ratings_2009_2013 varnum; run;

data fivestar_2009_2013_long;
  set mdsstar.ratings_2009_2013;
  length
    year 3.
	quarter 3.
    _survey_rating 3.
    _staffing_rating 3.
    _overall_rating 3.
    _quality_rating 3.
    _rn_staffing_rating 3.;

	_SURVEY_RATING=input(SURVEY_RATING,3.);
	_QUALITY_RATING=input(QUALITY_RATING,3.);
	_overall_rating=input(overall_rating,3.);
    _STAFFING_RATING=input(staffing_rating,3.);
    _RN_STAFFING_RATING=input(RN_STAFFING_RATING,3.);

	drop overall_rating
         survey_rating
         quality_rating
         staffing_rating
         rn_staffing_rating;

	_overall_rating=_overall_rating/10;
	_SURVEY_RATING=_SURVEY_RATING/10;
    _QUALITY_RATING=_QUALITY_RATING/10;
	_STAFFING_RATING=_STAFFING_RATING/10;
	_RN_STAFFING_RATING=_RN_STAFFING_RATING/10;

	rename _overall_rating=overall_rating
           _SURVEY_RATING=SURVEY_RATING
		   _QUALITY_RATING=QUALITY_RATING
		   _STAFFING_RATING=STAFFING_RATING
           _RN_STAFFING_RATING=RN_STAFFING_RATING;

	if month=1 or month=4 or month=7 or month=10 then do;
	   if month=1 then quarter=1;
         else if month=4 then quarter=2;
	        else if month=7 then quarter=3;
		      else if month=10 then quarter=4;
        output fivestar_2009_2013_long;
	end;
run;

proc sort data=fivestar_2009_2013_long nodupkey;
  by provnum year quarter;
run;

proc transpose data=fivestar_2009_2013_long out=fivestar_2009_2013_wide prefix=quarter;
  by provnum year;
  id quarter;
  var overall_rating survey_rating quality_rating staffing_rating rn_staffing_rating;
run;

 proc transpose data=fivestar_2009_2013_wide out=fivestar_2009_2013;
  by provnum year;
  id _name_;
  var quarter1 quarter2 quarter3 quarter4;
run;

data fivestar_2009_2013(drop=_quarter _name_);
set fivestar_2009_2013;
length _quarter $1.
       quarter 3.;
_quarter=substr(_name_,8,1);
quarter=input(_quarter,3.);
run;
/*
proc contents data=ratings_2014(obs=10);run;
proc contents data=ratings_2015(obs=10);run;
proc contents data=fivestar_2009_2013 (obs=10);run;
*/

data fivestar_2011_2015;
  set ratings_2014 
      ratings_2015
      fivestar_2009_2013;
  if 2015>=year>=2011;
run;

data fivestar_2011_2015(rename=(year=trgtdt_year
                                         quarter=trgtdt_quarter
                                         provnum=m_prvdrnum));
set fivestar_2011_2015;
run;

proc sort data=fivestar_2011_2015 out=nhout.fivestar_2011_2015;
by m_prvdrnum trgtdt_year trgtdt_quarter;
run;

**Merge MDS assessments with quarterly star data from 2011 to 2015;
%Macro getstarfall(prepost,prepost_output);

data nhout.&prepost.;
set nhout.&prepost.;
trgtdt_year=year(m_trgt_dt);
trgtdt_quarter=qtr(m_trgt_dt);
run;

proc sort data=nhout.&prepost.;
by m_prvdrnum trgtdt_year trgtdt_quarter;
run;

data nhout.&prepost_output.;
merge nhout.&prepost.(in=inm)
      nhout.fivestar_2011_2015;
	  by m_prvdrnum trgtdt_year trgtdt_quarter;
if inm;
run;

%mend getstarfall;

%getstarfall(mdspre_samenh_claim_com,mdspre_samenh_claim_star)

%getstarfall(mdspre_claim_com,mdspre_claim_star)

%MEND MGETSTARS;



