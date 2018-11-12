-- Patient facts, diagnosis
-- As in hf_utils.java
SELECT DISTINCT
	dsp.surgical_procedure_id,
	dsp.surgical_procedure_desc,
	dsp.anatomic_site,
	dsp.order_specialty,
	dsp.icd9_code,
	fe.encounter_id,
	fe.patient_id,
	fe.patient_type_id,
	fe.age_in_years,
	fe.hospital_id,
	fe.admitted_dt_tm AS date
FROM
	hf_f_surgical_procedure fsp
JOIN
	hf_d_surgical_procedure dsp ON fsp.surgical_procedure_id = dsp.surgical_procedure_id
JOIN
	hf_f_encounter fe ON fsp.encounter_id = fe.encounter_id
WHERE
	fe.patient_id IN (2650678,11878557,77588873,165326136,204984516)
	;
