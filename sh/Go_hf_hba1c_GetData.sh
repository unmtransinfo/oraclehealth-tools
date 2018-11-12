#!/bin/sh
#############################################################################
# Cohort:
#    - Juvenile diabetes diagnosis (250.01, 250.03)
#    - Dx between 2008-2013
#    - Age >= 18
#############################################################################
## '250.01': Diabetes Mellitus without Mention of Complication, Type I [juvenile Type], No
## '250.03': Diabetes Mellitus without Mention of Complication, Type I [juvenile Type], Un
#############################################################################
# Each patient:facttype requires approx 1min currently.  
# So for 1000 patients, 17hrs * 7ftypes ~ 120hr ~ 5 days.
#############################################################################
###
#
prefix="hf_diabetes_cohort"
#
hf_query.sh \
	-f ${prefix}.sql \
	-o data/${prefix}.csv \
	-v
#
csv_utils.py \
	--i data/${prefix}.csv \
	--extractcol \
	--coltag "patient_id" \
	|sort -nu \
	>data/${prefix}.pid
#
printf "patient_id count: %d\n" `cat data/${prefix}.pid |wc -l`
#
csv_utils.py \
	--i data/${prefix}.csv \
	--extractcol \
	--coltag "patient_sk" \
	|sort -nu \
	>data/${prefix}.sk
#
printf "patient_sk count: %d\n" `cat data/${prefix}.sk |wc -l`
#
###
#Get all data on cohort patients:
#ftypes="diagnosis medication med_history surgery lab clinical_event discharge"
ftypes="diagnosis medication lab"
for ftype in $ftypes ; do
	hf_patients.sh \
		-skfile data/${prefix}.sk \
		-ftype "${ftype}" \
		-o data/${prefix}_f_${ftype}.csv \
		-nmax 50000 \
		-vv
done
#
#
