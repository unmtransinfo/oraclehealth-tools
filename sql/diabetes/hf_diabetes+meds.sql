-- Health Facts Diabetes, Dx + meds
--
--
SELECT DISTINCT
	fe1.patient_id,
	dd1.diagnosis_code,
	dm3.medication_id,
	dm3.generic_name,
	fe1.admitted_dt_tm AS dx_date,
	fe3.admitted_dt_tm AS med_date,
	(EXTRACT(EPOCH FROM fe3.admitted_dt_tm-fe1.admitted_dt_tm)/3600/24)::INTEGER AS "days_d2m"
FROM
        hf_f_encounter fe1
JOIN
        hf_f_diagnosis fd1 ON fd1.encounter_id = fe1.encounter_id
JOIN
        hf_d_diagnosis dd1 ON fd1.diagnosis_id = dd1.diagnosis_id
JOIN
        hf_d_diagnosis_type ddt1 ON fd1.diagnosis_type_id = ddt1.diagnosis_type_id
JOIN
	hf_d_patient_type dpt1 ON fe1.patient_type_id = dpt1.patient_type_id
JOIN
	hf_f_encounter fe3 ON fe3.patient_id = fe1.patient_id
JOIN
	hf_f_medication fm3 ON fm3.encounter_id = fe3.encounter_id
JOIN
	hf_d_medication dm3 ON dm3.medication_id = fm3.medication_id
WHERE
	fe1.admitted_dt_tm::CHAR(4) = '2010'
        AND dd1.diagnosis_type = 'ICD9'
        AND dd1.diagnosis_code IN ('250.01', '250.03')
        AND dpt1.patient_type_desc = 'Outpatient'
        AND days_d2m BETWEEN 0 AND 365
	AND LOWER(dm3.generic_name) ILIKE 'insulin%'
	AND fe1.patient_type_id = fe3.patient_type_id
	AND RANDOM()<0.01
	;
--
