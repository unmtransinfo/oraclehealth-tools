#!/bin/bash
#
#
# Define DBNAME, DBHOST, DBPORT, TUNNELPORT
. ~/.healthfactsrc
#
printf "DBNAME = %s; DBHOST = %s; DBPORT = %s; TUNNELPORT = %s\n" "${DBNAME}" "${DBHOST}" "${DBPORT}" "${TUNNELPORT}"
#
ssh -T -O "check" $DBHOST
rval="$?"
#
if [ "$rval" -ne 0 ]; then
	ssh -f -N -T -M -4 -L ${TUNNELPORT}:localhost:${DBPORT} $DBHOST
fi
#
mvn --projects unm_biocomp_cerner exec:java -Dexec.mainClass="edu.unm.health.biocomp.cerner.hf.hf_patients" -Dexec.args="-dbname $DBNAME $*"
#
#ssh -T -O "exit" $DBHOST
#
