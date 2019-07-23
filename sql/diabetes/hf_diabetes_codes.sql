-- Health Facts Diagnoses
-- Diabetes Codes: all diabetes, ICD9 and ICD10
--
SELECT
	dd.diagnosis_id,
	dd.diagnosis_code,
	dd.diagnosis_type,
	dd.diagnosis_description
FROM	
	hf_d_diagnosis dd
WHERE
	dd.diagnosis_description ILIKE '%diabetes%'
ORDER BY
	dd.diagnosis_type,
	dd.diagnosis_code
	;
--
