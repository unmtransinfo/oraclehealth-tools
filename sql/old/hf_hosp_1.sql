-- Health Facts Hospitals - geography
-- Note that NM is West region, census division 8.
--
SELECT
	COUNT(DISTINCT fe.patient_id) AS "patient_count",
	COUNT(DISTINCT fe.encounter_id) AS "encounter_count",
	dh.census_region,
	dh.census_division,
	dh.bed_size_range,
	dh.urban_rural_status,
	dh.acute_status,
	dh.teaching_facility_ind
FROM	
	hf_f_encounter fe
JOIN
	hf_d_hospital dh ON dh.hospital_id = fe.hospital_id
WHERE
        fe.admitted_dt_tm BETWEEN CAST('2013-01-01' AS date) AND CAST('2013-12-31' AS date)
--        AND dh.census_region = 'West'
--        AND dh.census_division = 8
GROUP BY
	dh.census_region,
	dh.census_division,
	dh.bed_size_range,
	dh.urban_rural_status,
	dh.acute_status,
	dh.teaching_facility_ind
ORDER BY
	dh.census_region,
	dh.census_division,
	patient_count DESC
	;
--
--
