COLUMN recovery_file_dest FORMAT a30                  HEADING 'Recovery File Dest'
COLUMN space_limit_gb     FORMAT 9,999.99   HEADING 'Space Limit GB'
COLUMN space_used_gb      FORMAT 9,999.99   HEADING 'Space Used GB'
COLUMN space_used_pct     FORMAT 999.99               HEADING '% Used'
COLUMN space_reclaimable  FORMAT 99,999,999,999,999   HEADING 'Space Reclaimable'
COLUMN pct_reclaimable    FORMAT 999.99               HEADING '% Reclaimable'
COLUMN number_of_files    FORMAT 999,999              HEADING 'Number of Files'

SELECT
    f.name                                              recovery_file_dest
  , round(f.space_limit/1024/1024/1024,2)               space_limit_gb
  , round(f.space_used/1024/1024/1024,2)                space_used_gb
  , ROUND((f.space_used / f.space_limit)*100, 2)        space_used_pct
  , f.space_reclaimable                                 space_reclaimable
  , ROUND((f.space_reclaimable / f.space_limit)*100, 2) pct_reclaimable
  , f.number_of_files                                   number_of_files
FROM
    v$recovery_file_dest f
ORDER BY
    f.name;
