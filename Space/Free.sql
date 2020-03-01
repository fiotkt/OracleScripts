accept sortby default '1' prompt 'Order by 1-tablespace 2-percent used [1] : '
set lines 200

col nam format a29 heading 'TABLESPACE'
col typ format a5 heading 'TEMP?' noprint
col man format a6 heading 'EXTENT|MGMT' noprint
col alt format a9 heading 'ALLOC|TYPE' noprint
col csz format 999,999,990 heading 'CURR SIZE'
col msz format 999,999,990 heading 'MAX SIZE'
col usd format 999,999,990 heading 'USED|(MB)'
col cfr format 999,999,990 heading 'CURR FREE'
col mfr format 999,999,990 heading 'MAX FREE'
col cpu format 990.0 heading 'CURR|PCT|USED'
col mpu format 990.0 heading 'MAX|PCT|USED'
col fsx format 999,999 heading 'FREE SPACE'

break on report skip 1
compute sum of csz msz usd cfr mfr fs on report

ttitle 'Database = &sys_dbn (&sys_ver)' skip 'Tablespace Summary Report (MB)' skip 2



select t.tablespace_name nam
,decode(t.contents,'TEMPORARY','TEMP',NULL) typ
,decode(t.extent_management,'DICTIONARY','DICT',t.extent_management) man
,t.allocation_type alt
,f.csz csz
,f.msz msz
,nvl(e.usd,0) usd
,f.csz-nvl(e.usd,0) cfr
,f.msz-nvl(e.usd,0) mfr
,fsp.fs fsx
,nvl(e.usd,0)*100/f.csz cpu
,nvl(e.usd,0)*100/f.msz mpu
from ( select tablespace_name tbs
,sum(bytes)/1024/1024 usd
from dba_segments
group by tablespace_name
union
select tablespace_name tbs
,sum(bytes_used)/1024/1024 usd
from v$temp_space_header
group by tablespace_name ) e
,( select tablespace_name tbs
,sum(bytes)/1024/1024 csz
,sum(decode(maxbytes,0,bytes,maxbytes))/1024/1024 msz
from dba_data_files
group by tablespace_name
union
select tablespace_name tbs
,sum(bytes)/1024/1024 csz
,sum(decode(maxbytes,0,bytes,maxbytes))/1024/1024 msz
from dba_temp_files
group by tablespace_name ) f
,dba_tablespaces t,
(select tablespace_name tbs,
sum(bytes)/1024/1024 fs
from dba_free_space
group by tablespace_name
union
select tablespace_name tbs
,sum(bytes_free)/1024/1024 fs
from v$temp_space_header
group by tablespace_name ) fsp
where f.tbs = t.tablespace_name
and e.tbs(+) = t.tablespace_name
and fsp.tbs(+) = t.tablespace_name
order by decode('&sortby','1',nam,to_char(mpu,'000.0'))
,decode('&sortby','1','1',nam)
/
