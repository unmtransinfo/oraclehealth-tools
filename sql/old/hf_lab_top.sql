-- Health Facts Labs - top lab procedures
-- VERY SLOW (6+ hrs) -- WHY?
--
SELECT
	COUNT(DISTINCT fe.patient_id) AS "patient_count",
	COUNT(DISTINCT flp.encounter_id) AS "encounter_count",
	dlp.lab_procedure_id,
	dlp.lab_procedure_name,
	dlp.lab_procedure_mnemonic,
	dlp.lab_procedure_group,
	dlp.lab_super_group,
	dlp.loinc_code
FROM	
        hf_f_lab_procedure flp
JOIN
	hf_f_encounter fe ON flp.encounter_id = fe.encounter_id
JOIN
	hf_d_lab_procedure dlp ON dlp.lab_procedure_id = CAST(flp.detail_lab_procedure_id AS INTEGER)
WHERE
        fe.admitted_dt_tm BETWEEN CAST('2013-01-01' AS date) AND CAST('2013-12-31' AS date)
GROUP BY
	dlp.lab_procedure_id,
	dlp.lab_procedure_name,
	dlp.lab_procedure_mnemonic,
	dlp.lab_procedure_group,
	dlp.lab_super_group,
	dlp.loinc_code
ORDER BY
	patient_count DESC
	;
--
