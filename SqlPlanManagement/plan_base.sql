alter session set nls_timestamp_format = 'DD-MON-YYYY HH24:MI:SS';
set long 90000
col SQL_HANDLE format a30
col PLAN_NAME  format a30
col creator format a10
col PARSING_SCHEMA_NAME format a10
col CREATED format a10 newline
col LAST_EXECUTED format a20
col CREATED format a20
col LAST_VERIFIED format a20
col VERSION format a10
col LAST_MODIFIED format a20
col enabled format a8 newline
col accepted format a8
col FIXED format a5
col REPRODUCED format a10
col AUTOPURGE format a9
col ADAPTIVE format a8
col SQL_TEXT newline
col OPTIMIZER_COST newline
break on signature skip page
select
to_char(SIGNATURE) as SIGNATURE,
SQL_HANDLE,
PLAN_NAME,
CREATOR,
ORIGIN,
PARSING_SCHEMA_NAME,
--DESCRIPTION,
VERSION,
CREATED,
LAST_MODIFIED,
LAST_EXECUTED,
LAST_VERIFIED,
ENABLED,
ACCEPTED ,
FIXED,
REPRODUCED,
AUTOPURGE,
ADAPTIVE,
OPTIMIZER_COST,
--MODULE,
--ACTION,
EXECUTIONS,
ELAPSED_TIME,
CPU_TIME,
BUFFER_GETS,
DISK_READS,
DIRECT_WRITES,
ROWS_PROCESSED,
FETCHES,
--END_OF_FETCH_COUNT,
SQL_TEXT
from DBA_SQL_PLAN_BASELINES order by signature;

clear breaks
