-- Health Facts Vital Signs:
--	weight
--
SELECT
	dp.patient_sk,
	dp.patient_id,
	dec.event_code_desc,
	dec.event_code_display,
	dec.event_code_group,
	dec.event_code_category,
	fce.result_value_num,
	fce.result_units_id,
	du.unit_display,
	du.unit_desc
FROM	
        hf_f_clinical_event fce
        JOIN hf_f_encounter fe ON fce.encounter_id = fe.encounter_id
        JOIN hf_d_event_code dec ON fce.event_code_id = dec.event_code_id
        JOIN hf_d_unit du ON du.unit_id = fce.result_units_id
        JOIN hf_d_patient dp ON dp.patient_id = fe.patient_id
WHERE
	(dec.event_code_desc LIKE 'Weight%' OR dec.event_code_desc LIKE 'Height%')
	AND fce.result_value_num IS NOT NULL
        AND dp.patient_sk::INTEGER IN (1985352)
ORDER BY
	dp.patient_sk,
	dp.patient_id,
	dec.event_code_desc
	;
--
