#!/usr/bin/sh
#
# Script Name : db_housekeep_$ORACLE_SID.sh
# Description : Script to perform housekeeping
#             : - moves alert log to dated backup
#             : - removes backup alert logs, trace files and core files that are more than 28 days old
#             :
#---------------------------------------------------------------------
# Amendment History
#
# Date         Author        Change No   Description
# ----         ------        ---------   -----------
#
#
#---------------------------------------------------------------------

FILEPATH=/u01/app/diag/rdbms/phopfprd/PHOPFPRD2
ALERTLOG=${FILEPATH}/trace/alert_PHOPFPRD2.log
AUDITPATH=/u01/app/admin/PHOPFPRD/adump

# Rename the alert log

#mv ${ALERTLOG} ${ALERTLOG}.$(date "+%d-%m-%y")
mv ${ALERTLOG} ${ALERTLOG}.`date "+%d-%m-%y"`

# Housekeep old alert logs

find ${FILEPATH}/trace -name 'alert*' -mtime +28 -exec ls -l {} \;
find ${FILEPATH}/trace -name 'alert*' -mtime +28 -exec rm {} \;

# Housekeep old trace files

find ${FILEPATH} -follow -name '*trc' -mtime +14 -exec ls -l {} \;
find ${FILEPATH} -follow -name '*trc' -mtime +14 -exec rm {} \;
find ${FILEPATH} -follow -name '*trm' -mtime +14 -exec ls -l {} \;
find ${FILEPATH} -follow -name '*trm' -mtime +14 -exec rm {} \;

# Housekeep old core files

find ${FILEPATH} -follow -name 'core*' -mtime +14 -exec ls -l {} \;
find ${FILEPATH} -follow -name 'core*' -mtime +14 -exec rm {} \;

# Housekeep old audit files

find ${AUDITPATH} -name '*.aud' -mtime +180 -exec ls -l {} \;
find ${AUDITPATH} -name '*.aud' -mtime +180 -exec rm -r {} \;
