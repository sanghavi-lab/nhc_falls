/**************************************************************************************************************************/
/*  Macro MSEVERITY                                                                                                       */
/*  Last updated: 10/21/2018;                                                                                             */
/*  Last Run: 10/21/2018;                                                                                                 */                                                                                   
/*  This SAS macro merges output from Stata ICDPIC with mds and fall claims                                               */ 
/**************************************************************************************************************************/

dm 'log;clear;output;clear;';

%MACRO MSEVERITY(issout,mds);

proc import out=&issout.
   datafile="S:\Pan\NH\datasets\stata\final\NISS\&issout..dta"
   dbms=DTA replace;
run;

proc freq;
 tables niss/list missing;
run;

proc means;
 var niss;
run;

proc sort data=&issout.;
 by uniqueid;
run;

data &mds.;
set nhout.&mds.;
run;

proc sort data=&mds.;
 by uniqueid;
run;

data &mds._iss;
merge &mds.
      &issout.(drop=
  DX1 - DX27
  SEV_1 - SEV_27
  ISSBR_1 - ISSBR_27
  BRL_1 - BRL_27
  APC_1 - APC_27
  MXAISBR1 - MXAISBR6
  ECODE_1 - ECODE_4
  MECHMAJ1 - MECHMAJ4
  MECHMIN1 - MECHMIN4
  INTENT1 -  INTENT4
  BRL_1 - BRL_27
  APC_1 - APC_27
BLUNTPEN
LOWMECH
MAXAIS
XISS );

 by uniqueid;
run;

proc sort data=&mds._iss out=nhout.&mds._iss;
 by bene_id h_admsndt h_dschrgdt;
run;

proc print data=nhout.&mds._iss(obs=200);
 var uniqueid bene_id h_admsndt h_dschrgdt a0310e a0310f a2000 a2100 m_idschrg m_a0310e  niss;
run;

%MEND MSEVERITY;

*%mseverity(mdspre_samenh_claim_issout,mdspre_samenh_claim);
%mseverity(mdspre_claim_issout,mdspre_claim)





