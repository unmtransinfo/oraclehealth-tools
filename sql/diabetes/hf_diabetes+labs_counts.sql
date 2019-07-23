-- Health Facts Diabetes, labs
-- Only diagnostic ICD-9-CM codes (Volume 2).
-- Diabetes Codes: 250.*, includes Diabetes Mellitus type-1 and type-2
-- Here we select type-1 assuming "juvenile" is in all descriptions.
--
-- 2017-05-18: 7hrs
SELECT
	COUNT(DISTINCT fe1.patient_id) pid_count,
--	dd1.diagnosis_code,
	dlp2.lab_procedure_id
FROM
        hf_f_encounter fe1
JOIN
        hf_f_diagnosis fd1 ON fd1.encounter_id = fe1.encounter_id
JOIN
        hf_d_diagnosis dd1 ON fd1.diagnosis_id = dd1.diagnosis_id
JOIN
	hf_f_encounter fe2 ON fe2.patient_id = fe1.patient_id
JOIN
	hf_f_lab_procedure flp2 ON flp2.encounter_id = fe2.encounter_id
JOIN
	hf_d_lab_procedure dlp2 ON dlp2.lab_procedure_id = flp2.detail_lab_procedure_id
WHERE
	dd1.diagnosis_type = 'ICD9'
--	AND SUBSTRING(dd1.diagnosis_code,1,4) = '250.'
	AND dd1.diagnosis_code = '250.01'
	AND dd1.diagnosis_description ILIKE '%juvenile%'
	AND dlp2.lab_procedure_name ILIKE 'Hemoglobin A1C%'
GROUP BY
--	dd1.diagnosis_code,
	dlp2.lab_procedure_id
	;
--
