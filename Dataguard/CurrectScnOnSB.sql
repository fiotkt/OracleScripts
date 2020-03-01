SELECT name, value, datum_time, time_computed FROM V$DATAGUARD_STATS;

select LAST_CHANGE#, STATUS from V$STANDBY_LOG
/

This should increment in max avail mode even if not switching logfiles
