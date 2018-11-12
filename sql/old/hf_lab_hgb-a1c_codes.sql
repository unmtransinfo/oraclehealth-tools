-- Health Facts Diabetes, Dx + labs + meds
-- Only diagnostic ICD-9-CM codes (Volume 2).
-- Diabetes Codes: 250.*, includes Diabetes Mellitus type-1 and type-2
-- Here we select type-1 assuming "juvenile" is in all descriptions.
--
SELECT
	dlp.lab_procedure_id,
	dlp.lab_procedure_mnemonic,
	dlp.lab_procedure_name,
	dlp.lab_procedure_group,
	dlp.lab_super_group,
	dlp.loinc_code,
	dlp.loinc_ind
FROM
	hf_d_lab_procedure dlp 
WHERE
	dlp.lab_procedure_name LIKE 'Hemoglobin A1C%'
	;
--
