-- Sample of outpatients with labs in 2015.
CREATE TABLE jjyang.patient_sample_2015
	AS
SELECT
	t.patient_id
FROM (
	SELECT DISTINCT 
		dp.patient_id
	FROM
		hf_f_lab_procedure flp
--	JOIN
--		hf_d_lab_procedure dlp ON dlp.lab_procedure_id = flp.detail_lab_procedure_id
	JOIN
		hf_f_encounter fe ON fe.encounter_id = flp.encounter_id
	JOIN
		hf_d_patient dp ON dp.patient_id = fe.patient_id
	JOIN
		hf_d_patient_type dpt ON fe.patient_type_id = dpt.patient_type_id
	WHERE
		dp.patient_id IS NOT NULL
		AND dpt.patient_type_desc = 'Outpatient'
		AND DATE_PART('year', fe.admitted_dt_tm) = 2015
	) AS t
WHERE
	RANDOM() < 0.01
ORDER BY
	t.patient_id
	;
