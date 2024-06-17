/************************************


************************************/


	use "${output}baseline.dta", clear
	
	
	*OUTCOME VARS
*******************************************************************************

* FCS
 	egen FCSStap = rowmax(fcs_fq_cereals fcs_fq_tuber)
	
	rename fcs_fq_legumesnuts  FCSPulse
	rename fcs_fq_milk  	   FCSDairy
	rename fcs_fq_protein  	   FCSPr
	rename fcs_fq_veggies 	   FCSVeg
	rename fcs_fq_fruits 	   FCSFruit
	rename fcs_fq_oil 		   FCSFat
	rename fcs_fq_sugar        FCSSugar
	rename fcs_fq_condiments   FCSCond

	
	label var FCSStap    	   "Consumption over the past 7 days (cereals and tubers)"
	label var FCSVeg           "Consumption over the past 7 days (vegetables)"
	label var FCSFruit         "Consumption over the past 7 days (fruit)"
	label var FCSPr            "Consumption over the past 7 days (protein-rich foods)"
	label var FCSPulse         "Consumption over the past 7 days (pulses)"
	label var FCSDairy         "Consumption over the past 7 days (dairy products)"
	label var FCSFat           "Consumption over the past 7 days (oil)"
	label var FCSSugar         "Consumption over the past 7 days (sugar)"
	label var FCSCond          "Consumption over the past 7 days (condiments)"

	recode FCSStap FCSVeg FCSFruit FCSPr FCSPulse FCSDairy FCSFat FCSSugar FCSCond (.=0)

	capture confirm variable FCS 
	if !_rc {
	cap rename FCS old_FCS
	}
	gen FCS= FCSStap*2+FCSVeg+FCSFruit+FCSPr*4+FCSPulse*3+FCSDairy*4+FCSFat*0.5+FCSSugar*0.5+FCSCond*0
	label var FCS "Food Consumption Score"


*** Use this when analyzing a country with high consumption of sugar and oil
	*** thresholds 28-42
		gen FCSCat28 = cond(FCS <= 28, 1,cond(FCS <= 42, 2, 3))
		label var FCSCat28 "FCS Categories, thresholds 28-42"


	*** define variables labels and properties for "FCS Categories".

	label define FCSCat 1 "Poor (0-28)" 2 "Borderline (28.5-42)" 3 "Acceptable (42.5 and over)"
	label values FCSCat28 FCSCat
	
	
	**Creating dummies for categories for graph
	tab(FCSCat28), gen(FCSCat)
	
	
************************************************************************
* FCS- Nutritional
	
	rename   fcs_fq_meat 			FCSNPrMeatF
	rename   fcs_fq_organmeats  	FCSNPrMeatO
	rename   fcs_fq_fish			FCSNPrFish
	rename   fcs_fq_eggs			FCSNPrEggs
	rename   fcs_fq_veggies_orange  FCSNVegOrg
	rename   fcs_fq_veggies_green   FCSNVegGre
	rename   fcs_fq_fruits_vita		FCSNFruiOrg
	
	*assign variable and value labels
	*variable labels
	label variable FCSNPrMeatF "Flesh meat"
	label variable FCSNPrMeatO "Organ meat"
	label variable FCSNPrFish "Fish/shellfish"
	label variable FCSNPrEggs "Eggs"
	label variable FCSNVegOrg "Orange vegetables (vegetables rich in Vitamin A)"
	label variable FCSNVegGre "Green leafy vegetables"
	label variable FCSNFruiOrg "Orange fruits (Fruits rich in Vitamin A)"
	
	*recode "n/a" values to 0
	recode FCSNPrMeatF FCSNPrMeatO FCSNPrFish FCSNPrEggs FCSNVegOrg FCSNVegGre FCSNFruiOrg (.=0)

	 
	*compute aggregates of key micronutrient consumption of vitamin, iron and protein 
	gen FGVitA = FCSDairy +FCSNPrMeatO +FCSNPrEggs +FCSNVegOrg +FCSNVegGre +FCSNFruiOrg
	label variable FGVitA "Consumption of vitamin A-rich foods"

	gen FGProtein = FCSPulse +FCSDairy +FCSNPrMeatF +FCSNPrMeatO +FCSNPrFish +FCSNPrEggs
	label variable FGProtein "Consumption of protein-rich foods"

	gen FGHIron = FCSNPrMeatF +FCSNPrMeatO +FCSNPrFish
	label variable FGHIron "Consumption of hem iron-rich foods"

	gen FGStaple= fcs_fq_cereals + fcs_fq_tuber
	label variable FGStaple "Consumption of staples"

	gen FGVeg= FCSVeg + FCSNVegGre + FCSNVegOrg + FCSFruit + FCSNFruiOrg
	label variable FGVeg "Consumption of vegetables and fruits"

	*recode into nutritious groups  
	gen FGVitACat= cond(FGVitA ==0, 1, cond(FGVitA <=6, 2, 3))
	gen FGProteinCat= cond(FGProtein ==0, 1, cond(FGProtein <=6, 2, 3))
	gen FGHIronCat= cond(FGHIron ==0, 1, cond(FGHIron <=6, 2, 3))
	gen FGFatCat=  cond(FCSFat ==0, 1, cond(FCSFat <=6, 2, 3))
	gen FGStapleCat=  cond(FGStaple ==0, 1, cond(FGStaple <=6, 2, 3))
	gen FGVegCat=  cond(FGVeg ==0, 1, cond(FGVeg <=6, 2, 3))

	label define catlabels 1 "Never consumed" 2 "Consumed sometimes" 3 "Consumed daily"

	label values FGVitACat FGProteinCat FGHIronCat FGFatCat FGStapleCat FGVegCat catlabels


	label variable FGVitACat "Consumption of vitamin A-rich foods"
	label variable FGProteinCat "Consumption of protein-rich foods"
	label variable FGHIronCat "Consumption of hem iron-rich foods"
	label var FGFatCat "Consumption of oils and fats"
	label var FGStapleCat "Consumption of staples"
	label var FGVegCat "Consumption of fruits and vegetables"
******************************************************************************
*LLCSI
	** Creating new variables for analysis
	
	recode llcsi_children_ofs(.=0)
	
	gen used_stress_strat = (llcsi_sell_hh_asset == 1| llcsi_sell_hh_asset_reason ==2 | ///
							llcsi_spend_saving == 1  | llcsi_spend_saving_reason  ==2 | ///
							llcsi_borrow == 1 		 | llcsi_borrow_reason == 2       | ///
							llcsi_send_ewhere== 1 	 | llcsi_send_ewhere_reason ==2)
							
	gen used_crisis_strat = (llcsi_sell_prod_asset == 1    | llcsi_sell_prod_asset_reason ==2 | ///
						    llcsi_reduce_nonfood_exp == 1 | llcsi_reduce_nfood_exp_reason == 2 )
						   
	gen used_emerg_strat = (llcsi_children_ofs == 1 | llcsi_children_ofs_reason == 2 | ///
						   llcsi_sell_house == 1    | llcsi_sell_house_reason ==2    | ///
						   llcsi_beg == 1           | llcsi_beg_reason ==2)
	
	gen used_strategies = (used_stress_strat == 1 | used_crisis_strat  == 1 | used_emerg_strat == 1)

	

	
	label variable llcsi_motivation_1	 "To buy food"
	label variable llcsi_motivation_2	 "To pay the rent"
	label variable llcsi_motivation_3 	 "To pay for school, education fees"
	label variable llcsi_motivation_4 	 "To cover medical expenses"
	label variable llcsi_motivation_5 	 "To buy non-food items (clothes, small furniture...)"
	label variable llcsi_motivation_6 	 "To access water and sanitation facilities"
	label variable llcsi_motivation_7 	 "To access essential housing services (electricity, energy, waste disposal...)"
	label variable llcsi_motivation_8 	 "To pay existing debts"
	label variable llcsi_motivation_9 	 "Other, please specify"
	label variable llcsi_motivation__98  "Don't know"
	label variable llcsi_motivation__99  "Declined"
	
	

	*Labelling the new created variables		
	
	label variable used_strategies "Used at least one of the coping strategies"
	label define lused_strategies 0 "No" 1 "Yes"
	label values used_strategies lused_strategies
						   
						   
	label variable used_stress_strat "Used stress coping strategy"
	label define   lused_stress_strat 0 "No" 1 "Yes"
	label values   used_stress_strat lused_stress_strat
	
	label variable used_crisis_strat "Used crisis coping strategy"
	label define   lused_crisis_strat 0 "No" 1 "Yes"
	label values   used_crisis_strat lused_crisis_strat
	
	label variable used_emerg_strat "Used emergency coping strategy"
	label define   lused_emerg_strat 0 "No" 1 "Yes"
	label values   used_emerg_strat lused_emerg_strat
	


    gen max_coping_behavior=1 

	replace max_coping_behavior=2 if used_stress_strat==1 
	replace max_coping_behavior=3 if used_crisis_strat==1 
	replace max_coping_behavior=4 if used_emerg_strat==1 

	lab var max_coping_behavior "Summary of asset depletion" 
	lab def max_coping_behavior_label 1"HH not adopting coping strategies" 2"Stress coping strategies" ///
									  3"Crisis coping strategies" 4"Emergency coping strategies" 
									  
	lab val max_coping_behavior max_coping_behavior_label 
	tab max_coping_behavior, gen(coping_behavior)
	
	rename coping_behavior1 coping_no_strat
	rename coping_behavior2 coping_stress_strat
	rename coping_behavior3 coping_crisis_strat
	rename coping_behavior4 coping_emerg_strat
	
	
	label variable coping_no_strat     "Not using any coping strategies"
	label variable coping_stress_strat "Used stress coping strategies"
	label variable coping_crisis_strat "Used crisis coping strategies"
	label variable coping_emerg_strat  "Used emergency coping strategies"
	
	global behavior coping_no_strat coping_stress_strat coping_crisis_strat coping_emerg_strat
	
	foreach var in $behavior{
		label define l_`var' 0 "No" 1 "Yes"
		label values `var' l_`var'
	}
	
	*DEFINING SELECTION AND LOCKIN CRITERIA
******************************************************************************
	
label var cbc_widow "Proxy to household with widows (HoH is widow)"

******************************************************************************
*Setting the globals
	global tosplit  hh_type_housing		     hh_type_roof 		hh_goodcook_fuel ///
					fcs_hhs_sleep_hungry_fq  fcs_hhs_nofood_fq  fcs_hhs_24hnofood_fq ///
					hh_vil_province			 hh_vil_territory 	hhh_doc 	///
					type	   	 			 hhh_maritalstatus	hh_ethnic_group ///
					hh_status				 hh_source_income   hh_ammount_income ///
					FGVitACat 				 FGProteinCat 		FGHIronCat
	
	
	foreach var in $tosplit {
	    tab `var', gen(`var')
	}

*Arranging the labels

	 ds, has(varlabel "q*") 
	 foreach var in `r(varlist)' {
		local label : variable label `var'
		local pos = strpos("`label'", ".")
		if `pos' > 0 {
			local newlabel = substr("`label'",`pos' + 1, 200)
			label variable `var' "`newlabel'"
		}
	}
	
	
	ds, has(varlabel " How many*") 
		 
	 foreach var in `r(varlist)' {
		local label : var label `var' 
    if strpos("`label'", " How many") == 1 { 
        local label : subinstr local label " are living in the household?" ""
		local label : subinstr local label " are living in your household" ""
		local label : subinstr local label " are living in the hous" ""
		local label : subinstr local label " are living in the hou" ""
		local label : subinstr local label " are living in the" ""
		local label : subinstr local label " are living in th" ""
		local label : subinstr local label " live in the household" ""
		local label : subinstr local label "?" ""
		local label : subinstr local label " How many" "Number of"
        label var `var' "`label'" 
    }
	}
	
	
		ds, has(varlabel "1=*") 
		  
	 foreach var in `r(varlist)' {
		local label : var label `var' 
    if strpos("`label'", "1=") == 1 { 
        local label : subinstr local label "1=" ""
        label var `var' "`label'" 
    }
	}

	label variable hh_idp_kalemie "Are you from an IDP site of the city of Kalemie?"
	label variable hh_head_chronic "Does the head of HH has chronic disease?"
	
	label variable fcs_hhs_nofood "In the past 4 weeks, was there no food to eat?"
	label variable fcs_hhs_sleephungry  "In the past 4 weeks,were you or any member of your HH forced to sleep hungry?"
	label variable fcs_hhs_24hnofood "In the past 4 weeks, did you or any member of your HH go a whole day and night without eating?"
	label variable hh_sanitary "Household has a private pit latrine/improved toilet"
    
  
   **Droppig don't know and refused to answer for llcsi
	drop  llcsi_motivation_other llcsi_motivation__98 llcsi_motivation__99
	
	
******************************************************************************
	
***** Name vars similar to midline 
	
*LLCSI	
	rename llcsi_sell_hh_asset llcsi_strat_yn_1
	rename llcsi_sell_hh_asset_reason llcsi_strat_no_1  //assets
	
	rename llcsi_spend_saving llcsi_strat_yn_2
	rename llcsi_spend_saving_reason llcsi_strat_no_2 // spend savings
	
	rename llcsi_borrow llcsi_strat_yn_3
	rename llcsi_borrow_reason llcsi_strat_no_3 //bottow monay
		
	rename llcsi_send_ewhere llcsi_strat_yn_4
	rename llcsi_send_ewhere_reason llcsi_strat_no_4  // sending hh members somewhere else
	
	rename llcsi_sell_prod_asset llcsi_strat_yn_5
	rename llcsi_sell_prod_asset_reason llcsi_strat_no_5 // selling productive assetes
	
	*Note 6 at baseline was missing: sell livestock 
		
	rename llcsi_reduce_nonfood_exp llcsi_strat_yn_7  // reduce nonfood expenditures  
	rename llcsi_reduce_nfood_exp_reason llcsi_strat_no_7
	
	rename llcsi_children_ofs llcsi_strat_yn_8
	rename llcsi_children_ofs_reason llcsi_strat_no_8 // take children out of school 

	rename llcsi_sell_house llcsi_strat_yn_9
	rename llcsi_sell_house_reason llcsi_strat_no_9 // sell house or land
	
	rename llcsi_beg llcsi_strat_yn_10
	rename llcsi_beg_reason llcsi_strat_no_10 // beg


	
*FCS	
	
	rename fcs_fq_cereals  fcs_fq_1
	rename fcs_source_cereals fcs_source_1
	
	rename fcs_fq_tuber  fcs_fq_2
	rename fcs_source_tuber fcs_source_2

	rename fcs_source_legumesnuts fcs_source_3
	rename fcs_source_milk fcs_source_4
	rename fcs_source_protein fcs_source_5
	rename fcs_source_veggies fcs_source_10
	rename fcs_fq_veggies_other fcs_fq_13
	rename fcs_source_fruits fcs_source_14
	rename fcs_fq_fruits_other fcs_fq_16
	rename fcs_source_oil fcs_source_17
	rename fcs_source_sugar fcs_source_18

	
	
*	rename NumberofEnrolledBeneficiaries2 Numb_EnrolBeneficiaries2
//variable NumberofEnrolledBeneficiaries2 not found

*	rename NumberofEnrolledBeneficiaries  Numb_EnrolBeneficiaries
//variable NumberofEnrolledBeneficiaries2 not found
	label var max_coping_behavior "Max coping behavior adopted"
	
	
	
   **Saving the cleaned baseline dataset
	save "${output}baseline_final.dta", replace
	 
