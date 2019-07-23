-- Health Facts Diabetes
-- Only diagnostic ICD-9-CM codes (Volume 2).
-- Diabetes Codes: 250.*, includes Diabetes Mellitus type-1 and type-2
--
SELECT
	COUNT(DISTINCT fe1.patient_id) patient_count,
	COUNT(DISTINCT fe1.encounter_id) encounter_count,
	dd1.diagnosis_type,
	dd1.diagnosis_code,
	dd1.diagnosis_description,
	fe1.admitted_dt_tm::CHAR(4) AS "year"
FROM
        hf_f_encounter fe1
JOIN
        hf_f_diagnosis fd1 ON fd1.encounter_id = fe1.encounter_id
JOIN
        hf_d_diagnosis dd1 ON fd1.diagnosis_id = dd1.diagnosis_id
WHERE
	dd1.diagnosis_description LIKE 'Diabetes%'
GROUP BY
	dd1.diagnosis_type,
	dd1.diagnosis_code,
	dd1.diagnosis_description,
        year
	;
--
