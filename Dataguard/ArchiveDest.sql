select     ds.dest_id id
,     ad.status
,     ds.database_mode db_mode
,     ad.archiver type
,     ds.recovery_mode
,     ds.protection_mode
,     ds.standby_logfile_count "SRLs"
,     ds.standby_logfile_active active
,     ds.archived_seq#
from     v$archive_dest_status     ds
,     v$archive_dest          ad
where     ds.dest_id = ad.dest_id
and     ad.status != 'INACTIVE'
order by
     ds.dest_id
/
