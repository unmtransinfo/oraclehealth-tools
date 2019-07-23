-- 
-- Health Facts Diabetes, Dx + meds + labs (in that order)
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
	dm2.medication_id,
	dlp3.lab_procedure_id,
	flp3.numeric_result,
	CAST(flp3.result_indicator_id AS INTEGER) AS result_indicator_id,
	fe1.admitted_dt_tm AS dx_date,
	fe2.admitted_dt_tm AS med_date,
	fe3.admitted_dt_tm AS lab_date
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
	hf_f_medication fm2 ON fm2.encounter_id = fe2.encounter_id
JOIN
	hf_d_medication dm2 ON dm2.medication_id = fm2.medication_id
JOIN
	hf_f_encounter fe3 ON fe3.patient_id = fe1.patient_id
JOIN
	hf_f_lab_procedure flp3 ON flp3.encounter_id = fe3.encounter_id
JOIN
	hf_d_lab_procedure dlp3 ON dlp3.lab_procedure_id = flp3.detail_lab_procedure_id
WHERE
	fe2.admitted_dt_tm-fe1.admitted_dt_tm BETWEEN INTERVAL '0 DAYS' AND INTERVAL '365 DAYS'
	AND fe3.admitted_dt_tm-fe2.admitted_dt_tm BETWEEN INTERVAL '0 DAYS' AND INTERVAL '365 DAYS'
	AND EXTRACT(YEAR FROM fe1.admitted_dt_tm) BETWEEN 2008 AND 2010
	AND dd1.diagnosis_type = 'ICD9'
	AND dd1.diagnosis_code IN ('250.01', '250.03')
	AND dpt1.patient_type_desc = 'Outpatient'
	AND LOWER(dm2.generic_name) ILIKE 'insulin%'
	AND dlp3.lab_procedure_id = 1093
	AND flp3.numeric_result IS NOT NULL
	;
--
-- AND EXTRACT(YEAR FROM fe1.admitted_dt_tm) = 2010
-- AND RANDOM()<0.01
