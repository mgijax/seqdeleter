#!/bin/sh

echo 'Dropping SEQ_Sequence triggers' | tee -a ${LOG_PROC}
${MGD_DBSCHEMADIR}/trigger/SEQ_Sequence_drop.object

echo "Updating sequence status to 'ACTIVE'" | tee -a ${LOG_PROC}
cat - <<EOSQL | ${MGI_DBUTILS}/bin/doisql.csh ${MGD_DBSERVER} ${MGD_DBNAME} >> ${LOG_PROC}

use ${MGD_DBNAME}
go

select s._Sequence_key
into #seqsToUpdate
from  ACC_Accession a, SEQ_Sequence s
where a._MGIType_key = 19
and a._LogicalDB_key = ${LOGICALDB_KEY}
and a.preferred = 1
and a._Object_key = s._Sequence_key
and s._SequenceStatus_key = 316343
go

create index idx1 on #seqsToUpdate(_Sequence_key)
go

update SEQ_Sequence
set _SequenceStatus_key = 316342
from #seqsToUpdate u, SEQ_Sequence s
where u._Sequence_key = s._Sequence_key
go

checkpoint
go

quit

EOSQL

echo 'Creating SEQ_Sequence triggers' | tee -a ${LOG_PROC}
${MGD_DBSCHEMADIR}/trigger/SEQ_Sequence_create.object
