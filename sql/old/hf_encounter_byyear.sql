--
SELECT
	COUNT(t.encounter_id) AS "encounter_count",
	t.year
FROM
        (
        SELECT
                fe.encounter_id,
                SUBSTRING(CAST(CAST(fe.admitted_dt_tm AS date) AS CHAR),1,4) AS "year"
        FROM
        	hf_f_encounter fe
        ) t
GROUP BY
        t.year
ORDER BY
        t.year
        ;
--
