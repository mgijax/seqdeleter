#!/bin/sh
#
#  seqdeleter.sh
#
###########################################################################
#
#  Purpose:  This script controls the execution of the seqdeleter
#
  Usage="usage: seqdeleter.sh config_file"
#     e.g. gbseqdeleter.config or refseqdeleter.config
#
#  Env Vars:
#
#      See the configuration file
#
#  Inputs:
#
#      - Common configuration file -
#               /usr/local/mgi/live/mgiconfig/master.config.sh
#      - Common load configuration file (seqdeleter_common.config)
#      - Configuration file - gbseqdeleter.config or refseqdeleter.config
#      - delete input file
#
#  Outputs:
#
#      - An archive file
#      - Log files defined by the environment variables ${LOG_PROC},
#        ${LOG_DIAG}, ${LOG_CUR} and ${LOG_VAL}
#      - sql script file to ${OUTPUTDIR}
#      - Records updated in a database
#      - Exceptions written to standard error
#      - Configuration and initialization errors are written to a log file
#        for the shell script
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

#
#  Set up a log file for the shell script in case there is an error
#  during configuration and initialization.
#
cd `dirname $0`/..
LOG=`pwd`/seqdeleter.log
rm -f ${LOG}

#
#  Verify the argument(s) to the shell script.
#
if [ $# -ne 1 ]
then
    echo ${Usage} | tee -a ${LOG}
    exit 1
fi

#
#  Establish the configuration file names.
#
CONFIG_LOAD=`pwd`/$1
CONFIG_LOAD_COMMON=`pwd`/seqdeleter_common.config

echo ${CONFIG_LOAD}

#
#  Make sure the configuration files are readable.
#
if [ ! -r ${CONFIG_LOAD} ]
then
    echo "Cannot read configuration file: ${CONFIG_LOAD}" | tee -a ${LOG}
    exit 1
fi

if [ ! -r ${CONFIG_LOAD_COMMON} ]
then
    echo "Cannot read configuration file: ${CONFIG_LOAD_COMMON}"
    exit 1
fi

#
# source config files - order is important
#
. $CONFIG_LOAD
. ${CONFIG_LOAD_COMMON}

#
#  Establish master configuration file name, we pass this to java
#
CONFIG_MASTER=${MGICONFIG}/master.config.sh

echo "javaruntime:${JAVARUNTIMEOPTS}"
echo "classpath:${CLASSPATH}"
echo "dbserver:${MGD_DBSERVER}"
echo "database:${MGD_DBNAME}"

#
#  Source the DLA library functions.
#
if [ "${DLAJOBSTREAMFUNC}" != "" ]
then
    if [ -r ${DLAJOBSTREAMFUNC} ]
    then
	. ${DLAJOBSTREAMFUNC}
    else
	echo "Cannot source DLA functions script: ${DLAJOBSTREAMFUNC}"
	exit 1
    fi
else
    echo "Environment variable DLAJOBSTREAMFUNC has not been defined."
    exit 1
fi

#
# check that APP_INFILES has been set
#
if [ "${APP_INFILES}" = "" ]
then
     # set STAT for endJobStream.py called from postload in shutDown
    STAT=1
    echo "APP_INFILES not defined. Return status: ${STAT}" | \
        tee -a ${LOG_DIAG}
    shutDown
    exit 1
fi

#
#  Function that performs cleanup tasks for the job stream prior to
#  termination.
#
shutDown ()
{
    #
    # report location of logs
    #
    echo "\nSee logs at ${LOGDIR}\n" | tee -a ${LOG_PROC}

    #
    # call DLA library function
    #
    postload

}

##################################################################
# main
##################################################################

#
# createArchive including OUTPUTDIR, startLog, getConfigEnv, get job key
#
preload ${OUTPUTDIR}


#
# rm all files/dirs from OUTPUTDIR RPTDIR
#
cleanDir ${OUTPUTDIR} ${RPTDIR}

#
# Run the seqdeleter
#

echo "Running seqdeleter" | tee -a ${LOG_DIAG} ${LOG_PROC}


# log time and input files to process
echo "\n`date`" | tee -a ${LOG_DIAG} ${LOG_PROC}

echo "Processing input file ${APP_INFILES}" | \
    tee -a ${LOG_DIAG} ${LOG_PROC}

# run the load

${APP_CAT_METHOD}  ${APP_INFILES}  | \
${JAVA} ${JAVARUNTIMEOPTS} -classpath ${CLASSPATH} \
-DCONFIG=${CONFIG_MASTER},${CONFIG_LOAD},${CONFIG_LOAD_COMMON} \
-DJOBKEY=${JOBKEY} ${DLA_START}

STAT=$?
if [ ${STAT} -ne 0 ]
then
    echo "seqdeleter processing failed.  \
        Return status: ${STAT}" | tee -a ${LOG_DIAG} ${LOG_PROC}
    shutDown
    exit 1
fi
echo "seqdeleter completed successfully" | tee -a ${LOG_DIAG} ${LOG_PROC}

#
# run postload cleanup and email logs
#
shutDown

exit 0
