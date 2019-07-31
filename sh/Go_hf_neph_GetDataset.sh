#!/bin/sh
#############################################################################
# Cohort:
#    - Kidney disease diagnoses
#    - Dx between 2012-2017
#############################################################################
# Each patient:fact-type requires approx 30sec currently.
# So for 3 fact-types and 1000 patients: 7h * 3ftypes = ~21h = ~1d.
#############################################################################
###
#
cwd=$(pwd)
DATADIR=${cwd}/data
#
prefix="hf_neph_cohort"
#
${cwd}/sh/hf_query.sh \
	-f ${cwd}/sql/nephrology/${prefix}.sql \
	-o ${DATADIR}/${prefix}.tsv
	-v
#
${cwd}/python/pandas_utils.py \
	--i ${DATADIR}/${prefix}.tsv \
	--coltags "patient_id" \
	selectcols \
	|sed -e '1d' \
	|sort -nu \
	>${DATADIR}/${prefix}.pid
#
printf "patient_id count: %d\n" `cat ${DATADIR}/${prefix}.pid |wc -l`
#
${cwd}/python/pandas_utils.py \
	--i ${DATADIR}/${prefix}.tsv \
	--coltags "patient_sk" \
	selectcols \
	|sed -e '1d' \
	|sort -nu \
	>${DATADIR}/${prefix}.sk
#
printf "patient_sk count: %d\n" `cat ${DATADIR}/${prefix}.sk |wc -l`
#
###
# Get all data on cohort patients:
#
#ftypes="diagnosis medication med_history surgery lab clinical_event discharge"
ftypes="diagnosis medication lab"
#
for ftype in $ftypes ; do
	${cwd}/sh/hf_patients.sh \
		-skfile ${DATADIR}/${prefix}.sk \
		-ftype "${ftype}" \
		-o ${DATADIR}/${prefix}_f_${ftype}.tsv \
		-nmax 50000 \
		-vv
done
#
