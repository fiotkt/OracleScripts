define gname ='idle'
column global_name new_value gname

SELECT
case when to_number(substr(version,1,instr(version,'.',1)-1)) >11 then
substr(UPPER(SYS_CONTEXT('USERENV','SID')
||' U:'||SYS_CONTEXT('USERENV','CURRENT_USER')
||'@'||SYS_CONTEXT('USERENV','CON_NAME')
|| ':' ||
SYS_CONTEXT('USERENV','SERVER_HOST')),1,43)||' SQL> '
else
substr(UPPER(SYS_CONTEXT('USERENV','SID')
||' U:'||SYS_CONTEXT('USERENV','CURRENT_USER')
||'@'||SYS_CONTEXT('USERENV','DB_NAME')
|| ':' ||SYS_CONTEXT('USERENV','SERVER_HOST')),1,43) ||' SQL> '
end as global_name
FROM v$instance;

set sqlprompt '&gname'
