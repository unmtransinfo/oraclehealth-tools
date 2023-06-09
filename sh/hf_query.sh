#!/bin/bash
#
#
# Define DBNAME, DBHOST, DBPORT, maybe TUNNELPORT
. ~/.healthfactsrc
#
#
help() {
	echo "$1"
	echo "syntax: `basename $0` [options]"
	echo ""
	echo "  required:"
	echo "        -i .............. dbinfo"
	echo "  or"
	echo "        -f FILE ......... SQL file"
	echo "  or"
	echo "        -q QUERY ........ SQL"
	echo ""
	echo "  parameters:"
	echo "        -n NAME ......... db host [$DBNAME]"
	echo "        -h HOST ......... db host [$DBHOST]"
	echo "        -p PORT ......... db port [$DBPORT]"
	echo "        -t TUNNELPORT ... ssh tunnel port [$TUNNELPORT]"
	echo "        -o OFILE ........ output (CSV)"
	echo "  options:"
	echo "        -v .............. verbose"
	echo ""
	exit 1
}
#
VERBOSE=""
OFILE=""
OP="query"
#
if [ $# -eq 0 ]; then
	help "ERROR: SQL input required."
elif [ ! "$DBHOST" ]; then
	help "ERROR: DB specification required."
fi
#
### Parse options
while getopts "f:q:h:p:n:t:o:iv" opt ; do
	case "$opt" in
	  f)      SQLFILE="$OPTARG" ;;
	  q)      SQL="$OPTARG" ;;
	  n)      DBNAME="$OPTARG" ;;
	  h)      DBHOST="$OPTARG" ;;
	  z)      DBPORT="$OPTARG" ;;
	  t)      TUNNELPORT="$OPTARG" ;;
	  o)      OFILE="$OPTARG" ;;
	  i)      OP="info" ;;
	  v)      VERBOSE="TRUE" ;;
	  \?)     help
		exit 1 ;;
	esac
done
#
if [ $OP = "query" -a ! "$SQL" -a ! "$SQLFILE" ]; then
	echo "Query requires -f or -q."
	help
fi
#
if [ "$TUNNELPORT" ]; then
	args="-dbhost localhost -dbport $TUNNELPORT -dbname $DBNAME"
	print "Test db connection with: psql -h localhost -d $DBNAME -p $TUNNELPORT" 
else
	args="-dbhost $DBHOST -dbport $DBPORT -dbname $DBNAME"
	print "Test db connection with: psql -h $DBHOST -d $DBNAME -p $DBPORT"
fi
#
if [ "$VERBOSE" ]; then
	args="$args -v"
fi
###
if [ "$TUNNELPORT" ]; then
	ssh -M -T -O "check" $DBHOST
	rval="$?"
	#
	if [ "$rval" -ne 0 ]; then
		ssh -f -N -T -M -4 -L ${TUNNELPORT}:localhost:${DBPORT} $DBHOST
	fi
fi
#
if [ $OP = "info" ]; then
	args="$args -i"
elif [ $OP = "query" ]; then
	if [ "$SQLFILE" ]; then
		args="$args -query -sqlfile $SQLFILE"
	elif [ "$SQL" ]; then
		args="$args -query -sql \"$SQL\""
	fi
	if [ "$OFILE" ]; then
		args="$args -o $OFILE"
	fi
fi
#
#
set -x
#
LIBDIR=$(cd $HOME/../app/lib; pwd)
#
java \
	-classpath $LIBDIR/unm_biocomp_cerner-0.0.1-SNAPSHOT-jar-with-dependencies.jar \
	edu.unm.health.biocomp.cerner.hf.hf_query \
	${args}
#
###
# Note for patient cohort query instead use class:
#	edu.unm.health.biocomp.cerner.hf.hf_patients
#
if [ "$TUNNELPORT" ]; then
	ssh -M -T -O "exit" $DBHOST
fi
#
