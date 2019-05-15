Backing out a baseline


1. Find the SQL Handle of the baseline 

set long 9999999
col exact_matching_signature format 99999999999999999999
col force_matching_signature format 99999999999999999999
col signature                format 99999999999999999999
select sql.sql_id, sql.plan_hash_value, baseline.sql_handle, baseline.plan_name,
nvl(sql.sql_plan_baseline,'BASELINE NOT BEING USED') as sql_plan_baseline, 
sql.exact_matching_signature, sql.force_matching_signature, baseline.signature, 
baseline.enabled,   baseline.accepted,  baseline.fixed, baseline.reproduced,
baseline.optimizer_cost, baseline.executions, baseline.elapsed_time, baseline.cpu_time, baseline.buffer_gets,
baseline.disk_reads, baseline.direct_writes, baseline.rows_processed,
sql.sql_fulltext
from v$sql sql, dba_sql_plan_baselines baseline
where  sql_id='ajfvn0t2kcpw8';


SQL_ID        PLAN_HASH_VALUE SQL_HANDLE
------------- --------------- --------------------------------------------------------------------------------------------------------------------------------
PLAN_NAME                                                                                                                        SQL_PLAN_BASELINE
-------------------------------------------------------------------------------------------------------------------------------- ------------------------------
EXACT_MATCHING_SIGNATURE FORCE_MATCHING_SIGNATURE             SIGNATURE ENA ACC FIX REP OPTIMIZER_COST EXECUTIONS ELAPSED_TIME   CPU_TIME BUFFER_GETS DISK_READS DIRECT_WRITES
------------------------ ------------------------ --------------------- --- --- --- --- -------------- ---------- ------------ ---------- ----------- ---------- -------------
ROWS_PROCESSED SQL_FULLTEXT
-------------- --------------------------------------------------------------------------------
ajfvn0t2kcpw8      1853619288 SQL_b6c5157ae6cb5f55
SQL_PLAN_bdj8pgbmcqrup7a0a3e0c                                                                                                   BASELINE NOT BEING USED
    13169956302917164885     13169956302917164885  13169956302917164885 YES YES YES YES           1200      31317   9757416577 1537303063   148635366    3057712       3057505
      38975537 INSERT INTO TBL_BUNDLE_RULE_GROUP_GTT WITH BUN_DATA AS ( SELECT DISTINCT CUSTOME
               R_ID ,TRG1.RULE_GROUP ,COMPONENT_BUNDLE_ID ,TRG1.PRODUCT_ID ,COMPONENT_ID FROM M
               DM_OWNER.OFFER_AFT_RULE_SELLABLE OS1 INNER JOIN TEMP_RULE_GROUP_GTT TRG1 ON OS1.
               PRODUCT_ID = TRG1.PRODUCT_ID AND OS1.RULE_GROUP = TRG1.RULE_GROUP AND ROLE_ID =
               :B1 WHERE CUSTOMER_ID = :B4 AND VOC_ENABLED <> :B3 AND FRONTBOOK = NVL(:B2 , FRO
               NTBOOK) ), INVAL_BUN_ID AS ( SELECT COMPONENT_BUNDLE_ID FROM BUN_DATA BD WHERE N
               OT EXISTS ( SELECT 1 FROM TEMP_RULE_GROUP_GTT TRG1 WHERE CUSTOMER_ID = :B4 AND B
               D.COMPONENT_ID = TRG1.PRODUCT_ID ) ) SELECT DISTINCT CUSTOMER_ID ,RULE_GROUP ,CO
               MPONENT_BUNDLE_ID ,PRODUCT_ID FROM BUN_DATA BD WHERE NOT EXISTS ( SELECT 1 FROM
               INVAL_BUN_ID IBD WHERE BD.COMPONENT_BUNDLE_ID = IBD.COMPONENT_BUNDLE_ID )

2. Disable the baseline (There is an option to drop later - also purging the SQL out of the cache so that the optimiser reparses is later)

FUNCTION ALTER_SQL_PLAN_BASELINE RETURNS BINARY_INTEGER
 Argument Name                  Type                    In/Out Default?
 ------------------------------ ----------------------- ------ --------
 SQL_HANDLE                     VARCHAR2                IN     DEFAULT
 PLAN_NAME                      VARCHAR2                IN     DEFAULT
 ATTRIBUTE_NAME                 VARCHAR2                IN
 ATTRIBUTE_VALUE                VARCHAR2                IN

ATTRIBUTE_NAME 
enabled 		- 'YES' means the plan is available for use by the optimizer. It may or may not be used depending on accepted status. 
fixed 			- 'YES' means the SQL plan baseline is not evolved over time. A fixed plan takes precedence over a non-fixed plan.
autopurge 		- 'YES' means the plan is purged if it is not used for a time period. 'NO' means it is never purged.
plan_name 		- Name of the plan - String of up to 30 characters
description 	- Plan description. String of up to 500 bytes 
 
col sql_handle format a40
select sql_handle, enabled from dba_sql_plan_baselines where sql_handle='SQL_b6c5157ae6cb5f55';
 
 
SQL_HANDLE                               ENA
---------------------------------------- ---
SQL_b6c5157ae6cb5f55                     YES
 
 
set serveroutput on	
declare
   t_disable_plan PLS_INTEGER;
begin
	t_disable_plan := dbms_spm.alter_sql_plan_baseline(SQL_HANDLE      => 'SQL_b6c5157ae6cb5f55',
	                                                   PLAN_NAME       => 'SQL_PLAN_bdj8pgbmcqrup7a0a3e0c',
													   ATTRIBUTE_NAME  => 'ENABLED',
													   ATTRIBUTE_VALUE => 'NO');
	dbms_output.put_line('Number of disabled plans is '||t_disable_plan);
end;
/
 
Number of disabled plans is 1

PL/SQL procedure successfully completed.

1626 U:SYS@PRPCUT:ODA-KN-T21 SQL> select sql_handle, enabled from dba_sql_plan_baselines where sql_handle='SQL_b6c5157ae6cb5f55';

SQL_HANDLE                               ENA
---------------------------------------- ---
SQL_b6c5157ae6cb5f55                     NO

3. Drop the baseline
										
FUNCTION DROP_SQL_PLAN_BASELINE RETURNS BINARY_INTEGER
 Argument Name                  Type                    In/Out Default?
 ------------------------------ ----------------------- ------ --------
 SQL_HANDLE                     VARCHAR2                IN     DEFAULT
 PLAN_NAME                      VARCHAR2                IN     DEFAULT
	
set serveroutput on	
declare
   t_dropped PLS_INTEGER;
begin
	t_dropped := dbms_spm.drop_sql_plan_baseline(SQL_HANDLE => 'SQL_b6c5157ae6cb5f55',
	                                             PLAN_NAME  => 'SQL_PLAN_bdj8pgbmcqrup7a0a3e0c');
	dbms_output.put_line('Number of dropped plans is '||t_dropped);
end;
/


4. Purge the SQL from the shared pool

select 'exec DBMS_SHARED_POOL.PURGE('||chr(39)||ADDRESS||','||HASH_VALUE||chr(39)||',''C'');' as purging
from V$SQLAREA 
where SQL_Id='ajfvn0t2kcpw8';

exec DBMS_SHARED_POOL.PURGE('0000000693E4C268,2515443712','C');


--Alternatively if the above does not work then do manually
select address, hash_value from v$sqlarea 
where SQL_Id='ajfvn0t2kcpw8';

ADDRESS          HASH_VALUE
---------------- ----------
000000015ED297E8 1160140680

exec DBMS_SHARED_POOL.PURGE('000000015ED297E8,1160140680','C');
