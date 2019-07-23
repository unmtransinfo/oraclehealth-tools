-- Patient facts, diagnosis
-- As in hf_utils.java
SELECT DISTINCT
	dmp.med_product_id,
	dmp.drug_code,
	dmp.drug_mnemonic_code,
	dmp.drug_desc,
	dmp.drug_mnemonic_desc,
	fe.encounter_id,
	fe.patient_id,
	fe.patient_type_id,
	fe.age_in_years,
	fe.hospital_id,
	fe.admitted_dt_tm AS date
FROM
	hf_f_med_history fmh
JOIN
	hf_f_encounter fe ON fmh.encounter_id = fe.encounter_id
JOIN
	hf_d_med_product dmp ON fmh.med_product_id = dmp.med_product_id
WHERE
	fe.patient_id IN (2650678,11878557,77588873,165326136,204984516)
	;
