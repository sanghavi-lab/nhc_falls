# Nursing Home Compare Undercounts Major Injury Falls Code description

These notes describe the code files that were used to conduct the analysis. Explanations for specific decisions, such as the diagnosis codes used to identify fall-related injuries, are provided elsewhere in the main manuscript and supplementary materials. All code files listed below are available at https://github.com/sanghavi-lab/nhc\_falls.

## Software

We used SAS 9.4 and Stata/MP 15.0 for this analysis.

## C1. Setup MedPAR fall claims

We used inpatient claims of a 100% sample of Medicare fee-for-service beneficiaries from Medicare Provider Analysis and Review (MedPAR) records provided by CMS and linked each record to the Master Beneficiary Summary File (MBSF) based on beneficiary identification number to obtain the patient’s enrollment and demographic information. We identified claims for fall-related injuries based on diagnosis codes and external cause codes, created indicators to flag definite vs. probable falls and patients who are dually- eligible. These claims were subsequently linked to MDS assessments.
|Macro name |Input files (File source) |Output files|
|-|-|-|
|MCLAIMS2015|2015 MedPAR files|medpar_2015_Jan_Sept_icd9.sas7bdat|
|MCLAIMS|2011-2014 MedPAR files<br>2015 MedPAR file including only claims with ICD-9-CM<br>2011-2015 MBSF files|medpar_fall_mbsf_2011.sas7bdat<br>medpar_fall_mbsf_2012.sas7bdat<br>medpar_fall_mbsf_2013.sas7bdat<br>medpar_fall_mbsf_2014.sas7bdat<br>medpar_fall_mbsf_2015.sas7bdat|

## C2. Set up MDS assessments

The Minimum Data Set (MDS) assessments contain variables for nursing home assessment type, target date, discharge date, and fall questions J1700A-J1700B, J1800, J1900A-J1900C. We merged the MDS records with the Long-term Care: Facts on Care in the US (LTCFocus) dataset from Brown University to obtain provider geographical information and with the Certification and Survey Provider Enhanced Reporting (CASPER) for facility characteristics including registered resident counts by payment source, ownership type, etc. The final output file was linked to MedPAR fall claims in the next steps.

|Macro name |Input files (File source) |Output files|
|-|-|-|
|MMDS3|2011-2015 crosswalked MDS files|MDS2011.sas7bdat<br>MDS2012.sas7bdat<br>MDS2013.sas7bdat<br>MDS2014.sas7bdat<br>MDS2015.sas7bdat|
|MJOINMDS3|2011-2015 LTC Focus Facility files <br>MDS2011.sas7bdat <br>MDS2012.sas7bdat <br>MDS2013.sas7bdat <br>MDS2014.sas7bdat <br>MDS2015.sas7bdat|mds3_facility_2011_2015.sas7bdat|
|MADDCASPER|Part2.sas7bdat <br>mds3_facility_2011_2015.sas7bdat|mds3_fac_2011_2015_cap.sas7bdat|

## C3. Link MedPAR claims and MDS assessments

We linked fall claims and MDS assessments at the patient-level and created appropriate denominators for each MDS item, as described in Appendix Section S4. For example, for fall items J1800, J1900A-J1900C, the below files identify patients who have a discharge assessment from the nursing home, indicating discharge to a hospital, within one day prior to the hospital admission. They also identify those with a reentry assessment from the same nursing home within one day of the hospital discharge. These files also are used to identify other branches of our flowchart, such as patients who experienced falls during their nursing home stay but were missing discharge assessments, and patients who fell outside of their nursing home stay.

|Macro name |Input files (File source) |Output files|
|-|-|-|
|MMDSCLAIMS|medpar_fall_mbsf_2011.sas7bdat<br>medpar_fall_mbsf_2012.sas7bdat<br>medpar_fall_mbsf_2013.sas7bdat<br>medpar_fall_mbsf_2014.sas7bdat<br>medpar_fall_mbsf_2015.sas7bdat<br>mds3_fac_2011_2015_cap.sas7bda|mdsclaims.sas7bdat|
|MFALLINOUT|mdsclaims.sas7bdat|claims_fallin.sas7bdat<br> claims_fallout.sas7bdat<br> dmds.sas7bdat|
|MINOUTSENSUM|mdsclaims.sas7bdat|fall_in_out_sensitivity.csv |
|MMDSFALLIN|claims_fallin.sas7bdat<br>dmds.sas7bdat|mds_claims_fallin.sas7bdat|
|MDSCHRGPREPOST|mds_claims_fallin.sas7bdat|getmdspre.sas7bdat<br>getmdspost.sas7bdat<br>hosprecord.sas7bdat|
|MDSCHRG|mds_claims_fallin.sas7bdat|mdspre_back.sas7bdat<br>mdspost_back.sas7bdat<br>claims_fallin_notback.sas7bdat<br>mdspost_different_nh.sas7bdat<br>mdspost_same_nh.sas7bdat<br>mdspre_same_nh.sas7bdat|
|MDSCHRGADDCLAIM|mdspre_same_nh.sas7bdat<br>hosprecord.sas7bdat|mdspre_claim_samenh.sas7bdat|
|MCLAIMNODSCHRG|mdsclaims.sas7bdat<br>dmds.sas7bdat|claims_fallin_nodschrg.sas7bdat<br>claims_fallin_nodschrg_px.sas7bdat<br>mds_claims_fallin_nodschrg.sas7bdat|
|MNODSCHRG|mds_claims_fallin_nodschrg.sas7bdat|getmdspost_fallin_notback_nd.sas7bdat<br>getmdspost_fallin_back_nd.sas7bdat<br>mdspost_different_NH_nd.sas7bdat<br>mdspost_same_NH_nd.sas7bdat|
|MFALLOUTSIDE|claims_fallout.sas7bdat<br>dmds.sas7bdat|mds_claims_fallout.sas7bdat|

## Summary of Macro Contents

MMDSCLAIMS: Concatenate fall claims identified from MedPAR 2011-2015 with MDS assessments at the patient-level in the order of dates based on either the hospital admission date or MDS target date.

MFALLINOUT: Amongst patients who fell, identify those who fell during their nursing home stay and those who fell outside of their nursing home stay.

MINOUTSENSUM: Conduct sensitivity analysis to check how the number of patients who fell during their nursing home stay varies by varying the cutoff, i.e., the number of days between nursing home discharge and hospital admission.

MMDSFALLIN: Concatenate fall claims with MDS assessments and order based on hospital admission date or MDS target date for patients who fell during their nursing home stay.

MDSCHRGPREPOST: For patients who fell during their nursing home stay with discharge assessments, create separate datasets for their discharge assessments, fall claims, and up to three post-hospitalization MDS assessments.

MDSCHRG: Separate patients who went back to nursing home after hospital admission for falls and those who did not. Amongst patients who went back to nursing home, identify those who went back to same nursing home versus different nursing home.

MDSCHRGADDCLAIM: Merge discharge and up to three post-hospitalization MDS assessments with fall claims for patients who fell during their nursing home stay and went back to the same nursing home after hospitalization.

MCLAIMNODSCHRG: Identify patients who fell during their nursing home stay but were missing discharge assessments.

MNODSCHRG: For patients who fell during their nursing home stay but were missing discharge assessments, separate those who went back to nursing home after hospitalization for falls and those who did not. Amongst patients who went back to nursing home, separate those who went back to same nursing home versus different nursing home.

MFALLOUTSIDE: Identify patients who fell outside of their nursing home stay. Merge their hospital claims with post-hospitalization MDS entry assessments.

## C4. Construct patient measures

We used Stata’s ICDPIC software to map ICD-9CM discharge diagnosis codes to AIS scores to obtain New Injury Severity Score (NISS) for each fall episode. We included up to 38 diagnosis codes including admitting diagnosis code, 25 ICD-9 diagnosis codes, and 12 external cause codes for each observation and removed duplicate codes. We created a categorical variable based on NISS using breakdowns similar to other studies and used this in addition to the numerical score. Additionally, combined Charlson-Elixhauser comorbidity scores are calculated for each fall episode based on diagnosis codes on the same claim as the fall injury. We also flagged major injury falls based on the MDS J1900C major injury definition that includes bone fractures, joint dislocations, closed head injuries with altered consciousness, and subdural hematoma.

|Macro name |Input files (File source) |Output files|
|-|-|-|
|MWRITESTATAFL|mdspre_samenh_claim sas7bdat|mdspre_samenh_claim_issin.dta|
|MSEVERITY|mdspre_samenh_claim_issout.dta|mdspre_samenh_claim_iss.sas7bdat|
|MMAJOR|mdspre_samenh_claim_iss.sas7bdat<br>mds_claims_fallout.sas7bdat|mdspre_samenh_claim_mj.sas7bdat<br>mds_claims_fallout_mj.sas7bdat|
|MCOMORBIDITIES|mdspre_samenh_claim_mj.sas7bdat|mdspre_samenh_claim_com.sas7bdat|


## C5. Construct nursing home measures

We obtained publicly available data on one Nursing Home Compare (NHC) quality measure, the percent of long-stay residents experiencing one or more falls with major injury, and star ratings, overall rating and quality rating, from the CMS website. Since they are supplied in quarterly measurements, we merged the most recently surveyed results of the quality measure and star ratings with each MDS assessment based on survey date and MDS target date. Nursing home were divided into three categories based on the number of registered residents in each facility: small (<=65), medium (<=105), large (>105).

|Macro name |Input files (File source) |Output files|
|-|-|-|
|MGETSTARS|mdspre_samenh_claim_com.sas7bdat |mdspre_samenh_claim_star.sas7bdat |
|MPRVDRSIZE|mdspre_samenh_claim_star.sas7bdat|mdspre_samenh_claim_nhsize.sas7bdat|
|MREGION|mdspre_samenh_claim_nhsize.sas7bdat|mdspre_samenh_claim_region.sas7bdat|
|MQMFALL|mdspre_samenh_claim_region.sas7bdat|mdspre_samenh_claim_qmfall.sas7bdat|

## C6. Separate short-stay and long-stay residents

Each patient’s stay in the nursing home is separated into short-stay and long-stay. For the patients who fell during the current residency, we searched for a 5-day PPS assessment by looking back up to 101 days from the date of discharge to the hospital for the fall. If a 5-day PPS assessment was present in that look-back period, we categorized the stay as short-stay; otherwise, we categorized the stay as long-stay. For the patients who fell prior to the current residency, we searched for a 5-day PPS assessment by looking forward 8 days from the date of entry/admission to nursing home after the inpatient stay. If a 5-day PPS assessment was present within those 8 days, we categorized the patient as short-stay; otherwise, we categorized the patient as long-stay.

|Macro name |Input files (File source) |Output files|
|-|-|-|
|MSTAYIN|mdspre_samenh_claim_qmfall.sas7bdat |mdspre_samenh_claim_stay.sas7bdat |
|MSTAYOUT|mds_claims_fallout_mj.sas7bdat|mds_claims_fallout_stay.sas7bdat|

## C7. Generate main exhibit results

This section of macros generated results for main exhibits 1,3,4,5. Exhibit 3 displays the national reporting rate for each of the fall items stratifying between short-stay vs. long-stay and by white vs. non-white race. Exhibit 4 displays regression results for patient and nursing home characteristics that may be predictive of underreporting on MDS patient safety item J1900C. Exhibit 5 displays cross- tabulations of inpatient claim-based fall rates distribution vs. the NHC MDS-based fall measure and the overall and quality star ratings.

|Macro name |Input files (File source) |Output files|
|-|-|-|
|MEXHIBIT1|medpar_fall_mbsf_2011.sas7bdat<br>medpar_fall_mbsf_2012.sas7bdat <br>medpar_fall_mbsf_2013.sas7bdat <br>medpar_fall_mbsf_2014.sas7bdat<br> medpar_fall_mbsf_2015.sas7bdat<br> mds_claims_fallin.sas7bdat <br>claims_fallin_notback.sas7bdat<br> mdspre_back.sas7bdat<br> mdspres_same_nh.sas7bdat<br> mdspost_different_nh.sas7bdat<br> mdspre_samenh_claim_stay.sas7bdat <br>mds_claims_fallin_nodschrg.sas7bdat <br>getmdspost_fallin_notback_nd.sas7bdat <br>getmdspost_fallin_back_nd.sas7bdat <br>mdspost_different_nh_nd.sas7bdat<br> mdspost_same_nh_nd.sas7bdat <br>mds_claims_fallout_stay.sas7bdat|flowchart.csv|
|MEXHIBIT3IN|mdspre_samenh_claim_stay.sas7bdat <br>mdspost_samenh_claim.sas7bdat|mdsinside_final.sas7bdat <br>report_mdsinside.csv|
|MEXHIBIT3OUT|mds_claims_fallout_stay.sas7bdat |report_mdsoutside.csv|
|MEXHIBITINBYYEAR|mdsinside_final.sas7bdat|mdsinside2011.sas7bdat<br> mdsinside2012.sas7bdat<br> mdsinside2013.sas7bdat<br> mdsinside2014.sas7bdat<br>mdsinside2015.sas7bdat<br>mdsinside_2011_2015.sas7bdat|
|MEXHIBIT5|mdsinside2014.sas7bdat|exhibit5.csv|
|MANALYSIS|mdsinside_2011_2015.sas7bdat<br>mdsinside_final.sas7bdat|exhibit4.dta|
|MEXHIBIT4|exhibit4.dta|exhibit4.csv|
