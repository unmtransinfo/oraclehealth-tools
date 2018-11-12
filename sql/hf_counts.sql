--
SELECT
	'd:patient_ids' AS "type",COUNT(patient_id) AS "count" FROM hf_d_patient
UNION SELECT
	'd:patient_sks' AS "type",COUNT(DISTINCT patient_sk) AS "count" FROM hf_d_patient
UNION SELECT
	'd:diagnoses' AS "type",COUNT(diagnosis_id) AS "count" FROM hf_d_diagnosis
UNION SELECT
	'd:hospitals' AS "type",COUNT(hospital_id) AS "count" FROM hf_d_hospital
UNION SELECT
	'd:physicians' AS "type",COUNT(physician_id) AS "count" FROM hf_d_physician
UNION SELECT
	'd:procedures' AS "type",COUNT(procedure_id) AS "count" FROM hf_d_procedure
UNION SELECT
	'd:surgical_procedures' AS "type",COUNT(surgical_procedure_id) AS "count" FROM hf_d_surgical_procedure
UNION SELECT
	'd:lab_procedures' AS "type",COUNT(*) AS "count" FROM hf_d_lab_procedure
UNION SELECT
	'd:medications' AS "type",COUNT(medication_id) AS "count" FROM hf_d_medication
UNION SELECT
	'f:encounters' AS "type",COUNT(encounter_id) AS "count" FROM hf_f_encounter
UNION SELECT
	'f:diagnoses' AS "type",COUNT(encounter_id) AS "count" FROM hf_f_diagnosis
UNION SELECT
	'f:medications' AS "type",COUNT(encounter_id) AS "count" FROM hf_f_medication
UNION SELECT
	'f:med_history' AS "type",COUNT(encounter_id) AS "count" FROM hf_f_med_history
UNION SELECT
	'f:microbiology' AS "type",COUNT(encounter_id) AS "count" FROM hf_f_microbiology
UNION SELECT
	'f:micro_susceptibility' AS "type",COUNT(encounter_id) AS "count" FROM hf_f_micro_susceptibility
UNION SELECT
	'f:procedures' AS "type",COUNT(encounter_id) AS "count" FROM hf_f_procedure
UNION SELECT
	'f:surgical_procedures' AS "type",COUNT(encounter_id) AS "count" FROM hf_f_surgical_procedure
UNION SELECT
	'f:lab_procedures' AS "type",COUNT(encounter_id) AS "count" FROM hf_f_lab_procedure
	;
--
