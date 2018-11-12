-- Patient facts, diagnosis
-- As in hf_utils.java
SELECT DISTINCT
	fe.encounter_id,
	fe.patient_id,
	fe.patient_type_id,
	fe.age_in_years,
	fe.hospital_id,
	fe.admitted_dt_tm AS date,
	dlp.lab_procedure_id,
	dlp.lab_procedure_name,
	dlp.lab_procedure_mnemonic,
	dlp.lab_procedure_group,
	dlp.lab_super_group,
	dlp.loinc_code,
	flp.numeric_result,
	flp.result_units_id,
	du.unit_display,
	du.unit_desc
FROM
	hf_f_lab_procedure flp
JOIN
	hf_f_encounter fe ON flp.encounter_id = fe.encounter_id
JOIN
        hf_d_unit du ON flp.result_units_id = du.unit_id
JOIN
	hf_d_lab_procedure dlp ON dlp.lab_procedure_id = flp.detail_lab_procedure_id
WHERE
	fe.patient_id IN (2650678,11878557,77588873,165326136,204984516)
	;
