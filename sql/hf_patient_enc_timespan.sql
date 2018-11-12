-- Health Facts Patient info -- What is the timespan of patient encounters?
--
SELECT
	t.enc_tspan,
	TO_CHAR(AVG(t.enc_count),'FM999.90') AS "avg_enc",
	COUNT(t.patient_id)
FROM
	(SELECT
		fe.patient_id,
		COUNT(DISTINCT fe.encounter_id) AS "enc_count",
		(MAX(fe.discharged_dt_tm)::DATE - MIN(fe.admitted_dt_tm)::DATE)::INT AS "enc_tspan"
	FROM
		hf_f_encounter fe
	GROUP BY fe.patient_id
	) t
GROUP BY
	t.enc_tspan
ORDER BY
	t.enc_tspan
	;
--
