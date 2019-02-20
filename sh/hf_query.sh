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
#CLASSPATH="$CLASSPATH:$LIBDIR/jtds-1.3.1.jar"
CLASSPATH="$CLASSPATH:$LIBDIR/postgresql-9.4.1208.jre6.jar"
#
DBHOST="hsc-ctschf.health.unm.edu"
DBPORT="5432"
#
TUNNELPORT="63333"
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
while getopts "f:q:h:p:t:o:iv" opt ; do
	case "$opt" in
	  f)      SQLFILE="$OPTARG" ;;
	  q)      SQL="$OPTARG" ;;
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
cmd="java ${JAVA_OPTS} -classpath $CLASSPATH \
	edu.unm.health.biocomp.hf.hf_query \
	-dbhost localhost \
	-dbport $TUNNELPORT"
#
if [ "$VERBOSE" ]; then
	cmd="$cmd -v"
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
	cmd="$cmd -info"
elif [ $OP = "query" ]; then
	cmd="$cmd -query"
	if [ "$SQLFILE" ]; then
		cmd="$cmd -sqlfile $SQLFILE"
	elif [ "$SQL" ]; then
		cmd="$cmd -sql \"$SQL\""
	fi
	if [ "$OFILE" ]; then
		cmd="$cmd -o $OFILE"
	fi
fi
#
set -x
#
$cmd
#
#ssh -T -O "exit" $DBHOST
#
