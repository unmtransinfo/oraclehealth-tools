-- Health Facts Diabetes, Dx + labs + meds
-- Only diagnostic ICD-9-CM codes (Volume 2).
-- Diabetes Codes: 250.*, includes Diabetes Mellitus type-1 and type-2
-- Here we select type-1 assuming "juvenile" is in all descriptions.
--
-- 3 encounters linked by patient_id: Dx, Rx, and Lab.
--
-- BIG OUTPUT, SO TEXT FIELDS AVOIDED, LINKED ELSEWHERE.
--
-- 2015-11-02: 500000 row(s) affected, exec/fetch time: 25270.825/19.261 sec (~7hr)
-- 2015-11-03: 500000 row(s) affected, exec/fetch time: 21880.340/20.706 sec
--
SELECT
	fe1.patient_id,
	dd1.diagnosis_code,
	fe1.patient_type_id,
	dlp2.lab_procedure_id,
	fe2.patient_type_id,
	flp2.numeric_result,
	dm3.medication_id,
	fe3.patient_type_id,
	CAST(fe1.admitted_dt_tm AS DATE) AS [dx_date],
	CAST(fe2.admitted_dt_tm AS DATE) AS [lab_date],
	CAST(fe3.admitted_dt_tm AS DATE) AS [med_date],
	CAST(fe2.admitted_dt_tm - fe3.admitted_dt_tm AS INTEGER) AS [days_m2l]
FROM
        hf_f_encounter fe1
JOIN
        hf_f_diagnosis fd1 ON fd1.encounter_id = fe1.encounter_id
JOIN
        hf_d_diagnosis dd1 ON fd1.diagnosis_id = dd1.diagnosis_id
JOIN
        hf_d_diagnosis_type ddt1 ON fd1.diagnosis_type_id = ddt1.diagnosis_type_id
JOIN
	hf_f_encounter fe2 ON fe2.patient_id = fe1.patient_id
JOIN
	hf_f_lab_procedure flp2 ON flp2.encounter_id = fe2.encounter_id
JOIN
	hf_d_lab_procedure dlp2 ON dlp2.lab_procedure_id = CAST(flp2.detail_lab_procedure_id AS INTEGER)
JOIN
	hf_f_encounter fe3 ON fe3.patient_id = fe1.patient_id
JOIN
	hf_f_medication fm3 ON fm3.encounter_id = fe3.encounter_id
JOIN
	hf_d_medication dm3 ON dm3.medication_id = fm3.medication_id
WHERE
	dd1.diagnosis_code LIKE '[0-9][0-9][0-9].%'
	AND CAST(SUBSTRING(dd1.diagnosis_code,1,3) AS INTEGER) = 250
	AND LOWER(dd1.diagnosis_description) LIKE '%juvenile%'
        AND ddt1.diagnosis_type_display = 'Final'
	AND dlp2.lab_procedure_name LIKE 'Hemoglobin A1C%'
	AND LOWER(dm3.generic_name) LIKE 'insulin%'
	AND flp2.numeric_result IS NOT NULL
	AND fe2.admitted_dt_tm > fe3.admitted_dt_tm
	;
--
