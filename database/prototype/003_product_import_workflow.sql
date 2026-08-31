-- Sales Platform 产品 Excel 增量导入与动态列结构
-- 目标：192.168.9.121 / kj_sale_platform
-- 本脚本只创建导入工作流结构，不导入或修改任何产品参数。

SET NAMES utf8mb4;
USE kj_sale_platform;

CREATE TABLE IF NOT EXISTS sp_product_import_batch (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  source_id BIGINT UNSIGNED NOT NULL,
  file_name VARCHAR(255) NOT NULL,
  file_sha256 CHAR(64) NOT NULL,
  catalog_fingerprint CHAR(64) NOT NULL,
  sheet_count INT UNSIGNED NOT NULL DEFAULT 0,
  model_count INT UNSIGNED NOT NULL DEFAULT 0,
  added_count INT UNSIGNED NOT NULL DEFAULT 0,
  updated_count INT UNSIGNED NOT NULL DEFAULT 0,
  unchanged_count INT UNSIGNED NOT NULL DEFAULT 0,
  conflict_count INT UNSIGNED NOT NULL DEFAULT 0,
  accepted_count INT UNSIGNED NOT NULL DEFAULT 0,
  changed_field_count INT UNSIGNED NOT NULL DEFAULT 0,
  status VARCHAR(32) NOT NULL DEFAULT 'APPLIED',
  applied_by VARCHAR(80) NULL,
  applied_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  KEY idx_sp_import_batch_applied_at (applied_at),
  KEY idx_sp_import_batch_source (source_id),
  CONSTRAINT fk_sp_import_batch_source FOREIGN KEY (source_id) REFERENCES sp_product_source_file (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS sp_product_column_schema (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  batch_id BIGINT UNSIGNED NOT NULL,
  source_id BIGINT UNSIGNED NOT NULL,
  product_kind VARCHAR(40) NOT NULL,
  source_sheet VARCHAR(160) NOT NULL,
  section_name VARCHAR(255) NULL,
  header_row INT UNSIGNED NOT NULL,
  model_count INT UNSIGNED NOT NULL DEFAULT 0,
  column_count INT UNSIGNED NOT NULL DEFAULT 0,
  column_titles_json JSON NOT NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uk_sp_column_schema_batch_sheet_row (batch_id, source_sheet, header_row),
  KEY idx_sp_column_schema_kind (product_kind),
  CONSTRAINT fk_sp_column_schema_batch FOREIGN KEY (batch_id) REFERENCES sp_product_import_batch (id) ON DELETE CASCADE,
  CONSTRAINT fk_sp_column_schema_source FOREIGN KEY (source_id) REFERENCES sp_product_source_file (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS sp_equipment_product_attribute (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  product_id BIGINT UNSIGNED NOT NULL,
  field_key VARCHAR(96) NOT NULL,
  column_title VARCHAR(255) NOT NULL,
  source_column VARCHAR(8) NOT NULL,
  display_order INT UNSIGNED NOT NULL,
  raw_value TEXT NULL,
  source_id BIGINT UNSIGNED NOT NULL,
  source_sheet VARCHAR(160) NOT NULL,
  source_row INT UNSIGNED NOT NULL,
  import_batch_id BIGINT UNSIGNED NOT NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uk_sp_product_attribute_field (product_id, field_key),
  KEY idx_sp_product_attribute_batch (import_batch_id),
  CONSTRAINT fk_sp_product_attribute_product FOREIGN KEY (product_id) REFERENCES sp_equipment_product (id) ON DELETE CASCADE,
  CONSTRAINT fk_sp_product_attribute_source FOREIGN KEY (source_id) REFERENCES sp_product_source_file (id),
  CONSTRAINT fk_sp_product_attribute_batch FOREIGN KEY (import_batch_id) REFERENCES sp_product_import_batch (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS sp_product_import_change (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  batch_id BIGINT UNSIGNED NOT NULL,
  product_id BIGINT UNSIGNED NULL,
  change_key VARCHAR(255) NOT NULL,
  change_type VARCHAR(32) NOT NULL,
  product_kind VARCHAR(40) NOT NULL,
  model VARCHAR(120) NULL,
  drawing_no VARCHAR(160) NULL,
  field_key VARCHAR(96) NULL,
  column_title VARCHAR(255) NULL,
  old_value TEXT NULL,
  new_value TEXT NULL,
  source_sheet VARCHAR(160) NOT NULL,
  source_row INT UNSIGNED NOT NULL,
  accepted TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  KEY idx_sp_import_change_batch (batch_id),
  KEY idx_sp_import_change_product (product_id),
  CONSTRAINT fk_sp_import_change_batch FOREIGN KEY (batch_id) REFERENCES sp_product_import_batch (id) ON DELETE CASCADE,
  CONSTRAINT fk_sp_import_change_product FOREIGN KEY (product_id) REFERENCES sp_equipment_product (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 同名文件后续可能继续更新，来源版本以 SHA-256 区分，文件名只保留普通索引。
SET @has_file_name_unique = (
  SELECT COUNT(*) FROM information_schema.statistics
  WHERE table_schema = DATABASE() AND table_name = 'sp_product_source_file'
    AND index_name = 'uk_sp_source_file_name'
);
SET @drop_file_name_unique = IF(
  @has_file_name_unique > 0,
  'ALTER TABLE sp_product_source_file DROP INDEX uk_sp_source_file_name',
  'SELECT 1'
);
PREPARE stmt FROM @drop_file_name_unique;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_file_sha_unique = (
  SELECT COUNT(*) FROM information_schema.statistics
  WHERE table_schema = DATABASE() AND table_name = 'sp_product_source_file'
    AND index_name = 'uk_sp_source_file_sha256'
);
SET @add_file_sha_unique = IF(
  @has_file_sha_unique = 0,
  'ALTER TABLE sp_product_source_file ADD UNIQUE KEY uk_sp_source_file_sha256 (file_sha256), ADD KEY idx_sp_source_file_name (file_name)',
  'SELECT 1'
);
PREPARE stmt FROM @add_file_sha_unique;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
