-- Health Facts Diagnoses
-- Only diagnostic ICD-9-CM codes (Volume 2).
-- Cancer Codes: [140-209] + [230-234], to avoid benign & uncertain neoplasms.
--
SELECT
	dd.diagnosis_id,
	dd.diagnosis_code,
	dd.diagnosis_type,
	dd.diagnosis_description
FROM	
	hf_d_diagnosis dd
WHERE
	dd.diagnosis_code LIKE '[0-9][0-9][0-9].%'
	AND ( CAST(SUBSTRING(dd.diagnosis_code,1,3) AS INTEGER) BETWEEN 140 AND 209
	      OR CAST(SUBSTRING(dd.diagnosis_code,1,3) AS INTEGER) BETWEEN 230 AND 234
	    )
ORDER BY
	dd.diagnosis_code
	;
--
