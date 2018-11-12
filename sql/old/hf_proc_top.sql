-- Health Facts Procedures - top procedures
--
SELECT
	COUNT(DISTINCT fe.patient_id) AS "patient_count",
	COUNT(DISTINCT fe.encounter_id) AS "encounter_count",
	dp.procedure_id,
	dp.procedure_code,
	dp.procedure_type,
	dp.procedure_description
FROM	
        hf_f_procedure fp
JOIN
	hf_d_procedure dp ON fp.procedure_id = dp.procedure_id
JOIN
	hf_f_encounter fe ON fp.encounter_id = fe.encounter_id
GROUP BY
	dp.procedure_id,
	dp.procedure_code,
	dp.procedure_type,
	dp.procedure_description
ORDER BY
	patient_count DESC
	;
--
