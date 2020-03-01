set pages 0 feedback off echo off
--DROP
drop profile unlimited;
drop table users_tbc;


drop role fact_read;
drop role fact_read_write;

--END DROP  
CREATE PROFILE unlimited LIMIT
  SESSIONS_PER_USER UNLIMITED
  CPU_PER_SESSION UNLIMITED
  CPU_PER_CALL UNLIMITED
  CONNECT_TIME UNLIMITED
  IDLE_TIME UNLIMITED
  LOGICAL_READS_PER_SESSION UNLIMITED
  LOGICAL_READS_PER_CALL UNLIMITED
  COMPOSITE_LIMIT UNLIMITED
  PRIVATE_SGA UNLIMITED
  FAILED_LOGIN_ATTEMPTS unlimited
  PASSWORD_LIFE_TIME UNLIMITED
  PASSWORD_REUSE_TIME unlimited
  PASSWORD_REUSE_MAX unlimited
  PASSWORD_LOCK_TIME UNLIMITED  
  PASSWORD_GRACE_TIME unlimited
  PASSWORD_VERIFY_FUNCTION null;

create role fact_read_write;

create role fact_read;

create table users_tbc(username varchar2(30));

insert into users_tbc(username) values (upper('LNunaa'));
insert into users_tbc(username) values (upper('x03021'));
insert into users_tbc(username) values (upper('x02819'));
insert into users_tbc(username) values (upper('UPF895'));
insert into users_tbc(username) values (upper('ndesai'));
insert into users_tbc(username) values (upper('UPJ733'));
insert into users_tbc(username) values (upper('x07814'));
commit;

spool create_users_ddl.sql
select 'set pages 0 feedback on echo on' from dual;

select 'drop user '||username||' cascade;' 
from users_tbc;


select 'create user '||username||' identified by '||lower(username)||' default tablespace users password expire profile unlimited;' 
from users_tbc;

select 'grant create session to '||username||';'
from users_tbc;

select 'alter user '||username||' profile secure_user;'||chr(10)||
'alter user '||username||' quota unlimited on fact;'
from users_tbc;




select 'grant select,update,delete,insert on '||owner||'.'||table_name||' to fact_read_write;'
from dba_tables 
where owner='FACT';

select 'create synonym '||b.username||'.'||a.table_name||' for '||a.owner||'.'||a.table_name||';'
from dba_tables a, users_tbc b
where a.owner='FACT' order by b.username;

--For any environment other than dev

select 'grant select on '||owner||'.'||table_name||' to fact_read;'
from dba_tables 
where owner='FACT';

--For Dev
select 'grant '||decode(database_name,'DGP11','fact_read_write','fact_read')||' to '||username||';' from users_tbc, v$database ;

select 'drop profile unlimited;' from dual;

select 'drop table users_tbc;' from dual;

spool off
@create_users_ddl.sql
