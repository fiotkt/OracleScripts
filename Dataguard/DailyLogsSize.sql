set pages 200 lines 190
select dest_id, sum((blocks*block_size)/1024/1024/1024) as archive_log_MB, trunc(first_time) as date_
 from v$archived_log group by dest_id, trunc(first_time) order by trunc(first_time)
/
