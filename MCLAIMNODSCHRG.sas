/***************************************************************************************************************************/
/*  Macro MCLAIMNODSCHRG                                                                                                   */
/*  Last updated: 10/21/2018                                                                                               */
/*  Last ran: 10/21/2018                                                                                                   */                                                                                   
/*  This SAS macro creates two datasets for patients who came from NH but are missing mds discharge assessments            */
/*  1) their fall claims from                                                                                              */      
/*  2) concatenated fall claims and mds assessment from those patients                                                     */                                                 
/***************************************************************************************************************************/

dm 'log;clear;output;clear;';

%macro MCLAIMNODSCHRG;

data claims_fallin_nodschrg(keep=
    BENE_ID
    SORTDT
    AD_DGNS
    BSF_AGE            
    BSF_CNTY_CD    
    BSF_CREC     
    BSF_DOB        
    BSF_DOD           
    BSF_OREC       
    BSF_RACE       
    BSF_RFRNC_YR   
    BSF_SEX        
    BSF_STATE_CD   
    BSF_ZIP 
    BSF_RTI 
    CVRLVLDT
    D
    DGNSCD1-DGNSCD25
    DGNSECD1-DGNSECD12
	DUAL_ELG_01-DUAL_ELG_12
	DUAL_STUS_CD_01-DUAL_STUS_CD_12
    DISQUALIFIED      
    DRG_CD    
    DXECODE_VALUE
    DXINJURY_I        
    DXINJURY_VALUE   
    ECODE_I           
    ECODE_VALUE 
    ESRD_IND          
    H_ADMSNDT         
    H_AGE_CNT         
    H_DSCHRGCD        
    H_DSCHRGDT        
    H_DSTNTNCD                 
    H_PRVDRNUM 
	H_LOSCNT
    HMO_IND_12 
    PREV_A2000        
    PREV_A2100        
    PREV_A0310F       
    PREV_M_TRGT_DT    
    R         
    SSLSSNF
    primary_dx)
    ;

set nhout.mdsclaims;
 by bene_id;

length 
    r				$1.
    prev_a0310f	 	$2.
    prev_m_trgt_dt  4.
    prev_A2000		4.
    prev_A2100	 	$2.
    ;

format 
       prev_m_trgt_dt
       prev_a2000	   date10.;

prev_a0310f	=lag(A0310F_ENTRY_DSCHRG_CD);
prev_m_trgt_dt	=lag(M_TRGT_DT);
prev_a2000	=lag(A2000_DSCHRG_DT);
prev_a2100	=lag(A2100_DSCHRG_STUS_CD); 

if first.bene_id then do;
   prev_a0310f	    =" ";
   prev_m_trgt_dt   =.;
   prev_a2000	    =.;
   prev_a2100	    =" ";
   prev_r           =" ";
end;

label r="Indicator:M if obs is from MDS, H if obs is from MedPAR";

if m_prvdrnum ne " " then r="M";
else if h_prvdrnum ne " " then r="H";
prev_r=lag(r);

if r="H" then do;
   if not first.bene_id then do;    
     if prev_r="M" then do; 
      if prev_a0310f not in ("10" "11" "12") then do;     
          d = h_admsndt - prev_m_trgt_dt; 
          if d<=100 then output claims_fallin_nodschrg; 		
         end;
      end;
   end;
end;

rename
    A0310A_FED_OBRA_CD	        =    A0310A
    A0310B_PPS_CD 		        =    A0310B
    A0310C_PPS_OMRA_CD		    =    A0310C
    A0310D_SB_CLNCL_CHG_CD	    =    A0310D
    A0310E_FIRST_SINCE_ADMSN_CD	=    A0310E
    A0310F_ENTRY_DSCHRG_CD     	=    A0310F

    a1600_entry_dt		        =    a1600
    A1700_ENTRY_TYPE_CD  	    =    A1700
    A1800_ENTRD_FROM_TXT 	    =    A1800
    A2000_DSCHRG_DT      	    =    A2000
    A2100_DSCHRG_STUS_CD 	    =    A2100

    J1700A_FALL_30_DAY_CD       =    J1700A
    J1700B_FALL_31_180_DAY_CD   =    J1700B
    J1700C_FRCTR_SIX_MO_CD      =    J1700C

    J1800_FALL_LAST_ASMT_CD     =    J1800
    J1900A_FALL_NO_INJURY_CD    =    J1900A
    J1900B_FALL_INJURY_CD       =    J1900B
    J1900C_FALL_MAJ_INJURY_CD   =    J1900C;

run;

*1. Adjust for continuous hospitalizations: if current hospital discharge dates equals next hospital admission date;
*   Combined the two hospital claims;
*2. Create Prev_prvdrnum in claims_fallin_nodschrg before merging with MDS data;

**combine contiguous hospitalizations;
proc sort data=claims_fallin_nodschrg;
 by bene_id descending h_admsndt descending h_dschrgdt;
run;

data claims_fallin_nodschrg;
set claims_fallin_nodschrg;
hhh=_N_;
run;

data removehosp(keep=removebene removehhh)
     claims_fallin_nodschrg(drop=removebene);

set claims_fallin_nodschrg;
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

output claims_fallin_nodschrg;

run;

proc sort data=claims_fallin_nodschrg;
 by bene_id hhh;
run;

data claims_fallin_nodschrg;
merge claims_fallin_nodschrg
      removehosp(rename=(removebene=bene_id removehhh=hhh) in=inremove);
 by bene_id hhh;
 if not inremove;
run;

proc sort data=claims_fallin_nodschrg out=nhout.claims_fallin_nodschrg;
 by bene_id h_admsndt h_dschrgdt;
run;

*keep only definite fall claims and create uniqueid for each fall episode;
data nhout.claims_fallin_nodschrg_px;
set nhout.claims_fallin_nodschrg;
if primary_dx=1;
length uniqueid $30.;
uniqueid=bene_id || left(h_admsndt);
run;

*get mds assessments for patients who fell during their nh stay but are missing discharge assessments;
data target_benes;
set nhout.claims_fallin_nodschrg_px(keep=bene_id);
run;

proc sort data=target_benes nodupkey;
 by bene_id;
run;

data dmds_target_fallin_nodschrg;
merge nhout.dmds
      target_benes(in=int);
 by bene_id;
 if int;
run;

**now concatenate fall claims with mds asessments for patients  misssing discharge assessments;
data mds_claims_fallin_nodschrg;
set   dmds_target_fallin_nodschrg
      nhout.claims_fallin_nodschrg_px (in=inc);

if m_idschrg=-1 then m_idschrg=-2;
if inc then m_idschrg=-1;
run;

proc sort data=mds_claims_fallin_nodschrg;
 by bene_id sortdt m_a0310e m_idschrg;
run;

*create record indicator to keep track of location of fall claims and mds assessments;
data nhout.mds_claims_fallin_nodschrg;
set mds_claims_fallin_nodschrg;
n_claims_mds=_N_;
prev_r=lag(r);
prev_uniqueid=lag(uniqueid);
run;


%mend MCLAIMNODSCHRG;

