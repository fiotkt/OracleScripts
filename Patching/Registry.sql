The STBDEV database had three invalid registry packages

SQL>set pages 200 lines 190
Col comp_name format a60
Select comp_id, comp_name, status from dba_registry where status!= 'VALID';

COMP_ID		COMP_NAME					STATUS
-----------     -------------- 				-------------
AMD			OLAP Catalog				INVALID
APS			OLAP Analytic Workspace		INVALID
XOQ			Oracle OLAP API				INVALID

To fix

As the Oracle User on the Primary and Standby: Shutdown the Primary database cleanly and run the following commands

$>srvctl stop database –d <DB> -o immediate

$>cd $ORACLE_HOME/rdbms/lib
$>make -f ins_rdbms.mk olap_on
$>make -f ins_rdbms.mk ioracle
