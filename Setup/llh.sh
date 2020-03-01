#EXPORT
export SQLPATH=$HOME/scripts/llh
export PS1='${HOSTNAME}:$USER:${PWD} ($ORACLE_SID) $ '
export DISPLAY=localhost:10.0
export XAUTHORITY=/home/upi702/.Xauthority
export DISPLAY=localhost:10.0
export DB_DIAG=/u01/app/oraswdv/diag/rdbms/`echo ${ORACLE_SID}| tr '[A-Z]' '[a-z]'`/${ORACLE_SID}/trace


#ALIAS
alias si='sqlplus / as sysdba'
alias ri='rman target /'
alias di='dgmgrl /'
alias cdob='cd $ORACLE_BASE'
alias cdoh='cd $ORACLE_HOME'
alias cdta='cd $ORACLE_HOME/network/admin'
alias cddbs='cd $ORACLE_HOME/dbs'
alias cds='cd $SQLPATH'
alias cddbd='cd $DB_DIAG'
alias logs='cd $DB_DIAG'
alias tal='tail -100f $DB_DIAG/alert_${ORACLE_SID}.log'
alias vitns='vi $ORACLE_HOME/network/admin/tnsnames.ora'
alias vilis='vi $ORACLE_HOME/network/admin/listener.ora'
alias l='ls -ltr'
alias oraenv='grep '^[A-Z]' /etc/oratab|cut -d':' -f1;. $ORACLE_HOME/bin/oraenv;. ~/.llh'
