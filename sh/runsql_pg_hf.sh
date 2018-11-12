#!/bin/sh
#
DBHOST=""
DBPORT=""
DBTNLPORT=""
DBTNLHOST=""
DBNAME=""
#
#
if [ -e ".runsql_pg" ]; then
	. .runsql_pg
else
	echo "Not found: .runsql_pg"
fi
#
PSQL="psql"
#
help() {
	echo "$1"
	echo "syntax: `basename $0` [options]"
	echo ""
	echo "  required:"
	echo "        -f FILE ........ SQL file"
	echo "  or"
	echo "        -q QUERY ....... SQL"
	echo ""
	echo "  parameters:"
	echo "        -n NAME ........ db name [$DBNAME]"
	echo "        -h HOST ........ db host [$DBHOST]"
	echo "        -z PORT ........ db port [$DBPORT]"
	echo "        -x TNLPORT ..... db tunnel port [$DBTNLPORT]"
	echo "        -y TNLHOST ..... db tunnel host [$DBTNLHOST]"
	echo "        -u USR ......... db user [$DBUSR]"
	echo "        -p PW .......... db password"
	echo "  options:"
	echo "        -c ............. CSV output"
	echo "        -v ............. verbose"
	echo ""
	echo "$PSQL version: `$PSQL -V`"
	exit 1
}
#
if [ $# -eq 0 ]; then
	help "ERROR: SQL input required."
elif [ ! "$DBHOST" -o ! "$DBNAME" ]; then
	help "ERROR: DB specification required."
fi
#
CSV=""
VERBOSE=""
### Parse options
while getopts f:q:n:h:z:x:y:u:p:o:ctv opt ; do
	case "$opt"
	in
	f)      SQLFILE=$OPTARG ;;
	q)      SQL=$OPTARG ;;
	n)      DBNAME=$OPTARG ;;
	h)      DBHOST=$OPTARG ;;
	z)      DBPORT=$OPTARG ;;
	x)      DBTNLPORT=$OPTARG ;;
	y)      DBTNLHOST=$OPTARG ;;
	u)      DBUSR=$OPTARG ;;
	p)      DBPW=$OPTARG ;;
	c)      CSV="TRUE" ;;
	v)      VERBOSE="TRUE" ;;
	\?)     help
		exit 1 ;;
	esac
done
#
if [ ! "$SQL" -a ! "$SQLFILE" ]; then
	echo "-f or -q required."
	help
fi
#
DBOPTS="-At"
#
TMPSQLFILE="/tmp/`basename ${0}`.sql"
#
if [ "$CSV" ]; then
	rm -f $TMPSQLFILE
	echo "COPY (" >$TMPSQLFILE
	if [ "$SQLFILE" ]; then
		cat $SQLFILE |sed -e 's/; *$//' >>$TMPSQLFILE
	else
		echo "$SQL" |sed -e 's/; *$//' >>$TMPSQLFILE
	fi
	echo ") TO STDOUT WITH (FORMAT CSV,HEADER,DELIMITER ',',QUOTE '\"')" >>$TMPSQLFILE
	SQLFILE=$TMPSQLFILE
	DBOPTS="-qA"
else
	DBOPTS="-At"
fi
#
###
#
ssh -T -O "check" $DBHOST
rval="$?"
#
if [ "$rval" -ne 0 ]; then
	if [ "$VERBOSE" ]; then
		echo "Starting ssh tunnel..."
	fi
	ssh -f -N -T -M -4 -L ${DBTNLPORT}:${DBTNLHOST}:${DBPORT} $DBHOST
	ssh -T -O "check" $DBHOST
fi
#
#
DBOPTS="$DBOPTS -P pager=off"
#
DBOPTS="$DBOPTS -h ${DBTNLHOST} -p ${DBTNLPORT} -d $DBNAME -U $DBUSR"
#
if [ "$SQLFILE" ]; then
	$PSQL $DBOPTS -f $SQLFILE
else
	$PSQL $DBOPTS -c "$SQL" 
fi
#
#
# ssh -T -O "exit" $DBHOST
#
