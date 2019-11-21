/**********************************************************************************************************************/
/*  Macro MEXHIBIT1                                                                                                   */
/*  Last updated: 10/10/2018                                                                                          */
/*  Last run:  10/10/2018                                                                                             */                                                                                       
/**********************************************************************************************************************/
/*  This SAS macro performs the following                                                                             */
/*  1. identify falls from MedPAR claims based on the algorithm in the following paper                                */
/*  Kim SB, Zingmond DS, Keeler EB, et al. Development of an algorithm to identify fall-related                       */
/*  injuries and costs in Medicare data. Inj Epidemiol. 2016;3(1):1.                                                  */
/*  2. merge fall claims with MBSF files to obtain patient characteristics                                            */
/*  3. creat indicators to flag definite vs. probable falls and patients who are dually-eligible                      */                     
/**********************************************************************************************************************/
dm 'log;clear;output;clear;';

%MACRO MCLAIMS(MedParYear,medpar_dischrg,YYEAR,Fall_Output,Fall_Output_Final);
*drop obs with missing dicharge date;

data &medpar_dischrg.;
   set &MedParYear.;
   if DSCHRG_DT ne .;
run;

proc sql;
 create table mclaims&YYEAR. as
 select 

    C.BENE_ID,
    C.PRVDR_NUM,                             
    C.SS_LS_SNF_IND_CD		as SSLSSNF,      
    C.DSCHRG_DSTNTN_CD		as DSTNTNCD,     
    C.BENE_DSCHRG_STUS_CD	as DSCHRGCD,     
    C.CVRD_LVL_CARE_THRU_DT	as CVRLVLDT,     
    C.ADMSN_DT			as ADMSNDT,
    C.DSCHRG_DT			as DSCHRGDT,
    C.BENE_AGE_CNT		as AGE_CNT,          
    C.LOS_DAY_CNT		as LOSCNT,
    C.ADMTG_DGNS_CD	        as AD_DGNS,      

    C.DGNS_1_CD			as DGNSCD1,          
    C.DGNS_2_CD			as DGNSCD2,
    C.DGNS_3_CD			as DGNSCD3,
    C.DGNS_4_CD			as DGNSCD4,
    C.DGNS_5_CD			as DGNSCD5,
    C.DGNS_6_CD			as DGNSCD6,
    C.DGNS_7_CD			as DGNSCD7,
    C.DGNS_8_CD			as DGNSCD8,
    C.DGNS_9_CD			as DGNSCD9,
    C.DGNS_10_CD		as DGNSCD10,
    C.DGNS_11_CD		as DGNSCD11,
    C.DGNS_12_CD		as DGNSCD12,
    C.DGNS_13_CD		as DGNSCD13,
    C.DGNS_14_CD		as DGNSCD14,
    C.DGNS_15_CD		as DGNSCD15,
    C.DGNS_16_CD		as DGNSCD16,
    C.DGNS_17_CD		as DGNSCD17,
    C.DGNS_18_CD		as DGNSCD18,
    C.DGNS_19_CD		as DGNSCD19,
    C.DGNS_20_CD		as DGNSCD20,
    C.DGNS_21_CD		as DGNSCD21,
    C.DGNS_22_CD		as DGNSCD22,
    C.DGNS_23_CD		as DGNSCD23,
    C.DGNS_24_CD		as DGNSCD24,
    C.DGNS_25_CD		as DGNSCD25,

    C.DGNS_E_1_CD               as DGNSECD1, 
    C.DGNS_E_2_CD               as DGNSECD2,
    C.DGNS_E_3_CD               as DGNSECD3,
    C.DGNS_E_4_CD               as DGNSECD4,
    C.DGNS_E_5_CD               as DGNSECD5,
    C.DGNS_E_6_CD               as DGNSECD6,
    C.DGNS_E_7_CD               as DGNSECD7,
    C.DGNS_E_8_CD               as DGNSECD8,
    C.DGNS_E_9_CD               as DGNSECD9,
    C.DGNS_E_10_CD              as DGNSECD10,
    C.DGNS_E_11_CD              as DGNSECD11,
    C.DGNS_E_12_CD              as DGNSECD12,
    C.DRG_CD                                   

 from  &medpar_dischrg. as C  
 where SSLSSNF in("S" "L");
quit;

data mclaims&YYEAR.;
set mclaims&YYEAR.;

array dx{26}
    AD_DGNS DGNSCD1-DGNSCD25;

array ecode{12}
    DGNSECD1-DGNSECD12;

label DISQUALIFIED="1 if contains any disqualifying ecodes in external cause codes if not";     
label ECODE_I="The position of accidental falls code in external cause code (range 1-12)";    
label ECODE_VALUE="The value of accidental falls code in external cause code";  
label DXECODE_I="The position of accidental falls code in diagnosis code (range 1-26)";  
label DXECODE_VALUE="The value of accidental falls code in diagnosis code";    
label DXINJURY_I="The position of body site and type of injury code in diagnosis code (range 1-26)";     
label DXINJURY_VALUE="The value of body site and type of injury code in diagnosis code";
label PRIMARY_DX="1 if admission or/and primary diagnosis code or external cause code contain qualifying falls 0 if only secondary codes contain falls";

disqualified=.;
primary_dx=.;

 ***check whether disqualifying external cause codes are present in 26 diagnosis codes;
do i=1 to 26; 
   if substr(dx{i},1,4) in(
      "E806" 
      "E812" 
      "E813" 
      "E814" 
      "E867" 
      "E878" 
      "E879" 
      "E915" 
      "E916" 
      "E919" 
      "E920" 
      "E930"
      "E931" 
      "E932" 
      "E933" 
      "E934" 
      "E935" 
      "E936" 
      "E942" 
      "E943" 
      "E944" 
      "E945" 
      "E946" 
      "E947" 
      "E948" 
      "E949" 
      "E980") then do; 
         disqualified=1; 
      i=26;
   end;
end;

**if no disqualifying external cause codes found above, check 12 external cause codes for disqualifying value;
if disqualified=. then do i=1 to 12;
   if substr(ecode{i},1,4) in(
      "E806" 
      "E812" 
      "E813" 
      "E814" 
      "E867" 
      "E878" 
      "E879" 
      "E915" 
      "E916" 
      "E919" 
      "E920" 
      "E930"
      "E931" 
      "E932" 
      "E933" 
      "E934" 
      "E935" 
      "E936" 
      "E942" 
      "E943" 
      "E944" 
      "E945" 
      "E946" 
      "E947" 
      "E948" 
      "E949" 
      "E980") then do; 
         disqualified=1; 
      i=12;
   end;
end;

**if no disqualifying e-code found, look for accidental falls among up to 12 external cause codes and first 3 diagnosis codes;
**external cause codes for accidental fall e880.x, e881.x, e882, e883.x, e884.x, e885.x, e886.x, e888.x;

if disqualified=.;  

do i=1 to 12;
  if substr(ecode{i},1,4) in(
      "E880" 
      "E881" 
      "E882" 
      "E883" 
      "E884" 
      "E885" 
      "E886" 
      "E888") then do;
    ecode_i=i;
    ecode_value=ecode{i};
    i=12;
  end;
end;

if ecode_i=. then do i=1 to 3;
  if substr(dx{i},1,4) in(
      "E880" 
      "E881" 
      "E882" 
      "E883" 
      "E884" 
      "E885" 
      "E886" 
      "E888") then do;
     dxecode_i=i;
     dxecode_value=dx{i};
     i=3;
  end;
end;


**check 26 diagnosis codes for fall-related body site and type of injury diagnosis codes;
if ecode_i ne . or dxecode_i ne . then do i=1 to 26;
   if substr(dx{i},1,3) in(
      "820" 
      "808" 
      "810" 
      "812" 
      "813" 
      "814"
      "815" 
      "816" 
      "817" 
      "821" 
      "823" 
      "822" 
      "824" 
      "800" 
      "801" 
      "802" 
      "803" 
      "804" 
      "850"
      "851"
      "852"
      "853"
      "854"
      "831"
      "832"
      "833"
      "836") then do;
         dxinjury_i=i;
         dxinjury_value=dx{i}; 
	 i=26;
   end;
end;

** changed 807.0 to 8070 and 807.1 to 8071;

   if dxinjury_i=. then do i=1 to 26;
      if substr(dx{i},1,4) in(
         "8070"
         "8071") then do;
            dxinjury_i=i;
            dxinjury_value=dx{i};
    	    i=26;
      end;
   end;

**keep if fall-related external cause codes are present in 12 external cause code fields or first 3 diagnosis code fields;
if 1<=ecode_i<=12 or 1<=dxecode_i<=3;

*assign value to indicator primary_dx;
 if dxecode_i=1 or dxecode_i=2 or ecode_i=1 then primary_dx=1; *(1) inpatient fall-related injury;
	else if dxecode_i=3 or ecode_i=2 then primary_dx=0;  *(2) probable inpatient fall-related injury;
	  else primary_dx=9;
run;

proc contents data=mclaims&YYEAR. varnum;
run;

data mbsf&YYEAR.;
set mpar.mbsf_abcd_summary_&YYEAR.(keep=
BENE_ID
BENE_BIRTH_DT             
BENE_DEATH_DT               
ESRD_IND               
HMO_IND_12
AGE_AT_END_REF_YR 
        
BENE_RACE_CD 
RTI_RACE_CD 
BENE_ENROLLMT_REF_YR      
SEX_IDENT_CD              
STATE_CODE  
COUNTY_CD 
ZIP_CD    

ENTLMT_RSN_ORIG 
ENTLMT_RSN_CURR
DUAL_ELGBL_MONS
DUAL_STUS_CD_01-DUAL_STUS_CD_12);
run;

proc sql;

 create table &Fall_Output. as select
    C.*,
    B.*
 from mclaims&YYEAR. as C left join
      mbsf&YYEAR. as B
 on (C.bene_id = B.bene_id);
quit;

data &Fall_Output_Final.;
set &Fall_Output.(keep=

BENE_ID
PRVDR_NUM   
SSLSSNF     
DSTNTNCD     
DSCHRGCD    
CVRLVLDT     
ADMSNDT
DSCHRGDT
AGE_CNT          
LOSCNT
AD_DGNS     
  

DGNSCD1-DGNSCD25    
DGNSECD1-DGNSECD12
DRG_CD 


DISQUALIFIED    
ECODE_I  
ECODE_VALUE  
DXECODE_VALUE   
DXINJURY_I   
DXINJURY_VALUE
PRIMARY_DX
          
BENE_BIRTH_DT             
BENE_DEATH_DT               
ESRD_IND               
HMO_IND_12
AGE_AT_END_REF_YR 
        
BENE_RACE_CD 
RTI_RACE_CD 
BENE_ENROLLMT_REF_YR      
SEX_IDENT_CD              
STATE_CODE  
COUNTY_CD 
ZIP_CD    

ENTLMT_RSN_ORIG 
ENTLMT_RSN_CURR
DUAL_ELGBL_MONS
DUAL_STUS_CD_01-DUAL_STUS_CD_12

rename=(
          
BENE_BIRTH_DT           =BSF_DOB    
BENE_DEATH_DT           =BSF_DOD     
AGE_AT_END_REF_YR       =BSF_AGE 
        
BENE_RACE_CD            =BSF_RACE   
RTI_RACE_CD             =BSF_RTI  
BENE_ENROLLMT_REF_YR    =BSF_RFRNC_YR   
SEX_IDENT_CD            =BSF_SEX   
STATE_CODE              =BSF_STATE_CD 
COUNTY_CD               =BSF_CNTY_CD  
ZIP_CD                  =BSF_ZIP

ENTLMT_RSN_ORIG         =BSF_OREC
ENTLMT_RSN_CURR         =BSF_CREC
)
);

length
    dual_elg_01-dual_elg_12 $1;
array dstus{12}
    DUAL_STUS_CD_01-DUAL_STUS_CD_12;

array dual{12}
    dual_elg_01-dual_elg_12;
*create indicators for duals based on dual monthly indicator;
*f standards for full dual, r restricted dual, n nonedual;
do i=1 to 12;
  if dstus{i} in ("02" "04" "08") then dual{i}='f';
   else if dstus{i} in ("01" "03" "05" "06") then dual{i}='r';
    else dual{i}='n';
end;

run;

%MEND MCLAIMS;


%MCLAIMS(mpar.medpar_all_file_2011,medpar_all_file_2011,2011,medpar_fall_mbsf_2011,nhout.medpar_fall_mbsf_2011)
%MCLAIMS(mpar.medpar_all_file_2012,medpar_all_file_2012,2012,medpar_fall_mbsf_2012,nhout.medpar_fall_mbsf_2012)
%MCLAIMS(mpar.medpar_all_file_2013,medpar_all_file_2013,2013,medpar_fall_mbsf_2013,nhout.medpar_fall_mbsf_2013)
%MCLAIMS(mpar.medpar_all_file_2014,medpar_all_file_2014,2014,medpar_fall_mbsf_2014,nhout.medpar_fall_mbsf_2014);
%MCLAIMS(nhout.medpar_2015_jan_sept_icd9,medpar_all_file_2015,2015,medpar_fall_mbsf_2015,nhout.medpar_fall_mbsf_2015)

