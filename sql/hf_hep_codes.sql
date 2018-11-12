-- Health Facts Diagnoses
-- 
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
	AND (
	  dd.diagnosis_description ILIKE '%Hepatitis B%'
	  OR dd.diagnosis_description ILIKE '%Hepatitis C%'
	  OR dd.diagnosis_description ILIKE '%Alcoholic%Hepatitis%'
	)
ORDER BY
	dd.diagnosis_code
	;
--
-- AND CAST(SUBSTRING(dd.diagnosis_code,1,3) AS INTEGER) = 250
