#!/usr/bin/ksh
#
#
#
# Description
# Shell script to interact with the ADR through ADRCI and purge ADR contents
#
# Tunables
###
LOCKFILE=/tmp/mor_adrci_purge_.lck

###

######
# Start Of Functions
#
# tidyup – common fuction called if error has occured
tidyup () {
        rm -f ${LOCKFILE}
        echo “ERROR: Purge aborted at `date` with exit code ${ERR}”
        exit ${ERR}
}

######
# End Of Functions

### Main Program

# Check user is oracle
USERID=`/usr/bin/id -u -nr`
if [ $? -ne 0 ]
then
        echo “ERROR: unable to determine uid”
        exit 99
fi
if [ "${USERID}" != "oracle" ]
then
        echo “ERROR: This script must be run as oracle”
        exit 98
fi

echo “INFO: Purge started at `date`”

# Check if lockfile exists
if [ -f ${LOCKFILE} ]
then
        echo “ERROR: Lock file already exists”
        echo “       Purge already active or incorrectly terminated”
        echo “       If you are sure tidy isn’t active, please remove “
        echo “       ${LOCKFILE}”
        exit 97
fi

# Create lock file
touch ${LOCKFILE} 2>/dev/null
if [ $? -ne 0 ]
then
        echo “ERROR: Unable to create lock file”
        exit 96
fi

# Purge ADR contents
echo “INFO: adrci purge started at `date`”
/app/oracle/product/11.1.0/db_1/bin/adrci exec=”show homes”|grep -v : | while read file_line
do
  echo “INFO: adrci purging diagnostic destination ” $file_line
  echo “INFO: purging ALERT older than 90 days ….”
  /app/oracle/product/11.1.0/db_1/bin/adrci exec=”set homepath $file_line;purge -age 129600 -type ALERT”
  echo “INFO: purging INCIDENT older than 30 days ….”
  /app/oracle/product/11.1.0/db_1/bin/adrci exec=”set homepath $file_line;purge -age 43200 -type INCIDENT”
  echo “INFO: purging TRACE older than 30 days ….”
  /app/oracle/product/11.1.0/db_1/bin/adrci exec=”set homepath $file_line;purge -age 43200 -type TRACE”
  echo “INFO: purging CDUMP older than 30 days ….”
  /app/oracle/product/11.1.0/db_1/bin/adrci exec=”set homepath $file_line;purge -age 43200 -type CDUMP”
  echo “INFO: purging HM older than 30 days ….”
  /app/oracle/product/11.1.0/db_1/bin/adrci exec=”set homepath $file_line;purge -age 43200 -type HM”
  echo “”
  echo “”
done

echo
echo “INFO: adrci purge finished at `date`”

# All completed
rm -f ${LOCKFILE}
echo “SUCC: Purge completed successfully at `date`”

exit 0
