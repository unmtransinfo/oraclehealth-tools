-- 98 hrs (May 30, 2017)

-- Health Facts Diabetes, Dx + labs + meds
-- Only diagnostic ICD-9-CM codes (Volume 2).
--
-- '250.01': Diabetes Mellitus without Mention of Complication, Type I [juvenile Type], Not Stated as Uncontrolled
-- '250.03': Diabetes Mellitus without Mention of Complication, Type I [juvenile Type], Uncontrolled
--
-- 3 encounters linked by patient_id: Dx, Rx, and Lab.
-- Outpatient type.
--
SELECT DISTINCT
	fe1.patient_id,
	fe1.patient_type_id,
	dd1.diagnosis_code,
	dlp2.lab_procedure_id,
	flp2.numeric_result,
	CAST(flp2.result_indicator_id AS INTEGER) AS result_indicator_id,
	dm3.medication_id,
	fe1.admitted_dt_tm AS dx_date,
	fe2.admitted_dt_tm AS lab_date,
	fe3.admitted_dt_tm AS med_date
FROM
        hf_f_encounter fe1
JOIN
        hf_f_diagnosis fd1 ON fd1.encounter_id = fe1.encounter_id
JOIN
        hf_d_diagnosis dd1 ON fd1.diagnosis_id = dd1.diagnosis_id
JOIN
        hf_d_diagnosis_type ddt1 ON fd1.diagnosis_type_id = ddt1.diagnosis_type_id
JOIN
	hf_d_patient_type dpt1 ON fe1.patient_type_id = dpt1.patient_type_id
JOIN
	hf_f_encounter fe2 ON fe2.patient_id = fe1.patient_id
JOIN
	hf_f_lab_procedure flp2 ON flp2.encounter_id = fe2.encounter_id
JOIN
	hf_d_lab_procedure dlp2 ON dlp2.lab_procedure_id = flp2.detail_lab_procedure_id
JOIN
	hf_f_encounter fe3 ON fe3.patient_id = fe1.patient_id
JOIN
	hf_f_medication fm3 ON fm3.encounter_id = fe3.encounter_id
JOIN
	hf_d_medication dm3 ON dm3.medication_id = fm3.medication_id
WHERE
	fe1.admitted_dt_tm::CHAR(4) = '2010'
	AND (EXTRACT(EPOCH FROM fe2.admitted_dt_tm-fe1.admitted_dt_tm)/3600/24)::INTEGER BETWEEN 0 AND 365
	AND (EXTRACT(EPOCH FROM fe3.admitted_dt_tm-fe1.admitted_dt_tm)/3600/24)::INTEGER BETWEEN 0 AND 365
	AND dd1.diagnosis_type = 'ICD9'
	AND dd1.diagnosis_code IN ('250.01', '250.03')
	AND dpt1.patient_type_desc = 'Outpatient'
	AND dlp2.lab_procedure_id = 1093
	AND flp2.numeric_result IS NOT NULL
	AND RANDOM()<0.01
	;
--
