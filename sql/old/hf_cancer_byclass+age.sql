-- Health Facts Diagnoses - top diagnoses
-- Only 'Final' diagnoses.
-- Only diagnostic ICD-9-CM codes (Volume 2).
-- Cancer/neoplasm ICD-9-CM codes [140-239].
-- Codes: [140-209] + [230-234], to avoid benign & uncertain neoplasms.
--
SELECT
	COUNT(DISTINCT tcc.patient_id) AS "patient_count",
	COUNT(DISTINCT tcc.encounter_id) AS "encounter_count",
	tcc.cancer_class,
	ta.agerange
FROM
	(
	SELECT
		CASE
		WHEN (CAST(SUBSTRING(dd.diagnosis_code,1,3) AS INTEGER) BETWEEN 140 AND 149) THEN '140-149.99: MALIGNANT NEOPLASM OF LIP, ORAL CAVITY, AND PHARYNX'
		WHEN (CAST(SUBSTRING(dd.diagnosis_code,1,3) AS INTEGER) BETWEEN 150 AND 159) THEN '150-159.99: MALIGNANT NEOPLASM OF DIGESTIVE ORGANS AND PERITONEUM'
		WHEN (CAST(SUBSTRING(dd.diagnosis_code,1,3) AS INTEGER) BETWEEN 160 AND 165) THEN '160-165.99: MALIGNANT NEOPLASM OF RESPIRATORY AND INTRATHORACIC ORGANS'
		WHEN (CAST(SUBSTRING(dd.diagnosis_code,1,3) AS INTEGER) BETWEEN 170 AND 176) THEN '170-176.99: MALIGNANT NEOPLASM OF BONE, CONNECTIVE TISSUE, SKIN, AND BREAST'
		WHEN (CAST(SUBSTRING(dd.diagnosis_code,1,3) AS INTEGER) BETWEEN 179 AND 189) THEN '179-189.99: MALIGNANT NEOPLASM OF GENITOURINARY ORGANS'
		WHEN (CAST(SUBSTRING(dd.diagnosis_code,1,3) AS INTEGER) BETWEEN 190 AND 199) THEN '190-199.99: MALIGNANT NEOPLASM OF OTHER AND UNSPECIFIED SITES'
		WHEN (CAST(SUBSTRING(dd.diagnosis_code,1,3) AS INTEGER) BETWEEN 200 AND 208) THEN '200-208.99: MALIGNANT NEOPLASM OF LYMPHATIC AND HEMATOPOIETIC TISSUE'
		WHEN (CAST(SUBSTRING(dd.diagnosis_code,1,3) AS INTEGER) BETWEEN 209 AND 209) THEN '209-209.99: NEUROENDOCRINE TUMORS'
		WHEN (CAST(SUBSTRING(dd.diagnosis_code,1,3) AS INTEGER) BETWEEN 230 AND 234) THEN '230-234.99: CARCINOMA IN SITU'
		ELSE 'ERROR'
		END AS cancer_class,
		fe.patient_id,
		fe.encounter_id
	FROM
		hf_f_diagnosis fd
	JOIN
		hf_f_encounter fe ON fd.encounter_id = fe.encounter_id
	JOIN
		hf_d_diagnosis dd ON fd.diagnosis_id = dd.diagnosis_id
	JOIN
        	hf_d_diagnosis_type ddt ON fd.diagnosis_type_id = ddt.diagnosis_type_id
	WHERE
        	fe.admitted_dt_tm BETWEEN CAST('2013-01-01' AS date) AND CAST('2013-12-31' AS date)
        	AND ddt.diagnosis_type_display = 'Final'
        	AND dd.diagnosis_code LIKE '[0-9][0-9][0-9].%'
                AND ( CAST(SUBSTRING(dd.diagnosis_code,1,3) AS INTEGER) BETWEEN 140 AND 209
                        OR CAST(SUBSTRING(dd.diagnosis_code,1,3) AS INTEGER) BETWEEN 230 AND 234
            )
	) tcc,
        (
	SELECT
		CASE  
		WHEN fe.age_in_years BETWEEN  0 AND 17 THEN '00-17'
		WHEN fe.age_in_years BETWEEN 18 AND 64 THEN '18-64'
		WHEN fe.age_in_years >= 65 THEN '65+'
		ELSE 'Unknown'
		END AS agerange,
		fe.patient_id,
		fe.encounter_id
	FROM
		hf_f_encounter fe
	JOIN
		hf_f_diagnosis fd ON fd.encounter_id = fe.encounter_id
	JOIN
		hf_d_diagnosis dd ON fd.diagnosis_id = dd.diagnosis_id
	JOIN
		hf_d_diagnosis_type ddt ON fd.diagnosis_type_id = ddt.diagnosis_type_id
	WHERE
		fe.admitted_dt_tm BETWEEN CAST('2013-01-01' AS date) AND CAST('2013-12-31' AS date)
		AND ddt.diagnosis_type_display = 'Final'
		AND dd.diagnosis_code LIKE '[0-9][0-9][0-9].%'
		AND ( CAST(SUBSTRING(dd.diagnosis_code,1,3) AS INTEGER) BETWEEN 140 AND 209
		OR CAST(SUBSTRING(dd.diagnosis_code,1,3) AS INTEGER) BETWEEN 230 AND 234
		)
	) ta
WHERE
	tcc.encounter_id = ta.encounter_id
GROUP BY
	tcc.cancer_class,
	ta.agerange
ORDER BY
	ta.agerange,
	patient_count DESC
	;
--
