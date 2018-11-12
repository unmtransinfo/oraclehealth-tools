-- Health Facts Surgery - top surgeries
--
SELECT
	COUNT(DISTINCT fe.patient_id) AS "patient_count",
	COUNT(DISTINCT fe.encounter_id) AS "encounter_count",
	dsp.surgical_procedure_id,
	dsp.surgical_procedure_desc,
	dsp.anatomic_site,
	dsp.order_specialty,
	dsp.icd9_code
FROM	
        hf_f_surgical_procedure fsp
JOIN
	hf_d_surgical_procedure dsp ON fsp.surgical_procedure_id = dsp.surgical_procedure_id
JOIN
	hf_f_encounter fe ON fsp.encounter_id = fe.encounter_id
GROUP BY
	dsp.surgical_procedure_id,
	dsp.surgical_procedure_desc,
	dsp.anatomic_site,
	dsp.order_specialty,
	dsp.icd9_code
ORDER BY
	patient_count DESC
	;
--
