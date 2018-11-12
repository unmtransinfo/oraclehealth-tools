--
SELECT DISTINCT
	COUNT(DISTINCT fe3.patient_id) AS "patient_count",
	COUNT(DISTINCT fe3.encounter_id) AS "encounter_count",
	dm3.medication_id,
	dm3.ndc_code,
	dm3.brand_name,
	dm3.generic_name,
	fe3.admitted_dt_tm::CHAR(4) AS "year"
FROM
	hf_f_encounter fe3
JOIN
	hf_f_medication fm3 ON fm3.encounter_id = fe3.encounter_id
JOIN
	hf_d_medication dm3 ON dm3.medication_id = fm3.medication_id
WHERE
	LOWER(dm3.generic_name) ILIKE 'insulin%'
GROUP BY
	dm3.medication_id,
	dm3.ndc_code,
        dm3.brand_name,
	dm3.generic_name,
	year
	;
--
