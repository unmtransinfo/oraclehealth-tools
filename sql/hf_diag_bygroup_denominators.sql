-- Health Facts Diagnosis counts by gender
-- Denominators needed for normalized incidence (per 100K),
-- all patients with any diagnoses.
--
SELECT
	dp.gender,
	dp.race,
	EXTRACT(YEAR FROM fe.admitted_dt_tm)::INTEGER AS "year",
	COUNT(DISTINCT fd.encounter_id) AS "dx_count",
 	COUNT(DISTINCT fe.patient_id) AS "patient_count"
FROM
        hf_f_diagnosis fd
JOIN
	hf_f_encounter fe ON fe.encounter_id = fd.encounter_id
JOIN
	hf_d_patient dp ON dp.patient_id = fe.patient_id
WHERE
	dp.gender IS NOT NULL
        AND dp.race IS NOT NULL
GROUP BY
	dp.gender,
	dp.race,
	year
	;
--
