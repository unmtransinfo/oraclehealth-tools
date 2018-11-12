-- Health Facts Patients - age ranges
--
SELECT
	age_table.agerange AS [age],
	COUNT(DISTINCT age_table.encounter_id) AS [encounters],
	COUNT(DISTINCT age_table.patient_id) AS [patients]
FROM
	(
	SELECT
		CASE  
		WHEN fe.age_in_years BETWEEN  0 AND 17 THEN '00-17'
		WHEN fe.age_in_years BETWEEN 18 AND 64 THEN '18-64'
		WHEN fe.age_in_years >= 65 THEN '65+'
		ELSE 'Unknown'
		END AS agerange,
		fe.encounter_id,
		fe.patient_id
	FROM
		hf_f_encounter fe
	WHERE
        	fe.admitted_dt_tm BETWEEN CAST('2013-01-01' AS date) AND CAST('2013-12-31' AS date)
	) age_table
GROUP BY age_table.agerange
	;
--
--	JOIN
--		hf_d_hospital dh ON dh.hospital_id = fe.hospital_id
--		AND dh.census_region = 'West'
--		AND dh.census_division = 8
