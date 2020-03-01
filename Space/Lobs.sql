PROMPT Shows what tablespaces the LOBs for ESB_FWK_AUDIT are located and how much space is being used
col column_name format a30
select a.owner, a.table_name, a.column_name, b.tablespace_name, sum(b.bytes/1024/1024) as "MB_Used"
  from dba_lobs a, dba_segments b
 where a.segment_name = b.segment_name
   and a.owner = b.owner
   and a.table_name='ESB_FWK_AUDIT'
 group by a.owner, a.table_name, a.column_name, b.tablespace_name
 order by a.owner, a.table_name, a.column_name, b.tablespace_name;
