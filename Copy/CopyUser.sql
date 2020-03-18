set head off
set pages 0
set long 9999999
spool user_script.sql

exec dbms_metadata.set_transform_param(dbms_metadata.SESSION_TRANSFORM,'SQLTERMINATOR',TRUE);

select dbms_metadata.get_ddl ('USER', username)
from dba_users d where username='MWWORKFLOW'
UNION ALL
select (case
        when ((select count(*)
               from   dba_ts_quotas
               where  username = d.username) > 0)
        then  dbms_metadata.get_granted_ddl( 'TABLESPACE_QUOTA', username)
        else  to_clob ('   -- Note: No TS Quotas found!')
        end ) from dba_users d where username='MWWORKFLOW'
UNION ALL
select (case
        when ((select count(*)
               from   dba_role_privs
               where  grantee = d.username) > 0)
        then  dbms_metadata.get_granted_ddl ('ROLE_GRANT', username)
        else  to_clob ('   -- Note: No granted Roles found!')
        end ) from dba_users d where username='MWWORKFLOW'
UNION ALL
select (case
        when ((select count(*)
               from   dba_sys_privs
               where  grantee = d.username) > 0)
        then  dbms_metadata.get_granted_ddl ('SYSTEM_GRANT', username)
        else  to_clob ('   -- Note: No System Privileges found!')
        end ) from dba_users d where username='MWWORKFLOW'
UNION ALL
select (case
        when ((select count(*)
               from   dba_tab_privs
               where  grantee = d.username) > 0)
        then  dbms_metadata.get_granted_ddl ('OBJECT_GRANT', username)
        else  to_clob ('   -- Note: No Object Privileges found!')
        end ) from dba_users d where username='MWWORKFLOW';

spool off
