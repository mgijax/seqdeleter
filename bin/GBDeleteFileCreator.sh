#!/usr/bin/sh
# Program: DBCleanser
# Purpose: Remove duplicate sequence records from a FASTA
#          formatted file saving the record with the greatest
#          version number
Usage="DBCleanser inputFile"
# Envvars: 1) DBCLEANSER_LOG
#	   2) OUTPUTFILE_EXT
#	   3) DUP_SEQ_FILE
# Inputs:   'inputFile' - a FASTA format file
# Outputs: 1) DUP_SEQ_FILE -  file containing the seqids that are 
#             duplicated in #'inputFile'
#	   2) 'outputFile' - the non-redundant version of 'inputFile'
#	   3) renames 'outputFile' to 'inputFile'
# Exit Codes: 1 if Usage error, can't read config file or input file,
#               if cleanse.awk fails

# DEBUG
# set -x

cd `dirname $0`/
#
#  Verify the argument(s) to the shell script.
#
if [ $# -ne 1 ]
then
    echo "${Usage}" 
    exit 1
fi

#
#  Establish the configuration file names
#  and make sure readable, then source
#

CONFIG_LOAD=../Configuration

if [ ! -r ${CONFIG_LOAD} ]
then
    echo "Cannot read configuration file: ${CONFIG_LOAD}"
    exit 1
fi

. ${CONFIG_LOAD}

date | tee ${DBCLEANSER_LOG}

#
# get the inputFile param and make sure readable
#

inputFile=$1

if [ ! -r ${inputFile} ]
then
    echo "Cannot read input file: ${inputFile}" | tee -a ${DBCLEANSER_LOG}
    exit 1
fi

#
# create output file name
#

outputFile=$1${OUTPUTFILE_EXT}
echo "Processing input file ${inputFile} to output file ${outputFile}" | tee -a ${DBCLEANSER_LOG}

echo "Creating duplicate sequence file for ${inputFile}" | tee -a ${DBCLEANSER_LOG}


# create the filename for the current duplicate file
ext=.`basename ${inputFile}`
currentDupFile="${DUP_SEQ_FILE}${ext}"

#
# remove the old duplicate file
#
rm -f ${currentDupFile}

# create the duplicate file for ${inputFile}

#>gi|2641960|gb|AB004255.1|AB004255 Mus musculus genomic DNA.
# step1 = get the > line from each record - the description line
# step2 = get the 4 token of step1 using the '|' delimiter - the seqid.version
# step3 = get the 1st token of step2 using the '.' delimiter - the seqid
# step4 = sort in increasing alpha order
# step5 = get the list of seqids in step4 that are repeated (-d supresses lines
#         that are not repeated
# step5 - redirect to a file

cat ${inputFile} | grep "^>" | cut -d "|" -f4 | cut -d "." -f1 | sort | uniq -d > ${currentDupFile}

#
# Run the database cleanser
# 

echo "Running cleanse.awk" | tee -a ${DBCLEANSER_LOG}

date | tee -a ${DBCLEANSER_LOG}

# pipe input to awk which doesn't handle large files
# even though the man pages say so
cat ${inputFile} | /usr/local/bin/awk -f cleanse.awk -v DUPSfile=${currentDupFile} > ${outputFile}

STAT=$?
if [ ${STAT} -ne 0 ]
then
    echo "DBCleanser failed.  \
	Return status: ${STAT}" >> ${DBCLEANSER_LOG}
    exit 1
fi

#
# rename the outputFile to inputFile
#

echo "Renaming the output file from ${outputFile} to ${inputFile}" | tee -a ${DBCLEANSER_LOG}
mv ${outputFile} ${inputFile}

echo "Finished  running DBCleanser" | tee -a ${DBCLEANSER_LOG}
date | tee -a ${DBCLEANSER_LOG}

