#!/bin/bash
#
#
# Define DBNAME, DBHOST, DBPORT, maybe TUNNELPORT
. ~/.healthfactsrc
#
printf "DBNAME = %s; DBHOST = %s; DBPORT = %s\n" "${DBNAME}" "${DBHOST}" "${DBPORT}"
if [ "${TUNNELPORT}" ]; then
	printf "TUNNELPORT = %s (SSH tunnel mode)\n" "${TUNNELPORT}"
fi
#
if [ "${TUNNELPORT}" ]; then
	ssh -T -O "check" $DBHOST
	rval="$?"
	#
	if [ "$rval" -ne 0 ]; then
		ssh -f -N -T -M -4 -L ${TUNNELPORT}:localhost:${DBPORT} $DBHOST
	fi
fi
#
mvn --projects unm_biocomp_cerner exec:java \
	-Dexec.mainClass="edu.unm.health.biocomp.cerner.hf.hf_patients" \
	-Dexec.cleanupDaemonThreads=false \
	-Dexec.args="-dbname $DBNAME $*"
#
#if [ "${TUNNELPORT}" ]; then
#	ssh -T -O "exit" $DBHOST
#fi
#
