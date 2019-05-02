col ddl format a170 wrap
set long 90000  feedback off echo off verify off
col owner new_val new_owner
col partitioned heading "P/T"

desc &1
select owner, table_name, partitioned, num_rows, last_analyzed, degree  from dba_tables where table_name=upper('&1');

select dbms_metadata.get_ddl('TABLE',upper('&1'), '&new_owner') as ddl from dual;

select table_owner, table_name, owner, index_name, degree,  num_rows, last_analyzed  from dba_indexes where table_owner='&new_owner' and table_name=upper('&1');

select dbms_metadata.get_ddl('INDEX',index_name,owner) as ddl from dba_indexes where table_owner='&new_owner' and table_name=upper('&1');

break on index_name skip page
select table_owner, table_name, index_owner, index_name, column_name from dba_ind_columns where table_owner='&new_owner' and table_name=upper('&1');

