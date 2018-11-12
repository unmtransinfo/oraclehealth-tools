-- Health Facts Medication - Patient - Diagnosis links
-- Only 'Final' diagnoses.
-- Only diagnostic ICD-9-CM codes.
--
SELECT
	fe1.patient_id,
	dm.medication_id,
	fe1.admitted_dt_tm::CHAR(10) AS "med_date",
	fd.diagnosis_id,
	fe2.admitted_dt_tm::CHAR(10) AS "diag_date",
	(EXTRACT(EPOCH FROM fe1.admitted_dt_tm-fe2.admitted_dt_tm)/3600/24)::INTEGER AS "interval_days"
FROM	
	hf_f_encounter fe1
JOIN
        hf_f_medication fm ON fm.encounter_id = fe1.encounter_id
JOIN
	hf_d_medication dm ON fm.medication_id = dm.medication_id
JOIN
	hf_f_encounter fe2 ON fe1.patient_id = fe2.patient_id
JOIN
	hf_f_diagnosis fd ON  fe2.encounter_id = fd.encounter_id
JOIN
        hf_d_diagnosis dd ON fd.diagnosis_id = dd.diagnosis_id
JOIN
        hf_d_diagnosis_type ddt ON fd.diagnosis_type_id = ddt.diagnosis_type_id
WHERE
        ddt.diagnosis_type_display = 'Final'
	AND dd.diagnosis_code SIMILAR TO '\d\d\d\.%'
	AND fe1.admitted_dt_tm::date BETWEEN '2010-01-01'::date AND '2010-06-30'::date
        AND ((EXTRACT(EPOCH FROM fe1.admitted_dt_tm-fe2.admitted_dt_tm)/3600/24)::INTEGER BETWEEN -3 AND 3)
	AND  RANDOM() < 0.01
	;
--
-- AND fe1.admitted_dt_tm::CHAR(4) = '2010'
-- AND fe1.admitted_dt_tm::CHAR(7) = '2010-01'
-- LIMIT 1000000
