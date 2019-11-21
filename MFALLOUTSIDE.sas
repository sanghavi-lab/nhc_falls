/***************************************************************************************************************************/
/*  Macro MFALLOUTSIDE                                                                                                     */
/*  Last updated: 10/21/2018                                                                                               */
/*  Last ran: 10/21/2018                                                                                                   */                                                                                   
/*  This SAS macro performs the following:                                                                                 */
/*  For patients who fell outside of their NH stay, merge their fall claims with following entry/reentry mds assessments   */
/*  Note: Remove the following patients:                                                                                   */
/*  1) goes to NH more than 6 months later                                                                                 */
/*  2) only have fall claim without following entry/reentry mds assessments, i.e., did not go back to NH                   */                                               
/***************************************************************************************************************************/

dm 'log;clear;output;clear;';

%MACRO MFALLOUTSIDE;

*delete first six months of fall claims in year 2011 as we need to look back six month before to check fall history;
data claims_fallout;
set nhout.claims_fallout;
if year(h_admsndt)=2011 and month(h_admsndt)<7 then delete;
run;

*concatenate fall claims and mds assessments;
data mds_claims_fallout;
set claims_fallout
    nhout.dmds;
run;

proc sort data=mds_claims_fallout;
 by bene_id sortdt; 
run;

proc print data=mds_claims_fallout(obs=200);
 title 'before';
 var r bene_id sortdt m_idschrg m_trgt_dt a2000 a2100 a0310a a0310e a0310f h_admsndt h_dschrgdt j1700a j1700b j1700c j1800 j1900a j1900b j1900c;
run;

*removes MDS records preceding first out-of-NH hospitalization (mds discharge indicates a discharge to community,home etc., not to hospital);
data mds_claims_fallout;
set mds_claims_fallout;
 by bene_id;

retain hh;

if first.bene_id then do;
   if r="H" then hh=1;
   else hh=0;
end;
else do;
   if r="H" then hh=hh+1;
end;

if hh=0 then delete;	

if a0310f in("10" "11" "12") then delete;

if r="H" then output mds_claims_fallout;
else if r="M" then do;
   if a0310e="1" then output mds_claims_fallout;
   else if (a0310a="01" and a0310f ne "01") then output mds_claims_fallout;
end;
run;

proc sort data=mds_claims_fallout;
 by bene_id sortdt; 
run;

proc print data=mds_claims_fallout(obs=20);
 title 'set HH, remove if HH=0';
 var hh r bene_id sortdt m_idschrg m_trgt_dt a2000 a2100 a0310a a0310e a0310f h_admsndt h_dschrgdt j1700a j1700b j1700c j1800 j1900a j1900b j1900c;
run;

**keep first mds assessment following hospital claim;
data mds_claims_fallout;
set mds_claims_fallout;
 by bene_id;

retain i_mds;

if first.bene_id then i_mds=0;
else do;
  if r="M" then i_mds=i_mds+1;
  else if r="H" then i_mds=0;
end;
if i_mds in(0 1);
run;

proc print data=mds_claims_fallout(obs=20);
 title 'set i_mds (count of mds records following H)';
 var i_mds hh r bene_id sortdt m_idschrg m_trgt_dt a2000 a2100 a0310a a0310e a0310f h_admsndt h_dschrgdt j1700a j1700b j1700c j1800 j1900a j1900b j1900c;
run;

*remove patients who only had one fall claim with no following MDS assessments;
proc freq data=mds_claims_fallout noprint;
 tables bene_id* hh/out=outsingle(where=(count=1) drop=percent);
run;

proc print data=outsingle(obs=20);
 title 'outsingle';
run;

data mds_claims_fallout
     removebene(keep=bene_id hh);
merge mds_claims_fallout
      outsingle(in=getout);
 by bene_id hh;
 if not getout;

length prev_h_admsndt prev_h_dschrgdt 4.;
format prev_h_admsndt prev_h_dschrgdt date10.;

prev_h_admsndt = lag(h_admsndt);
prev_h_dschrgdt = lag(h_dschrgdt);

if first.bene_id then do;
   prev_h_admsndt = lag(h_admsndt);
   prev_h_dschrgdt = lag(h_dschrgdt);
end;

length dayssincehospadmit
       _1mo_post_claim
       _2to6mos_post_claim	3.;

if r="M" then do;
   _1mo_post_claim=0;
  _2to6mos_post_claim=0;
end;

*calculate days elapsed from hospital admission to NH entry/reentry;
dayssincehospadmit = m_trgt_dt - prev_h_admsndt;
if dayssincehospadmit ne . then do;
   if -2<=dayssincehospadmit<=31 then _1mo_post_claim=1;
   else if 31<dayssincehospadmit<=180 then _2to6mos_post_claim=1;
   if dayssincehospadmit > 181 then output removebene;
end;

output mds_claims_fallout;

run;

*remove patients who went back to nh more than six months after hospitalization for fall;
data mds_claims_fallout;
merge mds_claims_fallout    
     removebene(in=getout);
 by bene_id hh;
if not getout;
run;

proc print data=mds_claims_fallout(obs=200);
 title 'post-remove-singles';
 var i_mds hh r bene_id sortdt m_idschrg m_trgt_dt a2000 a2100 a0310a a0310e a0310f h_admsndt h_dschrgdt j1700a j1700b j1700c j1800 j1900a j1900b j1900c;
run;

data claims_fallout(keep=
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
    primary_dx
	HH
    )

     mds_fallout(drop=
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

set mds_claims_fallout;

if r="H" then output claims_fallout;
else if r="M" then output mds_fallout;
run;

data nhout.mds_claims_fallout;
merge claims_fallout
      mds_fallout;
 by bene_id hh;
run;

proc contents varnum;
run;

proc sort data=nhout.mds_claims_fallout;
by bene_id sortdt;
run;

proc print data=nhout.mds_claims_fallout(obs=100);
 var bene_id sortdt M_TRGT_DT h_admsndt h_dschrgdt hh DAYSSINCEHOSPADMIT   
    _1MO_POST_CLAIM      
    _2TO6MOS_POST_CLAIM j1700a j1700b j1700c j1800 j1900a j1900b j1900c; 
run;

%MEND MFALLOUTSIDE;


