#!/bin/csh
 
#
# Template for SQL report
#
# Notes:
#	- all public reports require a header and trailer
#	- all private reports require a header
#
# Usage:
#	seqIdQuery.sql PROD_MGI mgd <logicalDBKey>
#


setenv DSQUERY $1
setenv MGD $2
setenv LOGICALDB $3
setenv OUTPUT_PREFIX $4
#/mgi/software/customSQL/bin/header.sh $0

isql -S$DSQUERY -Umgd_public -Pmgdpub -w200 <<END >> ${OUTPUT_PREFIX}_$0.rpt

use $MGD
go
select accid
from ACC_Accession
where _MGIType_key = 19
and _LogicalDB_key = ${LOGICALDB}
and preferred = 1
go
quit

END
