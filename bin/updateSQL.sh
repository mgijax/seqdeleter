#!/bin/sh

echo "Updating sequence status to 'ACTIVE'" | tee -a ${LOG_PROC} >> ${LOG_PROC} 2>&1

cat - <<EOSQL | psql -h${MGD_DBSERVER} -d${MGD_DBNAME} -U mgd_dbo -e >> ${LOG_DIAG} 2>&1

select s._Sequence_key
into  temp seqsToUpdate
from  ACC_Accession a, SEQ_Sequence s
where a._MGIType_key = 19
and a._LogicalDB_key = ${LOGICALDB_KEY}
and a.preferred = 1
and a._Object_key = s._Sequence_key
and s._SequenceStatus_key = 316343;

create index idx1 on seqsToUpdate(_Sequence_key);

update SEQ_Sequence s
set _SequenceStatus_key = 316342
from seqsToUpdate u
where s._Sequence_key = u._Sequence_key;

EOSQL
