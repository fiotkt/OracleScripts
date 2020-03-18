--top 10 checks for slow db:
set echo on
-- check unusable indexes and invalid objects
@chkinvs
-- check running jobs
@chkjobs
-- check active sessions
@chkses
-- check is backup is currently running
select sid,serial#,username,OSUSER,MACHINE,program,LOGON_TIME,status from gv$session where username is not null and status <> 'INACTIVE' and lower(program) like '%rman%' order by logon_time;
-- check for locked objects (10g) ('library cache pin')
col event form a50
SELECT event, COUNT(*) FROM gv$session WHERE username IS NOT NULL GROUP BY event ORDER BY 1;
--9i:
-- check top wait events for instance since startup
select * from (select inst_id,EVENT,total_waits,(((time_waited)/100)/total_waits) as "ave (s)",WAIT_CLASS from  gv$system_event where lower(wait_class) != 'idle' order by 3 desc,4) where rownum<=10;
-- check current locks: (these are instance-specific, so run against each node)
select * from dba_blockers;
select * from dba_waiters;
--also check gv$access
col owner form a10
col object form a40
col program format A30
select a.inst_id,a.sid,a.owner||'.'||a.object object,a.type,s.program from gv$access a, gv$session s where a.sid     = s.sid and   a.inst_id = s.inst_id and   s.status  = 'ACTIVE' and  ( a.type = 'PACKAGE' or a.type = 'PROCEDURE') order by object;
--show blocking and waiting sessions:
col "User Name" form a30
col username form a30
col owner form a20
col inst_id form 9999999
col object_name form a30
col object_type form a20
select lpad(' ',decode(l.xidusn,0,3,0))||l.oracle_username "User Name",o.owner,o.object_name,o.object_type from v$locked_object l,dba_objects o where l.object_id=o.object_id order by o.object_id,1 desc;
select s.username,decode(l.type,'TM','TABLE LOCK','TX','ROW LOCK',null) "lock level",o.owner,o.object_name,o.object_type from v$session s,v$lock l,dba_objects o where s.sid=l.sid and o.object_id=l.id1 and username is not null;
select decode(request,0,'holder: ','waiter: ')||sid sess, id1, id2, lmode, request, type from gv$lock where (id1, id2, type) in (select id1, id2, type from gv$lock where request > 0) order by id1, request;
accept SID prompt 'Enter SID to check the SQL running: ' default 0
select u.inst_id,s.address,s.hash_value,s.child_number,s.plan_hash_value,buffer_gets,executions,s.sql_text from gv$session u, gv$sql s where u.SQL_ADDRESS=s.ADDRESS and u.sid=&SID;
-- check sessions currently waiting for something (blocked in some way)
column username format a25
column event format a60
col state format a20
select s.sid, s.username, s.status, w.event, w.state, round(w.SECONDS_IN_WAIT/60,2) "MINS_IN_WAIT" from v$session s, v$session_wait w where s.sid = w.sid and s.username is not null and s.status = 'ACTIVE' order by 2, 1, 5 desc;
accept SID prompt 'Enter SID to check the SQL running: ' default 0
select u.inst_id,s.address,s.hash_value,s.child_number,s.plan_hash_value,buffer_gets,executions,s.sql_text from gv$session u, gv$sql s where u.SQL_ADDRESS=s.ADDRESS and u.sid=&SID;
-- check which active sessions have done the most work since creation
column username format a12 trun
column event format a60
column module format a32 trun
col logon_time form a20
select * from (select s.inst_id, s.sid, s.username, s.status, w.event, s.module, round(w.TIME_WAITED/100/60,2) "TIME_WAITED (M)", to_char(s.logon_time,'DD-MON-YY HH24:MI:SS') logon_time from gv$session s, gv$session_event w where s.sid = w.sid and s.inst_id = w.inst_id and s.username is not null and s.status = 'ACTIVE' and w.TIME_WAITED > 1000 order by w.TIME_WAITED desc) where rownum<=20;
-- check sessions with large redo usage, indicating heavy transaction count
column username format a12
column module format a32
column sid format 99999
column status form a10
select s.sid, s.username, s.status, s.module, w.value, to_char(s.logon_time,'DD-MON-YY HH24:MI:SS') logon_time from gv$session s, gv$sesstat w, gv$statname n where s.sid = w.sid and w.inst_id = n.inst_id and w.inst_id = s.inst_id and w.statistic# = n.statistic# and s.username is not null and n.name like 'redo size' and w.value > 10000 order by w.value desc;
-- check redo log generation rate
select * from (select * from (SELECT THREAD#, SEQUENCE#, FIRST_CHANGE#, NEXT_CHANGE#, first_time,RESETLOGS_TIME FROM V$LOG_HISTORY order by FIRST_CHANGE# desc) where rownum<=10) order by FIRST_CHANGE#;
select * from (select * from (SELECT THREAD#, SEQUENCE#, FIRST_CHANGE#, NEXT_CHANGE#, first_time FROM V$LOG_HISTORY order by FIRST_CHANGE# desc) where rownum<=10) order by FIRST_CHANGE#;
-- check sga
select component, current_size/1024/1024 MB, to_char(last_oper_time,'DD-MON-YYYY HH24:MI:SS') last_resize from v$sga_dynamic_components order by MB desc;
-- check for distribution of os resources across rac
select inst_id,startup_time from gv$instance order by inst_id;
select * from gv$osstat order by stat_name,inst_id;
-- check for distribution of work across rac
select inst_id,startup_time from gv$instance order by inst_id;
select stat_name,inst_id,value from gv$sys_time_model order by value desc;
select stat_name,inst_id,value from gv$sys_time_model order by stat_name,inst_id;
accept wait_time prompt 'Enter no seconds over which to gather stats for hit ratio, soft parse ratio etc: (default 0)' default 0
-- check buffer cache hit:miss ratio

-- shared pool cache soft parse:hard parse ratio

-- check objects with old statistics

-- check when stats collection package DBMS_STATS was last run
col operation form a30 trunc
col target form a30 trunc
col start_time form a40
col end_time form a40
select * from dba_optstat_operations where start_time>sysdate-5 order by start_time;

-- if there are no stats on a table, dynamic sampling is used to generate them in real time. Check if this is enabled (default=2=enabled). If enabled, a small random sample of the table's blocks are scanned using recursive SQL, including any predicates (where clause). If this parameter is set higher, it's more aggressive, meaning even tables that already have stats are scanned, and more i/o is allowed for sampling.
show parameter optimizer_dynamic_sampling

-- check sessions performing rollback (UNDO):
select s.sid, s.username, r.name "RB Segment name", t.start_time, t.used_ublk "Undo blocks", round(t.used_ublk*8192/1024/1024/1024,2) GB,t.used_urec "Undo recs" from gv$session s, gv$transaction t, v$rollname r where t.addr = s.taddr and t.inst_id=s.inst_id and r.usn=t.xidusn;
select s.sid ,s.serial# ,s.username ,s.machine ,s.status ,s.lockwait ,t.used_ublk ,t.used_urec ,t.start_time from gv$transaction t inner join gv$session s on t.addr = s.taddr;

-- check how db is spending it's time in general:
select * from v$system_wait_class;

-- check how db spent it's time in the last 1 minute:
col wait_class form a40
select b.wait_class, round(a.average_waiter_count,2) "awc", a.dbtime_in_wait,a.time_waited, a.wait_count from v$waitclassmetric a,v$system_wait_class b where a.wait_class#=b.wait_class#;

-- check if any tablespace are running out of space
@chktbsp
-- check for long-running operations
col message form a100
select inst_id,SID,SERIAL#,OPNAME,ELAPSED_SECONDS,round(TIME_REMAINING/3600,2) HRS_REMAINING,SQL_ID,MESSAGE from gv$session_longops where time_remaining>0;
--(then look further into this view to see when exactly the plan changed etc)
-- show sql in shared pool that has many children. This points to an issue since really they should all use the same QEP unless NLS is different or other small differences (check gV$SQL_SHARED_CURSOR for reason):
select * from (select b.sql_id, b.child_number ,b.sql_text,b.rows_processed from (select sql_id,count(sql_id) scount from v$sql having count(sql_id)>2 group by sql_id) a,v$sql b where a.sql_id=b.sql_id order by a.scount desc,b.child_number) where rownum<20;
-- show any indexes with >4 levels, candidates for rebuild (however, ID 122008.1 suggests this measure is no longer meaningful. See ID 989186.1 for better script)
select owner,index_name,blevel from dba_indexes where blevel>2 and owner <>'SYS' order by 3,1,2;
-- show any indexes with >20% wasted space, candidates for rebuild (need to analyze index first before index_stats is populated)(however, ID 122008.1 suggests this measure is no longer meaningful. See ID 989186.1 for better script):
select name,(del_lf_rows_len/lf_rows_len)*100 "Wasted Space" from index_stats order by 1;
-- check for interconnect issues in RAC, if >0 then there's a problem
select * from gv$sysstat where lower(name) = 'global cache convert timeouts';
-- check for events that have waited over 60 seconds:
select sample_time, event, time_waited from V$ACTIVE_SESSION_HISTORY where event = 'db file sequential read' and time_waited> 10000000;
-- show recent sql with >2 execution plans (then run @?/rdbms/admin/awrsqrpt to see time of change, and compare exec plans etc - v comprehensive report). Also @?/rdbms/admin/ashrpti breaks it down further into calls per module etc:
col sql_text form a120 trunc
select sql_id,count(distinct plan_hash_value) num_plans,sql_text from v$sql where LAST_ACTIVE_TIME>sysdate-1 group by sql_id,sql_text having count(distinct plan_hash_value)>1 order by 2;
/*
Show all exec plans: select * from table(dbms_xplan.display_awr('&SQL_ID'));
run @?/rdbms/admin/awrsqrpt to get breakdown of when exec plan changed and which was best etc.
*/
-- check for top sql_id's ordered by impact (very basic)
col sql_text form a50 trunc
col value form a30
select sql_id,'max executions: '||executions value,sql_text  from v$sql a where executions =(select max(executions) from  v$sql) and LAST_ACTIVE_TIME between sysdate-1 and sysdate -1/24 union
select sql_id,'max disk_reads: '||disk_reads value,sql_text from v$sql a where disk_reads =(select max(disk_reads) from  v$sql) and LAST_ACTIVE_TIME between sysdate-1  and sysdate -1/24 union
select sql_id,'max buffer_gets: '||buffer_gets value,sql_text from v$sql a where buffer_gets=(select max(buffer_gets) from  v$sql) and LAST_ACTIVE_TIME between sysdate-1  and sysdate -1/24 union
select sql_id,'max cpu_time/elapsed_time: '||trunc(cpu_time/elapsed_time) value,sql_text from v$sql a where cpu_time/elapsed_time =(select max(cpu_time/elapsed_time) from  v$sql where elapsed_time<>0 and cpu_time<>0) and elapsed_time<>0 and cpu_time<>0 and LAST_ACTIVE_TIME between sysdate-1 and sysdate -1/24 union
select sql_id,'max elapsed_time: '||elapsed_time value,sql_text from v$sql a where elapsed_time=(select max(elapsed_time) from  v$sql) and LAST_ACTIVE_TIME between sysdate-1 and sysdate -1/24 ;
/*
additions for perf check script:

- no of fts from v$sysstat
- v$filestat i/o script
- check for tables with lots of chain_cnt, pointing to migrated/chained rows which is bad for perf. Maybe check as % of total rows.
- sort segment growth monitor
- check for latch contention from v$latch and v$system_event
- check for v$lock locks (my new one..)
-
*/
