--P
col display_value format a120
col name format a35
col inst_id format 9
select inst_id, name, display_value
  from gv$parameter2
 where upper(name) like upper('%&1%')
order by name, inst_id
/
--P2
col display_value format a120
col name format a35
col inst_id format 9
select inst_id, name, display_value
  from gv$parameter2
 where upper(name) like upper('%&1%') and name like '%\_&2' escape '\'
order by name, inst_id
/
