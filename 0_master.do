/************************************
Purpose of do-file: Master do-file to run all cleaning and analysis for production of beneficiary lists
SSC installations needed: 
	ssc install todate
Net installations needed:

************************************/

//This next do-file is for cleaning/constructing variables that are needed for the PMT.
do "${construct}2_recoding.do"

//Then we look at all of the community consultation data (both committees and focus groups), consolidating the criteria and generating the corresponding indicators we need from the census data
do "${construct}3_community_consultation.do"

//Referencing the above, we construct the relevant indicators in the census data.
do "${construct}4_census_creation.do"

//Using only the census, we then produce the different vulnerability lists
do "${construct}5_census_beneficiary_lists_final.do"

//Then we merge the data
do "${construct}6_merge_eligibility_treatment.do"

//label and rename the outcome variables
do "${construct}7_Outcomevars.do"