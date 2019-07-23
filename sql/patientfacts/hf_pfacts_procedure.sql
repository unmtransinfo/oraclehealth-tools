-- Patient facts, procedure
-- As in hf_utils.java
SELECT DISTINCT
	dp.procedure_id,
	dp.procedure_type,
	dp.procedure_code,
	dp.procedure_description,
	fe.encounter_id,
	fe.patient_id,
	fe.patient_type_id,
	fe.age_in_years,
	fe.hospital_id,
	fe.admitted_dt_tm AS date
FROM
	hf_f_procedure fp
JOIN
	hf_d_procedure dp ON fp.procedure_id = dp.procedure_id
JOIN
	hf_f_encounter fe ON fp.encounter_id = fe.encounter_id
WHERE
	fe.patient_id IN (
	2266984,
2385821,
2443061,
2450646,
2569758,
2944138,
2452099,
2936205,
2573286,
2931192,
2585914,
2590199,
2593012,
2594729,
2552277,
2949774,
2650136,
2650678,
2657552,
2689427,
2499648,
2691018,
2530080,
2454685,
2931071,
2699753,
2702429,
2750232,
2769989,
2944223,
2779319,
2534256,
2780852,
2824512,
2709369,
2860254,
2877289,
2880353
	)
	;
--
