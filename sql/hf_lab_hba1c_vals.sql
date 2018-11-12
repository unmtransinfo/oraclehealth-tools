-- 
SELECT
	dlp1.lab_procedure_id,
	flp1.numeric_result,
	flp1.result_indicator_id,
	EXTRACT(YEAR FROM fe1.admitted_dt_tm) AS "year"
FROM
	hf_f_encounter fe1
JOIN
	hf_f_lab_procedure flp1 ON flp1.encounter_id = fe1.encounter_id
JOIN
	hf_d_lab_procedure dlp1 ON dlp1.lab_procedure_id = flp1.detail_lab_procedure_id
WHERE
	dlp1.lab_procedure_name ILIKE 'Hemoglobin A1C%'
	AND flp1.numeric_result IS NOT NULL
	AND RANDOM()<0.1
	;
--
-- AND RANDOM()<0.01
