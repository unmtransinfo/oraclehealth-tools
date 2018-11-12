-- Health Facts Diagnoses - Co-morbid Breast Cancer-Diabetes patients
-- Only 'Final' diagnoses.
-- Only diagnostic ICD-9-CM codes (Volume 2).
-- Breast Cancer Codes: [140-209].* + [230-234].*, to avoid benign & uncertain neoplasms.
--
-- 174.0 Malignant Neoplasm of Nipple and Areola of Female Breast
-- 174.1 Malignant Neoplasm of Central Portion of Female Breast
-- 174.2 Malignant Neoplasm of Upper-Inner Quadrant of Female Breast
-- 174.3 Malignant Neoplasm of Lower-Inner Quadrant of Female Breast
-- 174.4 Malignant Neoplasm of Upper-Outer Quadrant of Female Breast
-- 174.5 Malignant Neoplasm of Lower-Outer Quadrant of Female Breast
-- 174.6 Malignant Neoplasm of Axillary Tail of Female Breast
-- 174.8 Malignant Neoplasm of Other Specified Sites of Female Breast
-- 174.9 Malignant Neoplasm of Breast (Female), Unspecified
-- 198.81 Secondary Malignant Neoplasm of Breast
-- 233.0 Carcinoma in Situ of Breast
--
-- Diabetes Codes: 250.*, includes type-1 and type-2 Diabetes Mellitus
--
-- We link two diagnostic encounters with same patient.
-- LARGE OUTPUT.  Save filesize/memory by getting diagnosis descriptions elsewhere.
--
SELECT
	fe1.patient_id,
	dpt1.patient_type_id,
	dd1.diagnosis_code AS [cancer_code],
	CAST(fe1.admitted_dt_tm AS DATE) AS [cancer_date],
	dd2.diagnosis_code AS [diabetes_code],
	CAST(fe2.admitted_dt_tm AS DATE) AS [diabetes_date]
FROM
	hf_f_encounter fe1
JOIN
	hf_f_encounter fe2 ON fe1.patient_id = fe2.patient_id
JOIN
        hf_d_patient dp1 ON fe1.patient_id = dp1.patient_id
JOIN
	hf_f_diagnosis fd1 ON fd1.encounter_id = fe1.encounter_id
JOIN
	hf_f_diagnosis fd2 ON fd2.encounter_id = fe2.encounter_id
JOIN
	hf_d_diagnosis dd1 ON fd1.diagnosis_id = dd1.diagnosis_id
JOIN
	hf_d_diagnosis dd2 ON fd2.diagnosis_id = dd2.diagnosis_id
JOIN
       	hf_d_diagnosis_type ddt1 ON fd1.diagnosis_type_id = ddt1.diagnosis_type_id
JOIN
       	hf_d_diagnosis_type ddt2 ON fd2.diagnosis_type_id = ddt2.diagnosis_type_id
JOIN
        hf_d_patient_type dpt1 ON fe1.patient_type_id = dpt1.patient_type_id
WHERE
	fe1.admitted_dt_tm BETWEEN CAST('2013-01-01' AS date) AND CAST('2013-12-31' AS date)
	AND ddt1.diagnosis_type_display = 'Final'
	AND dd1.diagnosis_code LIKE '[0-9][0-9][0-9].%'
	AND dd1.diagnosis_code IN ('174.0', '174.1', '174.2', '174.3', '174.4', '174.5', '174.6', '174.8', '174.9', '198.81', '233.0')
	AND fe2.admitted_dt_tm BETWEEN CAST('2013-01-01' AS date) AND CAST('2013-12-31' AS date)
	AND ddt2.diagnosis_type_display = 'Final'
	AND dd2.diagnosis_code LIKE '[0-9][0-9][0-9].%'
	AND CAST(SUBSTRING(dd2.diagnosis_code,1,3) AS INTEGER) = 250
	AND dp1.gender = 'Female'
	;
--
