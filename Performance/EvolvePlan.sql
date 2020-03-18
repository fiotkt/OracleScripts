var t_lee clob
exec :t_lee := dbms_spm.EVOLVE_SQL_PLAN_BASELINE('SQL_9d2bb7a533fa1432','SQL_PLAN_9uaxrnntzn51k5bea8246')
print t_lee
