/***************************************************************************************************************************/
/*  Macro MNODSCHRG                                                                                                        */
/*  Last updated: 10/21/2018                                                                                               */
/*  Last ran: 10/21/2018                                                                                                   */                                                                                   
/*  This SAS macro performs the following:                                                                                 */
/*  For patients who went to hospital for a fall with missing discharge assessments                                        */
/*  1) Separate patients who went back to NH vs not                                                                        */                   */      
/*  2) Separate patients who went back to same nursing home vs different NH                                                */                                                 
/***************************************************************************************************************************/

dm 'log;clear;output;clear;';

%macro MNODSCHRG;

*separate population who went back to NH versus those who did not for patients with missing discharges;

data getmdspost_fallin_back_nd (keep=bene_id prev_uniqueid m_prvdrnum prev_m_prvdrnum);
  set nhout.mds_claims_fallin_nodschrg;
  by bene_id;
  if not first.bene_id then do;
  if r="M" and prev_r="H" then output getmdspost_fallin_back_nd;
  end;
run;

data getmdspost_fallin_notback_nd (keep=bene_id uniqueid);
  set nhout.mds_claims_fallin_nodschrg;
  by bene_id;
  if last.bene_id and r="H" then do;
    output getmdspost_fallin_notback_nd;
  end;
run;

data nhout.getmdspost_fallin_notback_nd;
set getmdspost_fallin_notback_nd;
run;

data nhout.getmdspost_fallin_back_nd(rename=(prev_uniqueid=uniqueid));
set getmdspost_fallin_back_nd;
run;

*separate patients who went back do same versus different NH for those missing discharge assessments;
data nhout.mdspost_different_NH_nd (keep=bene_id uniqueid)
     nhout.mdspost_same_NH_nd      (keep=bene_id uniqueid);
set nhout.getmdspost_fallin_back_nd;
  if prev_m_prvdrnum ne m_prvdrnum then output nhout.mdspost_different_NH_nd;
  else if prev_m_prvdrnum=m_prvdrnum then output nhout.mdspost_same_NH_nd; 
run;


%mend MNODSCHRG;
