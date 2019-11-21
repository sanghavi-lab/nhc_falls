/**************************************************************************************************************************/
/*  Macro MDSCHRGPREPOST                                                                                                  */
/*  Last updated: 10/01/2018;                                                                                             */
/*  Last Run: 10/20/2018;                                                                                                 */                                                                                   
/*  This SAS macro creates three datasets:                                                                                */                               
/*  1)getmdspre: contains the mds assessment before fall claim                                                            */ 
/*  2)getmdspost: contains three mds assessment following fall claim                                                      */
/*  3)hosprecord: contains fall claims for patients who fell during their nh stay                                         */ 
/**************************************************************************************************************************/

%macro MDSCHRGPREPOST;

data _getmdspre(keep=bene_id get_n_claims_mds)
     _getmdspost(keep=bene_id get_n_claims_mds)
     hosprecord(keep=
    BENE_ID
    N_CLAIMS_MDS
    SORTDT
    AD_DGNS
    BSF_AGE            
    BSF_CNTY_CD    
    BSF_CREC     
    BSF_DOB        
    BSF_DOD
    BSF_RTI   
    BSF_OREC       
    BSF_RACE       
    BSF_RFRNC_YR   
    BSF_SEX        
    BSF_STATE_CD   
    BSF_ZIP        
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
    R         
    SSLSSNF
    primary_dx);
	
set nhout.mds_claims_fallin;

if r="H" then do;
  
   output hosprecord;
   
   *locate previous mds assessment before fall claim;
   get_n_claims_mds = n_claims_mds - 1;
   output _getmdspre;

   *locate three following mds assessment before fall claim;
   get_n_claims_mds = n_claims_mds + 1;
   output _getmdspost;

   get_n_claims_mds = n_claims_mds + 2;
   output _getmdspost;

   get_n_claims_mds = n_claims_mds + 3;
   output _getmdspost;
end;
run;

*get mds assessment before fall claim;
proc sql;
 create table getmdspre as select
   P.*,
   M.*
 from _getmdspre as P,
      nhout.mds_claims_fallin(drop=
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
    primary_dx)    as M

 where (P.BENE_ID = M.BENE_ID and P.GET_N_CLAIMS_MDS = M.N_CLAIMS_MDS);
quit;

*get three mds assessment following fall claim;
proc sql;
 create table getmdspost as select
   PO.*,
   M.*
 from _getmdspost as PO,
      nhout.mds_claims_fallin(drop=
    
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
    primary_dx)    as M
where (PO.BENE_ID = M.BENE_ID and PO.GET_N_CLAIMS_MDS = M.N_CLAIMS_MDS);

quit;

data nhout.getmdspre;
set getmdspre;
run;

data nhout.getmdspost;
set getmdspost;
run;

*hosprecord contains fall claims for patients who fell during their nh stay;
data nhout.hosprecord;
set hosprecord;
length uniqueid $30.;
uniqueid=bene_id || left(h_admsndt);
run;

%mend MDSCHRGPREPOST;
