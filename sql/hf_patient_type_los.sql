-- Health Facts 
--
SELECT
        dpt.patient_type_id,
        dpt.patient_type_desc,
	CAST(fe.admitted_dt_tm AS DATE) AS "admitted_date",
	(EXTRACT(EPOCH FROM fe.discharged_dt_tm-fe.admitted_dt_tm)/3600)::INTEGER AS "los_hrs"
FROM
	hf_f_encounter fe
JOIN
	hf_d_patient_type dpt ON fe.patient_type_id = dpt.patient_type_id
WHERE
        fe.discharged_dt_tm >= fe.admitted_dt_tm
	AND fe.admitted_dt_tm BETWEEN CAST('2014-01-01' AS date) AND CAST('2014-12-31' AS date)
ORDER BY RANDOM()
LIMIT 100000
	;
--
