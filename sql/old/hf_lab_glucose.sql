-- Health Facts Labs - blood glucose distribution
--
SELECT
        t.range AS [glucose],
        COUNT(DISTINCT t.encounter_id) AS [encounters],
        COUNT(DISTINCT t.patient_id) AS [patients]
FROM	
        (
        SELECT
                CASE
                WHEN flp.numeric_result IS NULL THEN 'NULL'
                WHEN flp.numeric_result BETWEEN 0 AND  99 THEN '0000-0099'
                WHEN flp.numeric_result BETWEEN 100 AND 199 THEN '0100-0199'
                WHEN flp.numeric_result BETWEEN 200 AND 299 THEN '0200-0299'
                WHEN flp.numeric_result BETWEEN 300 AND 399 THEN '0300-0399'
                WHEN flp.numeric_result BETWEEN 400 AND 499 THEN '0400-0499'
                WHEN flp.numeric_result BETWEEN 500 AND 599 THEN '0500-0599'
                WHEN flp.numeric_result BETWEEN 600 AND 699 THEN '0600-0699'
                WHEN flp.numeric_result BETWEEN 700 AND 799 THEN '0700-0799'
                WHEN flp.numeric_result BETWEEN 800 AND 899 THEN '0800-0899'
                WHEN flp.numeric_result BETWEEN 900 AND 999 THEN '0900-0999'
                WHEN flp.numeric_result >= 1000 THEN '1000+'
                ELSE 'ERROR'
                END AS range,
                fe.encounter_id,
                fe.patient_id
        FROM
        	hf_f_lab_procedure flp
	JOIN
		hf_f_encounter fe ON flp.encounter_id = fe.encounter_id
	JOIN
		hf_d_lab_procedure dlp ON dlp.lab_procedure_id = CAST(flp.detail_lab_procedure_id AS INTEGER)
        WHERE
                fe.admitted_dt_tm BETWEEN CAST('2013-01-01' AS date) AND CAST('2013-12-31' AS date)
		AND dlp.lab_procedure_id = 52
        ) t
GROUP BY t.range
	;
--
