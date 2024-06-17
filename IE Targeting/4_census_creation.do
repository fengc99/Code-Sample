/************************************


************************************/


*************************************************************
** Consolidating Criteria and Creating Variables in Census **
*************************************************************

** Variables to create from pre-programmed as potential criteria (both PMT and CB) 	ROOT				STATUS
		** 1) Household with elderly												elderly
		** 2) Household with pregnant or lactating woman							plw
		** 3) Women headed households												women_hoh
		** 4) Households headed by widows											widow
		** 5) Households with people living with disabilities						disabilities
		** 6) Households with people living with chronic illness					illness
		** 7) Households with girl mothers											girl_mothers		Approximate
		** 8) Child-headed households (under 18)									child_hoh
		** 9) Household headed by a woman/widow without a family provider			no_provider
		** 10) Household with a paltry shelter										paltry_shelter
		** 11) Household with separated/orphaned children							orphan				Pending new data
		** 12) Household with one or more survivors of protection incidents			survivor			Cannot create
		** 13) Household headed by a pregnant woman									pregnant_hoh		Approximate
		** 14) Household headed by a nursing woman									nursing_hoh			Approximate
		** 15) Household with more than 3 children under 5 years of age				3_child
		** 16) Household headed by a person with chronic illness					ill_hoh
		** 17) Household headed by a person with disability							disabled_hoh
		** 18) Household headed by an elderly person (60 or over)					elderly_hoh

** Variables to create from 'other criteria' listed in PMT/Focus Group
		** 1) Households headed by a widower										hhh_widower
		** 2) Households with malnourished children									malnchild			Needs attention
		** 3) Households hosting children has already been recoded as "orphan" in the pre-programmed criteria. 
		** 4) Households headed by a neglected, abandoned or separated woman		hhh_fsep			
		** 5) Households headed by a returnee 										returnee
		** 6) Households headed by/dependent on an orphan							hhh_orphan			Approximate
		** 7) Households with no kitchen inputs										nokitchen
		** 8) Households headed by a young mother									young_moth											
		** 9) Households which lost property during displacement due to conflict	loss_prop			Approximate
		** 10) Households with a lack of AME										noAME				Probably cannot create
		** 11) Households headed by TWAs;											hhh_twa
		** 12) Households of TWAs....(this will be the same as above.)									
		** 13) Households living from agriculture with low production 				ag_low				Approximate
		** 14) Households with several children										manychild
		** 15) Households with lack of food seeds for agriculture										Cannot create
		** 16) Households who lost crops to insects									croploss_ins
		** 17) Households with displaced HoH/displaced households					displacedhh
		** 18) Households headed by a person dependent on agIGA						hhh_farmer
		** 19) Displaced households living with host families						hostfamily
		** 20) Households with several family members								manymemb
		** 21) Householsd who lost crops because of bushfire/flooding				croploss_nat
		** 22) Households with a divorced woman HoH/displaced						fdivorced

** Variables to create from 'other criteria' listed in CB Committee
		** 1) Households headed by an orphan: 										hhh_orphan (as above)Pending new data
		** 2) Households headed by a widower										hhh_widower (as above)
		** 3) Households headed by Twa												hhh_twa (as above)
		** 4) Households headed by a young person with chronic illness/disability	hhh_young_illdis
		** 5) Households headed by a divorced woman									hhh_fdivorced
		** 6) Households headed or dependent on a person without IGA				noIGA
		** 7) Households headed by a farmer											hhh_farmer			Approximate
		** 8) Households headed by an elderly widow									hhh_eldwidow
		** 9) Households headed by a single pregnant orphan							hhh_orphsingpreg	Pending new data
		** 10) Households headed by a young person									hhh_youth
		** 11) Households that have houses with straw roofs							strawroof
		** 12) Households headed by youth with a 'less profitable' IGA 				hhh_young_lowIGA
				**(will likely code this as the similar one abov
		** 13) Households hosting displaced 										hostfamily
		** 14) Households that lost fields after natural disasters					croploss_nat
		** 15) Households with malnourished children								malnchild (as above) Needs attention
		** 15) Households with fields destroyed by insects							croploss_ins
		** 17) Displaced households 												displacedhh
		** 18) Households dependent on ag & have low production due to anomalies	ag_low (as above)
		** 19) Households living from a remunerated agricultural activity			agIGA
		** 20) Female headed households with no children (sterile)					hhh_femnochild
		** 21) Households without potable water										no_water

	

		
		
use "${output}DRC_IETargeting_Census_Fieldwork_V1_recoded.dta", clear

/////////////////////////// First, generate all the criteria pre-programmed (relevant for both PMT and CB) /////////////////////////////////////

**1) Household with elderly: elderly
gen pmtc_elderly = ((hh_nf60 > 0 & hh_nf60 != .) | (hh_nm60 > 0 & hh_nm60 != .)) //creates a binary equal to one if there are any females or males over 60 in the HH
gen cbc_elderly = ((hh_nf60 > 0 & hh_nf60 != .) | (hh_nm60 > 0 & hh_nm60 != .)) //note that these are exact duplicates
label var pmtc_elderly "PMT criteria: HH has at least one elderly person"
label var cbc_elderly "CB criteria: HH has at least one elderly person"

**2) Household with pregnant and lactating women
gen pmtc_plw = ((hh_npreg > 0 & hh_npreg !=.) | (hh_nbf >0 & hh_nbf != .))
gen cbc_plw = ((hh_npreg > 0 & hh_npreg !=.) | (hh_nbf >0 & hh_nbf != .))
lab var pmtc_plw "PMT criteria: HH has PLW"
lab var cbc_plw "CB criteria: HH has PLW"
				
** 3) Women headed households
gen pmtc_women_hoh = demo_headfemale
gen cbc_women_hoh = demo_headfemale
lab var pmtc_women_hoh "PMT criteria: woman-headed household"
lab var cbc_women_hoh "CB criteria: woman-headed household"
										
** 4) Households headed by widows										
gen pmtc_widow = (hhh_sex == 2 &  hhh_maritalstatus == 4)
gen cbc_widow = (hhh_sex == 2 &   hhh_maritalstatus == 4)
lab var pmtc_widow "PMT criteria: Household headed by a widow"
lab var cbc_widow "CB criteria: Household headed by a widow"

** 5) Households with people living with disabilities				
gen pmtc_disabilities = (hh_ndisability > 0 & hh_ndisability != .)
gen cbc_disabilities = (hh_ndisability > 0 & hh_ndisability != .)
lab var pmtc_disabilities "PMT criteria: Household has person with disability"
lab var cbc_disabilities "CB criteria: Household has person with disability"

** 6) Households with people living with chronic illness				
gen pmtc_illness = (hh_nchdis > 0 & hh_nchdis != .)
gen cbc_illness = (hh_nchdis > 0 & hh_nchdis != .)
lab var pmtc_illness "PMT criteria: Household has person with chronic illness"
lab var cbc_illness "CB criteria: Household has person with chronic illness"

** 7) Households with girl mothers (APPROXIMATE)
* if there is one pregnant person and no women adults of childbearing age			
gen pmtc_girl_mothers = (hh_npreg == 1 & hh_nf1859 == 0)
* also allow for cases where there are two pregnant women, but less than 2 women adults 
replace pmtc_girl_mothers = 1 if hh_npreg == 2 & hh_nf1859 <2

gen cbc_girl_mothers = pmtc_girl_mothers
lab var pmtc_girl_mothers "PMT criteria: Household has girl mother APPROX"
lab var cbc_girl_mothers "CB criteria: Household has girl mother APPROX"

** 8) Child-headed households (under 18)								
gen pmtc_child_hoh = (demo_headage <18) 
gen cbc_child_hoh = (demo_headage <18)
lab var pmtc_child_hoh "PMT critera: child-headed household"
lab var cbc_child_hoh "CB criteria: child-headed household"

** 9) Household headed by a woman/widow without a family provider		
	*First, figure out how to capture 'no provider'.  We'll create this from the income sources
	* that aren't some type of formal or informal employment
	gen temp_noIGA = 0
	replace temp_noIGA = 1 if inlist(socio_sourceincomecat, 9, 11, 13, 14, 15, 17)
	*Then, combine this with woman-headed households (which would include widowed hhh)
gen pmtc_no_provider = (hhh_sex == 2 & temp_noIGA == 1)
gen cbc_no_provider = (hhh_sex == 2 & temp_noIGA == 1)
lab var pmtc_no_provider "PMT criteria: HH headed by woman without provider"
lab var cbc_no_provider "CB criteria: HH headed by woman without provider"

** 10) Household with a paltry shelter									
	* Let's define 'paltry' as houses that are huts (made entirely of straw)
gen pmtc_paltry_shelter = (hh_type_housing == 1)
gen cbc_paltry_shelter = (hh_type_housing == 1)
lab var pmtc_paltry_shelter "PMT criteria: HH has a paltry shelter"
lab var cbc_paltry_shelter "CB criteria: HH has a paltry shelter"

** 11) Household with separated/orphaned children						orphan
	//We will update this when the new data comes in
gen pmtc_orphan = 0
replace pmtc_orphan = 1 if svy_orphan == 1
gen cbc_orphan = 0
replace cbc_orphan = 1 if svy_orphan == 1
lab var pmtc_orphan "PMT criteria: household has separated or orphaned child"
lab var cbc_orphan "CB criteria: household has separated or orphaned child"

** 12) Household with one or more survivors of protection incidents		survivor
	//We won't create household indicators for this.

	
** 13) Household headed by a pregnant woman	(APPROXIMATE)
* if head of household is a woman, and there is at least one pregnant person, and there are not more adult women in the household
gen pmtc_pregnant_hoh = (hhh_sex == 2 & hh_npreg > 0 & hh_npreg !=. & hh_nf1859 <2)
* account for situations where there are two pregnant people and two women in the household, with the HoH being female
replace pmtc_pregnant_hoh = 1 if hhh_sex == 2 & hh_npreg == 2 & hh_nf1859 == 2

gen cbc_pregnant_hoh = (hhh_sex == 2 & hh_npreg > 0 & hh_npreg !=. & hh_nf1859 <2)
replace cbc_pregnant_hoh = 1 if hhh_sex == 2 & hh_npreg == 2 & hh_nf1859 == 2

lab var pmtc_pregnant_hoh "PMT criteria: HH head is pregnant APPROX"
lab var cbc_pregnant_hoh "CB criteria: HH head is pregnant APPROX"

** 14) Household headed by a nursing woman (APPROXIMATE)
	* if head of household is a woman, and there is at least one breastfeeding person, and there are not more adult women in the household
gen pmtc_nursing_hoh = (hhh_sex == 2 & hh_nbf > 0 & hh_nbf !=. & hh_nf1859 <2)
	* account for situations where there are two breastfeeding people and two women in the household, with the HoH being female
replace pmtc_nursing_hoh = 1 if hhh_sex == 2 & hh_nbf == 2 & hh_nf1859 == 2

gen cbc_nursing_hoh = (hhh_sex == 2 & hh_nbf > 0 & hh_nbf !=. & hh_nf1859 <2)
replace cbc_nursing_hoh = 1 if hhh_sex == 2 & hh_nbf == 2 & hh_nf1859 == 2

lab var pmtc_nursing_hoh "PMT criteria: HH head is nursing APPROX"
lab var cbc_nursing_hoh "CB criteria: HH head is nursing APPROX"

** 15) Household with more than 3 children under 5 years of age		
gen pmtc_3_child = (demo_nochu5 > 3 &  demo_nochu5 != .)
gen cbc_3_child = (demo_nochu5 > 3 &  demo_nochu5 != .)
lab var pmtc_3_child "PMT criteria: HH has more than 3 children under 5"
lab var cbc_3_child "CB criteria: HH has more than 3 children under 5"

** 16) Household headed by a person with chronic illness				
gen pmtc_ill_hoh = hh_head_chronic
gen cbc_ill_hoh = hh_head_chronic
lab var pmtc_ill_hoh "PMT criteria: HH headed by a person with chronic illness"
lab var cbc_ill_hoh "CB criteria: HH headed by a person with chronic illness"

** 17) Household headed by a person with disability						
gen pmtc_disabled_hoh = hhh_head_dis
gen cbc_disabled_hoh = hhh_head_dis
lab var pmtc_disabled_hoh "PMT criteria: HH headed by a person with disability"
lab var cbc_disabled_hoh "CB criteria: HH headed by a person with disability"

** 18) Household headed by an elderly person (60 or over)				
gen pmtc_elderly_hoh = (demo_headage >= 60 & demo_headage != .)								
gen cbc_elderly_hoh = (demo_headage >= 60 & demo_headage != .)		
lab var pmtc_elderly_hoh "PMT criteria: HH headed by an elderly person"
lab var cbc_elderly_hoh "CB criteria: HH headed by an elderly person"		
										
								

/////////////////////////// Then, generate the 'other' criteria from the PMT /////////////////////////////////////

/// Here, I create the variables that describe all of those 'other' PMT criteria listed above.  I create these for the entire dataset (BOTH treatment arms), as we will need to calculate PMT estimates for both regardless.

** 1) Households headed by a widower												hhh_widower
	gen pmtc_hhh_widower = (hhh_sex == 1 & hhh_maritalstatus == 4)
	lab var pmtc_hhh_widower "PMT criteria: Household headed by a widowER"
	
** 2) Households with malnourished children											malnchild
	/** We don't have much information about child malnutrition;  just the number of meals pre day eaten currently by children.  
	The question about what number 	of meals is 'normal' is not always answered.  For this reason, we have to ignore 
	fcs_nmeals_childnormal in calculations.  Our choice is to either measure this by saying all children who get one meal a day 
	are malnourished (big assumption in terms of nutrition and the quality of the answers on this question), or leaving it out 
	of the calculations.
	*/
	tab fcs_nmeals_child //looks like 92 percent of households said the child got one meal per day.  This would be a very extreme "automatic in" criteria; let's leave it off for now.
	*gen pmtc_malnchild = (fcs_nmeals_child <= 1)
	*lab var pmtc_malnchild "PMT criteria: Household has malnourished children"
	
** 3) Children living with a host family											orphan
	**NOTE: this variable will be the same as the orphan pre-programmed criteria. 	
	
** 4) Households headed by a neglected, abandoned or separated woman				hhh_fsep
	** We don't have a question about the female head of household being 'abandoned', 
	* but we can deduce it would fall into one of three marriage categories.
	* This is probably analogous to a female-headed household, so its inclusion shoudn't make much difference
gen pmtc_hhh_fsep = 0
replace pmtc_hhh_fsep = 1 if hhh_sex == 2 & inlist(hhh_maritalstatus, 1, 3, 4) //if she's single, divorced, or widowed
lab var pmtc_hhh_fsep "PMT criteria: HH headed by abandoned woman (APPROX)"

** 5) Households headed by a returnee 												returnee
	** We don't ask this by household head, but by entire household status.
gen pmtc_returnee = (hh_status == 5)
lab var pmtc_returnee "PMT criteria: Household has returnee status"
	
** 6) Households headed by/dependent on an orphan 									hhh_orphan
* We don't have this information exactly.  Instead, we'll create a variable = 1 if there is an orphan
* in the household and the head of household is younger than 18.
gen pmtc_hhh_orphan = 0
replace pmtc_hhh_orphan = 1 if svy_orphan == 1 & demo_headage <18
lab var pmtc_hhh_orphan "PMT criteria: orphan HoH (APPROX: HH has orphan & HoH is child)"

** 7) Households with no kitchen inputs												nokitchen
	** We will code this as houses that do not have pots and pans(?)
gen pmtc_nokitchen = (asst_pans == 0)
lab var pmtc_nokitchen "PMT criteria: Household with no kitchen goods"

** 8) Households headed by a young mother (APPROX)									young_moth
	* Will estimate this if the hhh is a young woman, and there are other children in the household
	* Young can be defined as under 25
	egen temp_children = rowtotal(hh_f023m hh_nm023m hh_nf2459m hh_nm2459m hh_nf511 hh_nm511 hh_nf1217 hh_nm1217)
gen pmtc_young_moth = 0
replace pmtc_young_moth = 1 if hhh_sex == 2 & demo_headage <= 25 & temp_children > 0 & temp_children != .
lab var pmtc_young_moth "PMT criteria: HH headed by a young mother (APPROX)"
											
** 9) Households which lost property during displacement due to conflict			loss_prop
	* Best we can do in census is if they lost crops due to displacement.
gen pmtc_loss_prop = 0
replace pmtc_loss_prop = 1 if hh_grain_reason_loss == 2 | hh_root_reason_loss == 2
lab var pmtc_loss_prop "PMT criteria: HH lost property due to conflict (APPROX)"
	
** 10) Households with a lack of AME												noAME
	* AME are essential household items.  Looks like we don't have much information 
	* on these types of goods.  Will not create (for now)

** 11) Households headed by TWAs;													hhh_twa
gen pmtc_hhh_twa = (hh_ethnic_group == 1)
lab var pmtc_hhh_twa "PMT criteria: Household is Twa/ HH head is Twa"
	
** 12) Households of TWA: this is the same as above									
		
** 13) Households living from agriculture with low production 						ag_low
	* Will define this as households with agriculture as their primary IGA, and
	* who have lost crops over the last season
gen pmtc_ag_low = 0
replace pmtc_ag_low = 1 if socio_sourceincomecat == 1 & (inlist(hh_grow_grain_loss, 2, 3, 4, 5) | inlist(hh_grow_roots_loss, 2,3,4,5))
lab var pmtc_ag_low "PMT criteria: ag household with low production (APPROX)"

** 14) Households with several children												manychild
	* Let's make an assumption that the number of children that qualifies as "many" are those
	* in the top 10% percentile of households with children.
	tab temp_children if temp_children != 0 //looks like this is above 6 children
gen pmtc_manychild = (temp_children >6 & temp_children != .)
lab var pmtc_manychild "PMT criteria: Household has above 6 children"

** 15) Households with lack of food seeds for ag (cannot construct this)	
		
** 16) Households who lost crops to insects									croploss_ins
gen pmtc_croploss_ins = 0
replace pmtc_croploss_ins = 1 if hh_grain_reason_loss == 4 | hh_root_reason_loss == 4
lab var pmtc_croploss_ins "PMT criteria: HH lost crops due to insects"

** 17) Households with displaced HoH/displaced households					displacedhh
gen pmtc_displacedhh = (hh_status == 1 | hh_status == 3)
lab var pmtc_displacedhh "PMT criteria: displaced households"

** 18) Households headed by a person dependent on agIGA						hhh_farmer
gen pmtc_hhh_farmer = (socio_sourceincomecat == 1)
lab var pmtc_hhh_farmer "PMT criteria: Households headed by farmer (APPROX)"

** 19) Displaced households living with host families						hostfamily
gen pmtc_hostfamily = (hh_status == 2)
lab var pmtc_hostfamily "PMT criteria: Households hosting displaced"

** 20) Households with several family members								manymemb	
su demo_HHsize							
gen pmtc_manymemb = demo_HHsize >= 10 //2 SDs above the mean
lab var pmtc_manymemb "PMT criteria: Household has several members"

** 21) Households who lost crops because of bushfire/flooding				croploss_nat
gen pmtc_croploss_nat = 0
replace pmtc_croploss_nat = 1 if inlist(hh_grain_reason_loss,1,3) | inlist(hh_root_reason_loss,1,3)
lab var pmtc_croploss_nat "PMT criteria: HH lost crops due to natural disaster"

** 22) Households with a divorced woman HoH/displaced						fdivorced
gen pmtc_hhh_fdivorced = 0
replace pmtc_hhh_fdivorced = 1 if hhh_sex == 2 & hhh_maritalstatus == 3
lab var pmtc_hhh_fdivorced "PMT criteria: Household headed by divorced woman"

/////////////////////////// Now, generating the 'other' criteria from the CB arm committee consultation /////////////////////////////////////

** 1) Households headed by an orphan												hhh_orphan		
	* This will be the same as used in PMT
gen cbc_hhh_orphan = pmtc_hhh_orphan
lab var cbc_hhh_orphan "CB criteria: orphan HoH (APPROX: HH has orphan & HoH is child)"

** 2) Households headed by a widower												hhh_widower
gen cbc_hhh_widower = pmtc_hhh_widower
lab var cbc_hhh_widower "CB criteria: Household headed by a widowER"
	
** 3) Households headed by Twa														hhh_twa
gen cbc_hhh_twa = pmtc_hhh_twa
lab var cbc_hhh_twa "CB criteria: Household is Twa/ HH head is Twa"

** 4) Households headed by a young person with chronic illness or disability		hhh_young_illdis
gen cbc_hhh_young_illdis = 0
replace cbc_hhh_young_illdis = 1 if demo_headage <= 25 & (hh_head_chronic == 1 | hhh_head_dis == 1)
lab var cbc_hhh_young_illdis "CB criteria: Household headed by a young person with chronic illness or disability"	

** 5) Households headed by a divorced woman											hhh_fdivorced
gen cbc_hhh_fdivorced = 0
replace cbc_hhh_fdivorced = 1 if hhh_sex == 2 & hhh_maritalstatus == 3
lab var cbc_hhh_fdivorced "CB criteria: Household headed by divorced woman"

** 6) Households headed or dependent on a person without income generating activity	noIGA
	**For this, we will need to make some assumptions.  We do not have information on the IGA that the household head is engaged in.  Instead, we will assume that the the survey question "What is the main source of income of the household?" is best representative of the IGA for the household head (or on which the household is dependent).  Of this question, we consider 9 (begging), 11 (WFP assistance), 13 (donation from relatives or neighbors), 14 (transfer income), 15 (loan/debt) and 17 (no activity) as having no income generating activity.
gen cbc_noIGA = 0
replace cbc_noIGA = 1 if inlist(socio_sourceincomecat, 9, 11, 13, 14, 15, 17)
lab var cbc_noIGA "CB criteria: Household dependent on a person with no IGA (estimated)"	

** 7) Households headed by a farmer													hhh_farmer
	* We will have to assume that the main soure of income is related to the household head...
	* Meaning, we define this by whether or not the household's main source of income is farming.
gen cbc_hhh_farmer = (socio_sourceincomecat == 1)
lab var cbc_hhh_farmer "CB criteria: Households headed by farmer (APPROX)"

** 8) Households headed by an elderly widow											hhh_eldwidow
	* generate using the widow indicator from before (implies hhh is female)
	* and elderly indicator
gen cbc_hhh_eldwidow = (cbc_widow == 1 & cbc_elderly == 1) 
lab var cbc_hhh_eldwidow "CB criteria: Household headed by an elderly widow"

** 9) Households headed by a single pregnant orphan									hhh_orphsingpreg
	*This is SO specific that we won't try to approximate the variable.
	
** 10) Households headed by a young person											hhh_youth
gen cbc_hhh_youth = (demo_headage <= 25)
lab var cbc_hhh_youth "CB criteria: Household headed by a young person"

** 11) Households that have houses with straw roofs									strawroof
gen cbc_strawroof = 0
replace cbc_strawroof = 1 if inlist(hh_type_housing, 1, 3, 5)
lab var cbc_strawroof "CB criteria: Houses with straw roofs"

** 12) Households headed by youth with a 'less profitable' IGA 						young_lowIGA
		**(will ode this similarly to ones above), using young hhh and noIGA
gen cbc_hhh_young_lowIGA = (cbc_hhh_youth == 1 & cbc_noIGA == 1)
lab var cbc_hhh_young_lowIGA "CB criteria: households headed by youth with low IGA"

** 13) Households hosting displaced 												hostfamily
gen cbc_hostfamily = (hh_status == 2)
lab var cbc_hostfamily "CB criteria: Households hosting displaced"

** 14) Households that lost fields after natural disasters							croploss_nat
	* Will define natural diasters as floods or bush fires, but not pests
gen cbc_croploss_nat = 0
replace cbc_croploss_nat = 1 if inlist(hh_grain_reason_loss,1,3) | inlist(hh_root_reason_loss,1,3)
lab var cbc_croploss_nat "CB criteria: HH lost crops due to natural disaster"

** 15) Households with malnourished children										malnchild
	*This will be constructed as above if used.
*cbc_malnchild = pmtc_malnchild
*lab var cbc_malnchild "CB criteria: Household has malnourished children"
	
** 15) Households with fields destroyed by insects									croploss_ins
gen cbc_croploss_ins = 0
replace cbc_croploss_ins = 1 if hh_grain_reason_loss == 4 | hh_root_reason_loss == 4
lab var cbc_croploss_ins "CB criteria: HH lost crops due to insects"

** 17) Displaced households 		displacedhh
	*Not including host households in this case; just 'displaced in a camp' and 'refugee' status
gen cbc_displacedhh = (hh_status == 1 | hh_status == 3)
lab var cbc_displacedhh "CB criteria: displaced households"

** 18) Households dependent on agriculture & have low production due to anomalies	ag_low (as above)
gen cbc_ag_low = pmtc_ag_low
lab var cbc_ag_low "CB criteria: ag household with low production due to anomalies"

** 19) Households living from a remunerated agricultural activity					agIGA
gen cbc_agIGA = (socio_sourceincomecat == 1)
lab var cbc_agIGA "CB criteria: HH living from agriculture IGA"

** 20) Female headed households with no children (sterile)							hhh_femnochild
gen cbc_hhh_femnochild = (cbc_women_hoh == 1 & temp_children == 0)
lab var cbc_hhh_femnochild "CB criteria: woman-headed HH with no children"

** 21) Households without potable water												no_water
gen cbc_no_water = 0
replace cbc_no_water = 1 if infra_water == 1
lab var cbc_no_water "CB criteria: Household has no potable water (APPROX)"

** Updating the cbcriteria global from previous do-file (community_consultation.do) to exclude the variables we couldn't create

global cbcriteria_new elderly plw women_hoh widow disabilities illness girl_mothers child_hoh no_provider paltry_shelter orphan /*survivor*/ pregnant_hoh nursing_hoh 3_child ill_hoh disabled_hoh elderly_hoh no_water hhh_femnochild agIGA ag_low displacedhh croploss_ins /*malnchild*/ hostfamily hhh_young_lowIGA strawroof hhh_youth /*hhh_orphsingpreg*/ hhh_eldwidow hhh_farmer noIGA hhh_fdivorced hhh_young_illdis hhh_twa hhh_widower hhh_orphan croploss_nat

/// Make sure there are no missing observations
foreach i in $cbcriteria_new {
	replace cbc_`i' = 0 if cbc_`i' == .
}

global pmtcriteria elderly plw women_hoh widow disabilities illness girl_mothers child_hoh no_provider paltry_shelter orphan /*survivor*/ pregnant_hoh nursing_hoh 3_child ill_hoh disabled_hoh elderly_hoh hhh_widower hhh_twa croploss_ins displacedhh /*malnchild*/ hhh_fsep returnee hhh_orphan hhh_farmer hostfamily ag_low manymemb nokitchen croploss_nat young_moth /*noAME*/ loss_prop manychild hhh_fdivorced

foreach i in $pmtcriteria {
	replace pmtc_`i' = 0 if pmtc_`i' == .
}


save "${output}DRC_IETargeting_Census_constructed.dta", replace
