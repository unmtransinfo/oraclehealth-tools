-- Health Facts Patient info -- What is present?
-- Clinical events.
--
SELECT
	( SELECT COUNT(DISTINCT fe.patient_id) FROM hf_f_encounter fe JOIN hf_f_clinical_event fce ON fe.encounter_id = fce.encounter_id JOIN hf_d_event_code dec ON fce.event_code_id = dec.event_code_id WHERE dec.event_code_desc = 'Height' AND fce.result_value_num IS NOT NULL) AS [patient_height],
	( SELECT COUNT(DISTINCT fe.encounter_id) FROM hf_f_encounter fe JOIN hf_f_clinical_event fce ON fe.encounter_id = fce.encounter_id JOIN hf_d_event_code dec ON fce.event_code_id = dec.event_code_id WHERE dec.event_code_desc = 'Height' AND fce.result_value_num IS NOT NULL) AS [encounter_height]
	;
--
