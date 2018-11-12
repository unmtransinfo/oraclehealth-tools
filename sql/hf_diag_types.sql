-- Health Facts diagnosis types
--
SELECT
	COUNT(DISTINCT fd.encounter_id) AS "dx_count",
	dd.diagnosis_type,
	EXTRACT(YEAR FROM fe.admitted_dt_tm) AS "year"
FROM	
	hf_f_diagnosis fd
JOIN
	hf_f_encounter fe ON fd.encounter_id = fe.encounter_id
JOIN
        hf_d_diagnosis dd ON fd.diagnosis_id = dd.diagnosis_id
GROUP BY
        dd.diagnosis_type,
	year
ORDER BY
        dd.diagnosis_type,
	year
	;
--
