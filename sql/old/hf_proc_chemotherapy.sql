-- Health Facts Procedures - chemotherapy
--
-- http://www.fortherecordmag.com/archives/071910p28.shtml
--
SELECT
	dp.procedure_id,
	dp.procedure_code,
	dp.procedure_type,
	dp.procedure_description
FROM	
	hf_d_procedure dp
WHERE
	dp.procedure_code IN (
	'00.10',
	'03.92',
	'34.91',
	'54.97',
	'86.07',
	'96.49',
	'99.25',
	'V58.11'
	)
	;
--
