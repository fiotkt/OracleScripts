set pages 0 lines 132 feedback off echo off veri off
select 'alter database add standby logfile thread '|| thread# ||' size '|| bytes||';'
  from v$log
group by thread#, group#, bytes
union all
select 'alter database add standby logfile thread '|| thread# ||' size '|| bytes||';'
  from v$log
group by thread#, bytes
order by 1
.
spool create_standby_logfiles.sql
/
spool off
