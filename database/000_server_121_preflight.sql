-- Read-only MySQL preflight for server 121.
-- This script changes no schema, table, account, or global variable.

SELECT VERSION() AS mysql_version;

SELECT
  @@hostname AS hostname,
  @@port AS port,
  @@version_comment AS version_comment,
  @@character_set_server AS character_set_server,
  @@collation_server AS collation_server,
  @@time_zone AS session_time_zone,
  @@system_time_zone AS system_time_zone,
  @@sql_mode AS sql_mode,
  @@lower_case_table_names AS lower_case_table_names,
  @@default_storage_engine AS default_storage_engine,
  @@transaction_isolation AS transaction_isolation,
  @@binlog_format AS binlog_format;

SHOW VARIABLES WHERE Variable_name IN (
  'innodb_file_per_table',
  'innodb_flush_log_at_trx_commit',
  'log_bin',
  'sync_binlog',
  'max_connections',
  'max_allowed_packet'
);

SELECT
  SCHEMA_NAME,
  DEFAULT_CHARACTER_SET_NAME,
  DEFAULT_COLLATION_NAME
FROM information_schema.SCHEMATA
ORDER BY SCHEMA_NAME;

