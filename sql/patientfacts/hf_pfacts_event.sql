-- Patient facts, diagnosis
-- As in hf_utils.java
SELECT DISTINCT
	fe.encounter_id,
	fe.patient_id,
	fe.patient_type_id,
	fe.age_in_years,
	fe.hospital_id,
	fe.admitted_dt_tm AS date,
	dec.event_code_id,
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
JOIN
	hf_d_event_code dec ON fce.event_code_id = dec.event_code_id
JOIN
        hf_d_unit du ON fce.result_units_id = du.unit_id
JOIN
	hf_f_encounter fe ON fce.encounter_id = fe.encounter_id
WHERE
	fe.patient_id IN (2650678,11878557,77588873,165326136,204984516)
	;
