-- Health Facts Medication - top meds
-- "LVP Solution" means Large Volume Parenteral
--
SELECT
	COUNT(DISTINCT fe.patient_id) AS [patient_count],
	COUNT(DISTINCT fe.encounter_id) AS [encounter_count],
	dm.medication_id,
	dm.generic_name,
	dm.brand_name,
	dm.ndc_code
FROM	
        hf_f_medication fm
JOIN
	hf_d_medication dm ON fm.medication_id = dm.medication_id
JOIN
	hf_f_encounter fe ON fm.encounter_id = fe.encounter_id
WHERE
        fe.admitted_dt_tm BETWEEN CAST('2013-01-01' AS date) AND CAST('2013-12-31' AS date)
GROUP BY
	dm.medication_id,
	dm.generic_name,
	dm.brand_name,
	dm.ndc_code
ORDER BY
	patient_count DESC
	;
--
