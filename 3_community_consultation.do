/************************************


************************************/

*** Import community dataset ***
use "${data_bl_final}Consultations/Clean/DRC_Targeting_Committee_FGD_draft3_V1.dta", clear

*** Quick cleaning
destring block axe village, replace
drop m_fgd_criteria //this is just a prompt, doesn't give data

global criteria elderly plw women_hoh widow disabilities illness girl_mothers child_hoh no_provider paltry_shelter orphan survivor pregnant_hoh nursing_hoh 3_child ill_hoh disabled_hoh elderly_hoh

foreach i in $criteria {
	replace f_fgd_`i' = m_fgd_`i' if fgd_gender == 1 //consolidating the focus group criteria into single columns (not separated by the gender)
	rename f_fgd_`i' pmtcrit_`i' //renaming it so that the label isn't gender-specific
	drop m_fgd_`i' //dropping the male criteria columns since these are now reflected in the gender-neutral variable
}

tab block if consultation == "PMT_plus" //Three cases where the # of consultations is not 2.

replace block = 803 if block == 801 & team == 3 //there were accidentally 3 entries for block 801 when there should only be 2.  Further, block 803 only had 1 entry when there should be 2.  Team 3 appears to have been in charge of block 803, so we're changing the extra '801' to 803 where it says Team 3 was conducting the focus group.

drop if key=="uuid:42cf0f17-d4be-4a8c-80b7-af8fd85fef03" // there are three instances of block 1508 having a PMT consultation -- two for men and one for women. Enumerators confirm that this one was a test.

replace block = 1902 if block == 95 //95 is not a block id listed in the village treatment list, but the observation belongs to the same axe and village that Marcel (1902) does, which is a consultation that is currently missing.

br block consultation pmtcrit* other_criteria_cons_count - com_criteria_oth_name_cons_6

*****************************************************
** Identifying criteria by bloc: PMT TREATMENT ARM **
*****************************************************

// Starting with the PMT/Focus Group treatment arm,  we will look at the 'other' criteria from every block in this arm one-by-one, and consolidate the criteria we find below.  Note that in each case, I am only listing criteria which is NEW, not any of them which have been listed by a previously analysed block.

	sort block fgd_gender
	
	br village block fgd_gender com_criteria_other_cons - com_criteria_oth_name_cons_6 if block == 96
		**HHs headed by a widower
		gen pmtcrit_hhh_widower = 0 
		replace pmtcrit_hhh_widower = 1 if block == 96 & fgd_gender == 0
		**HHs headed/dependent on Twa
		gen pmtcrit_hhh_twa = 0
		replace pmtcrit_hhh_twa = 1 if block == 96 & fgd_gender == 0
		**HHs with fields attacked by insects
		gen pmtcrit_croploss_ins = 0
		replace pmtcrit_croploss_ins = 1 if block == 96 & fgd_gender == 1
		**Displaced households
		gen pmtcrit_displacedhh = 0
		replace pmtcrit_displacedhh = 1 if fgd_gender == 0
		**Households without seeds.... cannot create this in census data, so will leave blank.
		
	br village block fgd_gender com_criteria_other_cons - com_criteria_oth_name_cons_6 if block == 102
		**Households with malnourished children
		gen pmtcrit_malnchild = 0
		replace pmtcrit_malnchild = 1 if block == 102 & fgd_gender == 1
		**"Everyone"................................will not be included 
		**Twas
		replace pmtcrit_hhh_twa = 1 if block == 102 & fgd_gender == 0
		
	br village block fgd_gender com_criteria_other_cons - com_criteria_oth_name_cons_6 if block == 201 
		** Children living with a host family; this will be constructed the same way as 'orphan', so we'll
		*  indicate that here already.
		replace pmtcrit_orphan = 1 if block == 201 & fgd_gender == 0
		
	br village block fgd_gender com_criteria_other_cons - com_criteria_oth_name_cons_6 if block == 401 
		** Help the youth avoid stealing............will not be included as it doesn't reflect a criteria
		
	br village block fgd_gender com_criteria_other_cons - com_criteria_oth_name_cons_6 if block == 503
		** Household headed by a neglected, abandoned or separated woman
		gen pmtcrit_hhh_fsep = 0
		replace pmtcrit_hhh_fsep = 1 if block == 503 //listed by both men and women
		** Household headed by a returnee 
		gen pmtcrit_returnee = 0
		replace pmtcrit_returnee = 1 if block == 503 //listed by both men and women
		**Twa households
		replace pmtcrit_hhh_twa = 1 if block == 503 //was mentioned by both men and women
		**Household headed by an orphan/separated
		gen pmtcrit_hhh_orphan = 0
		replace pmtcrit_hhh_orphan = 1 if block == 503 & fgd_gender == 1
		**Household headed y a person with agriculture IGA
		gen pmtcrit_hhh_farmer = 0
		replace pmtcrit_hhh_farmer = 1 if block == 503 & fgd_gender == 0
		
	br village block fgd_gender com_criteria_other_cons - com_criteria_oth_name_cons_6 if block == 504
		** Household headed by a returnee
		replace pmtcrit_returnee = 1 if block == 504 & fgd_gender == 0
		** Household headed by/dependent on an orphan
		replace pmtcrit_hhh_orphan = 1 if block == 504 //listed by both men and women
		**Displaced households
		replace pmtcrit_displacedhh = 1 if block == 504 & fgd_gender == 1
		**Households hosting displaced
		gen pmtcrit_hostfamily = 0
		replace pmtcrit_hostfamily = 1 if block == 504 & fgd_gender == 1
		**Households (headed by farmer) with low ag production or profit //Note, we won't be able to specify the HHH is a farmer in census
		gen pmtcrit_ag_low = 0
		replace pmtcrit_ag_low = 1 if block == 504 & fgd_gender == 1
		
	br village block fgd_gender com_criteria_other_cons - com_criteria_oth_name_cons_6 if block == 602
		** Promoting young people in agricultural activities..............unclear if this means they want WFP to provide support for people to begin engaging in agricultural IGA (in which case, this is not a criteria), or if they mean the food assistance should be given to young people whose main IGA is agriculture.  Will not include.
		**Households helping people living in host families (i.e. host families)
		replace pmtcrit_hostfamily = 1 if block == 602 & fgd_gender == 1
		
	br village block fgd_gender com_criteria_other_cons - com_criteria_oth_name_cons_6 if block == 603
		** Twa
		replace pmtcrit_hhh_twa = 1 if block == 603 & fgd_gender == 1
		
	br village block fgd_gender com_criteria_other_cons - com_criteria_oth_name_cons_6 if block == 605
		**Households with malnourished children
		replace pmtcrit_malnchild = 1 if block == 605 & fgd_gender == 0
		**Households with several people
		gen pmtcrit_manymemb = 0
		replace pmtcrit_manymemb = 1 if block == 605 & fgd_gender == 1
		
	br village block fgd_gender com_criteria_other_cons - com_criteria_oth_name_cons_6 if block == 607
		**Kitchen inputs assistance........ will assume this means households without kitchen inputs (this shows up later as well)
		gen pmtcrit_nokitchen = 0
		replace pmtcrit_nokitchen = 1 if block == 607 & fgd_gender == 0
		**Assistance in education .... this isn't a criteria so we won't create it
		**Households that lost fields after flooding.  Will code this as natural disasters more generally (includes bushfires), since something similar shows up later.
		gen pmtcrit_croploss_nat = 0
		replace pmtcrit_croploss_nat = 1 if block == 607 & fgd_gender == 1
		
	br village block fgd_gender com_criteria_other_cons - com_criteria_oth_name_cons_6 if block == 608
		**assistance in WASH................................. this is not a criteria so it will not be included
		**asssitance to displaced
		replace pmtcrit_displacedhh = 1 if block == 608 & fgd_gender == 1
		
	br village block fgd_gender com_criteria_other_cons - com_criteria_oth_name_cons_6 if block == 609
		**Households headed by a young mother
		gen pmtcrit_young_moth = 0
		replace pmtcrit_young_moth = 1 if block == 609 & fgd_gender == 0
		**Households with no kitchen inputs
		replace pmtcrit_nokitchen = 1 if block == 609 & fgd_gender == 1
		**Households who can't pay school fees..... we can't create this from the census data so it will not be included

	br village block fgd_gender com_criteria_other_cons - com_criteria_oth_name_cons_6 if block == 611
		**Households headed by orphan
		replace pmtcrit_hhh_orphan = 1 if block == 611 & fgd_gender == 0

	br village block fgd_gender com_criteria_other_cons - com_criteria_oth_name_cons_6 if block == 701
		** Households with a lack of AME
		gen pmtcrit_noAME = 0
		replace pmtcrit_noAME = 1 if block == 701 & fgd_gender == 0
		** Households which lost property during forced displacement due to conflict
		gen pmtcrit_loss_prop = 0
		replace pmtcrit_loss_prop = 1 if block == 701 & fgd_gender == 1
		**Twa households
		replace pmtcrit_hhh_twa = 1 if block == 701 //named by both men and women
		**Households headed by a widower
		replace pmtcrit_hhh_widower = 1 if block == 701 & fgd_gender == 0
		
	br village block fgd_gender com_criteria_other_cons - com_criteria_oth_name_cons_6 if block == 702
	** BLOCK 702: DONE
		** Households headed by TWAs;
		** Households of TWAs.  These are both constructed the same way later
		replace pmtcrit_hhh_twa = 1 if block == 702 //it appeared with both men and women FGD
		** Retournee households
		replace pmtcrit_returnee = 1 if block == 702 & fgd_gender == 1
		**Households dependent on agriculture but with a low production
		replace pmtcrit_ag_low = 1 if block == 702 & fgd_gender == 1
		**Households dependent on an orphan
		replace pmtcrit_hhh_orphan = 1 if block == 702 & fgd_gender == 1
		
	br village block fgd_gender com_criteria_other_cons - com_criteria_oth_name_cons_6 if block == 801
		** Households living from agriculture with low production 	
		replace pmtcrit_ag_low = 1 if block == 801 & fgd_gender == 0
		** Twa households
		replace pmtcrit_hhh_twa = 1 if block == 801 & fgd_gender == 0
		
	br village block fgd_gender com_criteria_other_cons - com_criteria_oth_name_cons_6 if block == 803
		** Households with several children
		gen pmtcrit_manychild = 0
		replace pmtcrit_manychild = 1 if block == 803 & fgd_gender == 0
		** Twas
		replace pmtcrit_hhh_twa = 1 if block == 803 & fgd_gender == 1
		**Households with malnourished children
		replace pmtcrit_malnchild = 1 if block == 803 & fgd_gender == 0
		
	br village block fgd_gender com_criteria_other_cons - com_criteria_oth_name_cons_6 if block == 1303
		** Households with orphaned children (same construction as children living with host family)
		replace pmtcrit_orphan = 1 if block == 1303 & fgd_gender == 0
		**Twas
		replace pmtcrit_hhh_twa = 1 if block == 1303 & fgd_gender == 0
		
	br village block fgd_gender com_criteria_other_cons - com_criteria_oth_name_cons_6 if block == 1401
		** HH headed by Twa
		replace pmtcrit_hhh_twa = 1 if block == 1401 & fgd_gender == 0
		**Households where fields were attacked by insects
		replace pmtcrit_croploss_ins = 1 if block == 1401 & fgd_gender == 1
	
	br village block fgd_gender com_criteria_other_cons - com_criteria_oth_name_cons_6 if block == 1403
		** HHs with food seeds deficiency for Agriculture
		** Households headed by Twas
		replace pmtcrit_hhh_twa = 1 if block == 1403 & fgd_gender == 1
		**Households lacking AME after displacement or return
		replace pmtcrit_noAME = 1 if block == 1403 & fgd_gender == 1
		**Household headed by a widower
		replace pmtcrit_hhh_widower = 1 if block == 1403 & fgd_gender == 1
	
	br village block fgd_gender com_criteria_other_cons - com_criteria_oth_name_cons_6 if block == 1501
		** Households headed by Twa
		replace pmtcrit_hhh_twa = 1 if block == 1501 //both men and women
		**Households with albino children.... can't make this in the census so won't include
		**Households whose fields were attacked by insects
		replace pmtcrit_croploss_ins = 1 if block == 1501 & fgd_gender == 1
		**Households with malnourished children and women.... will do it for children only since this is mentioned elsewhere
		replace pmtcrit_malnchild = 1 if block == 1501 & fgd_gender == 0
	
	br village block fgd_gender com_criteria_other_cons - com_criteria_oth_name_cons_6 if block == 1505
		** Household headed by Twa
		replace pmtcrit_hhh_twa = 1 if block == 1505 & fgd_gender == 0
		** Household dependent on an ag IGA.  Later on in census we use the 'main agricultural activity' to represent HH and also head of HH 
		replace pmtcrit_hhh_farmer = 1 if block == 1505 & fgd_gender == 0
		**Household dependent on a widower
		replace pmtcrit_hhh_widower = 1 if block == 1505 & fgd_gender == 0
		
	br village block fgd_gender com_criteria_other_cons - com_criteria_oth_name_cons_6 if block == 1507
		** Households headed by Twa
		replace pmtcrit_hhh_twa = 1 if block == 1507 //both men and women
		** Households with malnourished children
		replace pmtcrit_malnchild = 1 if block == 1507 & fgd_gender == 0
		** Households headed by a person dependent on ag
		replace pmtcrit_hhh_farmer = 1 if block == 1507 & fgd_gender == 0
	
	br village block fgd_gender com_criteria_other_cons - com_criteria_oth_name_cons_6 if block == 1508
		** HHs with malnourished children
		replace pmtcrit_malnchild = 1 if block == 1508 & fgd_gender == 0

	br village block fgd_gender com_criteria_other_cons - com_criteria_oth_name_cons_6 if block == 1509
		** HHs headed by TWAs
		replace pmtcrit_hhh_twa = 1 if block == 1509 //both men and women
		** HHs headed by divorced woman
		gen pmtcrit_fdivorced = 0
		replace pmtcrit_fdivorced = 1 if block == 1509 & fgd_gender == 1
		
	br village block fgd_gender com_criteria_other_cons - com_criteria_oth_name_cons_6 if block == 1511
		** HHs headed by Twas
		replace pmtcrit_hhh_twa = 1 if block == 1511 & fgd_gender == 0

	br village block fgd_gender com_criteria_other_cons - com_criteria_oth_name_cons_6 if block == 1601
		** HHS whose fields were attacked by insects
		replace pmtcrit_croploss_ins = 1 if block == 1601 & fgd_gender == 1

	br village block fgd_gender com_criteria_other_cons - com_criteria_oth_name_cons_6 if block == 1606
	** BLOCK 1606: DONE
		**  and HHs with displaced dependant children living in host families) //this will be contructed as orphan/separated children
		replace pmtcrit_orphan = 1 if block == 1606 //it actualy already is indicated there as one. They just said it for 'other' criteria as well.
		** HHs headed by Twa
		replace pmtcrit_hhh_twa = 1 if block == 1606 & fgd_gender == 1
		** HHs dependent on widower
		replace pmtcrit_hhh_widower = 1 if block == 1606 & fgd_gender == 1
		** Displaced households
		replace pmtcrit_displacedhh = 1 if block == 1606 & fgd_gender == 1

	br village block fgd_gender com_criteria_other_cons - com_criteria_oth_name_cons_6 if block == 1610
		** BLOCK 1610: none

	br village block fgd_gender com_criteria_other_cons - com_criteria_oth_name_cons_6 if block == 2013
		** HHs headed by Twa
		replace pmtcrit_hhh_twa = 1 if block == 2013 //both men and women
		** (Note: Also mentioned HHs with orphans and HHs headed by TWAs)
		replace pmtcrit_orphan = 1 if block == 2013 & fgd_gender == 1
		** Host families
		replace pmtcrit_hostfamily = 1 if block == 2013 & fgd_gender == 0
		
	br village block fgd_gender com_criteria_other_cons - com_criteria_oth_name_cons_6 if block == 2101
		** HHs headed by Twas
		replace pmtcrit_hhh_twa = 1 if block == 2101 //both men and women
		** Host families
		replace pmtcrit_hostfamily = 1 if block == 2101 & fgd_gender == 0
		** Households headed by divorced woman
		replace pmtcrit_fdivorced = 1 if block == 2101 & fgd_gender == 1
		
		
	br village block fgd_gender com_criteria_other_cons - com_criteria_oth_name_cons_6 if block == 2201
		** HHs headed by Twa
		replace pmtcrit_hhh_twa = 1 if block == 2201 & fgd_gender == 1
		
///Order and then replace all of the new 'pmtcrit_*' as missing if they're not in the PMT category.
global temp hhh_widower hhh_twa croploss_ins displacedhh malnchild hhh_fsep returnee hhh_orphan hhh_farmer hostfamily ag_low manymemb nokitchen croploss_nat young_moth noAME loss_prop manychild fdivorced

foreach i of local temp {
	order pmtcrit_`i', after(pmtcrit_elderly_hoh)
	replace pmtcrit_`i' = . if consultation != "PMT_plus"
}



*****************************************************
** PRODUCING SCENARIOS FOR USE OF LOCK-IN CRITERIA **
*****************************************************

	egen criteria_sum1 = rowtotal(pmtcrit_*) if consultation == "PMT_plus" 
	sum criteria_sum1 //average of 9.6 criteria mentioned by focus groups
	
	preserve
		collapse (max) pmtcrit_* (first) consultation, by(block)	//collapse the two focus groups into each other
			egen criteria_total = rowtotal(pmtcrit_*) if consultation == "PMT_plus"  //now do the same thing as above, grouping for the whole block
			sum criteria_total //average of 14 criteria it looks like.  Minimum is 10 and max is 20.

			/// Now we sum up each of the criteria to see which ones were ever mentioned:
			foreach i in $criteria {
				egen pmttotal_`i' = total(pmtcrit_`i') if consultation == "PMT_plus" //this tells us the sum of PMT communities that listed each preprogrammed criteria
			}

			foreach i in $temp {
				egen pmttotal_`i' = total(pmtcrit_`i') if consultation == "PMT_plus" //this tells us the sum of PMT communities that listed each other criteria
			}
						
	///SCENARIO 1 | We randomly sample three PMT blocks, and choose the criteria listed in their consultations.
			set seed 9102019 //seed is date of publication of WFP IE Strategy <3
			gen rand = uniform() if consultation == "PMT_plus" //generate a random number for all PMT consultations
			sort rand //sort them in order from least to greatest. 
			list block if _n <=3 //these are the three blocks we will look at: 1501, 102, 1508

			sort block
			br if inlist(block, 1501, 102, 1508)
			
			foreach i in $criteria {
				egen smpl_total_`i' = total(pmtcrit_`i') if inlist(block,1501,102,1508)
			}
			foreach i in $temp {
				egen smpl_total_`i' = total(pmtcrit_`i') if inlist(block,1501,102,1508)
			}
			
			br smpl_total_* if block == 1501
			
			*global for all the criteria listed in any sampled consultation (union, where smpl_total_* > 0)
			global top_pmt_smpl1 elderly plw women_hoh disabilities illness no_provider paltry_shelter orphan /*survivor*/ pregnant_hoh nursing_hoh 3_child ill_hoh disabled_hoh elderly_hoh hhh_twa croploss_ins displacedhh malnchild
			
			*global for the common criteria listed between blocks (intersection)
			global top_pmt_smpl2 no_provider orphan pregnant_hoh ill_hoh disabled_hoh elderly_hoh displacedhh malnchild

			
	///SCENARIO 2 | Let's find out how many criteria the communities name, on average
			**I did this in excel 
*			collapse (first) pmttotal_*
*			export excel "$output/criteria_frequencies_PMT", firstrow(var) replace
			
			*According to the spreadsheet generated above, these would be:
			global top_pmt_14 no_provider elderly_hoh displacedhh disabled_hoh orphan ill_hoh disabilities pregnant_hoh women_hoh hhh_twa illness paltry_shelter plw nursing_hoh

			*Note that a few of these are redundant.  For example, plw will by definition include pregnant_hoh.  We will keep all of them like this just in case there is an error in the data where one or the other is missed.

	///SCENARIO 3 | According to the sub-office, previous consultations resulted in 9 criteria that were used as lock-ins.  If we mimic this and take the top 9:
			global top_pmt_9 no_provider elderly_hoh displacedhh disabled_hoh orphan ill_hoh disabilities pregnant_hoh women_hoh

restore
	drop criteria_sum1 // don't need anymore.
	
	
****************************************************
** Identifying criteria by bloc: CB TREATMENT ARM **
****************************************************

// Presence indicator = whether community said it was a relevant criteria or not
// Weight indicator = how important the community thinks that criteria is
// Household indicator = whether or not an individual household displays that criteria


//Now with the Committee treatment arm
	sort block
	**Since these should have only one bloc per observation, check for duplicates:
	duplicates tag block, gen(dup)
	tab dup if consultation == "CBT" // CHECK HERE THAT THERE ARE NO DUPLICATES
	drop dup 
	
**INSTRUCTIONS FOR THIS SECTION:
** 1) Look at all of the 'other' criteria that was listed in the community.  
** 2) If the criteria has not yet been listed previously in the do-file, create a binary variable that indicates whether that criteria was listed, in the form of com_(name)
** 3) Set that binary variable equal to one for the block you are looking at.
** 4) Then, create a weighting variable where the weight/importance of that criteria is held.  BE CAREFUL HERE! Pay attention to which 'other' criteria is being scored!  Name this in the form of rank_(name)
** 5) IF the criteria you're looking at HAS in fact been listed previously in the do-file, then simply replace the (already created) binary indicator with a one, and fill the score variable with the relevant weight.
** LATER: we will create the actual indicators that would represent the criteria.  But for now, we just want to know whether the criteria was named (yes/no), and its weight.

	**BLOCK 1902
	br village block com_elderly-rank_elderly_hoh if block == 1902 
	** Other criteria: 
		** Household headed or dependent on an orphan: hhh_orph (we will decide what to name this variable now, but will construct it in the census later...)
		gen com_hhh_orphan = 0 //(...so that we can already construct its yes/no for presence of the criteria... )
		lab var com_hhh_orphan "Household headed by an orphan"
		replace com_hhh_orphan = 1 if block == 1902
		order com_hhh_orphan, after(com_elderly_hoh)
		
		gen rank_hhh_orphan = 0 //(... and the variable for its _weight_ here.)
		replace rank_hhh_orphan = com_criteria_note_1 if block == 1902
		order rank_hhh_orphan, after(rank_elderly_hoh)
		
		** Household headed or dependent on a widower
		gen com_hhh_widower = 0 
		lab var com_hhh_widower "Households headed by a widower"
		replace com_hhh_widower = 1 if block == 1902
		order com_hhh_widower, after(com_elderly_hoh)
		
		gen rank_hhh_widower = 0 //(... and the variable for its _weight_ here.)
		replace rank_hhh_widower = com_criteria_note_2 if block == 1902
		order rank_hhh_widower, after(rank_elderly_hoh)
		
		** Household headed or dependent on a TWA
		gen com_hhh_twa = 0
		lab var com_hhh_twa "Households headed by Twa"
		replace com_hhh_twa = 1 if block == 1902
		order com_hhh_twa, after(com_elderly_hoh)
		
		gen rank_hhh_twa = 0
		replace rank_hhh_twa = com_criteria_note_3 if block == 1902
		order rank_hhh_twa, after(rank_elderly_hoh)
	
	**BLOCK 101: DONE
	br village block com_elderly-rank_elderly_hoh if block == 101 
	** Other criteria: 
		** Household headed by a widower
		replace com_hhh_widower = 1 if block == 101
		replace rank_hhh_widower = com_criteria_note_1 if block == 101
		
		** Household headed by a young person with chronic illness or disability: hhh_young_illdis
		gen com_hhh_young_illdis = 0
		lab var com_hhh_young_illdis "Household headed by a young person with chronic illness or disability"
		replace com_hhh_young_illdis = 1 if block == 101
		order com_hhh_young_illdis, after(com_elderly_hoh)
		
		gen rank_hhh_young_illdis = 0
		replace rank_hhh_young_illdis = com_criteria_note_2 if block == 101
		order rank_hhh_young_illdis, after(rank_elderly_hoh)
		
		
	**BLOCK 202: DONE
	br village block com_elderly-rank_elderly_hoh if block == 202 
	** Other criteria:
		** Household headed by a divorced woman
		gen com_hhh_fdivorced = 0
		lab var com_hhh_fdivorced "Household headed by divorced woman"
		replace com_hhh_fdivorced = 1 if block == 202
		order com_hhh_fdivorced, after(com_elderly_hoh)
		
		gen rank_hhh_fdivorced = 0
		replace rank_hhh_fdivorced = com_criteria_note_1 if block == 202
		order rank_hhh_fdivorced, after(rank_elderly_hoh)
		
		** Household headed or dependent on a person without income generating activity
		gen com_noIGA = 0
		lab var com_noIGA "Household dependent on a person with no IGA"
		replace com_noIGA = 1 if block == 202
		order com_noIGA, after(com_elderly_hoh)
		
		gen rank_noIGA = 0
		replace rank_noIGA = com_criteria_note_2 if block == 202
		order rank_noIGA, after(rank_elderly_hoh)
		
		
	**BLOCK 203: 
	br village block com_elderly-rank_elderly_hoh if block == 203 
	** Other criteria:
		** Household headed by an orphan
		replace com_hhh_orphan = 1 if block == 203
		replace rank_hhh_orphan = com_criteria_note_1 if block == 203
		
		** Household headed by a farmer
		gen com_hhh_farmer = 0
		lab var com_hhh_farmer "Households headed by farmer"
		replace com_hhh_farmer = 1 if block == 203
		order com_hhh_farmer, after(com_elderly_hoh)
		
		gen rank_hhh_farmer = 0
		replace rank_hhh_farmer = com_criteria_note_2 if block == 203
		order rank_hhh_farmer, after(rank_elderly_hoh)
		
	**BLOCK 301: 
	br village block com_elderly-rank_elderly_hoh if block == 301
	** Other criteria: NONE
	
	**BLOCK 501: 
	br village block com_elderly-rank_elderly_hoh if block == 501
	** Other criteria: 
		** Household headed by an older widow 
		gen com_hhh_eldwidow = 0
		lab var com_hhh_eldwidow "Households headed by older widow"
		replace com_hhh_eldwidow = 1 if block == 501
		order com_hhh_eldwidow, after(com_elderly_hoh)
		
		gen rank_hhh_eldwidow = 0
		replace rank_hhh_eldwidow = com_criteria_note_1 if block == 501
		order rank_hhh_eldwidow, after(rank_elderly_hoh)
		
		** Household headed by a single pregnant orphan girl
		gen com_hhh_orphsingpreg = 0
		lab var com_hhh_orphsingpreg "Households headed by an unmarried pregnant orphan"
		replace com_hhh_orphsingpreg = 1 if block == 501
		order com_hhh_orphsingpreg, after(com_elderly_hoh)
		
		gen rank_hhh_orphsingpreg = 0
		replace rank_hhh_orphsingpreg = com_criteria_note_2 if block == 501
		order rank_hhh_orphsingpreg, after(rank_elderly_hoh)
		
		** Households headed by Twa
		replace com_hhh_twa = 1 if block == 501
		replace rank_hhh_twa = com_criteria_note_3 if block == 501
	
	**BLOCK 502: 
	br village block com_elderly-rank_elderly_hoh if block == 502
	** Other criteria:
		** Household headed (or dependent on) a young person
		gen com_hhh_youth = 0
		lab var com_hhh_youth "Household headed by a young person"
		replace com_hhh_youth = 1 if block == 502
		order com_hhh_youth, after(com_elderly_hoh)
		
		gen rank_hhh_youth = 0
		replace rank_hhh_youth = com_criteria_note_1 if block == 502
		order rank_hhh_youth, after(rank_elderly_hoh)
		
		** Household headed by an orphan
		replace com_hhh_orphan = 1 if block == 502
		replace rank_hhh_orphan = com_criteria_note_1 if block == 502
		
		** Household headed by a widower
		replace com_hhh_widower = 1 if block == 502
		replace rank_hhh_widower = com_criteria_note_1 if block == 502	
		
		** Household headed by a divorced woman
		replace com_hhh_fdivorced = 1 if block == 502 //this criteria showed up in block 202 already, so we only need to replace the variable already generated.
		replace rank_hhh_fdivorced = com_criteria_note_4 if block == 502 //ditto.
	
	**BLOCK 505: 
	br village block com_elderly-rank_elderly_hoh if block == 505
	** Other criteria:
		** Households that have houses with straw roofs
		gen com_strawroof = 0
		lab var com_strawroof "Houses with a straw roof"
		replace com_strawroof = 1 if block == 505
		order com_strawroof, after(com_elderly_hoh)
		
		gen rank_strawroof = 0
		replace rank_strawroof = com_criteria_note_1 if block == 505
		order rank_strawroof, after(rank_elderly_hoh)
		
		** Households headed by a young person with a less profitable activity
		gen com_hhh_young_lowIGA = 0
		lab var com_hhh_young_lowIGA "Households headed by young person with less profitable activity"
		replace com_hhh_young_lowIGA = 1 if block == 505
		order com_hhh_young_lowIGA, after(com_elderly_hoh)
		
		gen rank_hhh_young_lowIGA = 0
		replace rank_hhh_young_lowIGA = com_criteria_note_2 if block == 505
		order rank_hhh_young_lowIGA, after(rank_elderly_hoh)
		
	**BLOCK 506: 
	br village block com_elderly-rank_elderly_hoh if block == 506
	** Other criteria:
		** Household headed by a Twa
		replace com_hhh_twa = 1 if block == 506
		replace rank_hhh_twa = com_criteria_note_1 if block == 506		
		
	**BLOCK 507
	br village block com_elderly-rank_elderly_hoh if block == 507
	** Other criteria:
		** Households that received people on the move (host households)
		gen com_hostfamily = 0
		lab var com_hostfamily "Households that host migrant/displaced people"
		replace com_hostfamily = 1 if block == 507
		order com_hostfamily, after(com_elderly_hoh)
		
		gen rank_hostfamily = 0
		replace rank_hostfamily = com_criteria_note_1 if block == 507
		order rank_hostfamily, after(rank_elderly_hoh)
		
		** Households that lost their fields following natural disasters (floods, bushfire)
		gen com_croploss_nat = 0
		lab var com_croploss_nat "Households that lost their fields from natural disaster"
		replace com_croploss_nat = 1 if block == 507
		order com_croploss_nat, after(com_elderly_hoh)
		
		gen rank_croploss_nat = 0
		replace rank_croploss_nat = com_criteria_note_2 if block == 507
		order rank_croploss_nat, after(rank_elderly_hoh)
	
	**BLOCK 510: 
	br village block com_elderly-rank_elderly_hoh if block == 510
	** Other criteria:
		** "Assistance to the Twa ethnic group"; assuming this can be written as a criteria that the household head is Twa
		replace com_hhh_twa = 1 if block == 510
		replace rank_hhh_twa = com_criteria_note_1 if block == 510	
		
		** "Assistance for the whole bloc"; won't use this as a criteria
		** Assistance to those displaced by war living with host families
		replace com_hostfamily = 1 if block == 510
		replace rank_hostfamily = com_criteria_note_3 if block == 510

	
	**BLOCK 511: 
	br village block com_elderly-rank_elderly_hoh if block == 511	
	** Other criteria:
		** Household headed by a Twa
		replace com_hhh_twa = 1 if block == 511
		replace rank_hhh_twa = com_criteria_note_1 if block == 511	
		
	**BLOCK 512: 
	br village block com_elderly-rank_elderly_hoh if block == 512	
	** Other criteria: NONE
	
	**BLOCK 601: 
	br village block com_elderly-rank_elderly_hoh if block == 601	
	** Other criteria: NONE
	
	**BLOCK 604: 
	br village block com_elderly-rank_elderly_hoh if block == 604
	** Other criteria: 
		** People in a host family
		replace com_hostfamily = 1 if block == 604
		replace rank_hostfamily = com_criteria_note_1 if block == 604
		
		** "Assist all the households in the village"
		** Households with malnourished children
		gen com_malnchild = 0
		lab var com_malnchild "Households with malnourished children"
		replace com_malnchild = 1 if block == 604
		order com_malnchild, after(com_elderly_hoh)
		
		gen rank_malnchild = 0
		replace rank_malnchild = com_criteria_note_3 if block == 604
		order rank_malnchild, after(rank_elderly_hoh)
	
	**BLOCK 606: 
	br village block com_elderly-rank_elderly_hoh if block == 606	
	** Other criteria:
		** Households whose fields were destroyed by insects (?)
		gen com_croploss_ins = 0
		lab var com_croploss_ins "Households that lost fields from insects"
		replace com_croploss_ins = 1 if block == 606
		order com_croploss_ins, after(com_elderly_hoh)
		
		gen rank_croploss_ins = 0
		replace rank_croploss_ins = com_criteria_note_1 if block == 606
		order rank_croploss_ins, after(rank_elderly_hoh)
		
		** Host families
		replace com_hostfamily = 1 if block == 606
		replace rank_hostfamily = com_criteria_note_2 if block == 606
		
		** Households headed by Twa
		replace com_hhh_twa = 1 if block == 606
		replace rank_hhh_twa = com_criteria_note_3 if block == 606			
	
	**BLOCK 610: 
	br village block com_elderly-rank_elderly_hoh if block == 610
	** Other criteria:
		** Household headed by Twa
		replace com_hhh_twa = 1 if block == 610
		replace rank_hhh_twa = com_criteria_note_1 if block == 610	
		
	**BLOCK 703: 
	br village block com_elderly-rank_elderly_hoh if block == 703	
	** Other criteria:
		** Household headed by Twa
		replace com_hhh_twa = 1 if block == 703
		replace rank_hhh_twa = com_criteria_note_1 if block == 703	
		
		** Households whose fields were destroyed by insects
		replace com_croploss_ins = 1 if block == 703
		replace rank_croploss_ins = com_criteria_note_2 if block == 703
	
	**Block 1101	
	br village block com_elderly-rank_elderly_hoh if block == 1101
	** Other criteria:
		** Household headed by Twas
		replace com_hhh_twa = 1 if block == 1101
		replace rank_hhh_twa = com_criteria_note_1 if block == 1101
		
		** Households whose fields were attacked by insects
		replace com_croploss_ins = 1 if block == 1101
		replace rank_croploss_ins = com_criteria_note_2 if block == 1101
	
	**BLOCK 1301: 
	br village block com_elderly-rank_elderly_hoh if block == 1301	
	** Other criteria:
		** Twa households
		replace com_hhh_twa = 1 if block == 1301
		replace rank_hhh_twa = com_criteria_note_1 if block == 1301	
		
		** "all households of the village"
	
	**BLOCK 1302: 
	br village block com_elderly-rank_elderly_hoh if block == 1302	
	** Other criteria:
		** Households headed by Twa
		replace com_hhh_twa = 1 if block == 1302
		replace rank_hhh_twa = com_criteria_note_1 if block == 1302
		
		** Displaced households
		gen com_displacedhh = 0
		lab var com_displacedhh "Displaced households"
		replace com_displacedhh = 1 if block == 1302
		order com_displacedhh, after(com_elderly_hoh)
		
		gen rank_displacedhh = 0
		replace rank_displacedhh = com_criteria_note_2 if block == 1302
		order rank_displacedhh, after(rank_elderly_hoh)
		
		** Households that are dependent on agriculture, that have low production due to anomalies
		gen com_ag_low = 0
		lab var com_ag_low "Households dependent on agriculture, had low production for anomalies"
		replace com_ag_low = 1 if block == 1302
		order com_ag_low, after(com_elderly_hoh)
		
		gen rank_ag_low = 0
		replace rank_ag_low = com_criteria_note_3 if block == 1302
		order rank_ag_low, after(rank_elderly_hoh)		
		
		** Households dependent on a young person without an IGA
		// Note: this is not exactly, but very similar to one we generated above (low IGA vs. no IGA).
		// Since this variable will likely be generated from the census in the same way for both, 
		// we'll keep them under the same variables here.
		replace com_hhh_young_lowIGA = 1 if block == 1302
		replace rank_hhh_young_lowIGA = com_criteria_note_4 if block == 1302

	**BLOCK 1402
	br village block com_elderly-rank_elderly_hoh if block == 1402	
	** Other criteria:
		** Households headed by a widower
		replace com_hhh_widower = 1 if block == 1402
		replace rank_hhh_widower = com_criteria_note_2 if block == 1402
		
		** Household headed by a young person without remunerated activity
		replace com_hhh_young_lowIGA = 1 if block == 1402
		replace rank_hhh_young_lowIGA = com_criteria_note_3 if block == 1402	
		
	**BLOCK 1502
	br village block com_elderly-rank_elderly_hoh if block == 1502	
	** Other criteria:
		** Households headed by a TWA
		replace com_hhh_twa = 1 if block == 1502
		replace rank_hhh_twa = com_criteria_note_1 if block == 1502
		
		** Households with severely malnourished children
		replace com_malnchild = 1 if block == 1502
		replace rank_malnchild = com_criteria_note_2 if block == 1502

	**BLOCK 1503
	br village block com_elderly-rank_elderly_hoh if block == 1503
	** Other criteria:
		** Households headed or dependent on a widower
		replace com_hhh_widower = 1 if block == 1503
		replace rank_hhh_widower = com_criteria_note_1 if block == 1503
		
		** Households headed or dependent on a TWA
		replace com_hhh_twa = 1 if block == 1503
		replace rank_hhh_twa = com_criteria_note_2 if block == 1503
		
		** Households living from a remunerated agricultural activity
		gen com_agIGA = 0
		lab var com_agIGA "Households with agriculture as remunerated activity"
		replace com_agIGA = 1 if block == 1503
		order com_agIGA, after(com_elderly_hoh)
		
		gen rank_agIGA = 0
		replace rank_agIGA = com_criteria_note_3 if block == 1503
		order rank_agIGA, after(rank_elderly_hoh)

	**BLOCK 1504
	br village block com_elderly-rank_elderly_hoh if block == 1504
	** Other criteria:
		** Displaced households in host families
		replace com_hostfamily = 1 if block == 1504
		replace rank_hostfamily = com_criteria_note_2 if block == 1504

	**BLOCK 1510
	br village block com_elderly-rank_elderly_hoh if block == 1510
	** Other criteria:
		** Households headed by a TWA
		replace com_hhh_twa = 1 if block == 1510
		replace rank_hhh_twa = com_criteria_note_1 if block == 1510
		
		** HOUSEHOLDS HEADED BY A WOMAN HAVING SUFFERED SEXUAL VIOLENCE: can't get this information but it has a spot already
		replace com_survivor = 1 if block == 1510 
		replace rank_survivor = com_criteria_note_2 if block == 1510		
		
		** HOUSEHOLDS WITH PERSONS DISPLACED BY WAR/CONFLICT IN HOST FAMILY
		replace com_hostfamily = 1 if block == 1510
		replace rank_hostfamily = com_criteria_note_3 if block == 1510		

	**BLOCK 1512
	br village block com_elderly-rank_elderly_hoh if block == 1512
	** Other criteria:
		** Household headed or dependent on a Twa
		replace com_hhh_twa = 1 if block == 1512
		replace rank_hhh_twa = com_criteria_note_1 if block == 1512
		
		** Household headed by an orphan child
		replace com_hhh_orphan = 1 if block == 1512
		replace rank_hhh_orphan = com_criteria_note_2 if block == 1512
		
	**BLOCK 1608
	br village block com_elderly-rank_elderly_hoh if block == 1608
	** Other criteria:
		** Households headed by a TWA
		replace com_hhh_twa = 1 if block == 1608
		replace rank_hhh_twa = com_criteria_note_1 if block == 1608
		
		** Households headed by an Orphan
		replace com_hhh_orphan = 1 if block == 1608
		replace rank_hhh_orphan = com_criteria_note_2 if block == 1608

	**BLOCK 1612
	br village block com_elderly-rank_elderly_hoh if block == 1612
	** Other criteria:
		** No other criteria listed

	**BLOCK 1701
	br village block com_elderly-rank_elderly_hoh if block == 1701
	** Other criteria:
		** Households headed or dependent on a Twa
		replace com_hhh_twa = 1 if block == 1701
		replace rank_hhh_twa = com_criteria_note_1 if block == 1701
		
		** Households headed or dependent on an orphan child
		replace com_hhh_orphan = 1 if block == 1701
		replace rank_hhh_orphan = com_criteria_note_2 if block == 1701

	**BLOCK 1901
	br village block com_elderly-rank_elderly_hoh if block == 1901
	** Other criteria:
		** Female-headed households with no children (sterile)
		gen com_hhh_femnochild = 0
		lab var com_hhh_femnochild "Households headed by women with no children (sterile)"
		replace com_hhh_femnochild = 1 if block == 1901
		order com_hhh_femnochild, after(com_elderly_hoh)
		
		gen rank_hhh_femnochild = 0
		replace rank_hhh_femnochild = com_criteria_note_1 if block == 1901
		order rank_hhh_femnochild, after(rank_elderly_hoh)
		
		** Households headed by a TWA
		replace com_hhh_twa = 1 if block == 1901
		replace rank_hhh_twa = com_criteria_note_2 if block == 1901
		
        ** Households with malnourished children
		replace com_malnchild = 1 if block == 1901
		replace rank_malnchild = com_criteria_note_3 if block == 1901
		
	**BLOCK 2001
	br village block com_elderly-rank_elderly_hoh if block == 2001
	** Other criteria:
		** Households headed by a TWA
		replace com_hhh_twa = 1 if block == 2001
		replace rank_hhh_twa = com_criteria_note_1 if block == 2001
		
		** Household with malnourished children
		replace com_malnchild = 1 if block == 2001
		replace rank_malnchild = com_criteria_note_2 if block == 2001
	
		** Household having received people on the move (host households)
		replace com_hostfamily = 1 if block == 2001
		replace rank_hostfamily = com_criteria_note_3 if block == 2001
		
		** Household having lost their fields following natural disasters (floods, bushfire)
		replace com_croploss_nat = 1 if block == 2001
		replace rank_croploss_nat = com_criteria_note_4 if block == 2001

	**BLOCK 2014
	br village block com_elderly-rank_elderly_hoh if block == 2014
	** Other criteria:
		** Households headed by Twas
		replace com_hhh_twa = 1 if block == 2014
		replace rank_hhh_twa = com_criteria_note_1 if block == 2014
		
		**Households headed by displaced person
		replace com_displacedhh = 1 if block == 2014
		replace rank_displacedhh = com_criteria_note_2 if block == 2014
		
		**Household with victims of sexual violence (can't make this one in census but will log here)
		replace com_survivor = 1 if block == 2014
		replace rank_survivor = com_criteria_note_3 if block == 2014 		
		
		**Households with low ag output after conflict
		replace com_ag_low = 1 if block == 2014
		replace rank_ag_low = com_criteria_note_4 if block == 2014
		
	**BLOCK 2602
	br village block com_elderly-rank_elderly_hoh if block == 2602	
	** Other criteria:
		** Internally displaced living with host families
		replace com_hostfamily = 1 if block == 2602
		replace rank_hostfamily = com_criteria_note_1 if block == 2602
		
		**Households with low ag output ater conflict or population movement
		replace com_ag_low = 1 if block == 2602
		replace rank_ag_low = com_criteria_note_2 if block == 2602
	
	**BLOCK 2608
	br village block com_elderly-rank_elderly_hoh if block == 2608
	** Other criteria:
		** Household where head of household is victim of sexual violence 
		replace com_survivor = 1 if block == 2608
		replace rank_survivor = com_criteria_note_1 if block == 2608
		
		**Household headed by Twa
		replace com_hhh_twa = 1 if block == 2608
		replace rank_hhh_twa = com_criteria_note_2 if block == 2608
		
		**Households with unaccompanied displaced children/orphans
		replace com_orphan = 1 if block == 2608
		replace rank_orphan = com_criteria_note_3 if block == 2608
		
		**Households with fields attacked by bush fire  // will code this in the broader 'natural disasters' category that includes floods
		replace com_croploss_nat = 1 if block == 2608
		replace rank_croploss_nat = com_criteria_note_4 if block == 2608
	
	**BLOCK 2701
	br village block com_elderly-rank_elderly_hoh if block == 2701
	** Other criteria	
		** Household head by Twa
		replace com_hhh_twa = 1 if block == 2701
		replace rank_hhh_twa = com_criteria_note_1 if block == 2701
		
		**Household headed by a widower
		replace com_hhh_widower = 1 if block == 2701
		replace rank_hhh_widower = com_criteria_note_2 if block == 2701
		
		**Household headed by victim of sexual violence
		replace com_survivor = 1 if block == 2701
		replace rank_survivor = com_criteria_note_3 if block == 2701
		
		**Households displaced with host families
		replace com_hostfamily = 1 if block == 2701
		replace rank_hostfamily = com_criteria_note_4 if block == 2701
		
		**Households whose fields were attached by bush fire
		replace com_croploss_nat = 1 if block == 2701
		replace rank_croploss_nat = com_criteria_note_5 if block == 2701

		**Household headed by an orphan
		replace com_hhh_orphan = 1 if block == 2701
		replace rank_hhh_orphan = com_criteria_note_6 if block == 2701
		**Households without potable water
		gen com_no_water = 0 
		lab var com_no_water "Households with no potable water"
		replace com_no_water = 1 if block == 2701
		order com_no_water, after(com_elderly_hoh)
		
		gen rank_no_water = 0
		replace rank_no_water = com_criteria_note_7 if block == 2701
		order rank_no_water, after(rank_elderly_hoh)
	
	**BLOCK 2707
	br village block com_elderly-rank_elderly_hoh if block == 2707
	** Other criteria:
		** Household headed by displaced person
		replace com_displacedhh = 1 if block == 2707
		replace rank_displacedhh = com_criteria_note_1 if block == 2707
		
		** Households with malnourished children
		replace com_malnchild = 1 if block == 2707
		replace rank_malnchild = com_criteria_note_2 if block == 2707
		
		** Households with victims of sexual violence
		replace com_survivor = 1 if block == 2707
		replace rank_survivor = com_criteria_note_3 if block == 2707
		
		** Households with fields attacked by insects
		replace com_croploss_ins = 1 if block == 2707
		replace rank_croploss_ins = com_criteria_note_4 if block == 2707
	
	
	**BLOCK 2711
	br village block com_elderly-rank_elderly_hoh if block == 2711	
		** Households where the HHH is a victim of sexual violence
		replace com_survivor = 1 if block == 2711
		replace rank_survivor = com_criteria_note_1 if block == 2711
		
		** Households headed by a displaced person
		replace com_displacedhh = 1 if block == 2711
		replace rank_displacedhh = com_criteria_note_2 if block == 2711
		
	**BLOCK 2801
	br village block com_elderly-rank_elderly_hoh if block == 2801
		**Households with malnourished children
		replace com_malnchild = 1 if block == 2801
		replace rank_malnchild = com_criteria_note_1 if block == 2801
		
		**Households with victims of sexual violence
		replace com_survivor = 1 if block == 2801
		replace rank_survivor = com_criteria_note_2 if block == 2801
		
		**Displaced households with host families
		replace com_hostfamily = 1 if block == 2801
		replace rank_hostfamily = com_criteria_note_3 if block == 2801
		
		**Households without potable water
		replace com_no_water = 1 if block == 2801
		replace rank_no_water = com_criteria_note_4 if block == 2801
	
	**3002 //This one isn't going to be used in the analysis since there is no census data.
	
	**BLOCK 3101
	br village block com_elderly-rank_elderly_hoh if block == 3101
		**Households headed by Twa
		replace com_hhh_twa = 1 if block == 3101
		replace rank_hhh_twa = com_criteria_note_1 if block == 3101
		
		**Households with malnourished children
		replace com_malnchild = 1 if block == 3101
		replace rank_malnchild = com_criteria_note_2 if block == 3101
		
		
	**BLOCK 3602
	br village block com_elderly-rank_elderly_hoh if block == 3602	
		**Households headed by displaced person
		replace com_displacedhh = 1 if block == 3602
		replace rank_displacedhh = com_criteria_note_1 if block == 3602
		
		**Households with displaced living in host family
		replace com_hostfamily = 1 if block == 3602
		replace rank_hostfamily = com_criteria_note_2 if block == 3602
		
	**BLOCK 3603
	br village block com_elderly-rank_elderly_hoh if block == 3603	
		**Households displaced with host families
		replace com_hostfamily = 1 if block == 3603
		replace rank_hostfamily = com_criteria_note_1 if block == 3603
		
		**Households with log ag production due to natural disasters
		replace com_croploss_nat = 1 if block == 3603
		replace rank_croploss_nat = com_criteria_note_2 if block == 3603
		
		**Households headed by Twa
		replace com_hhh_twa = 1 if block == 3603
		replace rank_hhh_twa = com_criteria_note_3 if block == 3603
		
		**Households headed by a divorced woman
		replace com_hhh_fdivorced = 1 if block == 3603
		replace rank_hhh_fdivorced = com_criteria_note_4 if block == 3603

/// I also sum up each of the pre-programmed criteria to see which ones were ever mentioned.
foreach i in $criteria {
	egen comtotal_`i' = total(com_`i') //this tells us the sum of CB communities that listed each pre-programmed criteria
}
*br comtotal* // these are already all mentioned.  So they will all be created for use later.

*** ONCE DONE, create a global of all of the criteria that will be potentially used in CB blocks.  This includes the pre-programmed ones, plus the new ones.  MAKE SURE you delete the ones that you are't able to create from the census data in the next do-file
global cbcriteria elderly plw women_hoh widow disabilities illness girl_mothers child_hoh no_provider paltry_shelter orphan survivor pregnant_hoh nursing_hoh 3_child ill_hoh disabled_hoh elderly_hoh no_water hhh_femnochild agIGA ag_low displacedhh croploss_ins malnchild hostfamily hhh_young_lowIGA strawroof hhh_youth hhh_orphsingpreg hhh_eldwidow hhh_farmer noIGA hhh_fdivorced hhh_young_illdis hhh_twa hhh_widower hhh_orphan croploss_nat 

foreach i in $cbcriteria {
	replace com_`i' = . if consultation != "CBT" 
	replace com_`i' = 0 if com_`i' == . & consultation == "CBT" //in the next do-file, it will be important that these are not missing.  Just double-checking here.
	replace rank_`i' = 0 if rank_`i' == . & consultation == "CBT" 
}

save "${output}DRC_Targeting_Committee_clean.dta", replace


	
