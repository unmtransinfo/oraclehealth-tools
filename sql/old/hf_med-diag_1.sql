-- Health Facts Medication - Diagnosis stats
-- Only 'Final' diagnoses.
-- Only diagnostic ICD-9-CM codes (Volume 2).
--
SELECT
	COUNT(fe.patient_id) AS "patient_count",
	COUNT(fm.encounter_id) AS "encounter_count",
	dm.medication_id,
	dm.generic_name,
	dm.brand_name,
	dm.ndc_code,
	dd.diagnosis_id,
	dd.diagnosis_code,
	dd.diagnosis_type,
	dd.diagnosis_description
FROM	
        hf_f_medication fm
JOIN
	hf_d_medication dm ON fm.medication_id = dm.medication_id
JOIN
	hf_f_diagnosis fd ON  fm.encounter_id = fd.encounter_id
JOIN
	hf_d_diagnosis dd ON fd.diagnosis_id = dd.diagnosis_id
JOIN
        hf_d_diagnosis_type ddt ON fd.diagnosis_type_id = ddt.diagnosis_type_id
JOIN
	hf_f_encounter fe ON fm.encounter_id = fe.encounter_id
WHERE
        fm.med_started_dt_tm BETWEEN CAST('2013-01-01' AS date) AND CAST('2013-12-31' AS date)
        AND dm.generic_name NOT IN ('LVP solution', 'sodium chloride')
        AND ddt.diagnosis_type_display = 'Final'
        AND dd.diagnosis_code LIKE '[0-9][0-9][0-9].%'
GROUP BY
	dm.medication_id,
	dm.generic_name,
	dm.brand_name,
	dm.ndc_code,
	dd.diagnosis_id,
	dd.diagnosis_code,
	dd.diagnosis_type,
	dd.diagnosis_description,
	ddt.diagnosis_type_display
ORDER BY
	patient_count DESC
	;
--
--
