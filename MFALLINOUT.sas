/**********************************************************************************************************************/
/*  Macro MFALLINOUT                                                                                                  */
/*  Last updated: 10/21/2018                                                                                          */
/*  Last run:  10/21/2018                                                                                             */                                                                                   
/*  This SAS macro uses the concatenated MDS assessments and MedPAR fall claims to create two groups:                 */
/*  1) Patients who came from NH, this group fell during their nursing home stay                                      */
/*  2) Patients who did not come from NH, this group fell outside of their nursing home stay                          */
/**********************************************************************************************************************/
dm 'log;clear;output;clear;';

%macro MFALLINOUT(daysin,daysout);

data claims_fallin(keep=
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
    FALL_IN           
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

     /*claims_fallout(keep=
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
    FALL_IN           
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

     dmds(drop=
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
    FALL_IN           
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
    SSLSSNF
    primary_dx);
*/
set nhout.mdsclaims;
 by bene_id;

length 
    r				$1.
    prev_a0310f	 	$2.
    prev_m_trgt_dt  4.
    prev_A2000		4.
    prev_A2100	 	$2.
    fall_in		 	3.;

format 
       prev_m_trgt_dt
       prev_a2000	   date10.;

*look back from hospital claim at the previous MDS assessment and record their values;
prev_a0310f	=lag(A0310F_ENTRY_DSCHRG_CD);
prev_m_trgt_dt	=lag(M_TRGT_DT);
prev_a2000	=lag(A2000_DSCHRG_DT);
prev_a2100	=lag(A2100_DSCHRG_STUS_CD); 

if first.bene_id then do;
   prev_a0310f	    =" ";
   prev_m_trgt_dt   =.;
   prev_a2000	    =.;
   prev_a2100	    =" ";
end;

*create indicator r to distinguith whether the record is a MDS assessment or a fall claim;
label r="Indicator:M if MDS record, H if MedPAR record";

if m_prvdrnum ne " " then r="M";
else if h_prvdrnum ne " " then r="H";

if r="H" then do; *if this is a fall claim;
   if first.bene_id then fall_in=0; *earliest hospital claim occurs before any NH assessment, patient does not come from NH;
   else do;                         
      if prev_a0310f in("10" "11","12") then do;               *if there is a MDS assessment indicating discharge assessment right before the hospital claim;
         if prev_a2100 not in("03" "09") then fall_in=0;  *if for that discharge assessment, the patient does not go to 03=acute hospital, 09=long term care hospital;
         else if prev_a2100 in("03" "09") then do;       *if that discharge assessment indicates that the patient goes to 03=acute hospital, 09=long term care hospital;
            d = h_admsndt - prev_a2000;	 *calculate the days since nh discharge to hospital admission;
             if abs(d) <=&daysin. then fall_in=1;	 *if hospital admission date is within plus/minus 1 days of mds discharge date then this patient comes from NH;
	         else if abs(d) > &daysin. and abs(d)<=&daysout. then fall_in=-1;
	         else if abs(d) > &daysout. then fall_in=0; *if days elapsed greater than 180 then patients did not come from NH;			
         end;
      end;
	  else do; *if previous MDS assessment looking back from fall claim is not a discharge assessment;
	  d=h_admsndt-prev_m_trgt_dt;
	  if abs(d) > &daysout. then fall_in=0; *if the more than 180 days has passed since NH discharge to hospital admission then patients did not come from NH;	
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

if fall_in=1 then output claims_fallin;
  else if fall_in=0 then output claims_fallout;
if r="M" then output dmds;

run;

*dmds contains mds assessments;
data dmds;
set dmds;
length prev_m_prvdrnum	$12.;
prev_m_prvdrnum=lag(m_prvdrnum);
run;

data nhout.dmds;
   set dmds;
run;

*claims_fallout contains fall claims from patients who fell outside of their nh stay;
data nhout.claims_fallout;
   set claims_fallout;
run;

*claims_fallin contains fall claims from patients who fell during their nh stay;
data nhout.claims_fallin;
   set claims_fallin;
run;


%mend MFALLINOUT;

%MFALLINOUT(1,180)

