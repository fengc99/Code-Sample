  ********************************************************************************

********************************************************************************
clear

use "${data_bl_raw}Census\Allmodules_census_orphan_clean_16 Mar 2023.dta", clear 

*Changing observations missing treatment to say "out of study" with a value.
replace treatment = 2 if treatment == .
lab def treatment 2 "out of study", modify
 
*Renaming variables
rename	(hh_total	hh_nm1859	hh_goodnmeals_child	hh_goodpork	hh_goodsheeps)(demo_HHsize	demo_wapopmale	socio_nomealsch	asst_pig	asst_sheep)

destring demo_HHsize, replace //NIDHI: MAKE SURE THIS IS IN THE DOFILE

*Creating new variables
gen socio_sourceincomecat = hh_source_income
recode hh_source_income (-99 = 16) (-98 = 16) (11 = 16) (12 = 16)

*gen		demo_headmaritalsts = hhh_marriagestatus
*gen		demo_headfemale = hhh_sex

recode hhh_marriagestatus (1=1) (2=3) (3=4) (4=2) (5=1), gen(demo_headmaritalsts)
recode hhh_sex (1=0)(2=1), gen(demo_headfemale )

replace demo_headfemale = 0 if demo_wapopmale >0 & demo_wapopmale != . //Changing households to male-headed (really, double-headed) if there are any working-aged men in the household.
lab var demo_headfemale "1 = HH is headed by woman, 0 = double-headed or male-headed"

/**Change 'today' into a Stata date format so we can calculate age
gen int hhh_date_of_birth = daily(hhh_datebirth , "MDY")
format hhh_date_of_birth %td
todate today, gen(today_date) p(yyyymmdd) f(%td)
gen demo_headage = today_date - hhh_date_of_birth
replace demo_headage=demo_headage/365.25
replace demo_headage=floor(demo_headage)
order today_date, after(today)
drop today today2
*/  //This part was done in the cleaning stage

gen demo_headage = hhh_age

recode hhh_marriagestatus (1=1)(2=0)(3=1)(4=1)(5=1), gen(demo_monoparental)

recode hhh_educ (1=1)(2=2)(3=2)(4=3)(5=3)(6=4)(7=4)(8=5)(9=5), gen(socio_headedulcat )

egen demo_nochu5=rowtotal(hh_f023m hh_nm023m hh_nf2459m hh_nm2459m)

gen demo_disabilityd=0
replace demo_disabilityd=1 if hh_ndisability>0 & hh_ndisability!=.

recode hh_goodcook_fuel (5=1)(1 2 3 4 = 0), gen(infra_electricity)

recode hh_gooddrinking (1=1)(2=1)(3=1)(4=0)(5=0)(6 7 8 =0), gen(infra_water)

gen asst_radio=0
replace asst_radio=1 if hh_goods == 1
rename hh_goods_1 asst_radio

gen asst_tv=0
replace asst_tv=1 if hh_goods == 2
rename hh_goods_2 asst_tv

gen asst_moto=0
replace asst_moto=1 if hh_goods == 6
rename hh_goods_6 asst_moto

gen asst_fishhunt=0
replace asst_fishhunt=1 if hh_goods == 8
rename hh_goods_8 asst_fishhunt

gen asst_plow=0
replace asst_plow=1 if hh_goods == 10
rename hh_goods_10 asst_plow

gen asst_cell=0
replace asst_cell=1 if hh_goods == 12
rename hh_goods_12 asst_cell

gen asst_table=0
replace asst_table=1 if hh_goods == 14
rename hh_goods_14 asst_table

gen asst_lamp=0
replace asst_lamp=1 if hh_goods == 15
rename hh_goods_15 asst_lamp

gen asst_pans=0
replace asst_pans=1 if hh_goods == 16
rename hh_goods_16 asst_pans

gen asst_agtools=0
replace asst_agtools=1 if hh_goods == 9
rename hh_goods_9 asst_agtools

****Further recoding 


* DEMO
	*Education
	gen education = hhh_educ

	label define labeleducation 1 "No education" 2 "Primary Incomplete" 3 "Primary Complete" 4 "Secondary Incomplete" 5 "Secondary Complete"
	label values education labeleducation
	label variable education "Household head's highest level of education"
	tab education, gen(educ)
	
	*HHH age
	label variable hhh_age "Age of the HH head in years" 
	gen hhh_female=(hhh_sex==2)
	label variable hhh_female "HH head is a female"

	*Ethnic group
	recode hh_ethnic_group(3=.o)
	
	*HH status
	recode hh_status(6=5)

	*Size of the HH
	label variable hh_total_017 "Number of HH members aged 0-17"
	label variable hh_total_1860 "Number of HH members aged 18-60"

	*Sex of the respondent
	gen hhm_male=(hhm_sex==1)
	label variable hhm_male "Respondent is a male"
	
	*Marital status
	rename hhh_marriagestatus hhh_maritalstatus
	
	*Respondent is the head
	label variable hh_areyouhead "Respondent is the head"
	
	*Age of the respondent
	label variable hhm_age "Age of the respondent in years"

	*Province and territory
	recode hh_vil_province(3=.)
	rename hh_vil_territory2_precise hh_vil_territory

	*Targeting variables
*	label variable beneficiaries "HH was eligible to receive cash"
*	label variable scope "HH has registered to receive cash"
*	label variable cash "HH received cash"
	// these 3 variables not found
	
	*Source of income
	recode hh_source_income(-66 16=.)(1 2 3 7=1)(5 6=2)(4 8 10 18=3)(17 =4)(9 14 15 13=5)
	label define lhh_source_income 1 "Agriculture and Livestock" 2 "Small business" 3 "Non-farm paid work" 4 "No activity" 5 "Other"
	label values hh_source_income lhh_source_income
	label variable hh_source_income "Household's source of income"
 
 
	* Generate wealth index (DHS)

	drop infra_electricity // empty

	*housing
	gen hh_type_roof= hh_type_housing
	recode hh_type_roof(1 2 3 5 6 7=1)(4=2)
	label define l_roof 1 "Straw" 2 "Metal"
	label values hh_type_roof l_roof

	recode hh_type_housing(1 7=1)(2 3 =2)(4 5 6=3)
	label define l_wall 1 "Hut/plank" 2 "Earth brick" 3  "Cement brick"
	label values hh_type_housing l_wall
	
* Assets
	global asset_old asst_agtools asst_fishhunt asst_pans hh_goods_3 hh_goods_5 hh_goods_7 asst_pig asst_sheep hh_goodgoats hh_goodpoultry hh_goodrabbit hh_goodbeef hh_goodcobbler hh_goods_4 asst_moto asst_cell asst_lamp asst_radio asst_table 	asst_tv hh_goods_11 hh_goods_13 hh_sanitary hh_gooddrinking hh_goodcook_fuel hh_type_housing hh_type_roof

	*Step one: check which vars to keep based on frequency and variation
foreach var in $asset {
tab `var', mi
}

	*Step two remove those with low-no variation: asst_fishhunt hh_goods_3 hh_goods_5 hh_goods_7 asst_pig asst_sheep hh_goodgoats hh_goodrabbit hh_goodbeef hh_goodcobbler hh_goods_4 asst_moto asst_tv hh_goods_11 hh_goods_13 hh_type_roof

	global asset asst_agtools asst_pans hh_goodpoultry asst_cell asst_lamp asst_radio asst_table  hh_sanitary hh_gooddrinking hh_goodcook_fuel hh_type_housing

	local tools asst_agtools asst_pans 
	local livestock hh_goodpoultry 
	local others asst_cell asst_lamp asst_radio asst_table 
	local house hh_gooddrinking hh_goodcook_fuel hh_type_housing

	corr $asset // check correlation: (not too high)

	*Step three factor analysis with principal components extraction using correlation method with one factor extracted, substitution of mean for missing values, estimation of the factor scores using the regression method

	factor $asset , pcf factors(1)
	predict wealth_index  // This is essentially the sum of the asset variables, weighted by the elements of the first eigenvector
	label var wealth_index "Wealth index "

	*Step four: create quintiles
	xtile wealth_quintile=wealth_index, nq(5)

	label define qui 1 "very poor" 2 "poor" 3 "middle" 4"rich" 5 "very rich"
	label value wealth_quintile qui
	label var wealth_quintile "Wealth quitiles"


	label variable infra_water "Household has good drinking water"
	
	label variable hh_receivedassistance "HH received assistance from WFP in 2022"
	rename hh_assistance_otype type

save "${output}DRC_IETargeting_Census_Fieldwork_V1_recoded.dta", replace 







