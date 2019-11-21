/**************************************************************************************************************************/
/*  Macro MMAJOR                                                                                                          */
/*  Last updated: 10/21/2018;                                                                                             */
/*  Last Run: 10/21/2018;                                                                                                 */ 
/*  This SAS macro identifies major injury falls among the following two denominator population:                          */
/*  1) Patients who fell during their NH and went back to same NH                                                         */
/*  2) Patients who fell outside of their NH stay                                                                         */ 
/**************************************************************************************************************************/

dm 'log;clear;output;clear;';

%MACRO MMAJOR(input,output);

data nhout.&output.;
set nhout.&input.;

array icd{38}
   AD_DGNS DGNSCD1-DGNSCD25 DGNSECD1-DGNSECD12;

length dx1-dx38 $25. majorinjury 3.;
array disease{38}
  dx1-dx38;

majorinjury=0;

do i=1 to 38;
   disease{i}='nonmajor';
   if '800' <= substr(ICD{I},1,3) <= '829' then do; disease{i} = 'fracture'; majorinjury=1;end;

   else if '830' <= substr(ICD{I},1,3) <= '839' then do; disease{i} = 'dislocation'; majorinjury=1;end;

   else if '850'<=substr(ICD{I},1,3)<= '854' or '803'<=substr(ICD{I},1,3)<= '804' and 
           ('2'<=substr(ICD{I},4,1)<='6' or substr(ICD{I},4,2) in ('11' '12')) then do; disease{i} = 'headinjury';majorinjury=1;end;

   else if substr(ICD{I},1,4) in('8522' '4321') then do; disease{i} = 'subduralhermatoma';majorinjury=1;end;

end;
run;

proc freq data=nhout.&output.;
   tables majorinjury / missing;
run;

%Mend MMAJOR;
/*%MMAJOR(mdspre_samenh_claim_iss,mdspre_samenh_claim_mj)
%MMAJOR(mds_claims_fallout,mds_claims_fallout_mj)
*/
%MMAJOR(mdspre_claim_iss,mdspre_claim_mj)
