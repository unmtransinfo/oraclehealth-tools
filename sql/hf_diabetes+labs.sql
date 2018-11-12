-- Health Facts Diabetes, labs
-- Only diagnostic ICD-9-CM codes (Volume 2).
--
-- '250.01': Diabetes Mellitus without Mention of Complication, Type I [juvenile Type], Not Stated as Uncontrolled
-- '250.03': Diabetes Mellitus without Mention of Complication, Type I [juvenile Type], Uncontrolled
--
-- 1093, 'Hemoglobin A1C (Glycosylated Hemoglobin)' ~99% of HbA1c labs
--
-- RANDOM()<0.01 for 1% sampling.
-- 5/20/17: 48hrs
--
SELECT
	fe1.patient_id,
	dd1.diagnosis_code,
	ddt1.diagnosis_type_display,
	dlp2.lab_procedure_name,
	flp2.numeric_result,
	flp2.result_indicator_id,
	fe1.admitted_dt_tm dx_date,
	fe2.admitted_dt_tm AS lab_date,
	(EXTRACT(EPOCH FROM fe1.admitted_dt_tm-fe2.admitted_dt_tm)/3600/24)::INTEGER AS "days_d2l"
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
WHERE
	fe1.admitted_dt_tm::CHAR(4) = '2010'
	AND days_d2l BETWEEN 0 AND 365
	AND dd1.diagnosis_type = 'ICD9'
	AND dd1.diagnosis_code IN ('250.01', '250.03')
	AND dpt1.patient_type_desc = 'Outpatient'
	AND dlp2.lab_procedure_id = 1093
	AND RANDOM()<0.01
	;
--
