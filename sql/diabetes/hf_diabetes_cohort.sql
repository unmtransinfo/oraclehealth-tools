-- 
-- Health Facts Diabetes cohort
-- Only diagnostic ICD-9-CM codes (Volume 2).
--
-- '250.01': Diabetes Mellitus without Mention of Complication, Type I [juvenile Type], Not Stated as Uncontrolled
-- '250.03': Diabetes Mellitus without Mention of Complication, Type I [juvenile Type], Uncontrolled
--
-- Outpatient type.
--
SELECT
	dp1.patient_id,
	dp1.patient_sk,
	dp1.gender,
	dp1.race,
	fe1.age_in_years,
	fe1.patient_type_id,
	fe1.hospital_id,
	dd1.diagnosis_code,
	fe1.admitted_dt_tm AS dx_date
FROM
	hf_d_patient dp1
JOIN
        hf_f_encounter fe1 ON dp1.patient_id = fe1.patient_id
JOIN
        hf_f_diagnosis fd1 ON fd1.encounter_id = fe1.encounter_id
JOIN
        hf_d_diagnosis dd1 ON fd1.diagnosis_id = dd1.diagnosis_id
JOIN
        hf_d_diagnosis_type ddt1 ON fd1.diagnosis_type_id = ddt1.diagnosis_type_id
JOIN
	hf_d_patient_type dpt1 ON fe1.patient_type_id = dpt1.patient_type_id
WHERE
	EXTRACT(YEAR FROM fe1.admitted_dt_tm) BETWEEN 2008 AND 2013
	AND fe1.age_in_years >= 18
	AND dd1.diagnosis_type = 'ICD9'
	AND dd1.diagnosis_code IN ('250.01', '250.03')
	AND dpt1.patient_type_desc = 'Outpatient'
	;
--
