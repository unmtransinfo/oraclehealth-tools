-- Health Facts Patients - types
--
SELECT
	COUNT(DISTINCT dp.patient_id) AS "patient_count",
	COUNT(DISTINCT fe.encounter_id) AS "encounter_count",
	dp.gender,
	dp.race
FROM	
        hf_d_patient dp
JOIN
	hf_f_encounter fe ON dp.patient_id = fe.patient_id
JOIN
	hf_d_patient_type dpt ON fe.patient_type_id = dpt.patient_type_id
JOIN
        hf_d_hospital dh ON dh.hospital_id = fe.hospital_id
WHERE
	fe.admitted_dt_tm BETWEEN CAST('2013-01-01' AS date) AND CAST('2013-12-31' AS date)
--	AND dh.census_region = 'West'
--	AND dh.census_division = 8
--	AND dp.gender IN ('Male','Female')
GROUP BY
	dp.gender,
	dp.race
ORDER BY
	dp.gender,
	dp.race,
	patient_count DESC
	;
--
