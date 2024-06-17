

clear all
set varabbrev off 
set more off
**//replace your own file path
cd "D:\xxxx" 
. pwd
*-----------------------------------------------------------------------
*                         Define file locations
*-----------------------------------------------------------------------

*** define input folders ***
global CFPS_Data 		"Rawdata/CGSS CFPS/CFPS data"
global Elite_Data		"Rawdata/Suppress"


*-----------------------------------------------------------------------
*** define output folders ***
global Rawdata 			"Rawdata"
global Interimdata 		"Interimdata"
global Finaldata		"Finaldata"
global Code 			"Code"
global Mergeusing       "$Rawdata/Merge using"

global Temp 			"Temp"
global Result			"Result"
global Figure 			"$result/Figure"
global Table 			"$result/Table"


cap mkdir "$Interimdata/CGSS"

*-----------------------------------------------------------------------
*** define files locations ***

* Cleaned CGSS Data 
global CGSS_Elite_2010          "$Interimdata/CGSS/CGSS_Elite_2010"
global CFPS_Elite_2010          "$Interimdata/CFPS/CFPS_Elite_2010"

*-----------------------------------------------------------------------
*** define files locations ***
* Wave 2010 file
global wave_2010_adult			"$CFPS_Data/CFPS_2010/cfps2010adult_202008"



* Wave 2012 file 
global wave_2012_adult          "$CFPS_Data/CFPS_2012/cfps2012adult_201906"


* Wave 2014 file 
global wave_2014_adult          "$CFPS_Data/CFPS_2014/cfps2014adult_201906"


* Wave 2016 file 
global wave_2016_adult          "$CFPS_Data/CFPS_2016/cfps2016adult_201906"


* Wave 2018 file 
global wave_2018_adult          "$CFPS_Data/CFPS_2018/cfps2018person_202012"


* Local Elite Data 
global elite_excel      	    "$Elite_Data/Suppress Movement.xlsx"
//Chinese version


*-----------------------------------------------------------------------
*                              Program Setting 
*-----------------------------------------------------------------------
*** Define program to add suffix year *** 
cap prog drop addwaveyear
prog define addwaveyear
	syntax, [Add(string)][Except(string)]
	if "`add'" == ""{
		display as error "index year not found"
		exit 111
	} 
	foreach var of varlist _all{
		ren `var' `var'_`add'
	}
	foreach var in `except'{
		ren `var'_`add' `var'
	}
end


*-----------------------------------------------------------------------
*                            Clean Elite Data 
*-----------------------------------------------------------------------
* Local Elite Data 
clear
import excel "$elite_excel", firstrow
drop X
global varlist ///
	x1 x2 x3 x4 x5 x6 x7 x8 x9 ///
	
foreach var in $varlist {
 destring `var', replace i("yuren" "duoren") force
 replace `var'=. if `var'==-99
} 



* Only keep the earlest (1st round) 
duplicates drop countyid, force

* City ID
cap drop cityid
gen cityid=floor(countyid/100)

replace cityid=1100 if cityid==1101 
replace cityid=1200 if cityid==1201 
replace cityid=3100 if cityid==3101 
replace cityid=5000 if cityid==5001 

* Calculate the key meausre: ratio of killing
gen kratio = x1/x3
replace kratio = 1/kratio if kratio>1 & kratio<. // misclassified obs
gen kratio_i = kratio
gen kratio_1 = kratio 
gen kratio_2 = kratio
order provid prov county cityid countyid kratio*


* Impute missing with the nearest county in the local city: kratio_i
sort countyid
forvalues i = 1/25{
	bys cityid (countyid): replace kratio_1 = kratio[_n-`i'] if mi(kratio_1) 
	bys cityid (countyid): replace kratio_2 = kratio[_n+`i'] if mi(kratio_2)
}
egen kr_rm = rowmean(kratio_1 kratio_2)
replace kratio_i = kr_rm 


* Impute missing with the nearest county in the local city/province: kratio_i2

sort countyid
forvalues i = 1/200{
	bys provid (countyid): replace kratio_1 = kratio[_n-`i'] if mi(kratio_i) & mi(kratio_1)
	bys provid (countyid): replace kratio_2 = kratio[_n+`i'] if mi(kratio_i) & mi(kratio_2)
}
egen kr_rm2 = rowmean(kratio_1 kratio_2) if mi(kr_rm)
replace kr_rm2= kr_rm if !mi(kr_rm)

gen kratio_i2 = kr_rm2 

order prov county provid cityid countyid kratio*


drop if countyid==.
rename countyid countyid_c

rename prov province
replace province = substr(province, 1, 6)

rename cityid cityid_c 
rename provid provid_c

save "$Interimdata/elite_data", replace
	
*-----------------------------------------------------------------------
*                            Clean CFPS Data 
*-----------------------------------------------------------------------
* clean countyid 
import excel "$CFPS_Data/CFPS correspondence table.xls", clear first
rename (C D E) (province city county)
rename code countyid_c
gen cityid_c=floor(countyid_c/100)
gen provid_c=floor(countyid_c/10000)
order provid_c cityid_c countyid_c countyid
save "$Interimdata/CFPS/CFPS_county_code", replace

* merge with elite data 
merge 1:m countyid_c using "$data/elite_data", update

* Impute missing with the nearest county in the local city: kratio_i
sort countyid
forvalues i = 1/25{
	bys cityid_c (countyid_c): replace kratio_1 = kratio[_n-`i'] if mi(kratio_1) & _merge==1
	bys cityid_c (countyid_c): replace kratio_2 = kratio[_n+`i'] if mi(kratio_2) & _merge==1
}
egen kr_rm3 = rowmean(kratio_1 kratio_2) if _merge==1
replace kratio_i = kr_rm3 if _merge==1

* Impute missing with the nearest county in the local city/province: kratio_i2

sort countyid
forvalues i = 1/200{
	bys provid_c (countyid_c): replace kratio_1 = kratio[_n-`i'] if mi(kratio_i) & mi(kratio_1) & _merge==1
	bys provid_c (countyid_c): replace kratio_2 = kratio[_n+`i'] if mi(kratio_i) & mi(kratio_2) & _merge==1
}
egen kr_rm4 = rowmean(kratio_1 kratio_2) if mi(kr_rm3) & _merge==1 
replace kr_rm4= kr_rm3 if !mi(kr_rm3) & _merge==1

replace kratio_i2 = kr_rm4 if _merge==1

drop kratio_1 kratio_2 kr_rm3 kr_rm4

drop if _merge==2

save "$Interimdata/CFPS/CFPS_elite_county", replace



*-----------------------------------------------------------------------
*** 2010 adult data ***
tempfile w2010_adult
use "$wave_2010_adult", clear

* local define variable lists 
local background /// Background Information
	  gender urban provcd qa1age qa1y qa1m qa1y_best qa2 qe1 qe1_best

local birth /// Birth Place and Residence History
	  qa102acode qa102c_code qa3 qa301acode qa301c_code qa302 qa4 ///
	  qa401acode qa401c_code qa402
	  
local education /// Education
	  cfps2010edu_best cfps2010eduy_best cfps2010sch_best

local health /// Health 
	  kt404_a_1 kt404_a_2 ql101_a_3 qp8 qp801 qq2 qq202 qq211 qq3 ///
	  qq302_s_1 qq302_s_2 qq302_s_3 qq311 kt101_a_1 kt101_a_2
	  
local cognition /// Cognition 
	  mathtest wordtest

local other /// Other
	  qp3 income feduc meduc sedu seduc seduy sedul
	  
local social_class /// attitudes toward equality & social class
	  qm701 qm702 qm703 qm704 qm705 qm707 /// no qm706
	  qn501 qn502 qn503 qn504 qn505 qn506 qn507 
	  
local political /// political participation
	  qa6 qa7* qa701 
	  
	  
local governance /// attitudes toward government and law
	  qn201 qn202 qn203 qn204 qn205 qn206 qn207 qn208 qn4 
 
 
local social_identity /// social identity, attitudes and statisfaction
	  qk801 qk802 qk803 qk804 ///
	  qm401 qm402 qm403 qm404 ///
	  qm501 qm502 qm503 qm504 qm505 qm506 qm507 qm508 qm509 qm510 qm6 
	  

	  
* Keep selected variables
keep pid countyid ///
     `background' `birth' `education' `health' `cognition' `other' ///
	 `social_class' `political' `governance' `social_identity'

order pid countyid ///
     `background' `birth' `education' `health' `cognition' `other' ///
	 `social_class' `political' `governance' `social_identity'	
	 
merge m:1 countyid using "$Interimdata/CFPS/CFPS_elite_county", ///
	keepusing(provid_c cityid_c countyid_c countyid ///
	          province city county kratio kratio_i kratio_i2)

order pid provid_c cityid_c countyid_c countyid ///
	      province city county kratio kratio_i kratio_i2

addwaveyear, add(2010) except(pid)

drop if pid == .
drop _merge*

save "`w2010_adult'"
global w2010_adult `w2010_adult'
clear



*-----------------------------------------------------------------------
*** 2012 adult data ***
tempfile w2012_adult
use "$wave_2012_adult"

* local define variable lists 
local background /// Background Information
	  cfps2012_gender_best urban12 provcd cfps2012_age qa301 /// 
	  qe104 cfps2012_birthy_best
	  
local birth /// Birth Place and Residence History

local education /// Education
	  sch2012 edu2012 eduy2012 cfps2011_latest_edu ///
	  cfps2011_latest_edudatey cfps2011_latest_edudatem

local health /// Health 
	  qp701 qq201 qq202 qq203 qq204 qq301 qq302_s_1 qq302_s_2 /// 
	  qq302_s_3 qq305 qp302 qq6015 
	  
local cognition /// Cognition 
	  iwr1 iwr2 iwr dwr ns_g ns_w ns_wse

local other /// Other
	  qp201 qp202 income


	  
local political /// political participation
	  qn401* qn402
	  
	  
local governance /// attitudes toward government and law
	  qn1011 qn1012 qn1013 qn1014 qn1015 qn1016 qn1017 ///
	  qn6011 qn6012 qn6013 qn6014 qn6015 qn6016 qn6017 qn6018 ///
	  qn1101 
	  
local trust /// social trsut 	  
	  qn1001 qn10021 qn10022 qn10023 qn10024 qn10025 qn10026 
 
 
local social_identity /// social identity, attitudes and statisfaction
	  qn8011 qn8012 qn12011 qn12012 qn12013 qn12014 
	  
local religion /// religious belief
	  qm601 qm602 qm603 
	  
	  	  
	  
	  
* Keep selected variables
keep pid countyid ///
     `background' `birth' `education' `health' `cognition' `other' ///
	 `political' `governance' `trust' `social_identity' `religion'

order pid countyid ///
     `background' `birth' `education' `health' `cognition' `other' ///
	 `political' `governance' `trust' `social_identity' `religion'
	  

merge m:1 countyid using "$Interimdata/CFPS/CFPS_elite_county", ///
	keepusing(provid_c cityid_c countyid_c countyid ///
	          province city county kratio kratio_i kratio_i2)

order pid provid_c cityid_c countyid_c countyid ///
	      province city county kratio kratio_i kratio_i2
		  
addwaveyear, add(2012) except(pid)

drop if pid == .
drop _merge*

save "`w2012_adult'"
global w2012_adult `w2012_adult'
clear


*-----------------------------------------------------------------------
*** 2014 adult data ***
tempfile w2014_adult
use "$wave_2014_adult"

* local define variable lists 
local background /// Background Information
	  cfps_gender urban14 provcd14 cfps2014_age cfps_birthy qa301 qea0 
	  
local birth /// Birth Place and Residence History
      qa401 qa401ccode qa501 qa502 qa502ccode qa601 qa602 qa602ccode
	  
local education /// Education
	  cfps2014sch cfps2014edu cfps2014eduy cfps2014eduy_im

local health /// Health 
	  qp701 qp702 qq301 qq201 qq202 qq204 qq4010 qq4011 qq4012 ///
	  qq501 qp302 qn10026
	  
local cognition /// Cognition 
	  mathtest14_sc2 mathtest14 whichmathlist ///
	  wordtest14_sc2 wordtest14 whichwordlist

local other /// Other
	  qp201 p_income

	  
local social_class /// attitudes toward equality & social class
	  qm3011 qm3012 qm3013 qm3014 qm3015 qm3016 qm3017 
	  
local political /// political participation
	  qn401* qn402 qn201 qn202 qn203 

local democracy /// democracy/election
	  qn7 qn701 qn702

	  
local governance /// attitudes toward government and law
	  qn1011 qn1012 qn1013 qn1014 qn1015 qn1016 qn1017 ///
	  qn6011 qn6012 qn6013 qn6014 qn6015 qn6016 qn6017 qn6018 ///
	  qn1101 qn102* 	  
	  *qn12 qn16 qn1701 qn1702 qn1703 qn1704 qn1705 ///
	  *qn1801 qn1802 qn1803 qn1804 qn1901 qn1902 qn1903 ///
	  *qn20 qn2001 qn2002 qn2003 qn211 qn212 qn213 qn221 qn222
 
local trust /// trust 
	  qn1001 qn10021 qn10022 qn10023 qn10024 qn10025 qn10026 
 
local social_identity /// social identity, attitudes and statisfaction
	  qn8011 qn8012 qn12011 qn12012 qn12013 qn12014 ///
	  qm2011 qm2012 qm2013 
	  
local religion /// religious belief
	  qm601a* qm602a qm602b qm603  	  

rename countyid14 countyid 
	  
* Keep selected variables
keep pid countyid ///
     `background' `birth' `education' `health' `cognition' `other' ///
	 `social_class' `political' `democracy' ///
	 `governance' `trust' `social_identity' `religion'

order pid countyid ///
     `background' `birth' `education' `health' `cognition' `other' ///
	 `social_class' `political' `democracy' ///
	 `governance' `trust' `social_identity' `religion'	 

merge m:1 countyid using "$Interimdata/CFPS/CFPS_elite_county", ///
	keepusing(provid_c cityid_c countyid_c countyid ///
	          province city county kratio kratio_i kratio_i2)

order pid provid_c cityid_c countyid_c countyid ///
	      province city county kratio kratio_i kratio_i2	 
	 
addwaveyear, add(2014) except(pid)

drop if pid == .
drop _merge*

save "`w2014_adult'"
global w2014_adult `w2014_adult'
clear


*-----------------------------------------------------------------------
*** 2016 adult data ***
tempfile w2016_adult
use "$wave_2016_adult"

* local define variable lists 
local background /// Background Information
	  cfps_gender urban16 provcd16 cfps_birthy pa301 qea0  
	  
local birth /// Birth Place and Residence History
	  
local education /// Education
	  cfps2016sch cfps2016edu cfps2016eduy cfps2016eduy_im

local health /// Health 
	  qp701 qp702 qq201 qq202 qq204 qq301 qq4010 qq4011 qq4012
	  
local cognition /// Cognition 
	  dwr iwr iwr1 iwr2 ns_g ns_w ns_wse

local other /// Other
	  qp201 income

	  

local political /// political participation
	  qn402 qn201 qn202 qn203 ///
	  qn4001 qn4002 qn4003 qn4004 qn4005 

	  
local governance /// attitudes toward government and law
	  qn1011 qn1012 qn1013 qn1014 qn1015 qn1016 qn1017 ///
	  qn6011 qn6012 qn6013 qn6014 qn6015 qn6016 qn6017 qn6018 ///
	  qn1101
	  
 
local trust /// trust 
	  pn1001 qn10021 qn10022 qn10023 qn10024 qn10025 qn10026 

local environemnt ///
	  ce1 ce2 ce3 ce4 ce5 ce6
	  
local social_identity /// social identity, attitudes and statisfaction
	  pm101m pm102m pm103m pm104m pm105m pm106m pm107m pm108m pm110m /// no pm109m 
	  qm2011 qm2014 ///
	  qn8011 qn8012 qn12012 qn12014 
	  
local religion /// religious belief
	  qm601* qm602a qm602b qm603 qn4004 		  

rename countyid16 countyid 	  
* Keep selected variables
keep pid countyid ///
     `background' `birth' `education' `health' `cognition' `other' ///
     `political' `governance' `trust' `environemnt' `social_identity' `religion'	  

order pid countyid ///
     `background' `birth' `education' `health' `cognition' `other' ///
     `political' `governance' `trust' `environemnt' `social_identity' `religion'	

merge m:1 countyid using "$Interimdata/CFPS/CFPS_elite_county", ///
	keepusing(provid_c cityid_c countyid_c countyid ///
	          province city county kratio kratio_i kratio_i2)

order pid provid_c cityid_c countyid_c countyid ///
	      province city county kratio kratio_i kratio_i2
		  
addwaveyear, add(2016) except(pid)

drop if pid == .
drop _merge*

save "`w2016_adult'"
global w2016_adult `w2016_adult'
clear


*-----------------------------------------------------------------------
*** 2018 adult data ***
tempfile w2018_adult
use "$wave_2018_adult"

* local define variable lists 
local background /// Background Information
	  gender_update urban18 provcd18 age ibirthy_update qa301 qea0   
	  
local birth /// Birth Place and Residence History
	  qa401 qa401a_code qa601 qa602 qa602a_code qa603
	  
local education /// Education
	  cfps2018sch edu_updated cfps2018edu cfps2018eduy

local health /// Health 
	  qp701 qp702 smokeage qq201 qq202 qq204 qq2011 qq301 qq4010 qq4011 ///
	  qq4012 qq501 qn10026
	  
local cognition /// Cognition 
	  mathtest18 mathtest18_sc2 mathlist whichmathlist ///
	  wordtest18 wordtest18_sc2 wordlist whichwordlist

local other /// Other
	  qp201 income

	  
local social_class /// attitudes toward equality & social class
	  wv102 wv103 wv104 wv105 wv106 wv107 wv108 wv101 

	  
local political /// political participation
	  qn402 qn201_b_1 qn202 qn203 ///
	  qn4001 qn4002 qn4003 qn4004 qn4005


local governance /// attitudes toward government and law
	  qn6011 qn6012 qn6013 qn6014 qn6015 qn6016 qn6017 qn6018 ///
	  qn1101 
 
local trust /// trust 
	  qn1001 qn10021 qn10022 qn10023 qn10024 qn10025 qn10026 
 
local social_identity /// social identity, attitudes and statisfaction
	  qm101m qm102m qm103m qm104m qm105m qm106m qm107m qm108m qm109m qm110m ///
	  qm2011 qm2016 qn8011 qn8012 qn12012 qn12016 ///
	  qph1 qph2 qph3 // denate
	  
local religion /// religious belief
	  qn4004 qm6010 qm6011 qm6012 qm6013 qm6014 qm6015 qm6016 qm6017 
	  
rename countyid18 countyid	  
	  
* Keep selected variables
keep pid countyid ///
     `background' `birth' `education' `health' `cognition' `other' ///
	 `social_class' `political' `governance' `trust' `social_identity' `religion'
	 
	 
order pid countyid ///
     `background' `birth' `education' `health' `cognition' `other' ///
	 `social_class' `political' `governance' `trust' `social_identity' `religion'
	
merge m:1 countyid using "$Interimdata/CFPS/CFPS_elite_county", ///
	keepusing(provid_c cityid_c countyid_c countyid ///
	          province city county kratio kratio_i kratio_i2)

order pid provid_c cityid_c countyid_c countyid ///
	      province city county kratio kratio_i kratio_i2	
	
addwaveyear, add(2018) except(pid)

drop if pid == .
drop _merge*

save "`w2018_adult'"
global w2018_adult `w2018_adult'
clear



*-----------------------------------------------------------------------
*                              Merge Data 
*-----------------------------------------------------------------------
***load CFPS 2010 adult dataset ***
use "$w2010_adult"

***In wave 2010
gen inw2010=1
label variable inw2010 "inw2010: In wave 2010" 
label values inw2010 yesno


*-----------------------------------------------------------------------
***load CFPS 2012 adult dataset ***

merge 1:1 pid using "$w2012_adult" 

***In wave 2014
gen inw2012 = 0
replace inw2012 = 1 if inlist(_merge,2,3)
label variable inw2012 "inw2012:In wave 2012" 
label values inw2012 yesno
drop _merge


*-----------------------------------------------------------------------
***load CFPS 2014 adult dataset ***

merge 1:1 pid using "$w2014_adult" 

***In wave 2014
gen inw2014 = 0
replace inw2014 = 1 if inlist(_merge,2,3)
label variable inw2014 "inw2014:In wave 2014" 
label values inw2014 yesno
drop _merge

*-----------------------------------------------------------------------
***load CFPS 2016 adult dataset ***

merge 1:1 pid using "$w2016_adult" 

***In wave 2016
gen inw2016 = 0
replace inw2016 = 1 if inlist(_merge,2,3)
label variable inw2016 "inw2016:In wave 2016" 
label values inw2016 yesno
drop _merge

*-----------------------------------------------------------------------
***load CFPS 2018 adult dataset ***

merge 1:1 pid using "$w2018_adult" 

***In wave 2018
gen inw2018 = 0
replace inw2018 = 1 if inlist(_merge,2,3)
label variable inw2018 "inw2018:In wave 2018" 
label values inw2018 yesno
drop _merge

/*
gen in3wave=0 
replace in3wave=1 if inw2010==1 & inw2014==1 & inw2018==1
label variable in3wave "In wave 2010, 2014 and 2018" 
label values in3wave yesno
*/


*-----------------------------------------------------------------------
*** Update inwave indicators *** 
* in Wave 2010 (update)
replace inw2010 = 0 if inw2010 ==.
tab inw2010

* in Wave 2012 (update)
replace inw2012 = 0 if inw2012 ==.
tab inw2012

* in Wave 2014 (update)
replace inw2014 = 0 if inw2014 ==.
tab inw2014

* in Wave 2016 (update)
replace inw2016 = 0 if inw2016 ==.
tab inw2016

* in Wave 2018 (update)
replace inw2018 = 0 if inw2018 ==.
tab inw2018



save "$Interimdata/CFPS/CFPS_Elite_Data", replace
global CFPS_Elite_Data        "$InterimdataCFPS/CFPS_Elite_Data"

* Show the value labels
numlabel , add




*-----------------------------------------------------------------------
*                               Covariates
*-----------------------------------------------------------------------

** 1. Birthyear and Age **
gen rabyear=cond(inw2010==1, qa1y_best_2010, ///
			cond(inw2012==1, cfps2012_birthy_best_2012, ///
			cond(inw2014==1, cfps_birthy_2014, ///
			cond(inw2016==1, cfps_birthy_2016, ///
			cond(inw2018==1, ibirthy_update_2018, .)))))
replace rabyear=. if rabyear<=1000
label variable rabyear "Birth year" 


gen Age_2010=2010-rabyear if rabyear<=2010
gen Age_2012=2010-rabyear if rabyear<=2012
gen Age_2014=2014-rabyear if rabyear<=2014
gen Age_2016=2016-rabyear if rabyear<=2016
gen Age_2018=2018-rabyear if rabyear<=2018

forvalues i = 2010(2)2018{
	label variable Age_`i' "Age in years: `i'"
}

*-----------------------------------------------------------------------
** 2. Gender **

gen ragender=cond(inw2010==1, gender_2010, ///
			 cond(inw2012==1, cfps2012_gender_best_2012, ///
			 cond(inw2014==1, cfps_gender_2014, ///
			 cond(inw2016==1, cfps_gender_2016, ///
			 cond(inw2018==1, gender_update_2018, .)))))
label variable ragender "Gender" 
label define ragenderlbl 0 "0. Female"  1 "1. Male" 
label values ragender ragenderlbl  


*-----------------------------------------------------------------------
** 3. Urban/Rural Hukou ** 
gen Hukou_2010=. 
replace Hukou_2010=0 if qa2_2010==1
replace Hukou_2010=1 if qa2_2010==3 


gen Hukou_2012=. 
replace Hukou_2012=0 if qa301_2012==1
replace Hukou_2012=1 if qa301_2012==3

gen Hukou_2014=. 
replace Hukou_2014=0 if qa301_2014==1
replace Hukou_2014=1 if qa301_2014==3


gen Hukou_2016=. 
replace Hukou_2016=0 if pa301_2016==1
replace Hukou_2016=1 if pa301_2016==3


gen Hukou_2018=. 
replace Hukou_2018=0 if qa301_2018==1
replace Hukou_2018=1 if qa301_2018==3

forvalues i = 2010(2)2018{
	label variable Hukou_`i' "Hukou status: 2018"
	label define Hukou_`i'lbl 0 "0. Agricultural"  1 "1. Non-agricultural" 
	label values Hukou_`i' Hukou_`i'lbl
}

*-----------------------------------------------------------------------
** 4. Marrital Status **
gen mstat_2010=cond(qe1_best_2010==2, 1, ///
			   cond(qe1_best_2010>0 & qe1_best_2010!=., 0, .))


gen mstat_2012=cond(qe104_2012==2, 1, ///
			   cond(qe104_2012>0 & qe104_2012!=., 0, .))
 

gen mstat_2014=cond(qea0_2014==2, 1, ///
			   cond(qea0_2014>0 & qea0_2014!=., 0, .))

			   
gen mstat_2016=cond(qea0_2016==2, 1, ///
			   cond(qea0_2016>0 & qea0_2016!=., 0, .))			   
			   

gen mstat_2018=cond(qea0_2018==2, 1, ///
			   cond(qea0_2018>0 & qea0_2018!=., 0, .))


forvalues i = 2010(2)2018{
	label variable mstat_`i' "Marrital status: 2018" 
	label define mstat_`i'lbl 0 "0. Not married"  1 "1. Married" 
	label values mstat_`i' mstat_`i'lbl
}
*-----------------------------------------------------------------------
** 5. Income **
rename p_income_2014 income_2014
gen log_income_2010=log(income_2010+1)
gen log_income_2012=log(income_2012+1)
gen log_income_2014=log(income_2014+1)
gen log_income_2016=log(income_2016+1)
gen log_income_2018=log(income_2018+1)

forvalues i = 2010(2)2018{
	label variable log_income_`i' "Log income: `i'"
	replace  log_income_`i'=. if income_`i'<0
}


*-----------------------------------------------------------------------
** 6. Self-rated health ** 
** Note: 2010 health status is in different scale with 2014 and 2018 ** 
clonevar selfhealth_2010=qp3_2010 
replace selfhealth_2010=. if qp3_2010<=0

clonevar selfhealth_2012=qp201_2012 
replace selfhealth_2012=. if qp201_2012<=0

clonevar selfhealth_2014=qp201_2014 
replace selfhealth_2014=. if qp201_2014<=0

clonevar selfhealth_2016=qp201_2016
replace selfhealth_2016=. if qp201_2016<=0

clonevar selfhealth_2018=qp201_2018 
replace selfhealth_2018=. if qp201_2018<=0

forvalues i = 2010(4)2018{
	label variable selfhealth_`i' "Self-rated health: `i'"
}




*-----------------------------------------------------------------------
*                                Education
*-----------------------------------------------------------------------

* The latest educational attainment reported (in years)
clonevar edu_c_2018=cfps2018eduy_2018
clonevar edu_c_2016=cfps2016eduy_2016
clonevar edu_c_2014=cfps2014eduy_2014
clonevar edu_c_2012=eduy2012_2012
clonevar edu_c_2010=cfps2010eduy_best_2010

gen edu_c=cond(edu_c_2018>=0 & edu_c_2018!=., edu_c_2018, ///
		  cond(edu_c_2016>=0 & edu_c_2016!=., edu_c_2016, ///
		  cond(edu_c_2014>=0 & edu_c_2014!=., edu_c_2014, ///
		  cond(edu_c_2012>=0 & edu_c_2012!=., edu_c_2012, ///
		  cond(edu_c_2010>=0 & edu_c_2010!=., edu_c_2010, .)))))
label variable edu_c "Edu in yrs: the lastest wave"
		  
forvalues i = 2010(2)2018{
	label variable edu_c_`i' "Edu in yrs: `i'"
}

		  
*-----------------------------------------------------------------------		  
* The latest educational attainment reported (in levels)
clonevar edu_l_2018=cfps2018edu_2018
clonevar edu_l_2016=cfps2016edu_2016
clonevar edu_l_2014=cfps2014edu_2014
clonevar edu_l_2012=edu2012_2012
clonevar edu_l_2010=cfps2010edu_best_2010

gen edu_l=cond(edu_l_2018>=0 & edu_l_2018!=., edu_l_2018, ///
		  cond(edu_l_2016>=0 & edu_l_2016!=., edu_l_2016, ///
		  cond(edu_l_2014>=0 & edu_l_2014!=., edu_l_2014, ///
		  cond(edu_l_2012>=0 & edu_l_2012!=., edu_l_2012, ///
		  cond(edu_l_2010>=0 & edu_l_2010!=., edu_l_2010, .)))))
		  
label variable edu_l "Edu in levels: the lastest wave"
		  
forvalues i = 2010(2)2018{
	label variable edu_l_`i' "Edu in levels: `i'"
}


*-----------------------------------------------------------------------
* The latest stage of education if already quit or still in school 
clonevar edu_s_2018=cfps2018sch_2018
clonevar edu_s_2016=cfps2016sch_2016
clonevar edu_s_2014=cfps2014sch_2014
clonevar edu_s_2012=sch2012_2012
clonevar edu_s_2010=cfps2010sch_best_2010

gen edu_s=cond(edu_s_2018>=0 & edu_s_2018!=., edu_s_2018, ///
		  cond(edu_s_2016>=0 & edu_s_2016!=., edu_s_2016, ///
		  cond(edu_s_2014>=0 & edu_s_2014!=., edu_s_2014, ///
		  cond(edu_s_2012>=0 & edu_s_2012!=., edu_s_2012, ///
		  cond(edu_s_2010>=0 & edu_s_2010!=., edu_s_2010, .)))))		  
		  
label variable edu_s "Edu in stages: the lastest wave"
		  
forvalues i = 2010(2)2018{
	label variable edu_s_`i' "Edu in stages: `i'"
}




*-----------------------------------------------------------------------
*                               Cognition
*-----------------------------------------------------------------------
*** Math test (2010 2014 2018 only) ***
* Math test 原始得分 (2010 2014 2018)
clonevar math_2010 = mathtest_2010
replace math_2010 =. if mathtest_2010<0
clonevar math_2014 = mathtest14_2014
replace math_2014 =. if mathtest14_2014<0
clonevar math_2018 = mathtest18_2018
replace math_2018 =. if mathtest18_2018<0

* Math test 可比算法 (2010 2014 2018)
clonevar math_sc2_2010 = mathtest_2010
replace math_sc2_2010 =. if mathtest_2010<0
clonevar math_sc2_2014 = mathtest14_sc2_2014
replace math_sc2_2014 =. if mathtest14_sc2_2014<0
clonevar math_sc2_2018 = mathtest18_sc2_2018
replace math_sc2_2018 =. if mathtest18_sc2_2018<0

forvalues i = 2010(4)2018{
	label variable math_`i' "Math test (yuanshi): `i'"
	label variable math_sc2_`i' "Math test (kebi): `i'"
}


*-----------------------------------------------------------------------
*** Word test (2010 2014 2018 only) ***
* Word test (2010 2014 2018)
clonevar word_2010 = wordtest_2010
replace word_2010 =. if wordtest_2010<0
clonevar word_2014 = wordtest14_2014
replace word_2014 =. if wordtest14_2014<0
clonevar word_2018 = wordtest18_2018
replace word_2018 =. if wordtest18_2018<0


* Word test 可比算法 (2010 2014 2018)
clonevar word_sc2_2010 = wordtest_2010
replace word_sc2_2010 =. if wordtest_2010<0
clonevar word_sc2_2014 = wordtest14_sc2_2014
replace word_sc2_2014 =. if wordtest14_sc2_2014<0
clonevar word_sc2_2018 = wordtest18_sc2_2018
replace word_sc2_2018 =. if wordtest18_sc2_2018<0

forvalues i = 2010(4)2018{
	label variable math_`i' "Math test (yuanshi): `i'"
	label variable math_sc2_`i' "Math test (kebi): `i'"
}

*-----------------------------------------------------------------------
*** Immediate/Delayed Word recall (2012 2016 only) *** 
* Immediate word recall (2012 2016)
clonevar IWR_2012=iwr_2012 
replace IWR_2012=. if iwr_2012<0

clonevar IWR_2016=iwr_2016 
replace IWR_2016=. if iwr_2016<0

* Delayed word recall (2012, 2016)
clonevar DWR_2012=dwr_2012 
replace DWR_2012=. if dwr_2012<0

clonevar DWR_2016=dwr_2016 
replace DWR_2016=. if dwr_2016<0

* Total Word recall (2012, 2016)
gen TWR_2012=DWR_2012+IWR_2012
gen TWR_2016=DWR_2016+IWR_2016

* Episodic Memory (2012, 2016)
gen EMEM_2012 = TWR_2012/2
gen EMEM_2016 = TWR_2016/2

forvalues i = 2012(4)2016{
	label variable IWR_`i' "Immediate word recall (0-10): `i'"
	label variable DWR_`i' "Delayed word recall (0-10): `i'"
	label variable TWR_`i' "Total word recall (0-20): `i'"
	label variable EMEM_`i' "Episodic memory (0-10): `i'"
}


*-----------------------------------------------------------------------
* Serial 7s (substracting 7 from 100) (2012 2016 only)
clonevar Series_2012=ns_g_2012
label variable Series_2012 "Wave 2012: Serial 7s"
clonevar Series_2016=ns_g_2016
label variable Series_2016 "Wave 2012: Serial 7s"

forvalues i = 2012(4)2016{
	label variable Series_`i' "Serials 7 (0-5): `i'"
}




*-----------------------------------------------------------------------
*                                  Health
*-----------------------------------------------------------------------

***** 1. Health Behavior ***** 

*** 1.1 Exercuse ***
gen Exercise_2010=qp8_2010 // Note the variable in 2010 is day/week
replace Exercise_2010=. if qp8_2010<0
label variable Exercise_2010 "Exercise (day/week): 2010"


// 2012 data is by levels, so a lot of respondents answered almost every day 
// overestimated frequency (warning)
gen Exercise_2012=. // Note the variable in 2012 is day/month (levels)
replace Exercise_2012=0 if qp701_2012==5
replace Exercise_2012=1 if qp701_2012==4
replace Exercise_2012=3 if qp701_2012==3
replace Exercise_2012=10 if qp701_2012==2
replace Exercise_2012=30 if qp701_2012==1
label variable Exercise_2012 "Exercise (day/month_l): 2012"



// Note the variable in 2014-2018 is day/month (cont)
gen Exercise_2014=qp701_2014 
replace Exercise_2014=. if qp701_2014<0
label variable Exercise_2014 "Exercise (day/month): 2014"

gen Exercise_2016=qp701_2016
replace Exercise_2016=. if qp701_2016<0
label variable Exercise_2016 "Exercise (day/month): 2016"

gen Exercise_2018=qp701_2018
replace Exercise_2018=. if qp701_2018<0
label variable Exercise_2018 "Exercise (day/month): 2018"


*-----------------------------------------------------------------------
*** 1.2 Smoking ***
forvalues i = 2010(2)2018{
	gen Smoking_`i'=qq202_`i' 
	replace Smoking_`i'=0 if qq202_`i'==-8
	replace Smoking_`i'=. if qq202_`i'==-1 | qq202_`i'==-2
	label variable Smoking_2010 "Number of cigarettes smoked per day: `i'"
}

/*
forvalues i = 2010(2)2018{
	gen Smoking_l3_`i'=0 if Smoking_`i'==0 
	replace Smoking_l3_`i'=1 if Smoking_`i'>=1 &  Smoking_`i'<=9
	replace Smoking_l3_`i'=2 if Smoking_`i'>=10 &  Smoking_`i'<.
	label variable Smoking_2010 "Number of cigerattes (levels): `i'"
}
*/

*-----------------------------------------------------------------------
*** 1.3 Drinking ***
gen Drinking_2010=.
replace Drinking_2010=0 if qq3_2010==0
replace Drinking_2010=1 if qq3_2010==1
label variable Drinking_2010 ///
	  "Whether drank alcohol 3 or more times per week last month: 2010"
label values Drinking_2010 yesno


forvalues i = 2012(2)2018{
	gen Drinking_`i'=.
	replace Drinking_`i'=0 if qq301_`i'==0
	replace Drinking_`i'=1 if qq301_`i'==1
	label variable Drinking_`i' ///
		  "Whether drank alcohol 3 or more times per week last month: `i'"
	label values Drinking_`i' yesno
}



	
save "$Interimdata/CFPS/CFPS_Elite_Data", replace
global CFPS_Elite_Data        "$Interimdata/CFPS/CFPS_Elite_Data"

