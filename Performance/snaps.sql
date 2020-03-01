EXEC dbms_workload_repository.modify_snapshot_settings(interval=>15);
select extract( day from snap_interval) *24*60+extract( hour from snap_interval) *60+extract( minute from snap_interval ) snapshot_interval,
extract( day from retention) *24*60+extract( hour from retention) *60+extract( minute from retention ) retention_in_mins,
(extract( day from retention) *24*60+extract( hour from retention) *60+extract( minute from retention ))/(60*24) retention_in_days,
topnsql
from dba_hist_wr_control;
