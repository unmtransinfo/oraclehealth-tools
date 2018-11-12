-- Health Facts Patients - weight ranges
--
-- PROBABLY USELESS BECAUSE THIS FIELD NOT POPULATED!
-- SEE F_CLINICAL_EVENT TABLE FOR WEIGHT.
--
SELECT
	weight_table.range AS [weight],
	COUNT(DISTINCT weight_table.patient_id) AS [patients],
	COUNT(DISTINCT weight_table.encounter_id) AS [encounters]
FROM
	(
	SELECT
		CASE
		WHEN fe.weight IS NULL THEN 'NULL'
		WHEN fe.weight BETWEEN 0 AND  100 THEN '000-100'
		WHEN fe.weight BETWEEN 100 AND 150 THEN '100-150'
		WHEN fe.weight BETWEEN 150 AND 200 THEN '150-200'
		WHEN fe.weight BETWEEN 200 AND 250 THEN '200-250'
		WHEN fe.weight BETWEEN 250 AND 300 THEN '250-300'
		WHEN fe.weight > 300 THEN '300+'
		ELSE 'ERROR'
		END AS range,
		fe.encounter_id,
		fe.patient_id
	FROM
		hf_f_encounter fe
	WHERE
                fe.admitted_dt_tm BETWEEN CAST('2013-01-01' AS date) AND CAST('2013-12-31' AS date)
	) weight_table
GROUP BY weight_table.range
	;
--
