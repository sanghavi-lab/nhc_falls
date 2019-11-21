* The code load analysis sample exported from SAS macro MANALYSIS and run mixed effect models
* 1. Run linear mixed effect model stratifying between short- vs long-stay (for main exhibit4)
* 2. Run logit mixed effect model stratifying between short- vs long-stay (for appendix etable5.)
* 3. Run linear mixed effect model stratifying between short- vs long-stay and dual vs. none-dual (for appendix etable4.)

capture log close
clear all
set more off
// 
// local logdir "//prfs.cri.uchicago.edu/sanghavi-lab/Pan/NH/results/paper/final/Exhibit4/stata/log"
local indir "//prfs.cri.uchicago.edu/sanghavi-lab/Pan/NH/datasets/stata/final/linprob"

log using `"`logdir'/Exhibit4.log"', text replace

cd "`indir'"

*load analysis dataset
use exhibit4,clear

*set up factor variables
*race
egen race=group(racename)
label define race 1 "Asian" 2 "Black" 3 "Hispanic" 4 "Other" 5 "White"
label values race race
tab race

*niss_catg
egen niss_cat=group(niss_catg)
label define niss_cat 1 "1-15" 2 "16-24" 3 "25-40" 4 "40-75"
label values niss_cat niss_cat
tab niss_cat

*region
egen area=group(region)
label define area 1 "midwest" 2 "northeast" 3 "south" 4 "west"
label values area area
tab area

*ownership
egen ownership=group(cap_ownership)
label define ownership 1 "For-Profit" 2 "Government" 3 "Non-Profit" 4 "Other"
label values ownership ownership
tab ownership

*provider size
egen size=group(prvdrsize)
label define size 1 "large" 2 "medium" 3 "small"
label values size size
tab size

*set panel variable
encode m_prvdrnum, gen(prvdrnum)
xtset prvdrnum

*create age linear splines
mkspline age1 78 age2 85 age3 90 age4=bsf_age

*drop obs with missing values 
keep if !missing(max_nj1900c,female,age1,age2,age3,age4,niss,niss_cat,combinedscore, ///
                 race,disability,dual_dm, meanbh,fallrate,area,ownership, ///  
				 meandual,size,year,pasian,pblack,phispanic,pother)
				 
*-------*-------*-------*-------*-------*-------*-------*-------*-------*-------*-------*-------*-------;
*Run linear mixed effect regressions for main exhibit 4;
*Shortstay, all variables;
*-------*-------*-------*-------*-------*-------*-------*-------*-------*-------*-------*-------*-------;
				 
*calculate mean J1900C reporting rate for short-stay population
su max_nj1900c if shortstay==1, detail

*run linear mixed effect model on short-stay population
eststo: mixed max_nj1900c female age1 age2 age3 age4 niss ib(first).niss_cat ib(last).race disability dual_dm combinedscore ///
                  fallrate ib3.area ib(first).ownership  meandual ///
				  ib(first).size ib(first).year ///
				  pasian pblack phispanic pother if shortstay==1|| prvdrnum: 

*Calculate between NH race effect
lincom pasian+i1.race
lincom pblack+i2.race
lincom phispanic+i3.race
lincom pother+i4.race

*Predict reporting rate using only fixed effects			  
predict p_j1900c_short_allvar
*calculate fixed effect variance 
su p_j1900c_short_allvar,detail

*calculate within nh variance and bewteen nh variance
mixed p_j1900c_short_allvar if shortstay==1|| prvdrnum: 

*-------*-------*-------*-------*-------*-------*-------*-------*-------*-------*-------*-------*-------;
*Run linear mixed effect regressions for main exhibit 4;
*Short-stay, only NH-level variables;
*-------*-------*-------*-------*-------*-------*-------*-------*-------*-------*-------*-------*-------;

*run linear mixed effect model on short-stay population
eststo: mixed max_nj1900c ib(last).race fallrate ib3.area ib(first).ownership  meandual ///
				  ib(first).size ib(first).year ///
				  pasian pblack phispanic pother if shortstay==1|| prvdrnum:	

*Calculate between NH race effect
lincom pasian+i1.race
lincom pblack+i2.race
lincom phispanic+i3.race
lincom pother+i4.race

*Predict reporting rate using only fixed effects			  
predict p_j1900c_short_nhvar
*calculate fixed effect variance 
su p_j1900c_short_nhvar,detail

*calculate within nh variance and bewteen nh variance
mixed p_j1900c_short_nhvar if shortstay==1|| prvdrnum: 

*-------*-------*-------*-------*-------*-------*-------*-------*-------*-------*-------*-------*-------;
*Run linear mixed effect regressions for main exhibit 4;
*Long-stay, all variables;
*-------*-------*-------*-------*-------*-------*-------*-------*-------*-------*-------*-------*-------;

*calculate mean J1900C reporting rate for long-stay population
su max_nj1900c if shortstay==0, detail

*run linear mixed effect model on long-stay population
eststo: mixed max_nj1900c female age1 age2 age3 age4 niss ib(first).niss_cat ib(last)i.race disability dual_dm combinedscore ///
                  fallrate ib3.area ib(first).ownership  meandual ///
				  ib(first).size ib(first).year ///
				  pasian pblack phispanic pother if shortstay==0|| prvdrnum:

*Calculate between nh race effect				  
lincom pasian+i1.race
lincom pblack+i2.race
lincom phispanic+i3.race
lincom pother+i4.race

*Predict reporting rate using only fixed effects	
predict p_j1900c_long_allvar
*calculate fixed effect variance 
su p_j1900c_long_allvar, detail

*calculate within nh variance and bewteen nh variance
mixed p_j1900c_long_allvar if shortstay==0|| prvdrnum: 

*-------*-------*-------*-------*-------*-------*-------*-------*-------*-------*-------*-------*-------;
*Run linear mixed effect regressions for main exhibit 4;
*Long-stay, only NH-level variables;
*-------*-------*-------*-------*-------*-------*-------*-------*-------*-------*-------*-------*-------;

*run linear mixed effect model on long-stay population
eststo: mixed max_nj1900c ib(last)i.race fallrate ib3.area ib(first).ownership  meandual ///
				  ib(first).size ib(first).year ///
				  pasian pblack phispanic pother if shortstay==0|| prvdrnum:

*Calculate between nh race effect				  
lincom pasian+i1.race
lincom pblack+i2.race
lincom phispanic+i3.race
lincom pother+i4.race

*Predict reporting rate using only fixed effects	
predict p_j1900c_long_nhvar	
*calculate fixed effect variance 
su p_j1900c_long_nhvar, detail

*calculate within nh variance and bewteen nh variance
mixed p_j1900c_long_nhvar if shortstay==0|| prvdrnum: 
  
*-------*-------*-------*-------*-------*-------*-------*-------*-------*-------*-------*-------*-------;
*Run logit mixed effect regressions for appendix;
*-------*-------*-------*-------*-------*-------*-------*-------*-------*-------*-------*-------*-------;

*run logit mixed effect model on short-stay population
melogit max_nj1900c i.female age1 age2 age3 age4 niss ib(first).niss_cat ib(last).race i.disability dual_dm combinedscore ///
                  fallrate ib3.area ib(first).ownership  meandual ///
				  ib(first).size ib(first).year ///
				  pasian pblack phispanic pother if shortstay==1|| prvdrnum:
				 
*Calculate between nh race effect
lincom pasian+i1.race
lincom pblack+i2.race
lincom phispanic+i3.race
lincom pother+i4.race

*predict marginal effect and check against linear model
margins r.female r.ib1.niss_cat r.disability r.ib5.race r.ib3.area r.ib1.ownership ///
        r.ib1.size
margins, dydx(niss)
margins, dydx(combinedscore)
margins, at(dual_dm=(-1(1)1))
margins, at(year=(2011(1)2015))
margins, at(fallrate100=(1(1)4))
*margins, at(fallrate100=(1(1)10))
margins, at(meandual=(0 1))
//
// margins, at(age1=(26(1)78))
// margins, at(age2=(0(1)7))
// margins, at(age3=(0(1)5))
// margins, at(age4=(0(1)19))
// 
margins, at(age1=(74 75))
margins, at(age2=(5 6))
margins, at(age3=(4 5))
margins, at(age4=(10 11))
margins, at(pasian=(0 1))
margins, at(pblack=(0 1))
margins, at(phispanic=(0 1))
margins, at(pother=(0 1))

*------------------------------------------------------------------------------------------------------------;
*run logit mixed effect model on long-stay population
melogit max_nj1900c i.female age1 age2 age3 age4 niss ib(first).niss_cat ib(last).race i.disability dual_dm combinedscore ///
                  fallrate ib3.area ib(first).ownership  meandual ///
				  ib(first).size ib(first).year ///
				  pasian pblack phispanic pother if shortstay==0|| prvdrnum:
				  
*Calculate between NH race effect
lincom pasian+i1.race
lincom pblack+i2.race
lincom phispanic+i3.race
lincom pother+i4.race

*predict marginal effect: marginal effect gives coefficient values equivalent to the coefficients in linear mixed effect models			   
margins r.female r.ib1.niss_cat r.disability r.ib5.race r.ib3.area r.ib1.ownership ///
        r.ib1.size
margins, dydx(niss)
margins, dydx(combinedscore)
margins, at(dual_dm=(-1(1)1))
margins, at(year=(2011(1)2015))
*margins, at(fallrate100=(1(1)10))
margins, at(fallrate100=(1(1)4))
margins, at(meandual=(0 1))
// 
// margins, at(age1=(23(1)78))
// margins, at(age2=(0(1)7))
// margins, at(age3=(0(1)5))
// margins, at(age4=(0(1)21))
// 
margins, at(age1=(74 75))
margins, at(age2=(5 6))
margins, at(age3=(4 5))
margins, at(age4=(10 11))
margins, at(pasian=(0 1))
margins, at(pblack=(0 1))
margins, at(phispanic=(0 1))
margins, at(pother=(0 1))
*-------*-------*-------*-------*-------*-------*-------*-------*-------*-------*-------*-------*-------;
*Run linear mixed effect regressions stratifying between short- versus long-stay
*and dual versus none-dual for appendix;
*-------*-------*-------*-------*-------*-------*-------*-------*-------*-------*-------*-------*-------;

*calculate mean J1900C reporting rate for short-stay dual population
su max_nj1900c if shortstay==1 & dual==1, detail

*run linear mixed effect model on short-stay dual population
mixed max_nj1900c female age1 age2 age3 age4 niss ib(first).niss_cat ib(last).race disability combinedscore ///
                  fallrate100 ib3.area ib(first).ownership  ///
				  ib(first).size ib(first).year ///
				  pasian pblack phispanic pother if shortstay==1 & dual==1|| prvdrnum: 
				  
*Calculate between NH race effect
lincom pasian+i1.race
lincom pblack+i2.race
lincom phispanic+i3.race
lincom pother+i4.race

*Predict reporting rate using only fixed effects			  
predict p_j1900c_short_dual
*calculate fixed effect variance 
su p_j1900c_short_dual,detail

*calculate within nh variance and bewteen nh variance
mixed p_j1900c_short_dual if shortstay==1 & dual==1|| prvdrnum: 
*------------------------------------------------------------------------------------------------------------;
*calculate mean J1900C reporting rate for short-stay non-edual population
su max_nj1900c if shortstay==1 & dual==0, detail

*run linear mixed effect model on short-stay none-dual population
mixed max_nj1900c female age1 age2 age3 age4 niss ib(first).niss_cat ib(last).race disability combinedscore ///
                  fallrate100 ib3.area ib(first).ownership  ///
				  ib(first).size ib(first).year ///
				  pasian pblack phispanic pother if shortstay==1 & dual==0|| prvdrnum: 
				  
*Calculate between NH race effect
lincom pasian+i1.race
lincom pblack+i2.race
lincom phispanic+i3.race
lincom pother+i4.race

*Predict reporting rate using only fixed effects			  
predict p_j1900c_short_nondual
*calculate fixed effect variance 
su p_j1900c_short_nondual,detail

*calculate within nh variance and bewteen nh variance
mixed p_j1900c_short_nondual if shortstay==1 & dual==0|| prvdrnum: 

*------------------------------------------------------------------------------------------------------------;
*calculate mean J1900C reporting rate for long-stay dual population
su max_nj1900c if shortstay==0 & dual==1, detail

*run linear mixed effect model on long-stay dual population
mixed max_nj1900c female age1 age2 age3 age4 niss ib(first).niss_cat ib(last)i.race disability combinedscore ///
                  fallrate100 ib3.area ib(first).ownership  ///
				  ib(first).size ib(first).year ///
				  pasian pblack phispanic pother if shortstay==0 & dual==1|| prvdrnum: ///
		  
*Calculate between NH race effect				  
lincom pasian+i1.race
lincom pblack+i2.race
lincom phispanic+i3.race
lincom pother+i4.race

*Predict reporting rate using only fixed effects	
predict p_j1900c_long_dual
*calculate fixed effect variance 
su p_j1900c_long_dual, detail

*calculate within nh variance and bewteen nh variance
mixed p_j1900c_long_dual if shortstay==0 & dual==1|| prvdrnum: 

 *------------------------------------------------------------------------------------------------------------;
*calculate mean J1900C reporting rate for long-stay none-dual population
su max_nj1900c if shortstay==0 & dual==0, detail

*run linear mixed effect on long-stay none-dual population
mixed max_nj1900c female age1 age2 age3 age4 niss ib(first).niss_cat ib(last)i.race disability combinedscore ///
                  fallrate100 ib3.area ib(first).ownership ///
				  ib(first).size ib(first).year ///
				  pasian pblack phispanic pother if shortstay==0 & dual==0|| prvdrnum: ///

				  
*Calculate between NH race effect				  
lincom pasian+i1.race
lincom pblack+i2.race
lincom phispanic+i3.race
lincom pother+i4.race

*Predict reporting rate using only fixed effects	
predict p_j1900c_long_nonedual
*calculate fixed effect variance 
su p_j1900c_long_nonedual, detail

*calculate within nh variance and bewteen nh variance
mixed p_j1900c_long_nonedual if shortstay==0 & dual==0|| prvdrnum: 

log close
