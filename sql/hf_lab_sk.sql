--
-- Find all lab results for a given patient_sk.
--
SELECT
	dlp.lab_procedure_id,
	dlp.lab_procedure_name,
	dlp.lab_procedure_mnemonic,
	dlp.lab_procedure_group,
	dlp.lab_super_group,
	dlp.loinc_code,
	flp.encounter_id,
	fe.patient_id,
	fe.patient_type_id,
	fe.hospital_id,
	fe.admitted_dt_tm AS date
FROM
	hf_f_lab_procedure flp
JOIN
	hf_f_encounter fe ON flp.encounter_id = fe.encounter_id
JOIN
	hf_d_lab_procedure dlp ON dlp.lab_procedure_id = flp.detail_lab_procedure_id
WHERE
	fe.patient_id IN (SELECT patient_id FROM hf_d_patient WHERE patient_sk::INTEGER = 1985352)
	;
--
