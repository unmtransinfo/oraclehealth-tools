-- Labs for a sample of patients, in 2015.
CREATE TABLE jjyang.hf_f_lab_2015_sample
AS
	SELECT
		flp.lab_performed_dt_id,
		flp.encounter_id,
		flp.detail_lab_procedure_id,
		flp.order_lab_procedure_id,
		flp.ordering_physician_id,
		flp.lab_order_caresetting_id,
		flp.reporting_priority_id,
		flp.lab_result_type_id,
		flp.result_indicator_id,
		flp.lab_ordered_dt_id,
		flp.lab_drawn_dt_id,
		flp.lab_received_dt_id,
		flp.lab_completed_dt_id,
		flp.lab_cancelled_dt_id,
		flp.lab_verified_dt_id,
		flp.accession,
		flp.date_result_id,
		flp.numeric_result,
		flp.result_units_id,
		flp.normal_range_low,
		flp.normal_range_high,
		flp.lab_ordered_dt_tm,
		flp.lab_drawn_dt_tm,
		flp.lab_received_dt_tm,
		flp.lab_completed_dt_tm,
		flp.lab_cancelled_dt_tm,
		flp.lab_performed_dt_tm,
		flp.lab_verified_dt_tm,
		flp.lab_ordered_tm_vld_flg,
		flp.lab_drawn_tm_vld_flg,
		flp.lab_received_tm_vld_flg,
		flp.lab_completed_tm_vld_flg,
		flp.lab_cancelled_tm_vld_flg,
		flp.lab_verified_tm_vld_flg,
		flp.lab_performed_tm_vld_flg,
		flp.lab_performed_caresetting_id,
		flp.collection_source_id,
		flp.collection_method_id
	FROM 
		hf_f_lab_procedure flp
	JOIN
		hf_f_encounter fe ON fe.encounter_id = flp.encounter_id
	JOIN
		hf_d_patient dp ON dp.patient_id = fe.patient_id
	JOIN
		jjyang.patient_sample_2015 jjtable ON jjtable.patient_id = fe.patient_id
	JOIN
		hf_d_patient_type dpt ON fe.patient_type_id = dpt.patient_type_id
	WHERE
		dp.patient_id IS NOT NULL
               AND flp.numeric_result IS NOT NULL
		AND dpt.patient_type_desc = 'Outpatient'
	        AND DATE_PART('year', fe.admitted_dt_tm) = 2015
	;
