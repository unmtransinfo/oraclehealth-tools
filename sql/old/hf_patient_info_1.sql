-- Health Facts Patient info -- What is present?
-- Patient and Encounter tables.  Clinical events handled elsewhere.
--
SELECT
	( SELECT COUNT(DISTINCT fe.patient_id) FROM hf_f_encounter fe) AS [patient_total],
	( SELECT COUNT(DISTINCT fe.patient_id) FROM hf_f_encounter fe WHERE fe.admitted_dt_tm IS NOT NULL) AS [patient_date],
	( SELECT COUNT(DISTINCT fe.patient_id) FROM hf_f_encounter fe WHERE fe.age_in_years IS NOT NULL) AS [patient_age],
	( SELECT COUNT(DISTINCT fe.patient_id) FROM hf_f_encounter fe WHERE fe.weight IS NOT NULL) AS [patient_weight],
	( SELECT COUNT(DISTINCT fe.patient_id) FROM hf_f_encounter fe JOIN hf_d_patient dp ON fe.patient_id = dp.patient_id WHERE dp.gender IS NOT NULL) AS [patient_gender],
	( SELECT COUNT(DISTINCT fe.patient_id) FROM hf_f_encounter fe JOIN hf_d_patient dp ON fe.patient_id = dp.patient_id WHERE pb.race IS NOT NULL) AS [patient_race],
	( SELECT COUNT(DISTINCT fe.patient_id) FROM hf_f_encounter fe JOIN hf_d_patient dp ON fe.patient_id = dp.patient_id JOIN hf_d_patient_type dpt ON fe.patient_type_id = dpt.patient_type_id WHERE dpt.patient_type_desc IS NOT NULL) AS [patient_patient_type],
	( SELECT COUNT(DISTINCT fe.encounter_id) FROM hf_f_encounter fe) AS [encounter_total],
	( SELECT COUNT(DISTINCT fe.encounter_id) FROM hf_f_encounter fe WHERE fe.admitted_dt_tm IS NOT NULL) AS [encounter_date],
	( SELECT COUNT(DISTINCT fe.encounter_id) FROM hf_f_encounter fe WHERE fe.age_in_years IS NOT NULL) AS [encounter_age],
	( SELECT COUNT(DISTINCT fe.encounter_id) FROM hf_f_encounter fe WHERE fe.weight IS NOT NULL) AS [encounter_weight]
	( SELECT COUNT(DISTINCT fe.encounter_id) FROM hf_f_encounter fe JOIN hf_d_patient dp ON fe.patient_id = dp.patient_id WHERE dp.gender IS NOT NULL) AS [encounter_gender],
	( SELECT COUNT(DISTINCT fe.encounter_id) FROM hf_f_encounter fe JOIN hf_d_patient dp ON fe.patient_id = dp.patient_id WHERE pb.race IS NOT NULL) AS [encounter_race],
	( SELECT COUNT(DISTINCT fe.encounter_id) FROM hf_f_encounter fe JOIN hf_d_patient dp ON fe.patient_id = dp.patient_id JOIN hf_d_patient_type dpt ON fe.patient_type_id = dpt.patient_type_id WHERE dpt.patient_type_desc IS NOT NULL) AS [encounter_patient_type],
	;
--
