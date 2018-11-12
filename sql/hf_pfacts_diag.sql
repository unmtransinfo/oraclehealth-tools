-- Patient facts, diagnosis
-- As in hf_utils.java
SELECT DISTINCT
	dd.diagnosis_id,
	dd.diagnosis_code,
	dd.diagnosis_type,
	dd.diagnosis_description,
	fe.encounter_id,
	fe.patient_id,
	fe.patient_type_id,
	fe.age_in_years,
	fe.hospital_id,
	fe.admitted_dt_tm AS date
FROM
	hf_f_diagnosis fd
JOIN
	hf_f_encounter fe ON fd.encounter_id = fe.encounter_id
JOIN
	hf_d_diagnosis dd ON fd.diagnosis_id = dd.diagnosis_id
JOIN
	hf_d_diagnosis_type ddt ON fd.diagnosis_type_id = ddt.diagnosis_type_id
WHERE
	dd.diagnosis_code SIMILAR TO '\d\d\d\.%'
	AND fe.patient_id IN (2650678,11878557,77588873,165326136,204984516)
	;
