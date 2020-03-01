select ses.username, substr(ses.program, 1, 19) command, tra.used_ublk, (tra.used_ublk * 8192)/1024/1024 undo_mb
from v$session ses, v$transaction tra
where ses.saddr = tra.ses_addr
and ses.sid=1739;
