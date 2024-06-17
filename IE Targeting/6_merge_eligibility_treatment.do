/************************************


************************************/



	** Loading the treatment_assignment dataset
	use "${data_bl_raw}treatment_assignment.dta", clear

	*Preparing the data to merge with the baseline
	decode axe_n, gen(axe_name)
	decode village_n, gen(village_name)
	decode blocs_n, gen(block_name)
	rename treatment treatment_assignment
	replace axe_name = subinstr(axe_name, " ", "",.)
	drop *_n

	keep *_name id_quadru treatment_assignment
	
	save "${output}treatment_assignment_clean.dta", replace
	*Merging with the baseline
	merge 1:m axe_name village_name block_name using"${output}DRC_IETargeting_Census_constructed.dta"
	keep if _merge==3
	drop _merge
	
	encode axe_name, gen(axe_n)
	encode village_name, gen(village_n)
	encode block_name, gen(block_n)
	
	*merge with vulnerability status as per PMT algorithem
	merge 1:1 key using"${output}key_eligibility", keepusing(eligibility_pmt vulnerability_pmt SCACat28_hat eligibility_cb score_cb) keep(match) nogen

	*keep only sample selected for midline
		save "${output}baseline.dta", replace
