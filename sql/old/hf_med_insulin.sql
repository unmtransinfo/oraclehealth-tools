-- Health Facts Diabetes, Dx + labs + meds
-- Only diagnostic ICD-9-CM codes (Volume 2).
-- Diabetes Codes: 250.*, includes Diabetes Mellitus type-1 and type-2
-- Here we select type-1 assuming "juvenile" is in all descriptions.
--
SELECT
	dm.medication_id,
	dm.generic_name,
	dm.brand_name,
	dm.ndc_code,
	dm.route_description
FROM
	hf_d_medication dm
WHERE
	LOWER(dm.generic_name) LIKE 'insulin%'
	;
--
