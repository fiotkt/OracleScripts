begin
dbms_metadata.set_transform_param( DBMS_METADATA.SESSION_TRANSFORM, 'CONSTRAINTS_AS_ALTER', true );
dbms_metadata.set_transform_param( DBMS_METADATA.SESSION_TRANSFORM, 'STORAGE', true );
dbms_metadata.set_transform_param( DBMS_METADATA.SESSION_TRANSFORM, 'CONSTRAINTS', true );
dbms_metadata.set_transform_param( DBMS_METADATA.SESSION_TRANSFORM, 'REF_CONSTRAINTS', true );
dbms_metadata.set_transform_param( DBMS_METADATA.SESSION_TRANSFORM, 'SQLTERMINATOR', TRUE );
end;
/

set pagesize 0
set long 1000000
select dbms_metadata.get_ddl('TABLE',''||table_name||'','LRMSTAGING') from dba_tables where table_name in 
('ALM_LIQUIDITY',
'SPOT_RATES',
'TREASURY_LIQUIDITY')
/

select dbms_metadata.get_ddl('INDEX',''||index_name||'','LRMSTAGING') from dba_indexes where table_name in (
'ALM_LIQUIDITY',
'SPOT_RATES',
'TREASURY_LIQUIDITY')
/
