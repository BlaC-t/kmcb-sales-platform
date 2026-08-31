-- Sales Platform product workbook staging and field-level diff workflow.
-- Target: the selected Sales Platform schema on MySQL 8.0.16+.
-- This migration creates staging structures only. It does not import workbooks,
-- mutate published equipment specifications, or create BMS menu/permission data.

CREATE TABLE gov_mapping_profile (
  id BINARY(16) PRIMARY KEY,
  profile_code VARCHAR(120) NOT NULL,
  version_no INTEGER NOT NULL CHECK (version_no > 0),
  status VARCHAR(24) NOT NULL DEFAULT 'DRAFT'
    CHECK (status IN ('DRAFT', 'PUBLISHED', 'SUPERSEDED', 'DISABLED')),
  workbook_family VARCHAR(255) NOT NULL,
  product_kind_code VARCHAR(120),
  header_signature CHAR(64) NOT NULL,
  column_mappings JSON NOT NULL,
  inheritance_rules JSON NOT NULL DEFAULT (JSON_OBJECT()),
  normalization_rules JSON NOT NULL DEFAULT (JSON_OBJECT()),
  published_profile_code VARCHAR(120)
    GENERATED ALWAYS AS (CASE WHEN status = 'PUBLISHED' THEN profile_code ELSE NULL END) STORED,
  created_by BINARY(16) NOT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  published_by BINARY(16),
  published_at DATETIME(6),
  UNIQUE (profile_code, version_no),
  UNIQUE KEY uq_gov_mapping_profile_published (published_profile_code),
  KEY idx_gov_mapping_profile_header (header_signature),
  CONSTRAINT fk_gov_mapping_profile_created_by FOREIGN KEY (created_by) REFERENCES identity_external_subject(id),
  CONSTRAINT fk_gov_mapping_profile_published_by FOREIGN KEY (published_by) REFERENCES identity_external_subject(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE gov_import_batch (
  id BINARY(16) PRIMARY KEY,
  source_document_id BINARY(16) NOT NULL,
  file_checksum CHAR(64) NOT NULL,
  parser_version VARCHAR(80) NOT NULL,
  mapping_profile_id BINARY(16),
  status VARCHAR(32) NOT NULL DEFAULT 'UPLOADED'
    CHECK (status IN ('UPLOADED', 'DISCOVERING', 'MAPPING_REQUIRED', 'EXTRACTING',
                      'DIFF_READY', 'REVIEW_REQUIRED', 'APPROVED', 'PUBLISHED', 'FAILED', 'CANCELLED')),
  sheet_count INTEGER UNSIGNED NOT NULL DEFAULT 0,
  region_count INTEGER UNSIGNED NOT NULL DEFAULT 0,
  record_count INTEGER UNSIGNED NOT NULL DEFAULT 0,
  new_count INTEGER UNSIGNED NOT NULL DEFAULT 0,
  update_count INTEGER UNSIGNED NOT NULL DEFAULT 0,
  unchanged_count INTEGER UNSIGNED NOT NULL DEFAULT 0,
  conflict_count INTEGER UNSIGNED NOT NULL DEFAULT 0,
  invalid_count INTEGER UNSIGNED NOT NULL DEFAULT 0,
  manifest JSON NOT NULL DEFAULT (JSON_OBJECT()),
  failure_summary JSON NOT NULL DEFAULT (JSON_OBJECT()),
  row_version BIGINT UNSIGNED NOT NULL DEFAULT 1,
  created_by BINARY(16) NOT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  submitted_at DATETIME(6),
  approved_at DATETIME(6),
  published_at DATETIME(6),
  UNIQUE (source_document_id, parser_version),
  KEY idx_gov_import_batch_status_updated (status, updated_at),
  CONSTRAINT fk_gov_import_batch_document FOREIGN KEY (source_document_id) REFERENCES gov_source_document(id),
  CONSTRAINT fk_gov_import_batch_profile FOREIGN KEY (mapping_profile_id) REFERENCES gov_mapping_profile(id),
  CONSTRAINT fk_gov_import_batch_created_by FOREIGN KEY (created_by) REFERENCES identity_external_subject(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE gov_import_sheet (
  id BINARY(16) PRIMARY KEY,
  import_batch_id BINARY(16) NOT NULL,
  sheet_index INTEGER UNSIGNED NOT NULL,
  sheet_name VARCHAR(255) NOT NULL,
  used_range VARCHAR(64),
  hidden TINYINT(1) NOT NULL DEFAULT false,
  structure_summary JSON NOT NULL DEFAULT (JSON_OBJECT()),
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE (import_batch_id, sheet_index),
  UNIQUE (import_batch_id, sheet_name),
  CONSTRAINT fk_gov_import_sheet_batch FOREIGN KEY (import_batch_id) REFERENCES gov_import_batch(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE gov_import_region (
  id BINARY(16) PRIMARY KEY,
  import_sheet_id BINARY(16) NOT NULL,
  region_index INTEGER UNSIGNED NOT NULL,
  source_range VARCHAR(64) NOT NULL,
  section_name VARCHAR(255),
  header_row_start INTEGER UNSIGNED NOT NULL,
  header_row_end INTEGER UNSIGNED NOT NULL,
  data_row_start INTEGER UNSIGNED,
  data_row_end INTEGER UNSIGNED,
  product_kind_code VARCHAR(120),
  mapping_profile_id BINARY(16),
  mapping_confidence DECIMAL(6,5)
    CHECK (mapping_confidence IS NULL OR mapping_confidence BETWEEN 0 AND 1),
  original_columns JSON NOT NULL,
  status VARCHAR(24) NOT NULL DEFAULT 'DISCOVERED'
    CHECK (status IN ('DISCOVERED', 'MAPPING_REQUIRED', 'MAPPED', 'EXTRACTED', 'INVALID')),
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  UNIQUE (import_sheet_id, region_index),
  CONSTRAINT fk_gov_import_region_sheet FOREIGN KEY (import_sheet_id) REFERENCES gov_import_sheet(id) ON DELETE CASCADE,
  CONSTRAINT fk_gov_import_region_profile FOREIGN KEY (mapping_profile_id) REFERENCES gov_mapping_profile(id),
  CHECK (header_row_start <= header_row_end),
  CHECK (data_row_start IS NULL OR data_row_end IS NULL OR data_row_start <= data_row_end)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE gov_import_record (
  id BINARY(16) PRIMARY KEY,
  import_region_id BINARY(16) NOT NULL,
  source_row INTEGER UNSIGNED NOT NULL,
  row_checksum CHAR(64) NOT NULL,
  identity_key VARCHAR(512),
  model_code VARCHAR(255),
  drawing_no VARCHAR(255),
  action VARCHAR(32) NOT NULL DEFAULT 'UNCLASSIFIED'
    CHECK (action IN ('NEW_MODEL', 'NEW_CONFIGURATION', 'UPDATE', 'FORMAT_ONLY',
                      'UNCHANGED', 'CONFLICT', 'INVALID', 'UNCLASSIFIED')),
  raw_payload JSON NOT NULL,
  display_payload JSON NOT NULL,
  normalized_payload JSON NOT NULL,
  current_equipment_model_id BINARY(16),
  current_spec_version_id BINARY(16),
  match_confidence DECIMAL(6,5)
    CHECK (match_confidence IS NULL OR match_confidence BETWEEN 0 AND 1),
  decision VARCHAR(24) NOT NULL DEFAULT 'PENDING'
    CHECK (decision IN ('PENDING', 'ACCEPTED', 'REJECTED', 'MANUAL_REVIEW')),
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  UNIQUE (import_region_id, source_row),
  KEY idx_gov_import_record_identity (identity_key(191)),
  KEY idx_gov_import_record_action (action, decision),
  CONSTRAINT fk_gov_import_record_region FOREIGN KEY (import_region_id) REFERENCES gov_import_region(id) ON DELETE CASCADE,
  CONSTRAINT fk_gov_import_record_model FOREIGN KEY (current_equipment_model_id) REFERENCES equipment_equipment_model(id),
  CONSTRAINT fk_gov_import_record_spec FOREIGN KEY (current_spec_version_id) REFERENCES equipment_equipment_spec_version(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE gov_import_record_diff (
  id BINARY(16) PRIMARY KEY,
  import_record_id BINARY(16) NOT NULL,
  field_key VARCHAR(160) NOT NULL,
  original_column_title VARCHAR(255) NOT NULL,
  source_cell VARCHAR(32),
  original_text TEXT,
  old_value JSON,
  proposed_value JSON,
  original_unit VARCHAR(80),
  normalized_unit VARCHAR(80),
  change_type VARCHAR(32) NOT NULL
    CHECK (change_type IN ('NEW_VALUE', 'UPDATED', 'CLEARED', 'FORMAT_ONLY',
                           'COLUMN_REGISTERED', 'COLUMN_TITLE_UPDATED', 'CONFLICT', 'NO_CHANGE')),
  validation_result JSON NOT NULL DEFAULT (JSON_OBJECT()),
  decision VARCHAR(24) NOT NULL DEFAULT 'PENDING'
    CHECK (decision IN ('PENDING', 'ACCEPTED', 'REJECTED', 'MANUAL_REVIEW')),
  decided_by BINARY(16),
  decided_at DATETIME(6),
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE (import_record_id, field_key),
  KEY idx_gov_import_record_diff_decision (decision, change_type),
  CONSTRAINT fk_gov_import_record_diff_record FOREIGN KEY (import_record_id) REFERENCES gov_import_record(id) ON DELETE CASCADE,
  CONSTRAINT fk_gov_import_record_diff_decided_by FOREIGN KEY (decided_by) REFERENCES identity_external_subject(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE gov_import_issue (
  id BINARY(16) PRIMARY KEY,
  import_batch_id BINARY(16) NOT NULL,
  import_sheet_id BINARY(16),
  import_region_id BINARY(16),
  import_record_id BINARY(16),
  severity VARCHAR(16) NOT NULL CHECK (severity IN ('INFO', 'WARNING', 'ERROR', 'BLOCKER')),
  issue_code VARCHAR(120) NOT NULL,
  issue_message VARCHAR(1000) NOT NULL,
  source_locator JSON NOT NULL DEFAULT (JSON_OBJECT()),
  status VARCHAR(24) NOT NULL DEFAULT 'OPEN'
    CHECK (status IN ('OPEN', 'ACKNOWLEDGED', 'RESOLVED', 'WAIVED')),
  assigned_to BINARY(16),
  resolved_by BINARY(16),
  resolution_note VARCHAR(1000),
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  resolved_at DATETIME(6),
  KEY idx_gov_import_issue_batch_status (import_batch_id, status, severity),
  CONSTRAINT fk_gov_import_issue_batch FOREIGN KEY (import_batch_id) REFERENCES gov_import_batch(id) ON DELETE CASCADE,
  CONSTRAINT fk_gov_import_issue_sheet FOREIGN KEY (import_sheet_id) REFERENCES gov_import_sheet(id) ON DELETE SET NULL,
  CONSTRAINT fk_gov_import_issue_region FOREIGN KEY (import_region_id) REFERENCES gov_import_region(id) ON DELETE SET NULL,
  CONSTRAINT fk_gov_import_issue_record FOREIGN KEY (import_record_id) REFERENCES gov_import_record(id) ON DELETE SET NULL,
  CONSTRAINT fk_gov_import_issue_assigned_to FOREIGN KEY (assigned_to) REFERENCES identity_external_subject(id),
  CONSTRAINT fk_gov_import_issue_resolved_by FOREIGN KEY (resolved_by) REFERENCES identity_external_subject(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
