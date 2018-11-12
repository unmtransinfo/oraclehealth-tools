-- Health Facts Patients - IDs.  Are they random-ish?
--
SELECT
	t.idgroup,
	COUNT(*) AS [patients]
FROM
	(
	SELECT
		(dp.patient_id % 100) AS [idgroup]
	FROM
		hf_d_patient dp
	) t
GROUP BY t.idgroup
ORDER BY t.idgroup
	;
--
