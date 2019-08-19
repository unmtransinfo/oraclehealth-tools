#!/bin/sh
#
DBHOST=""
DBPORT="5432"
DBTNLPORT=""
DBTNLHOST="localhost"
DBNAME=""
DBUSR="$USER"
#
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
	echo "        -n DBNAME ........ db name [$DBNAME]"
	echo "        -h DBHOST ........ db host [$DBHOST]"
	echo "        -z DBPORT ........ db port [$DBPORT]"
	echo "        -x DBTNLPORT ..... db tunnel port [$DBTNLPORT]"
	echo "        -y DBTNLHOST ..... db tunnel host [$DBTNLHOST]"
	echo "        -u DBUSR ......... db user [$DBUSR]"
	echo "        -p DBPW .......... db password"
	echo "  options:"
	echo "        -t ............. TSV output (STDOUT)"
	echo "        -v ............. verbose (STDERR)"
	echo ""
	echo "$PSQL version: `$PSQL -V`"
	exit 1
}
#
TSV=""
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
	t)      TSV="TRUE" ;;
	v)      VERBOSE="TRUE" ;;
	\?)     help
		exit 1 ;;
	esac
done
#
#
if [ $# -eq 0 ]; then
	help "ERROR: SQL input required."
elif [ ! "$DBHOST" -o ! "$DBNAME" ]; then
	help "ERROR: DB specification required."
fi
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
if [ "$TSV" ]; then
	rm -f $TMPSQLFILE
	echo "COPY (" >$TMPSQLFILE
	if [ "$SQLFILE" ]; then
		cat $SQLFILE |sed -e 's/; *$//' >>$TMPSQLFILE
	else
		echo "$SQL" |sed -e 's/; *$//' >>$TMPSQLFILE
	fi
	echo ") TO STDOUT WITH (FORMAT CSV,HEADER,DELIMITER '	',QUOTE '\"')" >>$TMPSQLFILE
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
	if [ ! "$DBTNLHOST" -o ! "$DBTNLPORT" -o ! "$DBPORT" ]; then
		help "ERROR: DBTNLHOST, DBTNLPORT, and DBPORT required for ssh tunnel."
	fi
	if [ "$VERBOSE" ]; then
		echo "Starting ssh tunnel..." 1>&2
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
