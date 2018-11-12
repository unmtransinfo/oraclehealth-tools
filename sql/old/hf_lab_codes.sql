-- Health Facts labs
--
SELECT
	dlp.lab_procedure_id,
	dlp.lab_procedure_mnemonic,
	dlp.lab_procedure_name,
	dlp.lab_procedure_group,
	dlp.lab_super_group,
	dlp.loinc_code,
	dlp.loinc_ind,
	du.unit_display,
	du.unit_desc
FROM
	hf_d_lab_procedure dlp 
JOIN
	hf_d_unit du ON dlp.result_units_id = du.unit_id
	;
--
