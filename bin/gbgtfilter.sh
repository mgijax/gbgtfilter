#!/bin/sh
#
#  gbgtfilter.sh
###########################################################################
#
#  Purpose:  This script controls the execution of the
#            genbank gene trap filter load.
#
Usage="Usage: $0"
#
#  Env Vars:
#
#      See the configuration file
#
#  Inputs:
#
#      - Configuration file
#      - Mouse only GenBank format file(s)
#
#  Outputs:
#
#      - An archive file
#      - Log files defined by the environment variables ${LOG_PROC},
#        ${LOG_DIAG}, ${LOG_CUR} and ${LOG_VAL}
#      - GenBank file (in directory DOWNLOADDIR)
#      - FASTA file (in directory DOWNLOADDIR)
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
#  Implementation:  Description
#
#      - select the input files  to process from RADAR where 
#	 fileType="GenBank_GTFilter"
#        that have been processed by gbseqload fileType="GenBank"
#      - filter out Gene Trap sequences into two files:
#          - GenBank format file of all Gene Trap sequences
#	   - FASTA format file of Gene Trap sequences that do not already have 
#		coordinates in the database
#      - create unique file names for the GenBank and FASTA files
#      - move the unique file names to the DOWNLOADDIR directory
#      - log the input files as processed in RADAR
#      - log the  GenBank and FASTA format files in RADAR with 
#	   fileType "GenBank_GTLoad" and "GenBank_GTBlat" respectively
#
#  Notes: 
#
#       05/23/11 - sc
#               added setting of gbgtfilter done flag when no files are found
#               to process
#
###########################################################################

#
#  Set up a log file for the shell script in case there is an error
#  during configuration and initialization.
#
cd `dirname $0`/..

SCRIPT_NAME=`basename $0`

LOG=`pwd`/gbgtfilter.log
rm -f ${LOG}

#
# Verify arguments to shell script
#
if [ $# -ne 0 ]
then
    echo ${Usage} | tee -a ${LOG}
    exit 1
fi

#
#  Establish the configuration file name 
#
CONFIG_LOAD=`pwd`/gbgtfilter.config
echo "CONFIG_LOAD: ${CONFIG_LOAD}"
#
#  Make sure the configuration file is readable.
#
if [ ! -r ${CONFIG_LOAD} ]
then
    echo "Cannot read configuration file: ${CONFIG_LOAD}" | tee -a ${LOG}
    exit 1
fi

# source config file
echo "Sourcing Configuration"
. ${CONFIG_LOAD}

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

##################################################################
##################################################################
#
# main
#
##################################################################
##################################################################

#
# createArchive including OUTPUTDIR, startLog, getConfigEnv, get job key
#
echo "Running preload" | tee -a ${LOG_DIAG}
preload 

#
# rm all files/dirs from OUTPUTDIR
#
cleanDir ${OUTPUTDIR}

#
# Wait for the "GB Seqload Done" flag to be set. Stop waiting if the number
# of retries expires or the abort flag is found.
#
date | tee -a ${LOG_DIAG}
echo 'Wait for the "GenBank SeqLoad Done" flag to be set' | tee -a ${LOG_DIAG}

# Use 16 hour wait period (5 minutes x 192) in case seq loads run long.
RETRY=192
while [ ${RETRY} -gt 0 ]
do
    READY=`${PROC_CTRL_CMD_PROD}/getFlag ${NS_DATA_LOADS} ${FLAG_GBSEQLOAD}`
    ABORT=`${PROC_CTRL_CMD_PROD}/getFlag ${NS_DATA_LOADS} ${FLAG_ABORT}`

    if [ ${READY} -eq 1 -o ${ABORT} -eq 1 ]
    then
        break
    else
        sleep ${PROC_CTRL_WAIT_TIME}
    fi

    RETRY=`expr ${RETRY} - 1`
done

#
# Terminate the script if the number of retries expired or the abort flag
# was found.
#
if [ ${RETRY} -eq 0 ]
then
   echo "${SCRIPT_NAME} timed out" | tee -a ${LOG_DIAG}
   date | tee -a ${LOG_DIAG}
   exit 1
elif [ ${ABORT} -eq 1 ]
then
   echo "${SCRIPT_NAME} aborted by process controller" | tee -a ${LOG_DIAG}
   date | tee -a ${LOG_DIAG}
   exit 1
fi

#
# Clear the "GB Seqload Done" flag.
#
date | tee -a ${LOG_DIAG}
echo 'Clear process control flag: GB Seqload Done' | tee -a ${LOG_DIAG}
${PROC_CTRL_CMD_PROD}/clearFlag ${NS_DATA_LOADS} ${FLAG_GBSEQLOAD} ${SCRIPT_NAME}

#
# select the Gene Trap input files that are ready to be processed
#
if [ ${APP_RADAR_INPUT} = true ]
then
     echo "Getting Gene Trap input files" | tee -a ${LOG_PROC} ${LOG_DIAG}
     APP_INFILES=`${RADAR_DBUTILS}/bin/getFilesToProcess2.csh \
	${RADAR_DBSCHEMADIR} ${APP_JOBSTREAM} ${APP_JOBSTREAM2} ${APP_FILETYPE1} ${APP_FILETYPE2} 0`
     STAT=$?
     checkStatus ${STAT} "getFilesToProcess2.csh"
fi
#
#  Make sure there is at least one Gene Trap input file to process
#
if [ "${APP_INFILES}" = "" ]
then
    echo "There are no Gene Trap input files to process" | tee -a \
	${LOG_PROC} ${LOG_DIAG}

    echo 'Set process control flag: GT Filter Done' | tee -a ${LOG_DIAG}
    ${PROC_CTRL_CMD_PROD}/setFlag ${NS_DATA_LOADS} ${FLAG_GTFILTER} ${SCRIPT_NAME}

    echo "Running postload" | tee -a ${LOG_DIAG}
    shutDown
    exit 0 
else
    echo "" >> ${LOG_PROC}
    echo "`date`" >> ${LOG_PROC}
    echo "Files read from stdin: ${APP_CAT_METHOD} ${APP_INFILES}" | \
        tee -a ${LOG_DIAG} ${LOG_PROC}
fi

#
# The gene trap filter will run multiple input files and 
# produce one output file
#
echo "Running Gene Trap Filter" | tee -a ${LOG_DIAG}
${APP_CAT_METHOD} ${APP_INFILES}  | \
${JAVA} ${JAVARUNTIMEOPTS} -classpath ${CLASSPATH} \
    -DCONFIG=${CONFIG_MASTER},${CONFIG_LOAD} \
    org.jax.mgi.app.gbgtfilter.GBGeneTrapFilter
STAT=$?
checkStatus ${STAT} "GBGeneTrapFilter"

#
# create FASTA file
# remove duplicates
#
echo "Generating FASTA" | tee -a ${LOG_PROC} ${LOG_DIAG}
${GB2FASTA} ${NEW_OUTFILE_NAME} > ${FASTAFILE_NAME}
STAT=$?
checkStatus ${STAT} "${GB2FASTA}"

echo "Removing duplicates" | tee -a ${LOG_PROC} ${LOG_DIAG}
${DBCLEANSER_APP} ${FASTAFILE_NAME} ${CONFIG_LOAD}
STAT=$?
checkStatus ${STAT} "${DBCLEANSER_APP}"
#
# create a new, unique file name for GenBank and FASTA files
#
echo "Creating new file counter" | tee -a ${LOG_PROC} ${LOG_DIAG}
if [ ! -f ${FILECOUNTER} ]
then
    fileCounter=1
    echo ${fileCounter} > ${FILECOUNTER}
else
    fileCounter=`cat ${FILECOUNTER}`
    fileCounter=`expr ${fileCounter} + 1`
    echo ${fileCounter} > ${FILECOUNTER}
fi

#
# move the original file names to the new file names
#
mv ${ALL_OUTFILE_NAME} ${ALL_OUTFILE_NAME}.${fileCounter}
mv ${FASTAFILE_NAME} ${FASTAFILE_NAME}.${fileCounter}

#
# reset the variable names
#
ALL_OUTFILE_NAME=${ALL_OUTFILE_NAME}.${fileCounter}
FASTAFILE_NAME=${FASTAFILE_NAME}.${fileCounter}

#
# log the new, unique GenBank and FASTA files into RADAR
#
echo "Logging the new GenBank and FASTA files" | tee -a ${LOG_PROC} ${LOG_DIAG}
${RADAR_DBUTILS}/bin/logFileToProcess.csh ${RADAR_DBSCHEMADIR} ${ALL_OUTFILE_NAME} ${DOWNLOADDIR} ${APP_FILETYPE3}
STAT=$?
checkStatus ${STAT} "logFileToProcess.csh GenBank"

${RADAR_DBUTILS}/bin/logFileToProcess.csh ${RADAR_DBSCHEMADIR} ${FASTAFILE_NAME} ${DOWNLOADDIR} ${APP_FILETYPE4}
STAT=$?
checkStatus ${STAT} "logFileToProcess.csh FASTA"

#
# move GenBank and FASTA files from ${OUTPUTDIR} (under /data/loads) to ${DOWNLOADDIR}
# under /data/downloads so the downstream processes can find them
#
mv -f ${ALL_OUTFILE_NAME} ${DOWNLOADDIR}
mv -f ${FASTAFILE_NAME} ${DOWNLOADDIR}

#
# log the processed files
#
if [ ${APP_RADAR_INPUT} = true ]
then
    echo "Logging processed files ${APP_INFILES}" >> ${LOG_DIAG}
    for file in ${APP_INFILES}
    do
        echo ${file} ${APP_FILETYPE2}
	echo "Logging processed file ${file}" | tee -a ${LOG_PROC} ${LOG_DIAG}
        ${RADAR_DBUTILS}/bin/logProcessedFile.csh ${RADAR_DBSCHEMADIR} ${JOBKEY} ${file} ${APP_FILETYPE2}
        STAT=$?
        checkStatus ${STAT} "logProcessedFile.csh"
    done
    echo 'Done logging processed files' >> ${LOG_DIAG}
fi

echo `date` | tee -a ${LOG_PROC} ${LOG_DIAG}
echo 'Set process control flag: GT Filter Done' | tee -a ${LOG_DIAG}
${PROC_CTRL_CMD_PROD}/setFlag ${NS_DATA_LOADS} ${FLAG_GTFILTER} ${SCRIPT_NAME}

#
# run postload cleanup and email logs
#
echo "Running postload" | tee -a ${LOG_DIAG}
shutDown

exit 0
