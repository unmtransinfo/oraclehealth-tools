-- 
-- Health Facts kidney disease cohort
--
SELECT
	dp.patient_id,
	dp.patient_sk,
	dp.gender,
	dp.race,
	fe.age_in_years,
	fe.patient_type_id,
	fe.hospital_id,
	dd.diagnosis_code,
	dd.diagnosis_type,
	fe.admitted_dt_tm AS dx_date
FROM
	hf_d_patient dp
JOIN
        hf_f_encounter fe ON dp.patient_id = fe.patient_id
JOIN
        hf_f_diagnosis fd1 ON fd1.encounter_id = fe.encounter_id
JOIN
        hf_d_diagnosis dd ON fd1.diagnosis_id = dd.diagnosis_id
WHERE
	EXTRACT(YEAR FROM fe.admitted_dt_tm) BETWEEN 2008 AND 2017
	AND dd.diagnosis_id IN
	( SELECT
		diagnosis_id
	FROM	
		hf_d_diagnosis
	WHERE
		diagnosis_description ILIKE '%kidney%'
		AND NOT (diagnosis_type = 'ICD9' AND (diagnosis_code ~ '^[EOV]' OR diagnosis_code ~ '^(866|996)' ))
		AND NOT (diagnosis_type = 'ICD10-CM' AND diagnosis_code ~ '^[EORSTZ]')
	)
	;
--
