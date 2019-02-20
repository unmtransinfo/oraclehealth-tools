#!/bin/sh
#
if [ "`uname -s`" = "Darwin" ]; then
	APPDIR="/Users/app"
elif [ "`uname -s`" = "Linux" ]; then
	APPDIR="/home/app"
else
	APPDIR="/home/app"
fi
#
LIBDIR=$APPDIR/lib
CLASSPATH=$LIBDIR/unm_biocomp_hf.jar
CLASSPATH=$CLASSPATH:$LIBDIR/unm_biocomp_db.jar
CLASSPATH=$CLASSPATH:$LIBDIR/unm_biocomp_util.jar
#
CLASSPATH="$CLASSPATH:$LIBDIR/postgresql-9.4.1208.jre6.jar"
#
DBHOST="hsc-ctschf.health.unm.edu"
DBPORT="5432"
#
TUNNELPORT="63333"
#
ssh -T -O "check" $DBHOST
rval="$?"
#
if [ "$rval" -ne 0 ]; then
	ssh -f -N -T -M -4 -L ${TUNNELPORT}:localhost:${DBPORT} $DBHOST
fi
#
java ${JAVA_OPTS} -classpath $CLASSPATH edu.unm.health.biocomp.hf.hf_patients $*
#
#ssh -T -O "exit" $DBHOST
#
