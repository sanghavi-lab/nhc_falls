/**************************************************************************************************************************/
/*  Macro MDSCHRG                                                                                                         */
/*  Last updated: 10/21/2018;                                                                                             */
/*  Last Run: 10/21/2018;                                                                                                 */                                                                                   
/*  This SAS macro performs the following:                                                                                */                               
/*  1) create deminominators for those who went back to nursing home versus those who did not go back                     */
/*    **for those who went back, obtain their post hospitalization mds assessments                                        */
/*    **for those who did not go back, obtain their hospital claims to count the number of fall episodes for the flowchart*/
/*  2) create denominators for those who went back to same nusing home vs those who went back to different nursing home   */
/*    **for those who went back to same nursing home, obtain their pre- and post- hospitalization mds assessments         */
/*       **store those mds assessments in two datasets mdspre_same_nh and mdspost_same_nh                                 */
/*    **for those who went back to different nursing home, obtain their post- hospitalization mds assessments             */
/*       **store those mds assessments in mdspost_different_nh                                                            */ 
/**************************************************************************************************************************/

dm 'log;clear;output;clear;';

%macro MDSCHRG;

data nhout.mds_claims_fallin;
set nhout.mds_claims_fallin;
prev_r=lag(r);
prev_uniqueid=lag(uniqueid);
run;

*separate patients who went back to NH versus those who did not;

*for patietns who went back to nh, separate their mds assessment before hospitalization and after;
data getpre_mds_fallin_back(keep=bene_id prev_uniqueid get_n_claims_mds)
     getpost_mds_fallin_back(keep=bene_id prev_uniqueid get_n_claims_mds);
  set nhout.mds_claims_fallin;
  by bene_id;
  if not first.bene_id then do;
  if r="M" and prev_r="H" then do;

    get_n_claims_mds=n_claims_mds-2;
    output getpre_mds_fallin_back;

    get_n_claims_mds=n_claims_mds;
    output getpost_mds_fallin_back;

	get_n_claims_mds=n_claims_mds+1;
    output getpost_mds_fallin_back;

	get_n_claims_mds=n_claims_mds+2;
    output getpost_mds_fallin_back;
  end;
  end;
run;

data getpost_mds_fallin_back(rename=(prev_uniqueid=uniqueid));
set getpost_mds_fallin_back;
run;

data getpre_mds_fallin_back(rename=(prev_uniqueid=uniqueid));
set getpre_mds_fallin_back;
run;

*for those who did not go back, obtain their hospital claims;
*checked that these are indeed all hospital claims;
data nhout.claims_fallin_notback(keep=bene_id uniqueid n_claims_mds h_admsndt);
  set nhout.mds_claims_fallin;
  by bene_id;
  if last.bene_id and r="H" then do;
     output nhout.claims_fallin_notback;
   end;
run;

*get mds assessments before hospitalization for those who went back to nh;
proc sql;
 create table mdspre_back as select
   P.*,
   M.*
 from getpre_mds_fallin_back as P,
      nhout.mds_claims_fallin(drop=
     AD_DGNS
	 uniqueid
    BSF_AGE            
    BSF_CNTY_CD    
    BSF_CREC     
    BSF_DOB        
    BSF_DOD           
    BSF_OREC 
    BSF_RTI 
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
    primary_dx
    SORTDT
    HHH
    NEXT_H_ADMSNDT
    NEXT_H_DSCHRGDT
    REMOVEHHH)    as M
 where (P.BENE_ID = M.BENE_ID and P.GET_N_CLAIMS_MDS = M.N_CLAIMS_MDS);
quit;


*get mds assessments after hospitalization for those who went back to nh;
proc sql;
 create table mdspost_back as select
   PO.*,
   M.*
 from getpost_mds_fallin_back as PO,
      nhout.mds_claims_fallin(drop=
	uniqueid
    AD_DGNS
    BSF_AGE            
    BSF_CNTY_CD    
    BSF_CREC     
    BSF_DOB        
    BSF_DOD           
    BSF_OREC       
    BSF_RACE
    BSF_RTI 
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
    PREV_A2000        
    PREV_A2100        
    PREV_A0310F       
    PREV_M_TRGT_DT            
    SSLSSNF
    primary_dx
    SORTDT
    HHH
    NEXT_H_ADMSNDT
    NEXT_H_DSCHRGDT
    REMOVEHHH)    as M
where (PO.BENE_ID = M.BENE_ID and PO.GET_N_CLAIMS_MDS = M.N_CLAIMS_MDS);

quit;

data nhout.mdspre_back;
set mdspre_back;
run;

*checked that the post mds assessments selected that having missing discharge dates are hospital claims;
*this happens when the patient had two fall claims and in between there are less than 3 MDS assessments;
*delete those hospital claims because we only want post hospitalization mds assessments;
data nhout.mdspost_back;
set mdspost_back;
if m_trgt_dt^=.;
run;

*sanity check:there are same number of fall episodes in pre-hospitalization mds assessments
*as the number of fall episodes in post-hospitalization mds assessments if we just include the first one after hospitalization;
/*
 data sanity_check;
 set nhout.mdspost_back;
 by uniqueid;
 if first.uniqueid;
 run;
*/

*Separate patients who came from NH who went back to same/different NH after hospitalization;
*checked that no missing m_prvdrnum or prev_m_prvdrnum in dataset mdspost_back;
data _getmdspost_different_NH (keep=bene_id uniqueid _n_claims_mds)
     _getmdspost_same_NH      (keep=bene_id uniqueid _n_claims_mds)
     _getmdspre_same_NH       (keep=bene_id uniqueid  _n_claims_mds);

set nhout.mdspost_back;

by uniqueid;
if first.uniqueid then do;

      if prev_m_prvdrnum ne m_prvdrnum then do;

      _n_claims_mds=get_n_claims_mds;
      output _getmdspost_different_NH; 

	  _n_claims_mds=get_n_claims_mds+1;
	  output _getmdspost_different_NH;

	  _n_claims_mds=get_n_claims_mds+2;
	  output _getmdspost_different_NH;

    end;
  else if prev_m_prvdrnum=m_prvdrnum then do;
      _n_claims_mds=get_n_claims_mds-2;
	  output _getmdspre_same_NH;

      _n_claims_mds=get_n_claims_mds;
      output _getmdspost_same_NH; 

	  _n_claims_mds=get_n_claims_mds+1;
	  output _getmdspost_same_NH;

	  _n_claims_mds=get_n_claims_mds+2;
	  output _getmdspost_same_NH;

   end; 
end;
run;

*get mds assessments after hospitalization for patients who went back to different nh;
proc sql;
 create table nhout.mdspost_different_nh as select
   PO.*,
   M.*
 from _getmdspost_different_nh as PO,
      nhout.mdspost_back (drop=uniqueid)  as M
 where (PO.bene_id = M.bene_id and PO._N_CLAIMS_MDS = M.GET_N_CLAIMS_MDS);
quit;

*get mds assessments after hospitalization for patients who went back to same nh;
proc sql;
 create table nhout.mdspost_same_nh as select
   PO.*,
   M.*
 from _getmdspost_same_nh as PO,
      nhout.mdspost_back(drop=uniqueid)  as M
where (PO.bene_id= M.bene_id and PO._N_CLAIMS_MDS = M.GET_N_CLAIMS_MDS);
quit;

*get mds assessments before hospitalization for patients who went back to same nh;
proc sql;
 create table nhout.mdspre_same_nh as select
   PO.*,
   M.*
 from _getmdspre_same_nh as PO,
      nhout.mds_claims_fallin(drop=
	uniqueid
    AD_DGNS
    BSF_AGE            
    BSF_CNTY_CD    
    BSF_CREC     
    BSF_DOB        
    BSF_DOD           
    BSF_OREC       
    BSF_RACE
    BSF_RTI 
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
    PREV_A2000        
    PREV_A2100        
    PREV_A0310F       
    PREV_M_TRGT_DT            
    SSLSSNF
    primary_dx
    SORTDT
    HHH
    NEXT_H_ADMSNDT
    NEXT_H_DSCHRGDT
    REMOVEHHH
    DUAL_ELGBL_MONS) as M
where (PO.bene_id = M.bene_id and PO._N_CLAIMS_MDS = M.N_CLAIMS_MDS);
quit;

%mend MDSCHRG;

