-- Health Facts Diagnoses - top diagnoses
-- Only 'Final' diagnoses.
-- Only diagnostic ICD-9-CM codes (Volume 2).
-- Cancer/neoplasm ICD-9-CM codes [140-239].
-- Codes: [140-209] + [230-234], to avoid benign & uncertain neoplasms.
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
        fe.admitted_dt_tm BETWEEN CAST('2013-01-01' AS date) AND fe.admitted_dt_tm CAST('2013-12-31' AS date)
        AND ddt.diagnosis_type_display = 'Final'
	AND dd.diagnosis_code LIKE '[0-9][0-9][0-9].%'
	AND ( CAST(SUBSTRING(dd.diagnosis_code,1,3) AS INTEGER) BETWEEN 140 AND 209
	      OR CAST(SUBSTRING(dd.diagnosis_code,1,3) AS INTEGER) BETWEEN 230 AND 234
	    )
GROUP BY
	dd.diagnosis_id,
	dd.diagnosis_code,
	dd.diagnosis_type,
	dd.diagnosis_description
ORDER BY
	patient_count DESC
	;
--
