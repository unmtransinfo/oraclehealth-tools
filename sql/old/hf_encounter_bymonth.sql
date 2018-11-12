--
SELECT
	COUNT(t.encounter_id) AS "encounter_count",
	t.month
FROM
        (
        SELECT
                fe.encounter_id,
                SUBSTRING(CAST(CAST(fe.admitted_dt_tm AS date) AS CHAR),6,2) AS "month"
        FROM
        	hf_f_encounter fe
	WHERE
		fe.admitted_dt_tm BETWEEN CAST('2014-01-01' AS date) AND CAST('2014-12-31' AS date)
        ) t
GROUP BY
        t.month
ORDER BY
        t.month
        ;
--
