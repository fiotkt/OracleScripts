select current_obj#, count(1) from
(select
      sample_time
    , sql_id
    , event
    , current_obj#
    --, sum (cnt)
    from  gv$active_session_history
       where sample_time between  to_date ('09-JUL-2014 18:15:00','DD-MON-YYYY HH24:MI:SS') and
        to_date ('09-JUL-2014 21:30:00','DD-MON-YYYY HH24:MI:SS')
   and event='gc buffer busy release'
       group by  sample_time,  sql_id, event, current_obj#
      order by sample_time)
      group by current_obj# order by count(1) asc nulls last
/


col inst_id format 9
col owner format a30
col object_type format a30
col object_name format a30
with ash_gc as
(select inst_id, event, current_obj#, count(1) cnt
from gv$active_session_history
where event=lower('&event')
group by inst_id, event, current_obj#
having count(1) > &threshold)
select * from 
(select inst_id, nvl(owner,'Non-Existent') owner,
nvl(object_name,'Non-Existent') object_name,
nvl(object_name,'Non-Existent') object_type,
cnt
from ash_gc a, dba_objects o
where (a.current_obj#=o.object_id (+))
and a.current_obj# >= 1
union
select inst_id,'','','Undo Header/Undo block', cnt
from ash_gc a where a.current_obj#=0
union
select inst_id, '', '', 'Undo Block', cnt
from ash_gc a
where a.current_obj#=-1
)
order by cnt DESC
/
