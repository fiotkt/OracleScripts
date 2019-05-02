set termout off
col name new_value switch_container
select name from  V$CONTAINERS where con_id=3;
alter session set container=&switch_container;
@set_prompt
set termout on
