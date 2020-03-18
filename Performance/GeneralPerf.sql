column sql_text format a170
set long 4000
col message form a100
col object_status form a10
select s.sql_id,s.child_number,s.plan_hash_value,executions,ROWS_PROCESSED,fetches,LOADS,INVALIDATIONS,USERS_EXECUTING,PARSE_CALLS,disk_reads,direct_writes,OBJECT_STATUS,buffer_gets,round
(SHARABLE_MEM/1024,2) "SHARABLE KB",round(PERSISTENT_MEM/1024,2) "PERSISTENT KB",round(RUNTIME_MEM/1024,2) "RUNTIME KB",sorts, s.sql_text from gv$session u, gv$sql s where u.SQL_ADDRESS=s
.ADDRESS and u.sid=&SID and u.inst_id=s.inst_id and u.sql_hash_value=s.hash_value;
--select s.sql_id,s.child_number,s.plan_hash_value,buffer_gets,executions,s.sql_text from gv$session u, gv$sql s where u.SQL_ADDRESS=s.ADDRESS and u.sid=&SID and u.inst_id=s.inst_id;
-- show explain plan
SELECT * FROM table(DBMS_XPLAN.DISPLAY_CURSOR('&SQL_ID'));
/*
also look in (only after a while once awr has run): select * from table(dbms_xplan.display_awr('&SQL_ID','&PLAN_HASH_VALUE'));
also look in gv$sql_plan
also run on each node if it's still not showing
*/
-- show when the sql QEP last changed for this sql_id
@'random scripts/steve_hist_sql_10g.sql'
-- show objects locked by this session
select a.sid,b.name from gv$session a,sys.obj$ b,gv$locked_object c where a.sid=c.session_id and  b.obj#=c.object_id and a.sid=&SID;
-- show current wait event for this session
col event form a35 trun
col "STATE T" form a10 trun
col p1text form a20 trun
col p2text form a20 trun
col p3text form a20 trun
col wait_class form a15 trun
col MINS form 99999
select inst_id,sid,EVENT,SECONDS_IN_WAIT/60 "MINS",STATE "STATE T",p1,p1text,p2,p2text,p3,p3text, wait_class from gv$session_wait where sid=&SID and inst_id=&INST_ID;
/*
We can find the table that it's reading from using: select * from dba_extents where file_id=&p1 and '&p2' between block_id and block_id+blocks;
*/
-- show any longops for this session
select a.inst_id,a.SID,a.SERIAL#,a.OPNAME,a.ELAPSED_SECONDS,a.TIME_REMAINING,b.SQL_ID,b.sql_text,a.MESSAGE from gv$session_longops a,gv$sql b where a.sql_id=b.sql_id and time_remaining>0
and sid=&SID;
-- show top wait events for this session since it connected
select sid,event,total_waits,round(time_waited/100/60,2) "TIME_WAITED (M)",wait_class from  gv$session_event where sid=&SID and inst_id=&INST_ID order by total_waits desc;
-- show last 10 wait events for this session
col sid form 9999
select sid,inst_id,event,p1text,p1,p2text,p2,p3text,p3,wait_time,wait_count from gV$SESSION_WAIT_HISTORY where sid=&SID;
-- show overall waits for session:
select * from gv$session_wait_class where sid=&SID;
-- show redo usage for this session
column username format a15
column module format a32
column sid format 99999
column status form a10
select s.sid, s.username, s.status, s.module, w.value, s.logon_time from gv$session s, gv$sesstat w, gv$statname n where s.sid = w.sid and w.inst_id = n.inst_id and w.inst_id = s.inst_id
and w.inst_id=&INST_ID and w.statistic# = n.statistic# and s.username is not null and n.name like 'redo size' and s.sid=&SID order by w.value desc;
-- show undo usage for this session
select s.sid, s.username, r.name "RB Segment name", t.start_time, t.used_ublk "Undo blocks", round(t.used_ublk*8192/1024,2) KB,t.used_urec "Undo recs" from v$session s, v$transaction t, v
$rollname r where t.addr = s.taddr and r.usn=t.xidusn and s.sid=&SID;
-- show temp usage for this session
SELECT a.username, a.sid, a.serial#, a.osuser, b.tablespace, b.blocks, c.sql_text FROM v$session a, v$tempseg_usage b, v$sqlarea c  WHERE a.saddr = b.session_addr AND c.address= a.sql_add
ress AND c.hash_value = a.sql_hash_value and a.sid=&SID ORDER BY b.tablespace, b.blocks;
