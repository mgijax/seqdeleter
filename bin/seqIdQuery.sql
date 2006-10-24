#!/bin/csh
 
#
# Report seqids for the given logical db
#
# Usage:
#	seqIdQuery.sql PROD_MGI mgd <logicalDBKey> <output prefix>
#


setenv DBSERVER $1
setenv DBNAME $2
setenv LOGICALDB $3
setenv OUTPUT_PREFIX $4

isql -S$DBSERVER -Umgd_public -Pmgdpub -w200 <<END >> ${OUTPUT_PREFIX}_$0.rpt

use $DBNAME
go
select accid
from ACC_Accession
where _MGIType_key = 19
and _LogicalDB_key = ${LOGICALDB}
and preferred = 1
go
quit

END
