-- Health Facts Patients - types
-- Patient type is more accurately an encounter attribute.
--
SELECT
	COUNT(DISTINCT dp.patient_id) AS "patient_count",
	COUNT(DISTINCT fe.encounter_id) AS "encounter_count",
	COUNT(DISTINCT fe.encounter_id)::FLOAT / COUNT(DISTINCT dp.patient_id) AS "encounters_per_patient",
	dpt.patient_type_id,
	dpt.patient_type_desc
FROM	
        hf_d_patient dp
JOIN
	hf_f_encounter fe ON dp.patient_id = fe.patient_id
JOIN
	hf_d_patient_type dpt ON fe.patient_type_id = dpt.patient_type_id
GROUP BY
	dpt.patient_type_id,
	dpt.patient_type_desc
ORDER BY
	patient_count DESC
	;
--
