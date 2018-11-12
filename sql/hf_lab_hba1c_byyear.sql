-- 
SELECT
	COUNT(DISTINCT fe1.patient_id) AS "patient_count",
	COUNT(DISTINCT fe1.encounter_id) AS "encounter_count",
	dlp1.lab_procedure_id,
	dlp1.lab_procedure_name,
	fe1.admitted_dt_tm::CHAR(4) AS "year"
FROM
	hf_f_encounter fe1
JOIN
	hf_f_lab_procedure flp1 ON flp1.encounter_id = fe1.encounter_id
JOIN
	hf_d_lab_procedure dlp1 ON dlp1.lab_procedure_id = flp1.detail_lab_procedure_id
WHERE
	dlp1.lab_procedure_name ILIKE 'Hemoglobin A1C%'
GROUP BY
	dlp1.lab_procedure_id,
	dlp1.lab_procedure_name,
	year
	;
--
