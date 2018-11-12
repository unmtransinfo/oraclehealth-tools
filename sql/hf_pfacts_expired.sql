-- Patient facts, expired
-- As in hf_utils.java
SELECT DISTINCT
	ddd.dischg_disp_id,
	ddd.dischg_disp_code,
	ddd.dischg_disp_code_desc,
	fe.encounter_id,
	fe.patient_id,
	fe.patient_type_id,
	fe.age_in_years,
	fe.hospital_id,
	fe.discharged_dt_tm AS "date"
FROM
	hf_d_dischg_disp ddd
JOIN
	hf_f_encounter fe ON fe.discharge_disposition_id = ddd.dischg_disp_id
WHERE
	ddd.dischg_disp_code_desc LIKE 'Expired%'
LIMIT 10
	;
