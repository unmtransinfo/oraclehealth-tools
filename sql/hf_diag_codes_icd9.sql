-- Health Facts Diagnosis codes
-- Only ICD-9-CM codes (Volume 2).
-- diagnosis_type IN ('ICD9', 'ICD10-CM')
--
SELECT
	dd.diagnosis_id,
	dd.diagnosis_code,
	dd.diagnosis_description
FROM	
	hf_d_diagnosis dd
WHERE
        dd.diagnosis_type = 'ICD9'
ORDER BY
	dd.diagnosis_code
	;
--
