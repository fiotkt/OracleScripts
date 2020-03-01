set pages 200 lines 190
col name format a50
col STORAGE_SIZE format 999,999,999,999
alter session set nls_date_format='DD-MON-YYYY HH24:MI:SS';
select * 
from V$FLASHBACK_DATABASE_LOGFILE 
order by first_time desc
