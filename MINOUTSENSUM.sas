/**********************************************************************************************************************/
/*  Macro MINOUTSENSUM                                                                                                */
/*  Last updated: 10/21/2018                                                                                          */
/*  Last run:  10/21/2018                                                                                             */                                                                                   
/*  This SAS macro carries out sensitivity analysis and calculates number of patients who fell during their nuring    */
/*  home stay by specifying different cutoffs,i.e., the number of days elapsed since nh discharge to hospital         */
/*  admission for fall                                                                                                */
/**********************************************************************************************************************/
dm 'log;clear;output;clear;';

%macro MINOUTSENSUM;

proc sql noprint;
create table fall_in_out_sensitivity
(
dschrg_admsn_days num 3,
N_fall_in num 8,
N_bene_in num 8,
 );
quit;

%macro MINOUTSEN(daysin);

data claims_fallin(keep=BENE_ID);

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

if m_prvdrnum ne " " then r="M";
else if h_prvdrnum ne " " then r="H";

if r="H" then do;
   if not first.bene_id then do;                    
      if prev_a0310f in("10" "11") then do;               
          if prev_a2100 in("03" "09") then do;       
            d = h_admsndt - prev_a2000;					
             if abs(d) <=&daysin. then output claims_fallin;	 					
         end;
      end;
   end;
end;
run;

proc sql noprint;
   select count(distinct bene_id), count(*) into: patient_fallin, : claims_fallin from claims_fallin; 
quit;	

proc sql;
   insert into fall_in_out_sensitivity
      set dschrg_admsn_days=&daysin.,
          n_fall_in=&claims_fallin.,
		  n_bene_in=&patient_fallin.;
quit;

run;

%mend MINOUTSEN;

%MINOUTSEN(0)
%MINOUTSEN(1)
%MINOUTSEN(2)
%MINOUTSEN(3)
%MINOUTSEN(4)
%MINOUTSEN(5)
%MINOUTSEN(6)
%MINOUTSEN(7)
%MINOUTSEN(8)
%MINOUTSEN(9)
%MINOUTSEN(10)
%MINOUTSEN(11)
%MINOUTSEN(12)
%MINOUTSEN(13)
%MINOUTSEN(14)
%MINOUTSEN(15)
%MINOUTSEN(16)
%MINOUTSEN(17)
%MINOUTSEN(18)
%MINOUTSEN(19)
%MINOUTSEN(20)
%MINOUTSEN(21)
%MINOUTSEN(22)
%MINOUTSEN(23)
%MINOUTSEN(24)
%MINOUTSEN(25)
%MINOUTSEN(26)
%MINOUTSEN(27)
%MINOUTSEN(28)
%MINOUTSEN(29)
%MINOUTSEN(30)

%MINOUTSEN(31)
%MINOUTSEN(32)
%MINOUTSEN(33)
%MINOUTSEN(34)
%MINOUTSEN(35)
%MINOUTSEN(36)
%MINOUTSEN(37)
%MINOUTSEN(38)
%MINOUTSEN(39)
%MINOUTSEN(40)
%MINOUTSEN(41)
%MINOUTSEN(42)
%MINOUTSEN(43)
%MINOUTSEN(44)
%MINOUTSEN(45)
%MINOUTSEN(46)
%MINOUTSEN(47)
%MINOUTSEN(48)
%MINOUTSEN(49)
%MINOUTSEN(50)
%MINOUTSEN(51)
%MINOUTSEN(52)
%MINOUTSEN(53)
%MINOUTSEN(54)
%MINOUTSEN(55)
%MINOUTSEN(56)
%MINOUTSEN(57)
%MINOUTSEN(58)
%MINOUTSEN(59)
%MINOUTSEN(60)


data nhout.fall_in_out_sensitivity;
set fall_in_out_sensitivity;
run;

ods csvall file="S:\Pan\NH\results\paper\final\appendix\fall_in_out_sensitivity.csv";
proc print data=nhout.fall_in_out_sensitivity; run;
ods csvall close;

%mend MINOUTSENSUM;


