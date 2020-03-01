set pages 200 lines 230
col owner format a20
col parent_table format a30
col child_table format a30
col column_name format a35
select  c1.owner, c1.table_name parent_table, c1.constraint_name, c2.owner, c2.table_name child_table, c2.column_name
from dba_constraints c1
JOIN dba_cons_columns c2
ON c1.R_CONSTRAINT_NAME=C2.CONSTRAINT_NAME and c1.r_owner=c2.owner
where C1.constraint_type = 'R'
and c1.owner not in ('SYS','SYSTEM','SYSMAN','OLAPSYS','CTXSYS','DBSNMP','SCOTT')
and c1.constraint_name='FK_ISBN'
order by c1.owner, c1.table_name, c1.constraint_name, c2.position;
