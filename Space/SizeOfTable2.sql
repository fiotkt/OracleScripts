SELECT
owner, table_name, tablespace_name, TRUNC(sum(bytes)/1024/1024) Meg
    FROM
    (SELECT segment_name table_name, owner, bytes, tablespace_name
     FROM dba_segments
     WHERE segment_type = 'TABLE'
     UNION ALL
     SELECT i.table_name, i.owner, s.bytes, s.tablespace_name
     FROM dba_indexes i, dba_segments s
    WHERE s.segment_name = i.index_name
    AND   s.owner = i.owner
    AND   s.segment_type = 'INDEX'
 UNION ALL
    SELECT l.table_name, l.owner, s.bytes, s.tablespace_name
    FROM dba_lobs l, dba_segments s
    WHERE s.segment_name = l.segment_name
    AND   s.owner = l.owner
    AND   s.segment_type = 'LOBSEGMENT'
    UNION ALL
    SELECT l.table_name, l.owner, s.bytes, s.tablespace_name
    FROM dba_lobs l, dba_segments s
    WHERE s.segment_name = l.index_name
    AND   s.owner = l.owner
    AND   s.segment_type = 'LOBINDEX'
UNION ALL
	SELECT l.table_name, l.table_owner, s.bytes, s.tablespace_name
  FROM dba_part_lobs l, dba_segments s
 WHERE s.segment_name = l.lob_name
   AND   s.owner = l.table_owner
   AND   s.segment_type = 'LOB PARTITION')
   WHERE owner in UPPER('ESB_FWK_DATA_LOG')
   GROUP BY table_name, owner, tablespace_name
   ORDER BY SUM(bytes) desc;
