-- Health Facts Diagnoses - Co-morbid Cancer-Diabetes patients, 2013
-- Only 'Final' diagnoses.
-- Only diagnostic ICD-9-CM codes (Volume 2).
-- Cancer Codes: [140-209].* + [230-234].*, to avoid benign & uncertain neoplasms.
-- Diabetes Codes: 250.*, includes type-1 and type-2 Diabetes Mellitus
--
-- We link two diagnostic encounters with same patient.
-- LARGE OUTPUT.  Save filesize/memory by getting diagnosis descriptions elsewhere.
--
SELECT TOP 500000
	fe1.patient_id,
	fe1.age_in_years,
	fe1.weight,
	dp1.gender,
	dp1.race,
	dpt1.patient_type_desc,
	fce1.result_value_num AS [height],
	dd1.diagnosis_code AS [cancer_code],
	CAST(fe1.admitted_dt_tm AS DATE) AS [cancer_date],
	dd2.diagnosis_code AS [diabetes_code],
	CAST(fe2.admitted_dt_tm AS DATE) AS [diabetes_date],
	CAST(fe1.admitted_dt_tm - fe2.admitted_dt_tm AS INTEGER) AS [days_between_diagnoses]
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
LEFT OUTER JOIN
	hf_f_clinical_event fce1 ON fe1.encounter_id = fce1.encounter_id
JOIN
        hf_d_event_code dec1 ON fce1.event_code_id = dec1.event_code_id
WHERE
	fe1.admitted_dt_tm BETWEEN CAST('2013-01-01' AS date) AND CAST('2013-12-31' AS date)
	AND ddt1.diagnosis_type_display = 'Final'
	AND dd1.diagnosis_code LIKE '[0-9][0-9][0-9].%'
	AND ( CAST(SUBSTRING(dd1.diagnosis_code,1,3) AS INTEGER) BETWEEN 140 AND 209 OR CAST(SUBSTRING(dd1.diagnosis_code,1,3) AS INTEGER) BETWEEN 230 AND 234)
	AND fe2.admitted_dt_tm BETWEEN CAST('2013-01-01' AS date) AND CAST('2013-12-31' AS date)
	AND ddt2.diagnosis_type_display = 'Final'
	AND dd2.diagnosis_code LIKE '[0-9][0-9][0-9].%'
	AND CAST(SUBSTRING(dd2.diagnosis_code,1,3) AS INTEGER) = 250
	AND dec1.event_code_desc = 'Height'
	;
--
