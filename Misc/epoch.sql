Create convert procedure
-------
create or replace FUNCTION QUEST.convert_epoch_to_date (epoch_in IN number) RETURN timestamp IS
  t_date_out timestamp;
BEGIN
  select
    to_timestamp('01/01/1970 00:00:00.000','dd-mm-yyyy hh24:mi:ss.FF3') + NUMTODSINTERVAL(epoch_in/1000,'second')
        INTO t_date_out
  from dual;
  RETURN t_date_out;
EXCEPTION WHEN OTHERS THEN RAISE;
END;
/

create or replace FUNCTION QUEST.convert_ts_to_epoch (ts_in IN timestamp) RETURN number IS
  t_epoch_out number(28);
BEGIN
     select extract(day from (ts_in - timestamp '1970-01-01 00:00:00')) * 86400000
     + extract(hour   from (ts_in - timestamp '1970-01-01 00:00:00')) * 3600000
     + extract(minute from (ts_in - timestamp '1970-01-01 00:00:00')) * 60000
     + extract(second from (ts_in - timestamp '1970-01-01 00:00:00')) * 1000 into t_epoch_out
	 from dual;  
	 RETURN t_epoch_out;
EXCEPTION WHEN OTHERS THEN RAISE;
END;
/

sys@BBAUTHST: select max(TIMESTAMP) ts FROM EPSTR.FTRESSAUDITLOG;

                                    TS
--------------------------------------
                         1409586899089


select QUEST.convert_ts_to_epoch(quest.convert_epoch_to_date(max(TIMESTAMP))) ts FROM EPSTR.FTRESSAUDITLOG
/
  2
                                    TS
--------------------------------------
                         1409586899089
