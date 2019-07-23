--
-- Names from DrugCentral ATC L4 = "BLOOD GLUCOSE LOWERING DRUGS, EXCL. INSULINS"
--
-- sulfonylureas:
--    chlorpropamide
--    carbutamide
--    tolazamide
--    tolbutamide
--    glipizide
--    glibenclamide
--    glimepiride
-- metformin
-- repaglinide 
-- natiglinide
-- thiazolidinediones:
--    rosiglitazone
--    pioglitazone
-- alpha-glucosidase inhibitors:
--    acarbose
--    miglitol
--
--
SELECT
	medication_id,
	ndc_code,
	brand_name,
	generic_name,
	product_strength_description,
	route_description,
	dose_form_description,
	obsolete_dt_tm
FROM
	hf_d_medication
WHERE
	generic_name IN (
	'acarbose',
	'acetohexamide',
	'albiglutide',
	'alogliptin',
	'benfluorex',
	'buformin',
	'canagliflozin',
	'carbutamide',
	'chlorpropamide',
	'dapagliflozin',
	'dulaglutide',
	'empagliflozin',
	'exenatide',
	'gemigliptin',
	'glibenclamide',
	'glibornuride',
	'gliclazide',
	'glimepiride',
	'glipizide',
	'gliquidone',
	'glisoxepide',
	'glymidine',
	'linagliptin',
	'liraglutide',
	'lixisenatide',
	'metahexamide',
	'metformin',
	'miglitol',
	'mitiglinide',
	'nateglinide',
	'phenformin',
	'pioglitazone',
	'pramlintide',
	'repaglinide',
	'rosiglitazone',
	'saxagliptin',
	'sitagliptin',
	'tolazamide',
	'tolbutamide',
	'troglitazone',
	'vildagliptin',
	'voglibose')
ORDER BY
	generic_name
	;
--
