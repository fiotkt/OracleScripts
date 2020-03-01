select distinct(case when a.date_ IS NULL THEN 'FAIL - MISSING BACKUPS FROM THE PAST SEVEN DAYS' ELSE '' END ) as Missing_backups
from 
   (select distinct(trunc(start_time)) date_ 
      from V$RMAN_BACKUP_JOB_DETAILS 
	 where trunc(start_time) > trunc(sysdate-8) 
       --IGNORE TODAY, ALSO MINUS ROWNUM (as ROWNUM STARTS AT 1) WILL MEAN THE BELOW FROM DUAL QUERY ALSO IGNORES TODAY
       and trunc(start_time)!=trunc(sysdate)) a,
(select trunc(sysdate) - rownum date_ from dual connect by level<=7) b
where b.date_=a.date_(+)
/
