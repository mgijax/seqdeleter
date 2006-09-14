#!/bin/sh
#
#  createReleaseDeletes.sh
#
###########################################################################
#
#  Purpose:  
#
  Usage="usage: createReleaseDeletes.sh providerFile, MGIFile, outputfilePrefix e.g. createReleaseDeletes.sh gbacc.idx.seqid gb_seqIdQuery.sql.rpt genbank"

#
#  Env Vars:
#
#      See the configuration file
#
#  Inputs:
#
#      - Provider index file
#      - index of genbank or refseq release
#
#  Outputs:
#
#      - file of seqids to be deleted from mgi, one per line 
#
#  Exit Codes:
#
#      0:  Successful completion
#      1:  Fatal error occurred
#      2:  Non-fatal error occurred
#
#  Assumes:  Nothing
#
#  Implementation:
#
#  Notes:  None
#
###########################################################################

PROVIDER_INFILE=$1
MGI_INFILE=$2
FILE_PREFIX=$3

/usr/bin/sort -o ${PROVIDER_INFILE} ${PROVIDER_INFILE}
/usr/bin/sort -o ${MGI_INFILE} ${MGI_INFILE}

# report all seqids in PROVIDER_INFILE that are not in file MGI_INFILE
/usr/bin/comm -13 ${PROVIDER_INFILE} ${MGI_INFILE} > ${FILE_PREFIX}_MGI_todelete.txt

