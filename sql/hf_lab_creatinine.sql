--
-- Count all encounters for specified lab results.
--
SELECT
	COUNT(flp.encounter_id) AS "encounter_count",
	dlp.lab_procedure_id,
	dlp.lab_procedure_name
FROM
	hf_f_lab_procedure flp,
	hf_d_lab_procedure dlp
WHERE
	dlp.lab_procedure_id = flp.detail_lab_procedure_id
	AND dlp.lab_procedure_name ILIKE '%creatinine%serum%'
GROUP BY
	dlp.lab_procedure_id,
        dlp.lab_procedure_name
	;
--
--	
--
--	dlp.lab_procedure_id,
--	dlp.lab_procedure_id,
--	COUNT(fe.patient_id) AS "patient_count",
-- JOIN hf_f_encounter fe ON flp.encounter_id = fe.encounter_id
