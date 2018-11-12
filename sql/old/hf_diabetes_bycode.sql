-- Health Facts Diagnoses
-- Only diagnostic ICD-9-CM codes (Volume 2).
-- Diabetes Codes: 250.*, includes Diabetes Mellitus type-1 and type-2
--
SELECT
	COUNT(DISTINCT fd.encounter_id) AS "encounter_count",
	COUNT(DISTINCT fe.patient_id) AS "patient_count",
	dd.diagnosis_id,
	dd.diagnosis_code,
	dd.diagnosis_type,
	dd.diagnosis_description
FROM	
	hf_f_diagnosis fd
JOIN
	hf_f_encounter fe ON fd.encounter_id = fe.encounter_id
JOIN
	hf_d_diagnosis dd ON fd.diagnosis_id = dd.diagnosis_id
JOIN
	hf_d_diagnosis_type ddt ON fd.diagnosis_type_id = ddt.diagnosis_type_id
WHERE
	ddt.diagnosis_type_display = 'Final'
	AND dd.diagnosis_code LIKE '[0-9][0-9][0-9].%'
	AND CAST(SUBSTRING(dd.diagnosis_code,1,3) AS INTEGER) = 250
GROUP BY
	dd.diagnosis_id,
	dd.diagnosis_code,
	dd.diagnosis_type,
	dd.diagnosis_description
ORDER BY
	patient_count DESC
	;
--
