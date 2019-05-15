1. Create the baseline

set serveroutput on
declare 
t_worked pls_integer;
begin
  t_worked := dbms_spm.load_plans_from_cursor_cache(SQL_ID=>'ajfvn0t2kcpw8',PLAN_HASH_VALUE  =>914266488, FIXED=>'YES', ENABLED=>'YES');
  dbms_output.put_line('did it work '||decode(t_worked,'1','YES','NO');
end;
/

--Check that the baseline has been created
set long 9999999
col exact_matching_signature format 99999999999999999999
col force_matching_signature format 99999999999999999999
col signature                format 99999999999999999999
select sql.sql_id, sql.plan_hash_value, baseline.sql_handle, nvl(sql.sql_plan_baseline,'BASELINE NOT BEING USED') as sql_plan_baseline, 
sql.exact_matching_signature, sql.force_matching_signature, baseline.signature, 
baseline.enabled,   baseline.accepted,  baseline.fixed, baseline.reproduced,
baseline.optimizer_cost, baseline.executions, baseline.elapsed_time, baseline.cpu_time, baseline.buffer_gets,
baseline.disk_reads, baseline.direct_writes, baseline.rows_processed,
sql.sql_fulltext
from v$sql sql, dba_sql_plan_baselines baseline
where  sql_id='ajfvn0t2kcpw8';

SQL_ID        PLAN_HASH_VALUE SQL_HANDLE                     SQL_PLAN_BASELINE              EXACT_MATCHING_SIGNATURE FORCE_MATCHING_SIGNATURE             SIGNATURE
------------- --------------- ------------------------------ ------------------------------ ------------------------ ------------------------ ---------------------
ENABLED  ACCEPTED FIXED REPRODUCED
-------- -------- ----- ----------
OPTIMIZER_COST EXECUTIONS ELAPSED_TIME   CPU_TIME BUFFER_GETS DISK_READS DIRECT_WRITES ROWS_PROCESSED
-------------- ---------- ------------ ---------- ----------- ---------- ------------- --------------
SQL_FULLTEXT
--------------------------------------------------------------------------------
ajfvn0t2kcpw8       914266488 SQL_b6c5157ae6cb5f55           BASELINE NOT BEING USED            13169956302917164885     13169956302917164885  13169956302917164885
YES      YES      YES   YES
          1200      31317   9757416577 1537303063   148635366    3057712       3057505       38975537
INSERT INTO TBL_BUNDLE_RULE_GROUP_GTT WITH BUN_DATA AS ( SELECT DISTINCT CUSTOME
R_ID ,TRG1.RULE_GROUP ,COMPONENT_BUNDLE_ID ,TRG1.PRODUCT_ID ,COMPONENT_ID FROM M
DM_OWNER.OFFER_AFT_RULE_SELLABLE OS1 INNER JOIN TEMP_RULE_GROUP_GTT TRG1 ON OS1.
PRODUCT_ID = TRG1.PRODUCT_ID AND OS1.RULE_GROUP = TRG1.RULE_GROUP AND ROLE_ID =
:B1 WHERE CUSTOMER_ID = :B4 AND VOC_ENABLED <> :B3 AND FRONTBOOK = NVL(:B2 , FRO
NTBOOK) ), INVAL_BUN_ID AS ( SELECT COMPONENT_BUNDLE_ID FROM BUN_DATA BD WHERE N
OT EXISTS ( SELECT 1 FROM TEMP_RULE_GROUP_GTT TRG1 WHERE CUSTOMER_ID = :B4 AND B
D.COMPONENT_ID = TRG1.PRODUCT_ID ) ) SELECT DISTINCT CUSTOMER_ID ,RULE_GROUP ,CO
MPONENT_BUNDLE_ID ,PRODUCT_ID FROM BUN_DATA BD WHERE NOT EXISTS ( SELECT 1 FROM
INVAL_BUN_ID IBD WHERE BD.COMPONENT_BUNDLE_ID = IBD.COMPONENT_BUNDLE_ID )

2. Create the table where the baselines are going to be stored ready for export

BEGIN
  DBMS_SPM.CREATE_STGTAB_BASELINE(
    table_name      => 'SPM_STAGING_TABLE',
    table_owner     => 'BASE',
    tablespace_name => 'RULES');
END;
/

PL/SQL procedure successfully completed.


select owner, table_name, tablespace_name from dba_tables where table_name='SPM_STAGING_TABLE';

OWNER                TABLE_NAME                          TABLESPACE_NAME
-------------------- ----------------------------------- ------------------------------
BASE                 SPM_STAGING_TABLE                   RULES

3. Pack the baselines into the staging table

FUNCTION PACK_STGTAB_BASELINE RETURNS NUMBER
 Argument Name                  Type                    In/Out Default?
 ------------------------------ ----------------------- ------ --------
 TABLE_NAME                     VARCHAR2                IN
 TABLE_OWNER                    VARCHAR2                IN     DEFAULT
 SQL_HANDLE                     VARCHAR2                IN     DEFAULT
 PLAN_NAME                      VARCHAR2                IN     DEFAULT
 SQL_TEXT                       CLOB                    IN     DEFAULT
 CREATOR                        VARCHAR2                IN     DEFAULT
 ORIGIN                         VARCHAR2                IN     DEFAULT
 ENABLED                        VARCHAR2                IN     DEFAULT
 ACCEPTED                       VARCHAR2                IN     DEFAULT
 FIXED                          VARCHAR2                IN     DEFAULT
 MODULE                         VARCHAR2                IN     DEFAULT
 ACTION                         VARCHAR2                IN     DEFAULT


SET SERVEROUTPUT ON
DECLARE
  l_plans_packed  PLS_INTEGER;
BEGIN
  l_plans_packed := dbms_spm.pack_stgtab_baseline(
    table_name      => 'SPM_STAGING_TABLE',
    table_owner     => 'BASE',
	SQL_HANDLE      => 'SQL_b6c5157ae6cb5f55');
  DBMS_OUTPUT.put_line('Plans Packed: ' || l_plans_packed);
END;
/

Plans Packed: 1

PL/SQL procedure successfully completed.


4. Export the table

expdp system/Pdfe2f9qbq0we#23f directory=llh tables=base.spm_staging_table dumpfile=llh.dmp


Processing object type TABLE_EXPORT/TABLE/STATISTICS/MARKER
. . exported "BASE"."SPM_STAGING_TABLE"                  67.10 KB      17 rows
Master table "SYSTEM"."SYS_EXPORT_TABLE_01" successfully loaded/unloaded
******************************************************************************

5. On the database that you wish to import the baseline to import the staging table

impdp system/HqenqpOFW#24loihq directory=llh dumpfile=llh.dmp

6. Unpack the table


FUNCTION UNPACK_STGTAB_BASELINE RETURNS NUMBER
 Argument Name                  Type                    In/Out Default?
 ------------------------------ ----------------------- ------ --------
 TABLE_NAME                     VARCHAR2                IN
 TABLE_OWNER                    VARCHAR2                IN     DEFAULT
 SQL_HANDLE                     VARCHAR2                IN     DEFAULT
 PLAN_NAME                      VARCHAR2                IN     DEFAULT
 SQL_TEXT                       CLOB                    IN     DEFAULT
 CREATOR                        VARCHAR2                IN     DEFAULT
 ORIGIN                         VARCHAR2                IN     DEFAULT
 ENABLED                        VARCHAR2                IN     DEFAULT
 ACCEPTED                       VARCHAR2                IN     DEFAULT
 FIXED                          VARCHAR2                IN     DEFAULT
 MODULE                         VARCHAR2                IN     DEFAULT
 ACTION                         VARCHAR2                IN     DEFAULT




SET SERVEROUTPUT ON
DECLARE
  l_plans_unpacked  PLS_INTEGER;
BEGIN
  l_plans_unpacked := dbms_spm.unpack_stgtab_baseline(
    table_name      => 'SPM_STAGING_TABLE',
    table_owner     => 'BASE',
    sql_handle      => 'SQL_b6c5157ae6cb5f55');
  DBMS_OUTPUT.put_line('Plans Unpacked: ' || l_plans_unpacked);
END;
/

Plans Unpacked: 1

PL/SQL procedure successfully completed.


7. Check that the baseline is there 

select count(1) from  dba_sql_plan_baselines where sql_handle='SQL_b6c5157ae6cb5f55';

  COUNT(1)
----------
         1

set long 9999999
col exact_matching_signature format 99999999999999999999
col force_matching_signature format 99999999999999999999
col signature                format 99999999999999999999
select sql.sql_id, sql.plan_hash_value, baseline.sql_handle, nvl(sql.sql_plan_baseline,'BASELINE NOT BEING USED') as sql_plan_baseline, 
sql.exact_matching_signature, sql.force_matching_signature, baseline.signature, 
baseline.enabled,   baseline.accepted,  baseline.fixed, baseline.reproduced,
baseline.optimizer_cost, baseline.executions, baseline.elapsed_time, baseline.cpu_time, baseline.buffer_gets,
baseline.disk_reads, baseline.direct_writes, baseline.rows_processed,
sql.sql_fulltext
from v$sql sql, dba_sql_plan_baselines baseline
where  sql_id='ajfvn0t2kcpw8';

SQL_ID        PLAN_HASH_VALUE SQL_HANDLE
------------- --------------- --------------------------------------------------------------------------------------------------------------------------------
SQL_PLAN_BASELINE              EXACT_MATCHING_SIGNATURE FORCE_MATCHING_SIGNATURE             SIGNATURE ENA ACC FIX REP OPTIMIZER_COST EXECUTIONS ELAPSED_TIME   CPU_TIME BUFFER_GETS
------------------------------ ------------------------ ------------------------ --------------------- --- --- --- --- -------------- ---------- ------------ ---------- -----------
DISK_READS DIRECT_WRITES ROWS_PROCESSED SQL_FULLTEXT
---------- ------------- -------------- --------------------------------------------------------------------------------
ajfvn0t2kcpw8      1853619288 SQL_b6c5157ae6cb5f55
BASELINE NOT BEING USED            13169956302917164885     13169956302917164885  13169956302917164885 YES YES YES YES           1200      31317   9757416577 1537303063   148635366
   3057712       3057505       38975537 INSERT INTO TBL_BUNDLE_RULE_GROUP_GTT WITH BUN_DATA AS ( SELECT DISTINCT CUSTOME
                                        R_ID ,TRG1.RULE_GROUP ,COMPONENT_BUNDLE_ID ,TRG1.PRODUCT_ID ,COMPONENT_ID FROM M
                                        DM_OWNER.OFFER_AFT_RULE_SELLABLE OS1 INNER JOIN TEMP_RULE_GROUP_GTT TRG1 ON OS1.
                                        PRODUCT_ID = TRG1.PRODUCT_ID AND OS1.RULE_GROUP = TRG1.RULE_GROUP AND ROLE_ID =
                                        :B1 WHERE CUSTOMER_ID = :B4 AND VOC_ENABLED <> :B3 AND FRONTBOOK = NVL(:B2 , FRO
                                        NTBOOK) ), INVAL_BUN_ID AS ( SELECT COMPONENT_BUNDLE_ID FROM BUN_DATA BD WHERE N
                                        OT EXISTS ( SELECT 1 FROM TEMP_RULE_GROUP_GTT TRG1 WHERE CUSTOMER_ID = :B4 AND B
                                        D.COMPONENT_ID = TRG1.PRODUCT_ID ) ) SELECT DISTINCT CUSTOMER_ID ,RULE_GROUP ,CO
                                        MPONENT_BUNDLE_ID ,PRODUCT_ID FROM BUN_DATA BD WHERE NOT EXISTS ( SELECT 1 FROM
                                        INVAL_BUN_ID IBD WHERE BD.COMPONENT_BUNDLE_ID = IBD.COMPONENT_BUNDLE_ID )


										
										
