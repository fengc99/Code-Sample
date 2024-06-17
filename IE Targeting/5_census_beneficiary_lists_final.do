/************************************

************************************/

*********************************
** Defining coverage using PMT **
*********************************
use "${data_bl_final}Survey\Analysis\BL_Targeting_Appended.dta", clear

	global all "i.demo_headmaritalsts demo_headfemale demo_headage demo_monoparental demo_HHsize demo_nochu5 demo_wapopmale demo_disabilityd i.socio_headedulcat i.socio_sourceincomecat socio_nomealsch"
	summ $all

	reg SCA i.demo_headmaritalsts demo_headfemale demo_headage demo_monoparental demo_HHsize  i.socio_headedulcat i.socio_sourceincomecat demo_nochu5 demo_disabilityd, nocons r  // demo_wapopmale socio_nomealsch  
	est store SCA_PMT
	
    outreg2 [SCA_PMT] using "${output}Beneficiary Lists\lin_allvars.xls",  nocons label 
	
	use "${output}DRC_IETargeting_Census_constructed.dta", clear
	
	predict SCA_hat
	predict phat
	predict idxhat, xb

	sum phat, d
	*twoway lfitci SCA SCA_hat

	gen SCACat28_hat=cond(SCA_hat<28,1,cond(SCA_hat<42,2,3))
	label var SCACat28_hat "SCA Categories, thresholds 28-42"
	label define SCACatl 1 "poor" 2 "borderline" 3 "acceptable"
	label values SCACat28_hat SCACatl

	tab SCACat28_hat, m //just to see if it works
	lab var SCACat28_hat "Predicted FCS categories from PMT model only"

	** Check to see what happens if any PMT model variables are missing
	gen flag_missPMT = 0
	foreach var of varlist demo_headmaritalsts demo_headfemale demo_headage demo_monoparental demo_HHsize  socio_headedulcat socio_sourceincomecat demo_nochu5 demo_disabilityd {
	 replace flag_missPMT = 1 if `var' == .	
				}
				
tab flag_missPMT  //only 2 have missing PMT variables
tab SCACat28_hat if flag_missPMT == 1  //they are deemed 'acceptable'.  Let's check this after the lock-ins to see if it changes.

//////////For all of the blocs, implement the 'lock-in' criteria////////
	****NOTE that the non-study blocks won't have the orphan criteria as a lock-in.  This is taken care of automatically, since eligibility only changes if orphan == 1, and nothing changes if orphan == .

	gen vulnerability_pmt = SCACat28_hat
	
	global top_pmt_smpl2 no_provider orphan pregnant_hoh elderly_hoh displacedhh disabled_hoh ill_hoh /*malnchild*/ //took this from community_consultation.do; since we don't have census data for malnourished children, that one is blocked out.  I have put the disabled_hoh and ill_hoh last, because these data are missing from some households and we want to see how much this effects inclusion after other lock-in criteria are already considered.
	
	global top_pmt_9 no_provider elderly_hoh displacedhh disabled_hoh orphan ill_hoh disabilities pregnant_hoh women_hoh  //took this from community_consultation.do
	
	foreach top in $top_pmt_smpl2 {
		replace vulnerability_pmt = 1 if pmtc_`top' == 1 //force vulnerability to be 'poor' if the household has any of the top pmt criteria identified in community_consultation.do
	}

	lab var vulnerability_pmt "final vulnerability score using PMT PLUS"
	lab val vulnerability_pmt SCACatl
	tab vulnerability_pmt // this shows the distribution once lock-in criteria are considered.

	tab vulnerability_pmt if flag_missPMT == 1 //both of the households that were missing PMT criteria changed from 'acceptable' to 'poor'; this means their missing values didn't put them at risk of losing assistance.  Good!

	gen eligibility_pmt = (vulnerability_pmt == 1)
	lab var eligibility_pmt "binary eligibility using PMT PLUS"
	count if eligibility_pmt == . //MAKE SURE THIS IS ZERO!  WE DONT WANT TO ACCIDENTALLY DROP ANY HOUSEHOLDS BECAUSE OF MISSING DATA.
	lab def eligibility 1 "eligible" 0 "not eligible"
	lab val eligibility_pmt eligibility
	
	tab eligibility_pmt //Check to see if the eligibility rate is over 90% -- if so, the SOPs indicate to blanket cover.
	// Eligibility rate is approx. 85%.


//////////Understanding the effect of missing data
	tab eligibility_pmt if flagm2_novulnerab == 1 & treatment != 1 //38 households don't make it in to PMT plus.  They are missing 'lock-in' criteria that could have determined their status.  These are: number of disabled members (for top 9 only), head is disabled, head has chronic illness.	Note that previously when replacing vulnerability_pmt = 1 if households had lock-in criteria, 100 households got in either specifically because they had a disabled HoH or because they had a chronically ill HoH.  This amounts to about 0.8% of the eligible households (small).  So it is unlikely that any of these 38 would have gotten in anyway.

	tab eligibility_pmt if treatment == 2 //253 non-study households are ineligible.  These ones did not have the orphan data that could have determined their status.  Unfortunately there's nothing that we can do about this; it was implemented this way across all of the blocks that are non-study, so it shouldn't cause tension.
	

//////////Export the full IDP lists; CO decided to blanket cover these in meeting on 17 April 2023

export excel key hhid axe_name village_name block_name hhh_doc* hhh_name hhh_lastname hhh_firstname hhh2_fullname hhh_sex hhh_datebirth hhh_maritalstatus demo_HHsize phone_number hh_address vulnerability_pmt using "${output}Beneficiary Lists/IDPcamp_beneficiary_list.xlsx" if block == 102 | block == 606 | block == 1302, firstrow(var) replace
	
//////////Exporting summary about population, # of eligible, and coverage rate per block.
preserve
		gen population = eligibility_pmt
		gen coverage = eligibility_pmt
		collapse (sum) eligibility_pmt (count) population (mean) coverage (first) treatment axe_name village_name if treatment != 1, by(block)
		export excel axe_name village_name block eligibility_pmt population coverage treatment using "${output}Beneficiary Lists/PMT_coverage_table.xlsx", firstrow(var) replace
restore	

/////////Non-study blocks	
	**Export the eligibility list for non-study blocks:
	gen temp_vuln = "1 Tres Vulnerable"
	export excel key hhid axe_name village_name block_name hhh_doc* hhh_name hhh_lastname hhh_firstname hhh2_fullname hhh_sex hhh_datebirth hhh_maritalstatus demo_HHsize phone_number hh_address temp_vuln using "${output}Beneficiary Lists/nonstudy_beneficiary_list.xlsx" if treatment == 2 & eligibility_pmt == 1, firstrow(var) replace
	drop temp_vuln

	//Testing balance: those classified as “poor” should be balanced between the PMT and the CB treatment arms. 
	**Run a t-test to check.  If this is not the case, alert the research team.  
	ttest eligibility_pmt if treatment != 2, by(treatment) //no difference

//////////Determine household coverage: PMT arm///////////////////////////
	**For households in the PMT blocs, calculate the percentage of households that are 'poor'.  Store this as a global.
	**Export the lists of all households classified as “poor” in the vulnerability_pmt variable.  This is the final beneficiary list for those blocs.
	sum eligibility_pmt if treatment == 0
	return list
	global PMT_arm_covg = r(mean)
	disp $PMT_arm_covg // works.  This is a global that shows the percentage of households deemed eligible for assistance in the PMT
	global CB_percentile = $PMT_arm_covg*100 //this just turns it into a percentile reading (whole number).  In the end, we don't need this as we won't use the percentage coverage in PMT to determine coverage in CB anymore.
	
	**Export the eligibility list for PMT blocks:
	gen temp_vuln = "1 Tres Vulnerable"
	export excel key hhid axe_name village_name block_name hhh_doc* hhh_name hhh_lastname hhh_firstname hhh2_fullname hhh_sex hhh_datebirth hhh_maritalstatus demo_HHsize phone_number hh_address temp_vuln using "${output}Beneficiary Lists/PMTarm_beneficiary_list.xlsx" if treatment == 0 & eligibility_pmt == 1, firstrow(var) replace
	drop temp_vuln

	//Testing balance:
	preserve
		collapse (mean) eligibility_pmt (first) treatment if treatment != 2, by(block)
		ttest eligibility_pmt if treatment != 2, by(treatment) //NOT statistically significantly different
	restore
	//Prepping for merge later
	preserve
		tempfile eligibility_pmt 
		keep key block treatment eligibility_pmt vulnerability_pmt SCACat28_hat 
		save `eligibility_pmt'
	restore
		
	
*********************************
** Defining coverage using CB ***
*********************************
	keep if treatment == 1 //Only looking at the CB arm so we don't accidentally make any mistakes.  Comment this out for the blog data.

//////////Assign scores to each household///////////////////////////
** In the community_consultation.do file, we created binary indicators that say whether or not that block mentioned that critiera, AND the associated weights in the COMMUNITY dataset.  These look the same as all of the pre-programmed weights, such that it's structured like this:

*com_(name): binary, indicating whether or not that block mentioned that criteria.  Looks the same for those which were pre-programmed and those we created afterward.
*rank_(name): ordinal, giving the weight (1, 2, or 3) that the communities placed on the corresponding criteria

** Then, in the census data, we created the actually indicators for each household.  I.e.: 
*cbc_(name): binary, indicating whether or not a household actually has the criteria mentioned in the consultations

**So, to determine eligibility in each block in the CB arm, we need to:
*1) Merge M:1 using the community data for everything that says com_* 
*2) Take each criteria listed by them, and multiply the binary representing that criteria with the weight, summing them up to generate a score for each household.  This would look like:
***    com_a x cbc_a x rank_a + com_b x cbc_b x rank_b + ...
* This sets it up so that if a community does not mention a criteria, that section of the equation "zeros out", and is not added.  
* If a community DID mention a criteria, then that 'one' multiples by the binary representing whether a household indeed HAS that criteria, and then (if so) multiplies by its importance.
* In this case, if a household does NOT have the criteria, it also zeros out and it is not added to their score.

	** Let's start by merging.
	preserve
		tempfile CBC_merge
		use "${output}DRC_Targeting_Committee_clean", clear
		keep if consultation == "CBT"
		save `CBC_merge'
	restore
	
	merge m:1 block using `CBC_merge', keepus (com_* rank_* ) //DOUBLE CHECK TO MAKE SURE THIS HAS ALL OF THE VARIABLES YOU NEED!
	tab _merge //there shouldn't be any _merge == 2, because we already restricted the using data to only those which are CB blocks
	* _merge == 1 means that there blocks in the census data which have not yet received a community consultation (this needs to be finished before moving forward)
	drop if block == 3002 //field coordinator confirms we could not collect census data from this block
	
	** Then let's create the score variable and formula
	generate score_cb = 0
	
	foreach i in $cbcriteria_new {
		replace score_cb = score_cb + (com_`i' * cbc_`i' * rank_`i') //if ANY of the variables have a missing value, then the resulting score will be missing.  Make sure this isn't the case!  We have corrected this in the previous do-file (community_consultation.do), but it's worth checking again here.
	}

	lab var score_cb "Vulnerability score for block; NOT comparable across blocks"
	tab score_cb, m //make sure there are no missing.
	
//////////Define eligibility///////////////////////////

	gen eligibility_cb = 0
	lab var eligibility_cb "binary eligibility using CB"
	lab val eligibility_cb eligibility //setting up a variable that will either say "eligible" or "not eligible" for all households in CB arm.


	//Reminder: if the distribution was different (had fewer zeros), we would have used the a cut-off to determine assistance.  Taking the most vulnerable households from each block, up to a certain percentage defined earlier by the PMT ($CB_percentile).  This code is left below.
			/*
			replace score_cb = score_cb * -1
			levelsof block //this takes every distinct observation in the variable block (i.e. every block)
			foreach lev in `r(levels)' { //so for each block, we want to...
				_pctile score_cb if block == `lev', p($CB_percentile) //...find the value WITHIN EACH BLOCK at which score_cb is the $PMT_arm_covg percentile OF THAT BLOCK
				ret li //Then return the list so that...
				local cutoff = r(r1) //...we can store that cut-off number FOR THAT BLOCK
				replace eligibility_cb = 1 if score_cb <= `cutoff' & block == `lev' //Then WITHIN THAT BLOCK, code households as eligible if their score_cb is below the cutoff that is at the percentile.
			}

			su eligibility_cb //DOUBLE CHECK THAT THIS WORKS

			*/

	su score_cb //looks like around 25% have zero scores
	levelsof block //this takes every distinct observation in the variable block (i.e. every block)
	foreach lev in `r(levels)' {
		dis `lev'
		su score_cb if block == `lev'
	}

	**** Taking all of the non-zero scores as eligible
	replace eligibility_cb = 1 if score_cb != 0
	
*save "$DATA/Clean Data/blog_data.dta", replace

	//Prepping for merge later
	preserve
		tempfile eligibility_cb
		keep key eligibility_cb score_cb
		save `eligibility_cb'
	restore
	
	
//////////Exporting summary about population, # of eligible, and coverage rate per block.
	preserve
		gen population = eligibility_cb
		gen coverage = eligibility_cb
		collapse (sum) eligibility_cb (count) population (mean) coverage (first) treatment axe_name village_name if treatment == 1, by(block)
		export excel axe_name village_name block eligibility_cb population coverage using "${output}Beneficiary Lists/CB_coverage_table.xlsx", firstrow(var) replace
	restore	


**Export the eligibility list for the CB blocks:
	gen tempvuln = "1 Tres Vulnerable"
	export excel key hhid axe_name village_name block_name hhh_doc* hhh_name hhh_lastname hhh_firstname hhh2_fullname hhh_sex hhh_datebirth hhh_maritalstatus demo_HHsize phone_number hh_address tempvuln using "${output}Beneficiary Lists/CBarm_beneficiary_list.xlsx" if eligibility_cb == 1, firstrow(var) replace
	drop tempvuln


//////Merging eligibility data

	use `eligibility_pmt', clear
	merge 1:1 key using `eligibility_cb'
	drop _merge
	save "${output}key_eligibility.dta", replace



