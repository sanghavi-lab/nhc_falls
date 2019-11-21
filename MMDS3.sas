/**********************************************************************************************************************/
/*  Macro MMDS3                                                                                                       */
/*  Last updated: 04/04/2018                                                                                          */
/*  Last run:  09/05/2018                                                                                             */                                                                                   
/*  This SAS macro creates dataset for MDS assessments for year 2011-2015 and select a subset of variables needed for */
/*  the analysis.                                                                                                     */
/**********************************************************************************************************************/
dm 'log;clear;output;clear;';

%MACRO MMDS3(YYEAR);
data mds&YYEAR.;
set mdsxwalk.mds_xwalk_bene_&YYEAR.(keep=
    BENE_ID
    TRGT_DT
    STATE_CD
    FAC_PRVDR_INTRNL_ID
    A0310A_FED_OBRA_CD
    A0310B_PPS_CD 
    A0310C_PPS_OMRA_CD
    A0310D_SB_CLNCL_CHG_CD
    A0310E_FIRST_SINCE_ADMSN_CD
    A0310F_ENTRY_DSCHRG_CD     
    A1600_ENTRY_DT
    A1700_ENTRY_TYPE_CD
    A1800_ENTRD_FROM_TXT
    A2000_DSCHRG_DT
    A2100_DSCHRG_STUS_CD
	A2300_ASMT_RFRNC_DT
	
    J1700A_FALL_30_DAY_CD
    J1700B_FALL_31_180_DAY_CD
    J1700C_FRCTR_SIX_MO_CD
    J1800_FALL_LAST_ASMT_CD
    J1900A_FALL_NO_INJURY_CD
    J1900B_FALL_INJURY_CD
    J1900C_FALL_MAJ_INJURY_CD
    

  rename=(A2000_DSCHRG_DT=_A2000_DSCHRG_DT
          TRGT_DT = _TRGT_DT));

  if A0310F_ENTRY_DSCHRG_CD in("10" "11") then dschrg=1; else dschrg=0;
  if A0310F_ENTRY_DSCHRG_CD="12" then delete;				

length 
   A2000_DSCHRG_DT 4.
   TRGT_DT 4.;
format 
  A2000_DSCHRG_DT 
  TRGT_DT date9.;

label TRGT_DT="target date";

*change discharge date and target date from character variables to numeric variables;
A2000_DSCHRG_DT = input(_A2000_DSCHRG_DT, anydtdte10.); 
drop _A2000_DSCHRG_DT;
TRGT_DT = input(_TRGT_DT, anydtdte10.);
drop _TRGT_DT;

run;

proc sort data=mds&YYEAR. out=mdsout.mds3_&YYEAR.;
 by bene_id trgt_dt a1600_entry_dt;
run;

proc contents data=mdsout.mds3_&YYEAR varnum;
run;

%MEND MMDS3;

%MMDS3(2011)
%MMDS3(2012)
%MMDS3(2013)
%MMDS3(2014)
%MMDS3(2015)



