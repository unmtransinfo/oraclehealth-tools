-- "medication_id","generic_name","brand_name","ndc_code","route_description"
-- 3603,"aminoglutethimide","Cytadren",83002430,"oral"
-- 55850,"letrozole","Femara",78024915,"oral"
-- 24000,"testolactone","Teslac",3069050,"oral"
-- 41931,"anastrozole","Arimidex",310020130,"oral"
-- 113350,"exemestane","Aromasin",9766304,"oral"
-- 
-- Health Facts meds
-- https://en.wikipedia.org/wiki/Aromatase_inhibitor
-- Selective 
--	Anastrozole (Arimidex)
--	Letrozole (Femara)
--	Exemestane (Aromasin)
--	Vorozole (Rivizor)
--	Formestane (Lentaron)
--	Fadrozole (Afema)
-- Non-selective
--	Aminoglutethimide
--	Testolactone (Teslac)
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
        LOWER(dm.generic_name) IN (
		'anastrozole',
		'letrozole',
		'exemestane',
		'vorozole',
		'formestane',
		'fadrozole',
		'aminoglutethimide',
		'testolactone'
	)
	OR LOWER(dm.brand_name) IN (
		'arimidex',
		'femara',
		'aromasin',
		'rivizor',
		'lentaron',
		'afema',
		'teslac'
	)
        ;
--
