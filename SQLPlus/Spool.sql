column append_vals new_value append_vals
set termout off
select SYS_CONTEXT ('USERENV', 'DB_NAME') ||'_'||to_char(sysdate,'DDMonYYYY_HH24:MI:SS') as append_vals from dual;
set termout on
spool script_&append_vals..log
select 1 from dual;
spool off
