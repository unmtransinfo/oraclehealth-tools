-- Health Facts Events
-- From data dictionary: 
--	Clinical Event Facts – Each record in the clinical event fact table
--	has a different event per event time and result. The same encounter
--	can have many records in this table. Clinical events were new in 2009
--	and at this time not all contributors are providing these.
--
-- SLOW: 42+ hrs.
--
SELECT
	COUNT(DISTINCT fe.patient_id) AS "patient_count",
	COUNT(DISTINCT fe.encounter_id) AS "encounter_count",
	dec.event_code_id,
	dec.event_code_desc,
	dec.event_code_display,
	dec.event_code_group,
	dec.event_code_category
FROM	
        hf_f_clinical_event fce
JOIN
	hf_f_encounter fe ON fce.encounter_id = fe.encounter_id
JOIN
	hf_d_event_code dec ON fce.event_code_id = dec.event_code_id
GROUP BY
        dec.event_code_id,
	dec.event_code_desc,
	dec.event_code_display,
	dec.event_code_group,
	dec.event_code_category
ORDER BY
	patient_count DESC
	;
--
