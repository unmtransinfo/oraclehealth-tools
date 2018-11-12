--
SELECT
	(SELECT COUNT(fe.encounter_id) FROM hf_f_encounter fe) AS "encounters (f)",
	(SELECT COUNT(dp.patient_id) FROM hf_d_patient dp) AS "patient_ids (d)",
	(SELECT COUNT(DISTINCT dp.patient_sk) FROM hf_d_patient dp) AS "patients (d)",
	(SELECT COUNT(dh.hospital_id) FROM hf_d_hospital dh) AS "hospitals (d)",
	(SELECT COUNT(dph.physician_id) FROM hf_d_physician dph) AS "physicians (d)",
	(SELECT COUNT(fd.diagnosis_id) FROM hf_f_diagnosis fd) AS "diagnoses (f)",
	(SELECT COUNT(dd.diagnosis_id) FROM hf_d_diagnosis dd) AS "diagnoses (d)",
	(SELECT COUNT(fm.medication_id) FROM hf_f_medication fm) AS "meds (f)",
	(SELECT COUNT(dm.medication_id) FROM hf_d_medication dm) AS "meds (d)",
	(SELECT COUNT(fsp.surgical_procedure_id) FROM hf_f_surgical_procedure fsp) AS "surgical_procedures (f)",
	(SELECT COUNT(dsp.surgical_procedure_id) FROM hf_d_surgical_procedure dsp) AS "surgical_procedures (d)",
	(SELECT COUNT_BIG(*) FROM hf_f_lab_procedure flp) AS "lab_procedures (f)",
	(SELECT COUNT(*) FROM hf_d_lab_procedure dlp) AS "lab_procedures (d)"
        ;
--
