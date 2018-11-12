-- Health Facts Diagnoses - Hepatitis
-- Only 'Final' diagnoses.
--
--
SELECT
	fe1.patient_id,
	dd1.diagnosis_code,
	CAST(fe1.admitted_dt_tm AS DATE) AS "admit_date"
FROM
	hf_f_encounter fe1
JOIN
	hf_f_diagnosis fd1 ON fd1.encounter_id = fe1.encounter_id
JOIN
	hf_d_diagnosis dd1 ON fd1.diagnosis_id = dd1.diagnosis_id
JOIN
	hf_d_diagnosis_type ddt ON fd1.diagnosis_type_id = ddt.diagnosis_type_id
WHERE
	dd1.diagnosis_code SIMILAR TO '\d\d\d\.%'
	AND ddt.diagnosis_type_display = 'Final'
	AND (
	  dd1.diagnosis_description ILIKE '%Hepatitis B%'
	  OR dd1.diagnosis_description ILIKE '%Hepatitis C%'
	  OR dd1.diagnosis_description ILIKE '%Alcoholic%Hepatitis%'
	)
	AND fe1.admitted_dt_tm::CHAR(4) = '2014'
	;
--
