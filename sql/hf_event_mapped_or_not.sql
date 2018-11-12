-- Health Facts Events
--
SELECT DISTINCT
	fce.event_code_id,
	dec.event_code_desc
FROM	
        hf_f_clinical_event fce
LEFT OUTER JOIN
	hf_d_event_code dec ON dec.event_code_id = fce.event_code_id
ORDER BY
	fce.event_code_id
	;
--
