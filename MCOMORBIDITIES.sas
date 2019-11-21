/**************************************************************************************************************************/
/*  Macro MCOMORBIDITIES                                                                                                  */
/*  Last updated: 10/21/2018;                                                                                             */
/*  Last Run: 10/21/2018;                                                                                                 */                                                                                   
/*  This SAS macro calculates the combined Charlson–Elixhauser comorbidity scores for the following denominator           */
/*    1) Patients who fell during their NH and went back to same NH                                                       */
/*  References: Gagne JJ, Glynn RJ, Avorn J, Levin R, Schneeweiss S. A combined comorbidity score predicted               */
/*  mortality in elderly patients better than existing scores. J Clin Epidemiol. 2011; 64:749–59. DOI:                    */
/*  10.1016/j.jclinepi.2010.10.004 [PubMed: 21208778]                                                                     */ 
/**************************************************************************************************************************/
dm 'log;clear;output;clear;';

%MACRO MCOMORBIDITIES(input, output);

proc contents data=nhout.&input. varnum; run;

data conditions;
set nhout.&input.(keep=uniqueid AD_DGNS DGNSCD1-DGNSCD25 DGNSECD1-DGNSECD12);

array icd{38}
   AD_DGNS DGNSCD1-DGNSCD25 DGNSECD1-DGNSECD12;

length dx1-dx38 $25.;
array disease{38}
  dx1-dx38;

do i=1 to 38;
   disease{i}='nopoints';

   if substr(ICD{I},1,3) in('196' '197' '198' '199') then disease{i} = 'metastatic_romano';

   else if ICD{I} in('40201' '40211' '40291') then disease{i} = 'chf_romano';
   else if substr(ICD{I},1,4) = '4293' then disease{i} = 'chf_romano';
   else if substr(ICD{I},1,3) in('425' '428') then disease{i} = 'chf_romano';

   else if substr(ICD{I},1,4) in('3310' '3311' '3312') then disease{i} = 'dementia_romano';
   else if substr(ICD{I},1,3) = '290' then disease{i} = 'dementia_romano';

   else if ICD{I} in('40311' '40391' '40412' '40492') then disease{i} = 'renal_elixhauser';
   else if substr(ICD{I},1,3) in('585' '586') then disease{i} = 'renal_elixhauser';
   else if substr(ICD{I},1,4) in ('V420' 'V451' 'V560' 'V568') then disease{i} = 'renal_elixhauser';

   else if '260' <= substr(ICD{I},1,3) <= '263' then disease{i} = 'wtloss_elixhauser';

   else if substr(ICD{I},1,3) in('342' '344') then disease{i} = 'hemiplegia_romano';

   else if substr(ICD{I},1,4) in('2911' '2912' '2915' '2918' '2919' 'V113') then disease{i} = 'alcohol_elixhauser';
   else if '30390' <= ICD{I} <= '30393' then disease{i} = 'alcohol_elixhauser';
   else if '30500' <= ICD{I} <= '30503' then disease{i} = 'alcohol_elixhauser';

   else if '140' <= substr(ICD{I},1,3) <= '171' then disease{i} = 'tumor_romano';
   else if '174' <= substr(ICD{I},1,3) <= '195' then disease{i} = 'tumor_romano';
   else if '200' <= substr(ICD{I},1,3) <= '208' then disease{i} = 'tumor_romano';
   else if substr(ICD{I},1,4) in('2730' '2733') then disease{i} = 'tumor_romano';
   else if substr(ICD{I},1,5) = 'V1046' then disease{i} = 'tumor_romano';

   else if ICD{I} in('42610' '42611' '42613' '42731' '42760') then disease{i} = 'arrhythmia_elixhauser';

   else if '4262' <= substr(ICD{I},1,4) <= '4264' then disease{i} = 'arrhythmia_elixhauser';
   else if '42650' <= ICD{I} <= '42653' then disease{i} = 'arrhythmia_elixhauser';
   else if '4266' <= substr(ICD{I},1,4) <= '4268' then disease{i} = 'arrhythmia_elixhauser';
   else if substr(ICD{I},1,4) in('4270' '4272' '4279' '7850' 'V450' 'V533') then disease{i} = 'arrhythmia_elixhauser';

   else if substr(ICD{I},1,4) in('4150' '4168' '4169') then disease{i} = 'pulmonarydz_romano';
   else if substr(ICD{I},1,3) in('491' '492' '493' '494' '496') then disease{i} = 'pulmonarydz_romano';

   else if '2860' <= substr(ICD{I},1,4) <= '2869' then disease{i} = 'coagulopathy_elixhauser';
   else if '2873' <= substr(ICD{I},1,4) <= '2875' then disease{i} = 'coagulopathy_elixhauser';
   else if substr(ICD{I},1,4) = '2871' then disease{i} = 'coagulopathy_elixhauser';

   else if '25040' <= ICD{I} <= '25073' then disease{i} = 'compdiabetes_elixhauser';
   else if '25090' <= ICD{I} <= '25093' then disease{i} = 'compdiabetes_elixhauser';

   else if '2801' <= substr(ICD{I},1,4) <= '2819' then disease{i} = 'anemia_elixhauser';
   else if substr(ICD{I},1,4) = '2859' then disease{i} = 'anemia_elixhauser';

   else if '2760' <= substr(ICD{I},1,4) <= '2769' then disease{i} = 'electrolytes_elixhauser';

   else if ICD{I} in('07032' '07033' '07054' '45620' '45621' '57140' '57149') then disease{i} = 'liver_elixhauser';
   else if substr(ICD{I},1,4) in('4560' '4561' '5710' '5712' '5713' '5715' '5716' '5718' '5719' '5723' '5728' 'V427') then disease{i} = 'liver_elixhauser';

   else if '4400' <= substr(ICD{I},1,4) <= '4409' then disease{i} = 'pvd_elixhauser';
   else if substr(ICD{I},1,4) in('4412' '4414' '4417' '4419' '4471' '5571' '5579' 'V434') then disease{i} = 'pvd_elixhauser';
   else if '4431' <= substr(ICD{I},1,4) <= '4439' then disease{i} = 'pvd_elixhauser';

   else if '29500' <= ICD{I} <= '29899' then disease{i} = 'psychosis_elixhauser';
   else if ICD{I} in('29910' '29911') then disease{i} = 'psychosis_elixhauser';

   else if substr(ICD{I},1,3) = '416' then disease{i} = 'pulmcirc_elixhauser';
   else if substr(ICD{I},1,4) = '4179' then disease{i} = 'pulmcirc_elixhauser';

   else if substr(ICD{I},1,3) in('042' '043' '044') then disease{i} = 'hivaids_romano';

   else if substr(ICD{I},1,4) in('4011' '4019') then disease{i} = 'hypertension_elixhauser';
   else if ICD{I} in('40210' '40290' '40410' '40490' '40511' '40519' '40591' '40599') then disease{i} = 'hypertension_elixhauser';

end;
run;

proc sort nodupkey data = conditions;
 by uniqueid dx1-dx38;
run;

*Applying the weights;

data combinedcomorbidityscore(keep=uniqueid combinedscore
 hypertension
 pvd
 anemia
 chf
 coagulopathy
 electrolytes
 metastatic
 renal
 tumor
 dementia
 wtloss
 hemiplegia
 alcohol
 arrhythmia
 pulmonary
 diabetes
 liver
 psychosis
 pulmcirc
 hiv);

set conditions;

array disease{38}
  dx1-dx38;

length wt1-wt38 3.;
array weight{38}
  wt1-wt38;

 hypertension		=0;
 pvd			=0;
 anemia			=0;
 chf			=0;
 coagulopathy		=0;
 electrolytes		=0;
 metastatic		=0;
 renal			=0;
 tumor			=0;
 dementia		=0;
 wtloss			=0;
 hemiplegia		=0;
 alcohol		=0;
 arrhythmia		=0;
 pulmonary		=0;
 diabetes		=0;
 liver			=0;
 psychosis		=0;
 pulmcirc		=0;
 hiv			=0;

do i=1 to 38;
        weight{i}=0;
        if disease{i} = 'metastatic_romano'			then do;  weight{i} = 5; metastatic=1; end;
	else if disease{i} = 'chf_romano'			then do;  weight{i} = 2; chf=1; end;
	else if disease{i} = 'dementia_romano'			then do;  weight{i} = 2; dementia=1; end;
	else if disease{i} = 'renal_elixhauser'			then do;  weight{i} = 2; renal=1; end;
	else if disease{i} = 'wtloss_elixhauser'		then do;  weight{i} = 2; wtloss=1; end;
	else if disease{i} = 'hemiplegia_romano'		then do;  weight{i} = 1; hemiplegia=1; end;
	else if disease{i} = 'alcohol_elixhauser'		then do;  weight{i} = 1; alcohol=1; end;
	else if disease{i} = 'tumor_romano'			then do;  weight{i} = 1; tumor=1; end;
	else if disease{i} = 'arrhythmia_elixhauser'		then do;  weight{i} = 1; arrhythmia=1; end;
	else if disease{i} = 'pulmonarydz_romano'		then do;  weight{i} = 1; pulmonary=1; end;
	else if disease{i} = 'coagulopathy_elixhauser'		then do;  weight{i} = 1; coagulopathy=1; end;
	else if disease{i} = 'compdiabetes_elixhauser'		then do;  weight{i} = 1; diabetes=1; end;
	else if disease{i} = 'anemia_elixhauser'		then do;  weight{i} = 1; anemia=1; end;
	else if disease{i} = 'electrolytes_elixhauser'		then do;  weight{i} = 1; electrolytes=1; end;
	else if disease{i} = 'liver_elixhauser'			then do;  weight{i} = 1; liver=1; end;
	else if disease{i} = 'pvd_elixhauser'			then do;  weight{i} = 1; pvd=1; end;
	else if disease{i} = 'psychosis_elixhauser'		then do;  weight{i} = 1; psychosis=1; end;
	else if disease{i} = 'pulmcirc_elixhauser'		then do;  weight{i} = 1; pulmcirc=1; end;
	else if disease{i} = 'hivaids_romano'			then do;  weight{i} = -1; hiv=1; end;
	else if disease{i} = 'hypertension_elixhauser'		then do;  weight{i} = -1; hypertension=1; end;
end;

combinedscore = 0;

*Summing the weights;
do i=1 to 38;
  combinedscore = combinedscore + weight{i};
end;

run;

proc print data=combinedcomorbidityscore(obs=10);
 title 'combinedcomorbidityscore';
run;

proc contents data=combinedcomorbidityscore varnum;
run;

proc sort data=nhout.&input. out=&input.;
 by uniqueid;
run;

data nhout.&output.;
 merge
   &input.(in=inkeep)
   combinedcomorbidityscore;
 by uniqueid;
 if inkeep;
format h_admsndt DDMMYY8.;
run;

proc contents data=nhout.&output. varnum;
run;

proc print data=nhout.&output.(obs=20);
 title 'comorbidities';
 var bene_id
     
    ECODE_VALUE
    AD_DGNS   
    DGNSCD1 
 
 combinedscore
 hypertension
 pvd
 anemia
 chf
 coagulopathy
 electrolytes
 metastatic
 renal
 tumor
 dementia
 wtloss
 hemiplegia
 alcohol
 arrhythmia
 pulmonary
 diabetes
 liver
 psychosis
 pulmcirc
 hiv;

run;

%MEND MCOMORBIDITIES;

*%MCOMORBIDITIES(mdspre_samenh_claim_mj,mdspre_samenh_claim_com);
%MCOMORBIDITIES(mdspre_claim_mj,mdspre_claim_com)

