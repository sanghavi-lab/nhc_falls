/**************************************************************************************************************************/
/*  Macro MMDSFALLIN                                                                                                      */
/*  Last updated: 10/01/2018                                                                                              */
/*  Last ran: 10/21/2018                                                                                                  */                                                                                   
/*  This SAS macro creates dataset that contains concatenated MDS assessment and fall claims for patients who fell during */                               
/*  their nursing home stay                                                                                               */                                                 
/**************************************************************************************************************************/

dm 'log;clear;output;clear;';

%macro MMDSFALLIN;

*keep fall claims that are definite falls;
data nhout.claims_fallin_px;
set nhout.claims_fallin;
if primary_dx=1;
run;

**combine contiguous hospitalizations;
proc sort data=nhout.claims_fallin_px;
 by bene_id descending h_admsndt descending h_dschrgdt;
run;

data claims_fallin;
set nhout.claims_fallin_px;
hhh=_N_;
run;

data removehosp(keep=removebene removehhh)
     claims_fallin(drop=removebene);
 set claims_fallin;
 by bene_id;

length
  next_h_admsndt 
  next_h_dschrgdt  4.;
format
  next_h_admsndt 
  next_h_dschrgdt  date10.;

next_h_admsndt = lag(h_admsndt);
next_h_dschrgdt = lag(h_dschrgdt);

if first.bene_id then do;
  next_h_admsndt = .;
  next_h_dschrgdt = .;
end;

if h_dschrgdt = next_h_admsndt then do;
   h_dschrgdt = next_h_dschrgdt;
   removebene=bene_id;
   removehhh=hhh-1;
   output removehosp;
end;
output claims_fallin;
run;

proc sort data=claims_fallin;
 by bene_id hhh;
run;

data claims_fallin;
merge claims_fallin
      removehosp(rename=(removebene=bene_id removehhh=hhh) in=inremove);
 by bene_id hhh;
 if not inremove;
run;

proc sort data=claims_fallin;
 by bene_id h_admsndt h_dschrgdt;
run;

*identify benes who fell during their nursing home stay;
data target_benes;
set claims_fallin(keep=bene_id);
run;

proc sort data=target_benes nodupkey;
 by bene_id;
run;

*get mds record for above benes;
data dmds_target_fallin;
merge nhout.dmds(in=inm)
      target_benes(in=int);
 by bene_id;
 if int;
run;

*concatenate fall claims with mds assessments;
data mds_claims_fallin;
set   dmds_target_fallin
      claims_fallin(in=inc);

if m_idschrg=-1 then m_idschrg=-2;
if inc then m_idschrg=-1;
run;

proc sort data=mds_claims_fallin;
 by bene_id sortdt m_idschrg m_a0310e ;
run;

*create record number for each mds assessment or fall claims to record their positions;
data mds_claims_fallin;
   set mds_claims_fallin;
   n_claims_mds=_N_;
run;

data nhout.mds_claims_fallin;
set mds_claims_fallin;
run;

%mend MMDSFALLIN;

