-- Health Facts Patients - types
--
SELECT
	COUNT(DISTINCT dp.patient_id) AS "patient_count",
	COUNT(DISTINCT fe.encounter_id) AS "encounter_count",
	dpt.patient_type_id,
	dpt.patient_type_desc
FROM	
        hf_d_patient dp
JOIN
	hf_f_encounter fe ON dp.patient_id = fe.patient_id
JOIN
	hf_d_patient_type dpt ON fe.patient_type_id = dpt.patient_type_id
WHERE
        fe.admitted_dt_tm BETWEEN CAST('2013-01-01' AS date) AND CAST('2013-12-31' AS date)
GROUP BY
	dpt.patient_type_id,
	dpt.patient_type_desc
ORDER BY
	patient_count DESC
	;
--
--
