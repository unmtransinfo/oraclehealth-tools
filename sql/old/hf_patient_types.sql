-- Health Facts Patients - types
--
SELECT
	dpt.patient_type_id,
	dpt.patient_type_desc
FROM	
	hf_d_patient_type dpt
ORDER BY
	dpt.patient_type_id
	;
--
