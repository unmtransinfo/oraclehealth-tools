-- Health Facts Diagnoses - Colorectal Cancer patients
-- Only 'Final' diagnoses.
-- Only diagnostic ICD-9-CM codes (Volume 2).
-- 
-- 153 Malignant neoplasm of colon
-- 153.0 Malignant neoplasm of hepatic flexure
-- 153.1 Malignant neoplasm of transverse colon
-- 153.2 Malignant neoplasm of descending colon
-- 153.3 Malignant neoplasm of sigmoid colon
-- 153.4 Malignant neoplasm of cecum
-- 153.5 Malignant neoplasm of appendix vermiformis
-- 153.6 Malignant neoplasm of ascending colon
-- 153.7 Malignant neoplasm of splenic flexure
-- 153.8 Malignant neoplasm of other specified sites of large intestine
-- 153.9 Malignant neoplasm of colon, unspecified site
-- 154 Malignant neoplasm of rectum rectosigmoid junction and anus
-- 154.0 Malignant neoplasm of rectosigmoid junction
-- 154.1 Malignant neoplasm of rectum
-- 154.2 Malignant neoplasm of anal canal
-- 154.3 Malignant neoplasm of anus, unspecified site
-- 154.8 Malignant neoplasm of other sites of rectum, rectosigmoid junction, and anus
--
--
SELECT
	dp.patient_sk,
	dp.gender,
	dp.race,
	fe1.patient_id,
	dd1.diagnosis_code AS "ccancer_code",
	CAST(fe1.admitted_dt_tm AS DATE) AS "ccancer_date"
FROM
	hf_f_encounter fe1
JOIN
	hf_d_patient dp ON fe1.patient_id = dp.patient_id
JOIN
	hf_f_diagnosis fd1 ON fd1.encounter_id = fe1.encounter_id
JOIN
	hf_d_diagnosis dd1 ON fd1.diagnosis_id = dd1.diagnosis_id
JOIN
	(SELECT
		fe.patient_id,
		MIN(fe.admitted_dt_tm)::DATE AS "t_start"
	FROM
		hf_f_encounter fe
	GROUP BY
		fe.patient_id
	) t1 ON fe1.patient_id = t1.patient_id
JOIN
	(SELECT
		fe.patient_id,
		MAX(fe.discharged_dt_tm)::DATE AS "t_end"
	FROM
		hf_f_encounter fe
	GROUP BY
		fe.patient_id
	) t2 ON fe1.patient_id = t2.patient_id
WHERE
	dd1.diagnosis_code SIMILAR TO '\d\d\d\.%'
	AND CAST(SUBSTRING(dd1.diagnosis_code,1,3) AS INTEGER) IN (153,154)
	AND (t2.t_end - t1.t_start)::INT > (5*365)
	;
--
