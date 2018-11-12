--
SELECT
	COUNT(t.encounter_id) AS "encounter_count",
	t.year
FROM
        (
        SELECT
                fe.encounter_id,
                fe.admitted_dt_tm::CHAR(4) AS "year"
        FROM
        	hf_f_encounter fe
        ) t
GROUP BY
        t.year
ORDER BY
        t.year
        ;
--
