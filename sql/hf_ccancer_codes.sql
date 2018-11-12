-- Health Facts Diagnoses
-- Only diagnostic ICD-9-CM codes (Volume 2).
-- Diabetes Codes: 250.*, includes Diabetes Mellitus type-1 and type-2
--
SELECT
	dd.diagnosis_id,
	dd.diagnosis_code,
	dd.diagnosis_type,
	dd.diagnosis_description
FROM	
	hf_d_diagnosis dd
WHERE
	dd.diagnosis_code SIMILAR TO '\d\d\d\.%'
	AND CAST(SUBSTRING(dd.diagnosis_code,1,3) AS INTEGER) IN (153,154)
ORDER BY
	dd.diagnosis_code
	;
--
