-- Health Facts Diabetes, labs
-- Only diagnostic ICD-9-CM codes (Volume 2).
-- Diabetes Codes: 250.*, includes Diabetes Mellitus type-1 and type-2
-- Here we select type-1 assuming "juvenile" is in all descriptions.
--
-- RANDOM()<0.01 for 1% sampling.
-- 
SELECT
	COUNT(DISTINCT fe1.patient_id) pid_count,
	dd1.diagnosis_code,
	dd1.diagnosis_description
FROM
        hf_f_encounter fe1
JOIN
        hf_f_diagnosis fd1 ON fd1.encounter_id = fe1.encounter_id
JOIN
        hf_d_diagnosis dd1 ON fd1.diagnosis_id = dd1.diagnosis_id
WHERE
	dd1.diagnosis_type = 'ICD9'
	AND SUBSTRING(dd1.diagnosis_code,1,4) = '250.'
	AND dd1.diagnosis_description ILIKE '%juvenile%'
	AND fe1.admitted_dt_tm::CHAR(4) = '2010'
GROUP BY
	dd1.diagnosis_code,
	dd1.diagnosis_description
ORDER BY
        dd1.diagnosis_code
	;
--
