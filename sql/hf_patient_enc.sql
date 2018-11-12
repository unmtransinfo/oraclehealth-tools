-- Health Facts Patient info -- How many encounters per patient?
--
SELECT
	t.enc_count,
	COUNT(t.patient_id)
FROM
	(SELECT
		fe.patient_id,
		COUNT(DISTINCT fe.encounter_id) AS "enc_count"
	FROM
		hf_f_encounter fe
	GROUP BY fe.patient_id
	) t
GROUP BY
	t.enc_count
ORDER BY
	t.enc_count
	;
--
