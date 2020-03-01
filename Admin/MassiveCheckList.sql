set heading off echo off feedback off 
col display_value format a60 
col name format a35 
spool check.log 
 
--Check that only SYS is granted SYSDBA access 
select case when count(1) >0 then 'FAIL - SOMEONE ELSE OTHER THAN SYS HAS SYSDBA ACCESS' else '' end as sysdba_access from v$pwfile_users where user !='SYS' 
/ 
 
select decode(flashback_on,'YES','','FAIL - FLASHBACK') as flashback from v$database 
/ 
 
select decode(force_logging,'YES','','FAIL - FORCE LOGGING') as force_logging from v$database 
/ 
 
select decode(log_mode,'ARCHIVELOG','','FAIL - Not in Archivelog Mode') as archive_logging from v$database 
/ 
 
select case when display_value > 4 then 
         'FAIL - Check parallel_max_servers parameter' 
       else 
         '' 
       end as parallel_max_servers 
from v$parameter2 where name = 'parallel_max_servers' 
/ 
 
--Snaps are every 15 mins and retained for two weeks 
select decode( 
              decode(SNAP_INTERVAL,'+00000 00:15:00.0','PASS','Fail')||decode(RETENTION,'+00014 00:00:00.0','PASS','Fail'), 
     'PASSPASS','','Fail - Snaps not kept for 15 mins over two weeks, run exec dbms_workload_repository.modify_snapshot_settings(retention=>20160, interval=> 15); to fix') as awr_snaps 
from dba_hist_wr_control; 
 
 
col PARALLEL_MAX_SERVERS format a90 
col name format a35 
select case when display_value < 600 then 
         'FAIL - Check archive_lag_target parameter, current value is ' ||display_value||' below 600 (10 mins' 
       when display_value > 900 then 
         'FAIL - Check archive_lag_target parameter, current value is ' ||display_value||' above 900 (15 mins)' 
    else 
         '' 
       end as parallel_max_servers 
from v$parameter2 where name = 'archive_lag_target' 
/ 
 
--Check for invalid objects in the database 
select case when count(1) > 0 then 
           'FAIL - '||count(1)||' invalid objects in the DB' 
   when count(1) = 0 then 
     '' 
   END as invalid_objects 
from dba_objects 
where status !='VALID' 
/ 
 
--Check for any invalid REGISTRY 
select case when count(1) > 0 then 
           'FAIL - '||count(1)||' invalid REGISTRY in the DB' 
   when count(1) = 0 then 
     '' 
   END as invalid_Registry 
from dba_registry where status!='VALID' 
/ 
 
--Check for accounts with DBA access 
select case when count(1) > 0 then 
           'FAIL - '||count(1)||' accounts with DBA priv' 
   when count(1) = 0 then 
     '' 
   END as dba_priv 
from dba_role_privs where granted_role='DBA' and grantee not in ('SYS','SYSTEM', 
'HALLWOODL', 
'BELFIELDA', 
'HULMEJ', 
'CLARKES', 
'FLYNNJ', 
'CASSIDYM', 
'HERONA', 
'ANDERTONN') 
/ 
 
--Check that no users are set as DEFAULT profile 
select decode(count(1),0,'','FAIL - A User with DEFAULT profile exists') from dba_users where profile = 'DEFAULT' 
/ 
 
select case when count(1)!=4 then 'FAIL - NUMBER OF PROFILES IS '||count(1) else '' end as no_of_profiles from 
(select distinct(profile) from dba_profiles) 
/ 
 
 
select case when count(1)!=0 THEN 'FAIL, PROFILE OTHER THAN SECURE_ADMIN,SECURE_USER,DEFAULT,MONITORING_PROFILE EXISTS' else '' end as profiles from 
(select distinct(profile) from dba_profiles where profile not in ('SECURE_ADMIN','SECURE_USER','DEFAULT','MONITORING_PROFILE')) 
/ 
 
 
--Is the SCOTT Schema installed 
select case when count(1)=1 then 'FAIL - SCOTT Schema Installed' else '' end 
from dba_users 
where username='SCOTT' 
/ 
 
--Check accounts created NB none of these are really required 
select case when a.counts >0 then 'FAIL - '||a.counts||' more oracle accounts created then needs to be' else '' end as no_of_default_ora_accs from 
(select count(1) as counts from dba_users where username in 
('ANONYMOUS', 
'APEX_030200', 
'APEX_PUBLIC_USER', 
'CTXSYS', 
'EXFSYS', 
'FLOWS_FILES', 
'MDDATA', 
'MDSYS', 
'MGMT_VIEW', 
'OLAPSYS', 
'ORDDATA', 
'ORDPLUGINS', 
'ORDSYS', 
'OWBSYS', 
'OWBSYS_AUDIT', 
'SCOTT', 
'SI_INFORMTN_SCHEMA', 
'SPATIAL_CSW_ADMIN_USR', 
'SPATIAL_WFS_ADMIN_USR', 
'XDB', 
'XS$NULL' 
)) a 
/ 
 
--Check that block checking is enabled 
select decode(count(1),1,'','FAIL - Block checking is NOT enabled') 
from v$block_change_tracking 
where status = 'ENABLED' 
/ 
 
--Check that at least 4 logfiles of 100 Meg each 
select case when (min(bytes)/1024/1024) < 100 then 'FAIL - logfile size under 100 meg' else '' end as logfilesize 
from v$log; 
 
--Check that at least 4 logfiles 
select case when count(1) <4 then 'FAIL - Need to create 4 logfile groups' else '' end from v$log; 
 
 
--Check that logfiles are duplexed 
select case when count(1)!=0 then 'FAIL - Logfiles are not duplexed' else '' end as duplexed_logs from dual where exists 
(select count(1), group# 
from v$logfile 
group by group# 
having count(1) =1); 
 
--Check that logfiles are on different mount points (NB Only works if logfiles are duplexed) 
col mount_point format a15 
select count(1), substr(member,1,instr(member,'/')) as mount_point, group# 
from v$logfile group by substr(member,1,instr(member,'/')), group# 
having count(1) >1 
order by group#, substr(member,1,instr(member,'/')); 
 
--Check that standby log have been created and that number_of_logs + number_of_instances 
select case when b.primary_log > a.standby_log then 
        'FAIL - Standby Logs Less than Primary Logs, standby logs '||a.standby_log ||' Primary logs '||b.primary_log 
  else 
  '' 
  end as standby_log_test 
from 
(select count(1) as standby_log 
from V$STANDBY_LOG) a, 
(select count(1) as primary_log 
from V$log) b; 
 
--Check that there has been a backup in the past day 
select case when nvl(max(start_time),to_date('01-Jan-2000','DD-MON-YYYY')) < trunc(sysdate-1) then 'FAIL - No backup in last 24 hours' else '' end as last_good_backup 
from V$BACKUP_SET; 
 
--Check that there has been a full backup in the past week 
select case when nvl(max(start_time),to_date('01-Jan-2000','DD-MON-YYYY')) < trunc(sysdate-7) then 'FAIL - No FULL backup in past week' else '' end as last_good_backup 
from V$BACKUP_SET 
where incremental_LEVEL=0; 
 
--Check for any failed backups in the past week 
select case when nvl(max(start_time),to_date('01-Jan-2000','DD-MON-YYYY')) > trunc(sysdate-7) then 'FAILED BACKUP IN PAST WEEK' else '' end as failed_backup_week 
from V$RMAN_BACKUP_JOB_DETAILS 
where status!='COMPLETED' 
/ 
 
--Check for any MISSING backups in the past week 
select distinct(case when a.date_ IS NULL THEN 'FAIL - MISSING BACKUPS FROM THE PAST SEVEN DAYS' ELSE '' END ) as Missing_backups 
from 
   (select distinct(trunc(start_time)) date_ 
      from V$RMAN_BACKUP_JOB_DETAILS 
  where trunc(start_time) > trunc(sysdate-8) 
       --IGNORE TODAY, ALSO SYSDATE MINUS ROWNUM FROM DUAL WILL MEAN THAT THE BELOW QUERY ALSO IGNORES TODAY (AS ROWNUM STARTS AT ONE) 
       and trunc(start_time)!=trunc(sysdate)) a, 
(select trunc(sysdate) - rownum date_ from dual connect by level<=7) b 
where b.date_=a.date_(+) 
/ 
 
 
--Controlfile duplexed?? 
select CASE WHEN COUNT(1) < 2 THEN 
         'FAIL - Check control files are duplexed' 
    else 
         '' 
       end as control_files 
from v$parameter2 where name = 'control_files' group by name; 
 
--Controlfiles on different mount points 
select distinct CASE WHEN count_mount >1 THEN 
         'FAIL - control files on same mount point' 
    else 
         '' 
       end as control_files 
from ( 
select substr(display_value,1,instr(display_value,'/')) as mount_point, count(1) as count_mount 
from v$parameter2 where name = 'control_files' 
group by substr(display_value,1,instr(display_value,'/'))); 
 
select case when count(1) = 0 then 
         'FAIL - No HP_DBSPI User created for monitoring' 
       else 
         '' 
       end as hp_monitoring 
 from dba_users where username='HP_DBSPI'; 
 
--FRA Greater than available disk 
select case when recover_set_to>recover_disk then 'FAIL - Recovery File Dest Size greater than amount available' else '' end as larger_fra_than_dsk 
from 
(select value/1024/1024 as recover_set_to 
from v$parameter2 where name = 'db_recovery_file_dest_size') a, 
(select TOTAL_MB as recover_disk from V$ASM_DISKGROUP where name ='FRA') b 
/ 
 
--FRA less than half available disk 
select case when (recover_set_to)<recover_disk/2 then 'FAIL - Recovery File Dest Size less than half available' else '' end as larger_fra_than_dsk 
from 
(select value/1024/1024 as recover_set_to 
from v$parameter2 where name = 'db_recovery_file_dest_size') a, 
(select TOTAL_MB as recover_disk from V$ASM_DISKGROUP where name ='FRA') b 
/ 
 
--ASM NOT set to Redundancy of unprotected 
select case when count(1)>0 then 'FAIL - DISKGROUP NOT SET TO UNPROTECTED REDUNDANCY' else '' end as asm_redundancy 
from v$ASM_FILE 
where redundancy !='UNPROT' 
  
--Users with Default password 
select case when count(1) >0 then 
  'FAIL - There are '||count(1)||' number of users with default password' 
  else 
  '' 
  end as default_password 
from DBA_USERS_WITH_DEFPWD; 
 
--Users with default password and account is open 
select 
case when count(1) >0 then 
  'FAIL - There are '||count(1)||' number of users with default password AND THE ACCOUNT IS OPEN' 
  else 
  '' 
  end as default_pass_open 
from DBA_USERS_WITH_DEFPWD a, dba_users b where a.username=b.username and account_status='OPEN'; 
 
--Check that AWR has been configured for snaps of 15 mins 
select case when extract( day from snap_interval) *24*60+extract( hour from snap_interval) *60+extract( minute from snap_interval ) != 15 then 
'Need to set rentention to 15 mins, run EXEC dbms_workload_repository.modify_snapshot_settings(interval=>15);' else '' end as awr_snap 
--extract( day from retention) *24*60+extract( hour from retention) *60+extract( minute from retention ) retention_interval, 
--topnsql 
from dba_hist_wr_control; 
 
--Check hidden parameter _query_on_physical, if not set then you will get stung for Active Dataguard license costs 
select 
decode(b.ksppstvl,'TRUE','FAIL - Hidden parameter Query on Physical not set to FALSE HAVE YOU GOT LICENCE FOR ACTIVE DATAGUARD','') as hidden_query_on_physical 
from 
sys.x$ksppi a, 
sys.x$ksppcv b 
where 
a.indx = b.indx 
and a.ksppinm like '$_query_on_physical%' escape '$'; 
 
--Failed logon attempts 
col terminal format a30 
Prompt Failed logon Attempts 
select count(1) number_of_failed_attempts,username,terminal,to_char(timestamp,'DD-MON-YYYY') as time_logon_failure 
from dba_audit_session 
where returncode<>0 
group by username,terminal,to_char(timestamp,'DD-MON-YYYY') 
order by to_char(timestamp,'DD-MON-YYYY'), count(1); 
 
--Check that Audit Purge Job is installed 
select case when count(1)=1 then '' else 'FAIL Audit Purge Job NOT installed' end audit_installed from dba_scheduler_jobs where job_name='JOB_PURGE_AUDIT_TRAILS'; 
 
-- SQL to check for attempts to access the database with non existant users. This could 
-- indicate someone trying to guess user names and passwords. 
-- 
 
select username,terminal,to_char(timestamp,'DD-MON-YYYY HH24:MI:SS') 
from dba_audit_session 
where returncode<>0 
and not exists (select 'x' 
   from dba_users 
   where dba_users.username=dba_audit_session.username) 
/ 
 
--Check that partitioning is not installed as has licence implications 
select 'Partitioning Installed, LICENSE IMPLICATIONS' from DBA_FEATURE_USAGE_STATISTICS where (DETECTED_USAGES>0 or CURRENTLY_USED='TRUE') and name in 
('Encrypted Tablespaces','Partitioning (system)') 
/ 
 
-- Check the audit trail for any changes being made to the structure of the database schema. 
-- 
--Prompt Checking Audit Trail for any changes being made to the structure of the database schema 
col username for a8 
col priv_used for a16 
col obj_name for a30 
col timestamp for a17 
col returncode for 9999 
select to_char(timestamp,'DD-MON-YYYY') timestamp, 
        username, 
  priv_used, 
        obj_name, 
        returncode 
from dba_audit_trail 
where priv_used is not null 
and priv_used<>'CREATE SESSION' 
order by timestamp desc, username, priv_used, obj_name 
/ 
 
 
--Check that users that own tables have not got expiring passwords, the thought being that users with tables are application users 
--and may not want an expiring password 
select username||' '||profile 
from dba_users 
where username not in ( 
'SCOTT', 
'DBSNMP', 
'OLAPSYS', 
'CTXSYS', 
'ORDSYS', 
'XDB', 
'EXFSYS', 
'OWBSYS', 
'APEX_030200', 
'APPQOSSYS', 
'ORDDATA', 
'WMSYS', 
'MDSYS', 
'FLOWS_FILES', 
'SYSMAN', 
'SYSTEM', 
'SYS', 
'OUTLN') 
AND exists (select 1 from dba_tables where owner=dba_users.username) and expiry_date is not null 
/ 
 
set pages 50000 
break on privilege skip 1 
select privilege, grantee, admin_option 
from dba_sys_privs 
where privilege not in 
( 
/* list any other privilege here you don't find "sweeping" 
*/ 
'ALTER SESSION', 
'QUERY REWRITE', 
'CREATE DIMENSION', 
'CREATE INDEXTYPE', 
'CREATE LIBRARY', 
'CREATE OPERATOR', 
'CREATE PROCEDURE', 
'CREATE SEQUENCE', 
'CREATE SESSION', 
'CREATE SNAPSHOT', 
'CREATE SYNONYM', 
'CREATE TABLE', 
'CREATE TRIGGER', 
'CREATE TYPE', 
'CREATE USER', 
'CREATE VIEW', 
'UNLIMITED TABLESPACE' 
) 
and grantee not in 
('SYS','SYSTEM','WKSYS','XDB', 
'MDSYS','ORDPLUGINS','ODM','DBA','IMP_FULL_DATABASE','EXP_FULL_DATABASE','DBSNMP','OEM_MONITOR','WMSYS','DATAPUMP_IMP_FULL_DATABASE', 
'SCHEDULER_ADMIN','OUTLN','AQ_ADMINISTRATOR_ROLE','RECOVERY_CATALOG_OWNER','OEM_ADVISOR','APPQOSSYS') 
/* Place all the user names you want to exclude */ 
order by privilege, grantee 
/ 
 
 
--DBA Access 
select case when count(1)>0 then 'FAIL - DBA ACCESS GRANTED TO NON DBA' else '' end as Dba_access from dba_role_privs where GRANTED_ROLE='DBA' and grantee not in 
('HALLWOODL', 
'SYSTEM', 
'BELFIELDA', 
'CLARKES', 
'FLYNNJ', 
'SYS', 
'HERONA', 
'ANDERTONN', 
'ASPDENJ') 
/ 
 
--Check that SYS/SYSTEM and USERS are not set to autoextend to values greater than 2 Gig 
select max(autoextend) from ( 
Select case when sum(maxbytes) > 2147483648 then 'FAIL - Tablespaces USERS/SYSAUX or SYSTEM set to autoextend to greater than 2 gig' else '' end as autoextend 
from dba_data_files 
where tablespace_name in ('USERS','SYSAUX','SYSTEM') 
group by tablespace_name ) 
/ 
 
select case when count(1) < 24 then 
         'FAIL: Check that Auditing has been applied, only '||count(1)||' operations being audited' 
    else 
      '' 
       end audit_ops 
from DBA_PRIV_AUDIT_OPTS 
/ 
 
select distinct backup_type, completion_time, to_char(completion_time, 'DAY') day from 
( select set_stamp, 
 case when BACKUP_TYPE = 'D' then 
   case when CONTROLFILE_INCLUDED = 'YES' then 'ControlFile Backup' when INCREMENTAL_LEVEL = 0 THEN 'Full Backup' else 'Incremental Backup' end 
 when BACKUP_TYPE = 'L' then 'Archive Logs' 
 when BACKUP_TYPE = 'I' then 
   case when INCREMENTAL_LEVEL = 0 THEN 'Full Backup' else 'Incremental Backup' end 
  when CONTROLFILE_INCLUDED = 'YES' then 'ControlFile Backup' 
 else backup_type||INCREMENTAL_LEVEL|| CONTROLFILE_INCLUDED end backup_type, 
 trunc(completion_time) completion_time 
 from v$backup_set 
 ) where backup_type in ('Incremental Backup','Full Backup') 
 order by 2 
/ 
 
/* 
PROMPT ALERTS IN THE DATABASE 
col host_id format a15 
col process_id format a30 
col creation_time format a20 
select 
MESSAGE_TYPE, 
to_char(CREATION_TIME,'DD-MON-YYYY HH24:MI:SS') as CREATION_TIME, 
--RESOLUTION, 
--ERROR_INSTANCE_ID, 
--EXECUTION_CONTEXT_ID, 
--USER_ID, 
--INSTANCE_NUMBER, 
INSTANCE_NAME, 
--HOST_NW_ADDR, 
--HOST_ID, 
--PROCESS_ID, 
--MODULE_ID, 
--HOSTING_CLIENT_ID, 
--MESSAGE_LEVEL, 
MESSAGE_GROUP, 
--METRIC_VALUE, 
--ADVISOR_NAME, 
SUGGESTED_ACTION, 
--TIME_SUGGESTED, 
REASON 
--OBJECT_TYPE, 
--SUBOBJECT_NAME, 
--OBJECT_NAME, 
--OWNER, 
--REASON_ID, 
--SEQUENCE_ID 
from DBA_ALERT_HISTORY; 
*/ 
spool off
