select MAX_MB - MB_USED + MB_FREE as total_amount_free, MB_FREE as amount_free, a.tablespace_name tbs 
from 
(select floor(sum(bytes)/1024/1024) MB_USED,
floor(sum(decode(MAXBYTES,0,bytes,MAXBYTES)/1024/1024)) MAX_MB,
tablespace_name
from dba_data_files
group by tablespace_name) a,
(select  floor(sum(bytes)/1024/1024) MB_FREE, tablespace_name from dba_free_space group by tablespace_name) b
where a.tablespace_name=b.tablespace_name;
