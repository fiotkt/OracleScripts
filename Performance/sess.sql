col machine format a30
col osuser format a10
col last_call_et1 format a30
select username, machine, osuser,terminal,
case
when last_call_et/60 < 1 then -- Less than a min
       last_call_et||' Secs'
when last_call_et/3600 < 1  then --Less then an Hour
       floor(last_call_et/60)||' Mins ' ||mod(last_call_et,60)||' Secs'
when last_call_et/86400<1 then -- Less than a Day
       floor(last_call_et/60/60)||' Hours '||floor(mod(last_call_et,3600)/60)||' Mins '--||mod(last_call_et,60)||' S'
else -- Over a Day
       floor(last_call_et/84600)||' Days '|| floor(mod(last_call_et,84600)/3600)||' Hours '--||floor(mod(last_call_et,3600)/60)||' M '||mod(last_call_et,60)||' S'
end as last_call_et1, status, sql_id, prev_sql_id, sid, serial#
from v$session
where nvl(username,'SYS') not in ('SYS','SYSTEM','DBSNMP','HP_DBSPI') and sid != (SELECT SYS_CONTEXT('USERENV','SID') from dual)
order by status, last_call_et;


col machine format a30
col osuser format a10
col last_call_et1 format a30
select username, machine, osuser,terminal,
case
when last_call_et/60 < 1 then -- Less than a min
       last_call_et||' Secs'
when last_call_et/3600 < 1  then --Less then an Hour
       floor(last_call_et/60)||' Mins ' ||mod(last_call_et,60)||' Secs'
when last_call_et/86400<1 then -- Less than a Day
       floor(last_call_et/60/60)||' Hours '||floor(mod(last_call_et,3600)/60)||' Mins '--||mod(last_call_et,60)||' S'
else -- Over a Day
       floor(last_call_et/84600)||' Days '|| floor(mod(last_call_et,84600)/3600)||' Hours '--||floor(mod(last_call_et,3600)/60)||' M '||mod(last_call_et,60)||' S'
end as last_call_et1, status, sql_id, prev_sql_id, sid, serial#
from v$session
where nvl(username,'SYS') not in ('SYS','SYSTEM','DBSNMP','HP_DBSPI') and sid != (SELECT SYS_CONTEXT('USERENV','SID') from dual)
order by status, last_call_et;
