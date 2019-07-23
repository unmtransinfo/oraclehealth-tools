-- Patient facts, diagnosis
-- As in hf_utils.java
SELECT DISTINCT
	dm.medication_id,
	dm.generic_name,
	dm.brand_name,
	dm.ndc_code,
	fe.encounter_id,
	fe.patient_id,
	fe.patient_type_id,
	fe.age_in_years,
	fe.hospital_id,
	fe.admitted_dt_tm AS date
FROM
	hf_f_medication fm
JOIN
	hf_f_encounter fe ON fm.encounter_id = fe.encounter_id
JOIN
	hf_d_medication dm ON fm.medication_id = dm.medication_id
WHERE
	fe.patient_id IN (2650678,11878557,77588873,165326136,204984516)
	;
