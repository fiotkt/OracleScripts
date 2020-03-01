select max(sequence#) as  last_applied_log, thread#, dest_id, applied, standby_dest
from v$archived_log
where resetlogs_change#= (select max(resetlogs_change#) FROM V$ARCHIVED_LOG)
and ((STANDBY_DEST='NO' and applied='NO') OR (applied='YES' and STANDBY_DEST='YES'))
group by  thread#,  dest_id, applied, standby_dest
order by thread#;

SELECT name, value, datum_time, time_computed FROM V$DATAGUARD_STATS;
