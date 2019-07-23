#!/bin/bash
#
#
# Define DBHOST, DBPORT, TUNNELPORT
. ~/.healthfactsrc
#
printf "DBHOST = %s; DBPORT = %s; TUNNELPORT = %s\n" "${DBHOST}" "${DBPORT}" "${TUNNELPORT}"
#
#
ssh -T -O "check" $DBHOST
rval="$?"
#
if [ "$rval" -ne 0 ]; then
	ssh -f -N -T -M -4 -L ${TUNNELPORT}:localhost:${DBPORT} $DBHOST
fi
#
(cd unm_biocomp_cerner ; mvn exec:java -Dexec.mainClass="edu.unm.health.biocomp.cerner.hf.hf_patients" -Dexec.args="$*")
#
#ssh -T -O "exit" $DBHOST
#
