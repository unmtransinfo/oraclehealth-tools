-- Health Facts Diagnoses - Breast Cancer
-- 
-- Only diagnostic ICD-9-CM codes (Volume 2).
-- Breast Cancer Codes: [140-209].* + [230-234].*, to avoid benign & uncertain neoplasms.
--
-- 174.0 Malignant Neoplasm of Nipple and Areola of Female Breast
-- 174.1 Malignant Neoplasm of Central Portion of Female Breast
-- 174.2 Malignant Neoplasm of Upper-Inner Quadrant of Female Breast
-- 174.3 Malignant Neoplasm of Lower-Inner Quadrant of Female Breast
-- 174.4 Malignant Neoplasm of Upper-Outer Quadrant of Female Breast
-- 174.5 Malignant Neoplasm of Lower-Outer Quadrant of Female Breast
-- 174.6 Malignant Neoplasm of Axillary Tail of Female Breast
-- 174.8 Malignant Neoplasm of Other Specified Sites of Female Breast
-- 174.9 Malignant Neoplasm of Breast (Female), Unspecified
-- 198.81 Secondary Malignant Neoplasm of Breast
-- 233.0 Carcinoma in Situ of Breast
--
-- Diabetes Codes: 250.*, includes type-1 and type-2 Diabetes Mellitus
--
--
SELECT
	dd.diagnosis_id,
	dd.diagnosis_code,
	dd.diagnosis_type,
	dd.diagnosis_description
FROM
	hf_d_diagnosis dd
WHERE
	dd.diagnosis_code LIKE '[0-9][0-9][0-9].%'
	AND dd.diagnosis_code IN ('174.0', '174.1', '174.2', '174.3', '174.4', '174.5', '174.6', '174.8', '174.9', '198.81', '233.0')
	;
--
