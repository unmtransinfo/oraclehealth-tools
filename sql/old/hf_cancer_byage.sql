-- Health Facts Diagnoses - top diagnoses
-- Only 'Final' diagnoses.
-- Only diagnostic ICD-9-CM codes (Volume 2).
-- Cancer Codes: [140-209] + [230-234], to avoid benign & uncertain neoplasms.
--
-- - age ranges
--
SELECT
	COUNT(DISTINCT age_table.encounter_id) AS [encounters],
	COUNT(DISTINCT age_table.patient_id) AS [patients],
	age_table.agerange,
	age_table.diagnosis_code,
	age_table.diagnosis_description
FROM
	(
	SELECT
		CASE  
		WHEN fe.age_in_years BETWEEN  0 AND 17 THEN '00-17'
		WHEN fe.age_in_years BETWEEN 18 AND 64 THEN '18-64'
		WHEN fe.age_in_years >= 65 THEN '65+'
		ELSE 'Unknown'
		END AS agerange,
		fe.encounter_id,
		fe.patient_id,
		dd.diagnosis_code,
		dd.diagnosis_description
	FROM
		hf_f_encounter fe
	JOIN
		hf_f_diagnosis fd ON fd.encounter_id = fe.encounter_id
	JOIN
		hf_d_diagnosis dd ON fd.diagnosis_id = dd.diagnosis_id
	JOIN
        	hf_d_diagnosis_type ddt ON fd.diagnosis_type_id = ddt.diagnosis_type_id
	WHERE
        	fe.admitted_dt_tm BETWEEN CAST('2013-01-01' AS date) AND CAST('2013-12-31' AS date)
        	AND ddt.diagnosis_type_display = 'Final'
		AND dd.diagnosis_code LIKE '[0-9][0-9][0-9].%'
		AND ( CAST(SUBSTRING(dd.diagnosis_code,1,3) AS INTEGER) BETWEEN 140 AND 209
		  OR CAST(SUBSTRING(dd.diagnosis_code,1,3) AS INTEGER) BETWEEN 230 AND 234
		  )
	) age_table
GROUP BY
        age_table.agerange,
        age_table.diagnosis_code,
	age_table.diagnosis_description
	;
--
