#!/bin/bash
#
#
# Define DBNAME, DBHOST, DBPORT, TUNNELPORT
. ~/.healthfactsrc
#
#
help() {
	echo "$1"
	echo "syntax: `basename $0` [options]"
	echo ""
	echo "  operation:"
	echo "        -i .............. dbinfo"
	echo ""
	echo "  required:"
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
	echo "-f or -q required."
	help
fi
#
args="-dbhost localhost -dbport $TUNNELPORT -dbname $DBNAME"
#
if [ "$VERBOSE" ]; then
	args="$args -v"
fi
###
ssh -T -O "check" $DBHOST
rval="$?"
#
if [ "$rval" -ne 0 ]; then
	ssh -f -N -T -M -4 -L ${TUNNELPORT}:localhost:${DBPORT} $DBHOST
fi
#
if [ $OP = "info" ]; then
	#args="$args -info"
	args="$args -list_tables"
elif [ $OP = "query" ]; then
	args="$args -query"
	if [ "$SQLFILE" ]; then
		args="$args -sqlfile $SQLFILE"
	elif [ "$SQL" ]; then
		args="$args -sql \"$SQL\""
	fi
	if [ "$OFILE" ]; then
		args="$args -o $OFILE"
	fi
fi
#
set -x
#
mvn --projects unm_biocomp_cerner exec:java  \
	-Dexec.mainClass="edu.unm.health.biocomp.cerner.hf.hf_query" \
	-Dexec.args="${args}"
#
#ssh -T -O "exit" $DBHOST
#
