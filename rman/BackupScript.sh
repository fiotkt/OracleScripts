#!/usr/bin/ksh
#-----------------------------------------------------------------------------------------------------------
# Script: rman_backup.ksh
#
# Author: Lee Hallwood
#
# Date: 30/07/2012
#
# Purpose: Main script for the backup of all the databases on a cluster.
#
# Release History
#
#  Version  Date       Who?                 Remarks
#  -------  ---------- --------------       ----------------------------------------------------------------
#  1.0      30/07/2012 Lee Hallwood        Initial version.
#
#-----------------------------------------------------------------------------------------------------------

. ~/.profile
SCRIPTDIR=$(dirname $0);
BACKUP_BASE_LOC="/u01/dd_channel1"

usage() {
  cmd=${0##*/};
  print "Incorrect usage.";

  if [[ "$1" != "" ]]
  then
    print "$1";
  fi

  print "Usage:${cmd} <Backup Level>";
}

if (( $# != 1))
then
  usage "Incorrect number of arguments.";
  exit 1;
fi

if [[ "$1" != "0" && "$1" != "1" ]]
then
  usage "Backup level can only be 0 or 1."
  exit 1;
fi

backup_level=$1

for dbname in `srvctl config`
do

  dbstatus=$(srvctl status database -d ${dbname});

  if [ "${dbstatus}" == "Database is running." ]
  then
    instance=${dbname};
  else
    instance=$(echo ${dbstatus} | grep "is running on " | grep `hostname` | cut -d" " -f2)
  fi

  if [ "${instance}" == "" ]
  then
   echo "No instance is running on this server for the database ${dbname}";
   exit;
  fi

  $SCRIPTDIR/run_backup.ksh ${dbname} ${instance} ${backup_level} ${BACKUP_BASE_LOC}

done

find /home/oracle/backup/logs -name *lev*log -mtime +7 -exec compress {} \;

find /home/oracle/backup/logs -name *lev*Z -mtime +14 -exec rm {} \;
