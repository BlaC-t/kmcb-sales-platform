-- Sales Platform
-- MySQL 8.0.16+ / 8.4-compatible review DDL.
-- The operator creates and selects the dedicated schema on server 121 first.
-- This file intentionally contains no CREATE DATABASE, DROP, or destructive reset.
-- Application code generates UUIDv7 values and stores them as BINARY(16).

SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;
SET time_zone = '+00:00';
SET SESSION sql_mode = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- Example only; keep the actual schema name in deployment configuration:
-- USE `sales_platform`;

CREATE TABLE identity_external_subject (
  id BINARY(16) PRIMARY KEY,
  source_system VARCHAR(255) NOT NULL,
  external_subject_id VARCHAR(255) NOT NULL,
  display_name VARCHAR(255) NOT NULL,
  email VARCHAR(255),
  preferred_time_zone VARCHAR(64) NOT NULL DEFAULT 'UTC',
  active TINYINT(1) NOT NULL DEFAULT true,
  attributes JSON NOT NULL DEFAULT (JSON_OBJECT()),
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE (source_system, external_subject_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE identity_external_organization (
  id BINARY(16) PRIMARY KEY,
  source_system VARCHAR(255) NOT NULL,
  external_organization_id VARCHAR(255) NOT NULL,
  name VARCHAR(255) NOT NULL,
  active TINYINT(1) NOT NULL DEFAULT true,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE (source_system, external_organization_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE identity_subject_role (
  id BINARY(16) PRIMARY KEY,
  subject_id BINARY(16) NOT NULL,
  role_code VARCHAR(64) NOT NULL,
  organization_id BINARY(16),
  scope_type VARCHAR(32) NOT NULL DEFAULT 'ORGANIZATION',
  scope_id VARCHAR(128),
  valid_from DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  valid_to DATETIME(6),
  UNIQUE (subject_id, role_code, organization_id, scope_type, scope_id),
  CONSTRAINT fk_001 FOREIGN KEY (subject_id) REFERENCES identity_external_subject(id),
  CONSTRAINT fk_002 FOREIGN KEY (organization_id) REFERENCES identity_external_organization(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE identity_external_permission_mapping (
  id BINARY(16) PRIMARY KEY,
  source_system VARCHAR(128) NOT NULL DEFAULT 'BMS',
  external_permission_code VARCHAR(255) NOT NULL,
  local_permission_code VARCHAR(255) NOT NULL,
  scope_type VARCHAR(32) NOT NULL DEFAULT 'ORGANIZATION',
  active TINYINT(1) NOT NULL DEFAULT true,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE (source_system, external_permission_code),
  UNIQUE (source_system, local_permission_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE md_dictionary_term (
  id BINARY(16) PRIMARY KEY,
  dictionary_code VARCHAR(255) NOT NULL,
  term_code VARCHAR(255) NOT NULL,
  parent_term_id BINARY(16),
  name_zh VARCHAR(255) NOT NULL,
  name_en VARCHAR(255),
  description VARCHAR(255),
  active TINYINT(1) NOT NULL DEFAULT true,
  sort_order integer NOT NULL DEFAULT 0,
  metadata JSON NOT NULL DEFAULT (JSON_OBJECT()),
  UNIQUE (dictionary_code, term_code),
  CONSTRAINT fk_003 FOREIGN KEY (parent_term_id) REFERENCES md_dictionary_term(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE md_term_alias (
  id BINARY(16) PRIMARY KEY,
  term_id BINARY(16) NOT NULL,
  alias VARCHAR(255) NOT NULL,
  language_code VARCHAR(255),
  source VARCHAR(255),
  UNIQUE (term_id, alias),
  CONSTRAINT fk_004 FOREIGN KEY (term_id) REFERENCES md_dictionary_term(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE md_unit_definition (
  code VARCHAR(255) PRIMARY KEY,
  dimension VARCHAR(255) NOT NULL,
  symbol VARCHAR(255) NOT NULL,
  canonical_unit_code VARCHAR(255) NOT NULL,
  multiplier_to_canonical DECIMAL(30,12) NOT NULL DEFAULT 1,
  offset_to_canonical DECIMAL(30,12) NOT NULL DEFAULT 0,
  active TINYINT(1) NOT NULL DEFAULT true
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE md_operation_type (
  id BINARY(16) PRIMARY KEY,
  code VARCHAR(255) NOT NULL UNIQUE,
  name_zh VARCHAR(255) NOT NULL,
  name_en VARCHAR(255),
  category_code VARCHAR(255) NOT NULL,
  parameter_schema JSON NOT NULL DEFAULT (JSON_OBJECT()),
  allowed_input_ports JSON NOT NULL DEFAULT (JSON_ARRAY()),
  allowed_output_ports JSON NOT NULL DEFAULT (JSON_ARRAY()),
  requires_equipment TINYINT(1) NOT NULL DEFAULT true,
  active TINYINT(1) NOT NULL DEFAULT true
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE project_project (
  id BINARY(16) PRIMARY KEY,
  organization_id BINARY(16),
  project_code VARCHAR(255) NOT NULL UNIQUE,
  project_name VARCHAR(255) NOT NULL,
  customer_display_name VARCHAR(255),
  country_code VARCHAR(255),
  region VARCHAR(255),
  site_time_zone VARCHAR(64) NOT NULL DEFAULT 'UTC',
  created_time_zone VARCHAR(64) NOT NULL DEFAULT 'UTC',
  owner_subject_id BINARY(16),
  created_by BINARY(16) NOT NULL,
  status VARCHAR(255) NOT NULL DEFAULT 'ACTIVE',
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  CONSTRAINT fk_005 FOREIGN KEY (organization_id) REFERENCES identity_external_organization(id),
  CONSTRAINT fk_006 FOREIGN KEY (owner_subject_id) REFERENCES identity_external_subject(id),
  CONSTRAINT fk_project_creator FOREIGN KEY (created_by) REFERENCES identity_external_subject(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE project_requirement_version (
  id BINARY(16) PRIMARY KEY,
  project_id BINARY(16) NOT NULL,
  version_no integer NOT NULL CHECK (version_no > 0),
  status VARCHAR(255) NOT NULL CHECK (status IN ('DRAFT', 'VALIDATING', 'READY', 'SNAPSHOTTED', 'SUPERSEDED')),
  throughput_tpd DECIMAL(16,4) CHECK (throughput_tpd IS NULL OR throughput_tpd > 0),
  operating_hours_per_day DECIMAL(7,3) CHECK (operating_hours_per_day IS NULL OR operating_hours_per_day > 0 AND operating_hours_per_day <= 24),
  availability_pct DECIMAL(7,3) CHECK (availability_pct IS NULL OR availability_pct > 0 AND availability_pct <= 100),
  design_margin_pct DECIMAL(7,3) CHECK (design_margin_pct IS NULL OR design_margin_pct >= 0),
  design_tph DECIMAL(16,4) CHECK (design_tph IS NULL OR design_tph > 0),
  lines_count integer CHECK (lines_count IS NULL OR lines_count > 0),
  raw_payload JSON NOT NULL DEFAULT (JSON_OBJECT()),
  completeness_score DECIMAL(6,5) CHECK (completeness_score IS NULL OR completeness_score BETWEEN 0 AND 1),
  created_by BINARY(16) NOT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  row_version integer NOT NULL DEFAULT 1,
  UNIQUE (project_id, version_no),
  CONSTRAINT fk_007 FOREIGN KEY (project_id) REFERENCES project_project(id),
  CONSTRAINT fk_008 FOREIGN KEY (created_by) REFERENCES identity_external_subject(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE project_ore_profile (
  requirement_version_id BINARY(16) PRIMARY KEY,
  ore_family_term_id BINARY(16),
  valuable_minerals JSON NOT NULL DEFAULT (JSON_ARRAY()),
  gangue_minerals JSON NOT NULL DEFAULT (JSON_ARRAY()),
  head_assays JSON NOT NULL DEFAULT (JSON_OBJECT()),
  feed_top_size_mm DECIMAL(14,4),
  feed_p80_mm DECIMAL(14,4),
  moisture_pct DECIMAL(7,3) CHECK (moisture_pct IS NULL OR moisture_pct BETWEEN 0 AND 100),
  clay_pct DECIMAL(7,3) CHECK (clay_pct IS NULL OR clay_pct BETWEEN 0 AND 100),
  bulk_density_t_m3 DECIMAL(12,5),
  bond_work_index_kwh_t DECIMAL(12,5),
  abrasiveness_index DECIMAL(12,5),
  oxidation_state_code VARCHAR(255),
  variability_class_code VARCHAR(255),
  testwork_document_ids JSON NOT NULL DEFAULT (JSON_ARRAY()),
  evidence JSON NOT NULL DEFAULT (JSON_OBJECT()),
  CONSTRAINT fk_009 FOREIGN KEY (requirement_version_id) REFERENCES project_requirement_version(id) ON DELETE CASCADE,
  CONSTRAINT fk_010 FOREIGN KEY (ore_family_term_id) REFERENCES md_dictionary_term(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE project_site_condition (
  requirement_version_id BINARY(16) PRIMARY KEY,
  altitude_m DECIMAL(12,3),
  temperature_min_c DECIMAL(8,3),
  temperature_max_c DECIMAL(8,3),
  water_available_m3h DECIMAL(16,4),
  power_available_kw DECIMAL(16,4),
  grid_voltage_v DECIMAL(12,3),
  power_reliability_code VARCHAR(255),
  compressed_air_available TINYINT(1),
  footprint_limit_m2 DECIMAL(16,4),
  foundation_condition_code VARCHAR(255),
  crane_capacity_t DECIMAL(12,4),
  on_site_maintenance_level VARCHAR(255),
  evidence JSON NOT NULL DEFAULT (JSON_OBJECT()),
  CONSTRAINT fk_011 FOREIGN KEY (requirement_version_id) REFERENCES project_requirement_version(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE project_logistics_condition (
  requirement_version_id BINARY(16) PRIMARY KEY,
  max_vehicle_width_m DECIMAL(10,4),
  max_vehicle_height_m DECIMAL(10,4),
  max_vehicle_length_m DECIMAL(10,4),
  max_single_piece_weight_t DECIMAL(12,4),
  bridge_load_limit_t DECIMAL(12,4),
  max_road_gradient_pct DECIMAL(7,3),
  min_turning_radius_m DECIMAL(10,4),
  seasonal_access_restriction TINYINT(1),
  container_shipping_required TINYINT(1),
  on_site_assembly_available TINYINT(1),
  evidence JSON NOT NULL DEFAULT (JSON_OBJECT()),
  CONSTRAINT fk_012 FOREIGN KEY (requirement_version_id) REFERENCES project_requirement_version(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE project_process_objective (
  id BINARY(16) PRIMARY KEY,
  requirement_version_id BINARY(16) NOT NULL,
  objective_type VARCHAR(255) NOT NULL,
  target_value DECIMAL(20,6),
  target_text VARCHAR(255),
  unit_code VARCHAR(255),
  priority integer NOT NULL DEFAULT 50 CHECK (priority BETWEEN 0 AND 100),
  mandatory TINYINT(1) NOT NULL DEFAULT false,
  source_type VARCHAR(255),
  evidence JSON NOT NULL DEFAULT (JSON_OBJECT()),
  CONSTRAINT fk_013 FOREIGN KEY (requirement_version_id) REFERENCES project_requirement_version(id) ON DELETE CASCADE,
  CONSTRAINT fk_014 FOREIGN KEY (unit_code) REFERENCES md_unit_definition(code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE project_input_snapshot (
  id BINARY(16) PRIMARY KEY,
  requirement_version_id BINARY(16) NOT NULL,
  schema_version integer NOT NULL,
  payload JSON NOT NULL,
  payload_checksum VARCHAR(255) NOT NULL,
  created_by BINARY(16) NOT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE (requirement_version_id, payload_checksum),
  CONSTRAINT fk_015 FOREIGN KEY (requirement_version_id) REFERENCES project_requirement_version(id),
  CONSTRAINT fk_016 FOREIGN KEY (created_by) REFERENCES identity_external_subject(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE equipment_equipment_type (
  id BINARY(16) PRIMARY KEY,
  code VARCHAR(255) NOT NULL UNIQUE,
  name_zh VARCHAR(255) NOT NULL,
  name_en VARCHAR(255),
  category_code VARCHAR(255) NOT NULL,
  active TINYINT(1) NOT NULL DEFAULT true
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE equipment_equipment_model (
  id BINARY(16) PRIMARY KEY,
  equipment_type_id BINARY(16) NOT NULL,
  manufacturer VARCHAR(255) NOT NULL,
  model_code VARCHAR(255) NOT NULL,
  display_name VARCHAR(255),
  lifecycle_status VARCHAR(255) NOT NULL DEFAULT 'ACTIVE',
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE (manufacturer, model_code),
  CONSTRAINT fk_017 FOREIGN KEY (equipment_type_id) REFERENCES equipment_equipment_type(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE equipment_equipment_spec_version (
  id BINARY(16) PRIMARY KEY,
  equipment_model_id BINARY(16) NOT NULL,
  version_no integer NOT NULL CHECK (version_no > 0),
  status VARCHAR(32) NOT NULL DEFAULT 'DRAFT',
  wet_duty_supported TINYINT(1),
  dry_duty_supported TINYINT(1),
  power_kw DECIMAL(16,4),
  empty_weight_t DECIMAL(14,4),
  operating_weight_t DECIMAL(14,4),
  shipping_weight_t DECIMAL(14,4),
  shipping_length_m DECIMAL(12,4),
  shipping_width_m DECIMAL(12,4),
  shipping_height_m DECIMAL(12,4),
  specification JSON NOT NULL DEFAULT (JSON_OBJECT()),
  published_model_id BINARY(16)
    GENERATED ALWAYS AS (CASE WHEN status = 'PUBLISHED' THEN equipment_model_id ELSE NULL END) STORED,
  source_document_id BINARY(16),
  effective_from DATETIME(6),
  effective_to DATETIME(6),
  published_by BINARY(16),
  published_at DATETIME(6),
  created_by BINARY(16) NOT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE (equipment_model_id, version_no),
  UNIQUE KEY uq_equipment_one_published_spec (published_model_id),
  CONSTRAINT fk_018 FOREIGN KEY (equipment_model_id) REFERENCES equipment_equipment_model(id),
  CONSTRAINT fk_019 FOREIGN KEY (published_by) REFERENCES identity_external_subject(id),
  CONSTRAINT fk_020 FOREIGN KEY (created_by) REFERENCES identity_external_subject(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE equipment_equipment_capability (
  id BINARY(16) PRIMARY KEY,
  spec_version_id BINARY(16) NOT NULL,
  operation_type_id BINARY(16) NOT NULL,
  ore_family_term_id BINARY(16),
  capacity_basis VARCHAR(255) NOT NULL CHECK (capacity_basis IN ('MANUFACTURER', 'ENGINEERING', 'OBSERVED')),
  capacity_min_tph DECIMAL(16,4),
  capacity_max_tph DECIMAL(16,4),
  max_feed_size_mm DECIMAL(14,4),
  product_size_min_mm DECIMAL(14,4),
  product_size_max_mm DECIMAL(14,4),
  moisture_min_pct DECIMAL(7,3),
  moisture_max_pct DECIMAL(7,3),
  solids_min_pct DECIMAL(7,3),
  solids_max_pct DECIMAL(7,3),
  applicability JSON NOT NULL DEFAULT (JSON_OBJECT()),
  confidence DECIMAL(6,5) CHECK (confidence IS NULL OR confidence BETWEEN 0 AND 1),
  source_reference JSON NOT NULL DEFAULT (JSON_OBJECT()),
  CHECK (capacity_min_tph IS NULL OR capacity_max_tph IS NULL OR capacity_min_tph <= capacity_max_tph),
  CONSTRAINT fk_021 FOREIGN KEY (spec_version_id) REFERENCES equipment_equipment_spec_version(id) ON DELETE CASCADE,
  CONSTRAINT fk_022 FOREIGN KEY (operation_type_id) REFERENCES md_operation_type(id),
  CONSTRAINT fk_023 FOREIGN KEY (ore_family_term_id) REFERENCES md_dictionary_term(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE case_historical_case (
  id BINARY(16) PRIMARY KEY,
  case_code VARCHAR(255) NOT NULL UNIQUE,
  name VARCHAR(255) NOT NULL,
  country_code VARCHAR(255),
  region VARCHAR(255),
  project_status VARCHAR(255),
  commissioning_status VARCHAR(255),
  ore_profile JSON NOT NULL DEFAULT (JSON_OBJECT()),
  design_basis JSON NOT NULL DEFAULT (JSON_OBJECT()),
  site_condition JSON NOT NULL DEFAULT (JSON_OBJECT()),
  logistics_condition JSON NOT NULL DEFAULT (JSON_OBJECT()),
  source_quality DECIMAL(6,5) CHECK (source_quality IS NULL OR source_quality BETWEEN 0 AND 1),
  data_completeness DECIMAL(6,5) CHECK (data_completeness IS NULL OR data_completeness BETWEEN 0 AND 1),
  status VARCHAR(32) NOT NULL DEFAULT 'DRAFT',
  published_at DATETIME(6),
  published_by BINARY(16),
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  CONSTRAINT fk_024 FOREIGN KEY (published_by) REFERENCES identity_external_subject(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE case_flowsheet_version (
  id BINARY(16) PRIMARY KEY,
  historical_case_id BINARY(16),
  template_code VARCHAR(255),
  version_no integer NOT NULL CHECK (version_no > 0),
  status VARCHAR(32) NOT NULL DEFAULT 'DRAFT',
  name VARCHAR(255) NOT NULL,
  description VARCHAR(255),
  created_by BINARY(16) NOT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  published_by BINARY(16),
  published_at DATETIME(6),
  CHECK (historical_case_id IS NOT NULL OR template_code IS NOT NULL),
  CONSTRAINT fk_025 FOREIGN KEY (historical_case_id) REFERENCES case_historical_case(id),
  CONSTRAINT fk_026 FOREIGN KEY (created_by) REFERENCES identity_external_subject(id),
  CONSTRAINT fk_027 FOREIGN KEY (published_by) REFERENCES identity_external_subject(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE case_flowsheet_node (
  id BINARY(16) PRIMARY KEY,
  flowsheet_version_id BINARY(16) NOT NULL,
  node_code VARCHAR(255) NOT NULL,
  operation_type_id BINARY(16) NOT NULL,
  purpose_code VARCHAR(255),
  parameters JSON NOT NULL DEFAULT (JSON_OBJECT()),
  narrative VARCHAR(255),
  x DECIMAL(12,3),
  y DECIMAL(12,3),
  width DECIMAL(12,3),
  height DECIMAL(12,3),
  UNIQUE (flowsheet_version_id, node_code),
  UNIQUE (flowsheet_version_id, id),
  CONSTRAINT fk_028 FOREIGN KEY (flowsheet_version_id) REFERENCES case_flowsheet_version(id) ON DELETE CASCADE,
  CONSTRAINT fk_029 FOREIGN KEY (operation_type_id) REFERENCES md_operation_type(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE case_flowsheet_edge (
  id BINARY(16) PRIMARY KEY,
  flowsheet_version_id BINARY(16) NOT NULL,
  from_node_id BINARY(16) NOT NULL,
  to_node_id BINARY(16) NOT NULL,
  from_port VARCHAR(255) NOT NULL,
  to_port VARCHAR(255) NOT NULL,
  stream_role VARCHAR(255) NOT NULL,
  dry_tph DECIMAL(16,4),
  water_m3h DECIMAL(16,4),
  solids_pct DECIMAL(7,3) CHECK (solids_pct IS NULL OR solids_pct BETWEEN 0 AND 100),
  p80_mm DECIMAL(14,4),
  top_size_mm DECIMAL(14,4),
  moisture_pct DECIMAL(7,3) CHECK (moisture_pct IS NULL OR moisture_pct BETWEEN 0 AND 100),
  assays JSON NOT NULL DEFAULT (JSON_OBJECT()),
  recycle_flag TINYINT(1) NOT NULL DEFAULT false,
  properties JSON NOT NULL DEFAULT (JSON_OBJECT()),
  CONSTRAINT fk_030 FOREIGN KEY (flowsheet_version_id) REFERENCES case_flowsheet_version(id) ON DELETE CASCADE,
  CONSTRAINT fk_031 FOREIGN KEY (flowsheet_version_id, from_node_id)
    REFERENCES case_flowsheet_node(flowsheet_version_id, id),
  CONSTRAINT fk_032 FOREIGN KEY (flowsheet_version_id, to_node_id)
    REFERENCES case_flowsheet_node(flowsheet_version_id, id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE case_node_equipment_assignment (
  id BINARY(16) PRIMARY KEY,
  node_id BINARY(16) NOT NULL,
  spec_version_id BINARY(16) NOT NULL,
  quantity_total integer NOT NULL CHECK (quantity_total > 0),
  quantity_duty integer NOT NULL CHECK (quantity_duty >= 0),
  quantity_standby integer NOT NULL CHECK (quantity_standby >= 0),
  utilization_pct DECIMAL(7,3) CHECK (utilization_pct IS NULL OR utilization_pct BETWEEN 0 AND 100),
  parameters JSON NOT NULL DEFAULT (JSON_OBJECT()),
  CHECK (quantity_duty + quantity_standby <= quantity_total),
  CONSTRAINT fk_033 FOREIGN KEY (node_id) REFERENCES case_flowsheet_node(id) ON DELETE CASCADE,
  CONSTRAINT fk_034 FOREIGN KEY (spec_version_id) REFERENCES equipment_equipment_spec_version(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE equipment_performance_observation (
  id BINARY(16) PRIMARY KEY,
  historical_case_id BINARY(16) NOT NULL,
  assignment_id BINARY(16),
  spec_version_id BINARY(16) NOT NULL,
  observed_from date,
  observed_to date,
  actual_throughput_tph DECIMAL(16,4),
  actual_power_kw DECIMAL(16,4),
  availability_pct DECIMAL(7,3),
  product_p80_mm DECIMAL(14,4),
  maintenance_hours DECIMAL(14,3),
  wear_life_hours DECIMAL(14,3),
  data_quality DECIMAL(6,5) CHECK (data_quality IS NULL OR data_quality BETWEEN 0 AND 1),
  observation JSON NOT NULL DEFAULT (JSON_OBJECT()),
  source_reference JSON NOT NULL DEFAULT (JSON_OBJECT()),
  CONSTRAINT fk_035 FOREIGN KEY (historical_case_id) REFERENCES case_historical_case(id),
  CONSTRAINT fk_036 FOREIGN KEY (assignment_id) REFERENCES case_node_equipment_assignment(id),
  CONSTRAINT fk_037 FOREIGN KEY (spec_version_id) REFERENCES equipment_equipment_spec_version(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE rule_rule_set_version (
  id BINARY(16) PRIMARY KEY,
  rule_set_code VARCHAR(255) NOT NULL,
  version_no integer NOT NULL CHECK (version_no > 0),
  name VARCHAR(255) NOT NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'DRAFT',
  published_rule_set_code VARCHAR(255)
    GENERATED ALWAYS AS (CASE WHEN status = 'PUBLISHED' THEN rule_set_code ELSE NULL END) STORED,
  applies_to JSON NOT NULL DEFAULT (JSON_OBJECT()),
  created_by BINARY(16) NOT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  published_by BINARY(16),
  published_at DATETIME(6),
  UNIQUE (rule_set_code, version_no),
  UNIQUE KEY uq_rule_set_one_published (published_rule_set_code),
  CONSTRAINT fk_038 FOREIGN KEY (created_by) REFERENCES identity_external_subject(id),
  CONSTRAINT fk_039 FOREIGN KEY (published_by) REFERENCES identity_external_subject(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE rule_knowledge_rule (
  id BINARY(16) PRIMARY KEY,
  rule_set_version_id BINARY(16) NOT NULL,
  rule_code VARCHAR(255) NOT NULL,
  name VARCHAR(255) NOT NULL,
  effect VARCHAR(16) NOT NULL,
  priority integer NOT NULL DEFAULT 50 CHECK (priority BETWEEN 0 AND 1000),
  enabled TINYINT(1) NOT NULL DEFAULT true,
  condition_tree JSON NOT NULL,
  action_payload JSON NOT NULL,
  explanation_template VARCHAR(255) NOT NULL,
  source_reference JSON NOT NULL DEFAULT (JSON_OBJECT()),
  owner_subject_id BINARY(16),
  UNIQUE (rule_set_version_id, rule_code),
  CONSTRAINT fk_040 FOREIGN KEY (rule_set_version_id) REFERENCES rule_rule_set_version(id) ON DELETE CASCADE,
  CONSTRAINT fk_041 FOREIGN KEY (owner_subject_id) REFERENCES identity_external_subject(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE rule_rule_test_case (
  id BINARY(16) PRIMARY KEY,
  rule_id BINARY(16) NOT NULL,
  name VARCHAR(255) NOT NULL,
  facts JSON NOT NULL,
  expected_match TINYINT(1) NOT NULL,
  expected_effect VARCHAR(16),
  expected_message_pattern VARCHAR(255),
  active TINYINT(1) NOT NULL DEFAULT true,
  CONSTRAINT fk_042 FOREIGN KEY (rule_id) REFERENCES rule_knowledge_rule(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE rec_catalog_snapshot (
  id BINARY(16) PRIMARY KEY,
  snapshot_type VARCHAR(255) NOT NULL CHECK (snapshot_type IN ('EQUIPMENT', 'CASE_LIBRARY', 'FEATURE_SCHEMA')),
  version_label VARCHAR(255) NOT NULL,
  manifest JSON NOT NULL,
  checksum VARCHAR(255) NOT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE (snapshot_type, version_label)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE rec_recommendation_run (
  id BINARY(16) PRIMARY KEY,
  run_number VARCHAR(255) NOT NULL UNIQUE,
  project_id BINARY(16) NOT NULL,
  input_snapshot_id BINARY(16) NOT NULL,
  status VARCHAR(16) NOT NULL DEFAULT 'QUEUED',
  current_stage VARCHAR(255),
  algorithm_version VARCHAR(255) NOT NULL,
  rule_set_version_id BINARY(16) NOT NULL,
  equipment_snapshot_id BINARY(16) NOT NULL,
  case_snapshot_id BINARY(16) NOT NULL,
  feature_schema_version VARCHAR(255) NOT NULL,
  scenario_preferences JSON NOT NULL DEFAULT (JSON_OBJECT()),
  evidence_coverage DECIMAL(6,5) CHECK (evidence_coverage IS NULL OR evidence_coverage BETWEEN 0 AND 1),
  failure_code VARCHAR(255),
  failure_detail JSON,
  requested_by BINARY(16) NOT NULL,
  requested_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  started_at DATETIME(6),
  completed_at DATETIME(6),
  CONSTRAINT fk_043 FOREIGN KEY (project_id) REFERENCES project_project(id),
  CONSTRAINT fk_044 FOREIGN KEY (input_snapshot_id) REFERENCES project_input_snapshot(id),
  CONSTRAINT fk_045 FOREIGN KEY (rule_set_version_id) REFERENCES rule_rule_set_version(id),
  CONSTRAINT fk_046 FOREIGN KEY (equipment_snapshot_id) REFERENCES rec_catalog_snapshot(id),
  CONSTRAINT fk_047 FOREIGN KEY (case_snapshot_id) REFERENCES rec_catalog_snapshot(id),
  CONSTRAINT fk_048 FOREIGN KEY (requested_by) REFERENCES identity_external_subject(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE rec_recommendation_dependency (
  id BINARY(16) PRIMARY KEY,
  recommendation_run_id BINARY(16) NOT NULL,
  dependency_type VARCHAR(64) NOT NULL,
  dependency_id VARCHAR(128) NOT NULL,
  dependency_version VARCHAR(128) NOT NULL,
  dependency_checksum VARCHAR(255),
  UNIQUE (recommendation_run_id, dependency_type, dependency_id, dependency_version),
  CONSTRAINT fk_049 FOREIGN KEY (recommendation_run_id) REFERENCES rec_recommendation_run(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE rec_candidate_solution (
  id BINARY(16) PRIMARY KEY,
  recommendation_run_id BINARY(16) NOT NULL,
  candidate_no integer NOT NULL CHECK (candidate_no > 0),
  scenario_code VARCHAR(255) NOT NULL,
  title VARCHAR(255) NOT NULL,
  technical_status VARCHAR(255) NOT NULL,
  rank_no integer,
  total_score DECIMAL(14,6),
  evidence_coverage DECIMAL(6,5),
  flowsheet_payload JSON NOT NULL,
  equipment_plan_payload JSON NOT NULL,
  assumptions JSON NOT NULL DEFAULT (JSON_ARRAY()),
  warnings JSON NOT NULL DEFAULT (JSON_ARRAY()),
  explanation JSON NOT NULL DEFAULT (JSON_OBJECT()),
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE (recommendation_run_id, candidate_no),
  CONSTRAINT fk_050 FOREIGN KEY (recommendation_run_id) REFERENCES rec_recommendation_run(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE rec_candidate_score_component (
  id BINARY(16) PRIMARY KEY,
  candidate_solution_id BINARY(16) NOT NULL,
  component_code VARCHAR(255) NOT NULL,
  raw_score DECIMAL(16,6),
  weight DECIMAL(12,6),
  weighted_score DECIMAL(16,6),
  explanation VARCHAR(255),
  evidence JSON NOT NULL DEFAULT (JSON_ARRAY()),
  UNIQUE (candidate_solution_id, component_code),
  CONSTRAINT fk_051 FOREIGN KEY (candidate_solution_id) REFERENCES rec_candidate_solution(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE rec_rejected_candidate (
  id BINARY(16) PRIMARY KEY,
  recommendation_run_id BINARY(16) NOT NULL,
  candidate_type VARCHAR(255) NOT NULL,
  candidate_ref VARCHAR(255) NOT NULL,
  rule_code VARCHAR(255),
  reason_code VARCHAR(255) NOT NULL,
  message VARCHAR(255) NOT NULL,
  evidence JSON NOT NULL DEFAULT (JSON_OBJECT()),
  CONSTRAINT fk_052 FOREIGN KEY (recommendation_run_id) REFERENCES rec_recommendation_run(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE sales_content_collection (
  id BINARY(16) PRIMARY KEY,
  collection_code VARCHAR(128) NOT NULL UNIQUE,
  name VARCHAR(255) NOT NULL,
  default_locale VARCHAR(16) NOT NULL DEFAULT 'zh-CN',
  active TINYINT(1) NOT NULL DEFAULT true,
  created_by BINARY(16) NOT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  CONSTRAINT fk_sales_content_collection_creator FOREIGN KEY (created_by) REFERENCES identity_external_subject(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE sales_content_page (
  id BINARY(16) PRIMARY KEY,
  collection_id BINARY(16) NOT NULL,
  page_code VARCHAR(128) NOT NULL,
  route_path VARCHAR(255) NOT NULL,
  section_type VARCHAR(64) NOT NULL CHECK (section_type IN ('COMPANY', 'UZBEKISTAN_SUBSIDIARY', 'PRODUCTION_CAPABILITY', 'PRODUCT_FUNCTION', 'AUTHORIZED_CASE', 'OTHER')),
  sort_order integer NOT NULL DEFAULT 0,
  customer_safe TINYINT(1) NOT NULL DEFAULT true,
  active TINYINT(1) NOT NULL DEFAULT true,
  created_by BINARY(16) NOT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE (collection_id, page_code),
  UNIQUE (collection_id, route_path),
  CONSTRAINT fk_sales_content_page_collection FOREIGN KEY (collection_id) REFERENCES sales_content_collection(id),
  CONSTRAINT fk_sales_content_page_creator FOREIGN KEY (created_by) REFERENCES identity_external_subject(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE sales_content_revision (
  id BINARY(16) PRIMARY KEY,
  page_id BINARY(16) NOT NULL,
  version_no integer NOT NULL CHECK (version_no > 0),
  source_locale VARCHAR(16) NOT NULL DEFAULT 'zh-CN' CHECK (source_locale IN ('zh-CN', 'en', 'ru', 'uk')),
  status VARCHAR(32) NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'IN_REVIEW', 'APPROVED', 'PUBLISHED', 'SUPERSEDED')),
  published_page_id BINARY(16)
    GENERATED ALWAYS AS (CASE WHEN status = 'PUBLISHED' THEN page_id ELSE NULL END) STORED,
  structure_checksum VARCHAR(128),
  change_summary VARCHAR(2000),
  created_by BINARY(16) NOT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  reviewed_by BINARY(16),
  reviewed_at DATETIME(6),
  published_by BINARY(16),
  published_at DATETIME(6),
  row_version integer NOT NULL DEFAULT 1,
  UNIQUE (page_id, version_no),
  UNIQUE KEY uq_sales_content_published_page (published_page_id),
  CONSTRAINT fk_sales_content_revision_page FOREIGN KEY (page_id) REFERENCES sales_content_page(id),
  CONSTRAINT fk_sales_content_revision_creator FOREIGN KEY (created_by) REFERENCES identity_external_subject(id),
  CONSTRAINT fk_sales_content_revision_reviewer FOREIGN KEY (reviewed_by) REFERENCES identity_external_subject(id),
  CONSTRAINT fk_sales_content_revision_publisher FOREIGN KEY (published_by) REFERENCES identity_external_subject(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE sales_content_block (
  id BINARY(16) PRIMARY KEY,
  content_revision_id BINARY(16) NOT NULL,
  block_key VARCHAR(128) NOT NULL,
  sort_order integer NOT NULL DEFAULT 0,
  block_type VARCHAR(32) NOT NULL CHECK (block_type IN ('HERO', 'TEXT', 'IMAGE', 'VIDEO', 'METRIC', 'GALLERY', 'DOCUMENT', 'CASE_CARD')),
  layout_payload JSON NOT NULL DEFAULT (JSON_OBJECT()),
  shared_payload JSON NOT NULL DEFAULT (JSON_OBJECT()),
  audience_scope VARCHAR(32) NOT NULL DEFAULT 'CUSTOMER_SAFE',
  active TINYINT(1) NOT NULL DEFAULT true,
  UNIQUE (content_revision_id, block_key),
  CONSTRAINT fk_sales_content_block_revision FOREIGN KEY (content_revision_id) REFERENCES sales_content_revision(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE sales_content_translation (
  id BINARY(16) PRIMARY KEY,
  content_revision_id BINARY(16) NOT NULL,
  locale VARCHAR(16) NOT NULL CHECK (locale IN ('zh-CN', 'en', 'ru', 'uk')),
  status VARCHAR(32) NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'STALE', 'IN_REVIEW', 'APPROVED')),
  page_title VARCHAR(255) NOT NULL,
  page_summary VARCHAR(2000),
  seo_payload JSON NOT NULL DEFAULT (JSON_OBJECT()),
  translation_method VARCHAR(32) NOT NULL CHECK (translation_method IN ('SOURCE', 'HUMAN', 'LLM_DRAFT', 'IMPORT')),
  source_content_checksum VARCHAR(128),
  translation_checksum VARCHAR(128),
  reviewed_by BINARY(16),
  reviewed_at DATETIME(6),
  created_by BINARY(16) NOT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  row_version integer NOT NULL DEFAULT 1,
  UNIQUE (content_revision_id, locale),
  CONSTRAINT fk_sales_content_translation_revision FOREIGN KEY (content_revision_id) REFERENCES sales_content_revision(id) ON DELETE CASCADE,
  CONSTRAINT fk_sales_content_translation_reviewer FOREIGN KEY (reviewed_by) REFERENCES identity_external_subject(id),
  CONSTRAINT fk_sales_content_translation_creator FOREIGN KEY (created_by) REFERENCES identity_external_subject(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE sales_content_block_translation (
  id BINARY(16) PRIMARY KEY,
  content_block_id BINARY(16) NOT NULL,
  locale VARCHAR(16) NOT NULL CHECK (locale IN ('zh-CN', 'en', 'ru', 'uk')),
  status VARCHAR(32) NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'STALE', 'IN_REVIEW', 'APPROVED')),
  heading VARCHAR(1000),
  body JSON NOT NULL DEFAULT (JSON_OBJECT()),
  action_label VARCHAR(255),
  accessibility_payload JSON NOT NULL DEFAULT (JSON_OBJECT()),
  translation_method VARCHAR(32) NOT NULL CHECK (translation_method IN ('SOURCE', 'HUMAN', 'LLM_DRAFT', 'IMPORT')),
  source_content_checksum VARCHAR(128),
  translation_checksum VARCHAR(128),
  reviewed_by BINARY(16),
  reviewed_at DATETIME(6),
  created_by BINARY(16) NOT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  row_version integer NOT NULL DEFAULT 1,
  UNIQUE (content_block_id, locale),
  CONSTRAINT fk_sales_block_translation_block FOREIGN KEY (content_block_id) REFERENCES sales_content_block(id) ON DELETE CASCADE,
  CONSTRAINT fk_sales_block_translation_reviewer FOREIGN KEY (reviewed_by) REFERENCES identity_external_subject(id),
  CONSTRAINT fk_sales_block_translation_creator FOREIGN KEY (created_by) REFERENCES identity_external_subject(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE sales_media_asset (
  id BINARY(16) PRIMARY KEY,
  asset_code VARCHAR(128) NOT NULL UNIQUE,
  media_type VARCHAR(32) NOT NULL CHECK (media_type IN ('IMAGE', 'VIDEO', 'DOCUMENT')),
  original_file_name VARCHAR(255) NOT NULL,
  original_storage_uri VARCHAR(1000) NOT NULL,
  mime_type VARCHAR(128) NOT NULL,
  checksum VARCHAR(128) NOT NULL UNIQUE,
  size_bytes bigint NOT NULL CHECK (size_bytes >= 0),
  width_px integer,
  height_px integer,
  duration_ms bigint,
  rights_status VARCHAR(32) NOT NULL DEFAULT 'INTERNAL' CHECK (rights_status IN ('INTERNAL', 'LICENSED', 'CUSTOMER_AUTHORIZED', 'RESTRICTED', 'EXPIRED')),
  rights_owner VARCHAR(255),
  rights_expires_at DATETIME(6),
  metadata JSON NOT NULL DEFAULT (JSON_OBJECT()),
  active TINYINT(1) NOT NULL DEFAULT true,
  created_by BINARY(16) NOT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  CONSTRAINT fk_sales_media_asset_creator FOREIGN KEY (created_by) REFERENCES identity_external_subject(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE sales_media_variant (
  id BINARY(16) PRIMARY KEY,
  media_asset_id BINARY(16) NOT NULL,
  variant_code VARCHAR(64) NOT NULL,
  format VARCHAR(32) NOT NULL,
  storage_uri VARCHAR(1000) NOT NULL,
  checksum VARCHAR(128) NOT NULL,
  size_bytes bigint NOT NULL CHECK (size_bytes >= 0),
  width_px integer,
  height_px integer,
  processing_status VARCHAR(32) NOT NULL DEFAULT 'PENDING' CHECK (processing_status IN ('PENDING', 'READY', 'FAILED')),
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE (media_asset_id, variant_code, format),
  CONSTRAINT fk_sales_media_variant_asset FOREIGN KEY (media_asset_id) REFERENCES sales_media_asset(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE sales_content_block_media (
  id BINARY(16) PRIMARY KEY,
  content_block_id BINARY(16) NOT NULL,
  media_asset_id BINARY(16) NOT NULL,
  media_role VARCHAR(64) NOT NULL,
  locale_scope VARCHAR(16) NOT NULL DEFAULT '*' CHECK (locale_scope IN ('*', 'zh-CN', 'en', 'ru', 'uk')),
  sort_order integer NOT NULL DEFAULT 0,
  focal_point_x DECIMAL(7,6),
  focal_point_y DECIMAL(7,6),
  crop_payload JSON NOT NULL DEFAULT (JSON_OBJECT()),
  UNIQUE (content_block_id, media_role, locale_scope, sort_order),
  CONSTRAINT fk_sales_content_block_media_block FOREIGN KEY (content_block_id) REFERENCES sales_content_block(id) ON DELETE CASCADE,
  CONSTRAINT fk_sales_content_block_media_asset FOREIGN KEY (media_asset_id) REFERENCES sales_media_asset(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE sales_content_release (
  id BINARY(16) PRIMARY KEY,
  release_number VARCHAR(64) NOT NULL UNIQUE,
  collection_id BINARY(16) NOT NULL,
  channel_code VARCHAR(32) NOT NULL DEFAULT 'SALES',
  status VARCHAR(32) NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'SCHEDULED', 'PUBLISHED', 'SUPERSEDED', 'ROLLED_BACK', 'FAILED')),
  published_collection_id BINARY(16)
    GENERATED ALWAYS AS (CASE WHEN status = 'PUBLISHED' THEN collection_id ELSE NULL END) STORED,
  published_channel_code VARCHAR(32)
    GENERATED ALWAYS AS (CASE WHEN status = 'PUBLISHED' THEN channel_code ELSE NULL END) STORED,
  locales JSON NOT NULL,
  manifest JSON NOT NULL,
  manifest_checksum VARCHAR(128) NOT NULL,
  publish_at_utc DATETIME(6),
  created_by BINARY(16) NOT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  published_by BINARY(16),
  published_at DATETIME(6),
  supersedes_release_id BINARY(16),
  rollback_reason VARCHAR(2000),
  UNIQUE KEY uq_sales_content_current_release (published_collection_id, published_channel_code),
  CONSTRAINT fk_sales_content_release_collection FOREIGN KEY (collection_id) REFERENCES sales_content_collection(id),
  CONSTRAINT fk_sales_content_release_creator FOREIGN KEY (created_by) REFERENCES identity_external_subject(id),
  CONSTRAINT fk_sales_content_release_publisher FOREIGN KEY (published_by) REFERENCES identity_external_subject(id),
  CONSTRAINT fk_sales_content_release_supersedes FOREIGN KEY (supersedes_release_id) REFERENCES sales_content_release(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE sales_content_release_item (
  id BINARY(16) PRIMARY KEY,
  content_release_id BINARY(16) NOT NULL,
  locale VARCHAR(16) NOT NULL CHECK (locale IN ('zh-CN', 'en', 'ru', 'uk')),
  content_page_id BINARY(16) NOT NULL,
  content_revision_id BINARY(16) NOT NULL,
  content_translation_id BINARY(16) NOT NULL,
  sort_order integer NOT NULL DEFAULT 0,
  snapshot_checksum VARCHAR(128) NOT NULL,
  UNIQUE (content_release_id, locale, content_page_id),
  CONSTRAINT fk_sales_content_release_item_release FOREIGN KEY (content_release_id) REFERENCES sales_content_release(id) ON DELETE CASCADE,
  CONSTRAINT fk_sales_content_release_item_page FOREIGN KEY (content_page_id) REFERENCES sales_content_page(id),
  CONSTRAINT fk_sales_content_release_item_revision FOREIGN KEY (content_revision_id) REFERENCES sales_content_revision(id),
  CONSTRAINT fk_sales_content_release_item_translation FOREIGN KEY (content_translation_id) REFERENCES sales_content_translation(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE sales_questionnaire_version (
  id BINARY(16) PRIMARY KEY,
  questionnaire_code VARCHAR(128) NOT NULL,
  version_no integer NOT NULL CHECK (version_no > 0),
  locale VARCHAR(16) NOT NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'DRAFT',
  title VARCHAR(255) NOT NULL,
  description VARCHAR(2000),
  published_questionnaire_code VARCHAR(128)
    GENERATED ALWAYS AS (CASE WHEN status = 'PUBLISHED' THEN questionnaire_code ELSE NULL END) STORED,
  published_locale VARCHAR(16)
    GENERATED ALWAYS AS (CASE WHEN status = 'PUBLISHED' THEN locale ELSE NULL END) STORED,
  created_by BINARY(16) NOT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  published_by BINARY(16),
  published_at DATETIME(6),
  UNIQUE (questionnaire_code, version_no, locale),
  UNIQUE KEY uq_sales_questionnaire_published (published_questionnaire_code, published_locale),
  CONSTRAINT fk_sales_questionnaire_creator FOREIGN KEY (created_by) REFERENCES identity_external_subject(id),
  CONSTRAINT fk_sales_questionnaire_publisher FOREIGN KEY (published_by) REFERENCES identity_external_subject(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE sales_question (
  id BINARY(16) PRIMARY KEY,
  questionnaire_version_id BINARY(16) NOT NULL,
  question_code VARCHAR(128) NOT NULL,
  group_code VARCHAR(64) NOT NULL,
  sort_order integer NOT NULL DEFAULT 0,
  answer_type VARCHAR(32) NOT NULL CHECK (answer_type IN ('BOOLEAN', 'SINGLE_SELECT', 'MULTI_SELECT', 'NUMBER', 'NUMBER_WITH_UNIT', 'TEXT', 'ATTACHMENT')),
  label VARCHAR(1000) NOT NULL,
  help_text VARCHAR(2000),
  required_flag TINYINT(1) NOT NULL DEFAULT false,
  unit_dimension VARCHAR(64),
  visibility_condition JSON NOT NULL DEFAULT (JSON_OBJECT()),
  option_payload JSON NOT NULL DEFAULT (JSON_ARRAY()),
  requirement_mapping_path VARCHAR(255),
  UNIQUE (questionnaire_version_id, question_code),
  CONSTRAINT fk_sales_question_questionnaire FOREIGN KEY (questionnaire_version_id) REFERENCES sales_questionnaire_version(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE sales_consultation_session (
  id BINARY(16) PRIMARY KEY,
  session_number VARCHAR(64) NOT NULL UNIQUE,
  project_id BINARY(16) NOT NULL,
  questionnaire_version_id BINARY(16) NOT NULL,
  content_release_id BINARY(16),
  presenter_subject_id BINARY(16) NOT NULL,
  requirement_version_id BINARY(16),
  status VARCHAR(32) NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'IN_PROGRESS', 'ANSWERS_COMPLETE', 'RECOMMENDING', 'PROPOSAL_READY', 'SUBMITTED_TO_ENGINEERING', 'CLOSED', 'CANCELLED')),
  locale VARCHAR(16) NOT NULL DEFAULT 'zh-CN',
  time_zone VARCHAR(64) NOT NULL DEFAULT 'UTC',
  customer_display_name VARCHAR(255),
  customer_organization_name VARCHAR(255),
  completeness_score DECIMAL(6,5) CHECK (completeness_score IS NULL OR completeness_score BETWEEN 0 AND 1),
  consent_payload JSON NOT NULL DEFAULT (JSON_OBJECT()),
  content_version_manifest JSON NOT NULL DEFAULT (JSON_ARRAY()),
  sales_notes VARCHAR(4000),
  started_at DATETIME(6),
  completed_at DATETIME(6),
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  row_version integer NOT NULL DEFAULT 1,
  CONSTRAINT fk_sales_consultation_project FOREIGN KEY (project_id) REFERENCES project_project(id),
  CONSTRAINT fk_sales_consultation_questionnaire FOREIGN KEY (questionnaire_version_id) REFERENCES sales_questionnaire_version(id),
  CONSTRAINT fk_sales_consultation_content_release FOREIGN KEY (content_release_id) REFERENCES sales_content_release(id),
  CONSTRAINT fk_sales_consultation_presenter FOREIGN KEY (presenter_subject_id) REFERENCES identity_external_subject(id),
  CONSTRAINT fk_sales_consultation_requirement FOREIGN KEY (requirement_version_id) REFERENCES project_requirement_version(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE sales_answer (
  id BINARY(16) PRIMARY KEY,
  consultation_session_id BINARY(16) NOT NULL,
  question_id BINARY(16) NOT NULL,
  answer_value JSON,
  original_text VARCHAR(4000),
  original_unit VARCHAR(64),
  known_flag TINYINT(1) NOT NULL DEFAULT true,
  source_type VARCHAR(32) NOT NULL DEFAULT 'CUSTOMER',
  confidence DECIMAL(6,5) CHECK (confidence IS NULL OR confidence BETWEEN 0 AND 1),
  mapping_result JSON NOT NULL DEFAULT (JSON_OBJECT()),
  answered_by BINARY(16) NOT NULL,
  answered_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE (consultation_session_id, question_id),
  CONSTRAINT fk_sales_answer_session FOREIGN KEY (consultation_session_id) REFERENCES sales_consultation_session(id) ON DELETE CASCADE,
  CONSTRAINT fk_sales_answer_question FOREIGN KEY (question_id) REFERENCES sales_question(id),
  CONSTRAINT fk_sales_answer_actor FOREIGN KEY (answered_by) REFERENCES identity_external_subject(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE sales_proposal (
  id BINARY(16) PRIMARY KEY,
  proposal_number VARCHAR(64) NOT NULL UNIQUE,
  project_id BINARY(16) NOT NULL,
  consultation_session_id BINARY(16) NOT NULL,
  recommendation_run_id BINARY(16) NOT NULL,
  selected_candidate_id BINARY(16) NOT NULL,
  owner_subject_id BINARY(16) NOT NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'SUPERSEDED', 'CANCELLED')),
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  CONSTRAINT fk_sales_proposal_project FOREIGN KEY (project_id) REFERENCES project_project(id),
  CONSTRAINT fk_sales_proposal_consultation FOREIGN KEY (consultation_session_id) REFERENCES sales_consultation_session(id),
  CONSTRAINT fk_sales_proposal_run FOREIGN KEY (recommendation_run_id) REFERENCES rec_recommendation_run(id),
  CONSTRAINT fk_sales_proposal_candidate FOREIGN KEY (selected_candidate_id) REFERENCES rec_candidate_solution(id),
  CONSTRAINT fk_sales_proposal_owner FOREIGN KEY (owner_subject_id) REFERENCES identity_external_subject(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE sales_proposal_revision (
  id BINARY(16) PRIMARY KEY,
  proposal_id BINARY(16) NOT NULL,
  revision_no integer NOT NULL CHECK (revision_no > 0),
  based_on_revision_id BINARY(16),
  status VARCHAR(32) NOT NULL DEFAULT 'SALES_DRAFT' CHECK (status IN ('SALES_DRAFT', 'READY_FOR_CUSTOMER', 'SUBMITTED_TO_ENGINEERING', 'ACCEPTED_BY_ENGINEERING', 'SUPERSEDED', 'CANCELLED')),
  title VARCHAR(255) NOT NULL,
  customer_preferences JSON NOT NULL DEFAULT (JSON_OBJECT()),
  sales_notes VARCHAR(4000),
  warnings JSON NOT NULL DEFAULT (JSON_ARRAY()),
  created_by BINARY(16) NOT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  submitted_at DATETIME(6),
  row_version integer NOT NULL DEFAULT 1,
  UNIQUE (proposal_id, revision_no),
  CONSTRAINT fk_sales_proposal_revision_proposal FOREIGN KEY (proposal_id) REFERENCES sales_proposal(id),
  CONSTRAINT fk_sales_proposal_revision_base FOREIGN KEY (based_on_revision_id) REFERENCES sales_proposal_revision(id),
  CONSTRAINT fk_sales_proposal_revision_creator FOREIGN KEY (created_by) REFERENCES identity_external_subject(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE sales_proposal_node (
  id BINARY(16) PRIMARY KEY,
  proposal_revision_id BINARY(16) NOT NULL,
  source_candidate_node_id BINARY(16),
  node_code VARCHAR(128) NOT NULL,
  operation_type_id BINARY(16) NOT NULL,
  purpose_code VARCHAR(128),
  narrative VARCHAR(2000) NOT NULL DEFAULT '',
  design_dry_tph DECIMAL(16,4),
  design_water_m3h DECIMAL(16,4),
  x DECIMAL(12,3),
  y DECIMAL(12,3),
  UNIQUE (proposal_revision_id, node_code),
  UNIQUE (proposal_revision_id, id),
  CONSTRAINT fk_sales_proposal_node_revision FOREIGN KEY (proposal_revision_id) REFERENCES sales_proposal_revision(id) ON DELETE CASCADE,
  CONSTRAINT fk_sales_proposal_node_operation FOREIGN KEY (operation_type_id) REFERENCES md_operation_type(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE sales_proposal_edge (
  id BINARY(16) PRIMARY KEY,
  proposal_revision_id BINARY(16) NOT NULL,
  from_node_id BINARY(16) NOT NULL,
  to_node_id BINARY(16) NOT NULL,
  from_port VARCHAR(128) NOT NULL,
  to_port VARCHAR(128) NOT NULL,
  stream_role VARCHAR(128) NOT NULL,
  dry_tph DECIMAL(16,4),
  water_m3h DECIMAL(16,4),
  recycle_flag TINYINT(1) NOT NULL DEFAULT false,
  properties JSON NOT NULL DEFAULT (JSON_OBJECT()),
  CONSTRAINT fk_sales_proposal_edge_revision FOREIGN KEY (proposal_revision_id) REFERENCES sales_proposal_revision(id) ON DELETE CASCADE,
  CONSTRAINT fk_sales_proposal_edge_from FOREIGN KEY (proposal_revision_id, from_node_id) REFERENCES sales_proposal_node(proposal_revision_id, id),
  CONSTRAINT fk_sales_proposal_edge_to FOREIGN KEY (proposal_revision_id, to_node_id) REFERENCES sales_proposal_node(proposal_revision_id, id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE sales_equipment_option (
  id BINARY(16) PRIMARY KEY,
  proposal_revision_id BINARY(16) NOT NULL,
  node_id BINARY(16) NOT NULL,
  spec_version_id BINARY(16) NOT NULL,
  rank_no integer,
  origin_type VARCHAR(32) NOT NULL CHECK (origin_type IN ('ALGORITHM', 'SALES_CATALOG_SEARCH', 'ENGINEER_SUGGESTED')),
  algorithm_recommended TINYINT(1) NOT NULL DEFAULT false,
  fit_status VARCHAR(32) NOT NULL CHECK (fit_status IN ('PASS', 'WARN', 'ENGINEERING_CONFIRMATION_REQUIRED', 'REJECT')),
  score DECIMAL(14,6),
  required_capacity_tph DECIMAL(16,4),
  effective_capacity_per_unit_tph DECIMAL(16,4),
  default_quantity_total integer CHECK (default_quantity_total IS NULL OR default_quantity_total > 0),
  default_quantity_duty integer CHECK (default_quantity_duty IS NULL OR default_quantity_duty >= 0),
  default_quantity_standby integer CHECK (default_quantity_standby IS NULL OR default_quantity_standby >= 0),
  selection_reason VARCHAR(2000) NOT NULL,
  warnings JSON NOT NULL DEFAULT (JSON_ARRAY()),
  UNIQUE (proposal_revision_id, node_id, spec_version_id),
  UNIQUE (proposal_revision_id, node_id, id),
  CONSTRAINT fk_sales_equipment_option_node FOREIGN KEY (proposal_revision_id, node_id) REFERENCES sales_proposal_node(proposal_revision_id, id) ON DELETE CASCADE,
  CONSTRAINT fk_sales_equipment_option_spec FOREIGN KEY (spec_version_id) REFERENCES equipment_equipment_spec_version(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE sales_equipment_selection (
  id BINARY(16) PRIMARY KEY,
  proposal_revision_id BINARY(16) NOT NULL,
  node_id BINARY(16) NOT NULL,
  selection_group_code VARCHAR(64) NOT NULL DEFAULT 'PRIMARY',
  selected_option_id BINARY(16) NOT NULL,
  quantity_total integer NOT NULL CHECK (quantity_total > 0),
  quantity_duty integer NOT NULL CHECK (quantity_duty >= 0),
  quantity_standby integer NOT NULL CHECK (quantity_standby >= 0),
  sales_override_reason VARCHAR(2000),
  engineering_confirmation_required TINYINT(1) NOT NULL DEFAULT false,
  updated_by BINARY(16) NOT NULL,
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE (proposal_revision_id, node_id, selection_group_code),
  CHECK (quantity_duty + quantity_standby <= quantity_total),
  CONSTRAINT fk_sales_equipment_selection_node FOREIGN KEY (proposal_revision_id, node_id) REFERENCES sales_proposal_node(proposal_revision_id, id) ON DELETE CASCADE,
  CONSTRAINT fk_sales_equipment_selection_option FOREIGN KEY (proposal_revision_id, node_id, selected_option_id) REFERENCES sales_equipment_option(proposal_revision_id, node_id, id),
  CONSTRAINT fk_sales_equipment_selection_actor FOREIGN KEY (updated_by) REFERENCES identity_external_subject(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE sales_customer_handout (
  id BINARY(16) PRIMARY KEY,
  handout_number VARCHAR(64) NOT NULL UNIQUE,
  proposal_revision_id BINARY(16) NOT NULL,
  handout_type VARCHAR(32) NOT NULL DEFAULT 'PRELIMINARY' CHECK (handout_type IN ('PRELIMINARY')),
  locale VARCHAR(16) NOT NULL,
  status VARCHAR(32) NOT NULL CHECK (status IN ('GENERATING', 'PENDING_REVIEW', 'APPROVED_FOR_DELIVERY', 'REJECTED', 'FAILED', 'SUPERSEDED')),
  time_zone VARCHAR(64) NOT NULL DEFAULT 'UTC',
  manifest_schema_version integer NOT NULL,
  manifest JSON NOT NULL,
  manifest_checksum VARCHAR(128) NOT NULL,
  disclaimer_version VARCHAR(64) NOT NULL,
  generated_by BINARY(16) NOT NULL,
  generated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  CONSTRAINT fk_sales_handout_revision FOREIGN KEY (proposal_revision_id) REFERENCES sales_proposal_revision(id),
  CONSTRAINT fk_sales_handout_generator FOREIGN KEY (generated_by) REFERENCES identity_external_subject(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE sales_customer_handout_file (
  id BINARY(16) PRIMARY KEY,
  customer_handout_id BINARY(16) NOT NULL,
  format VARCHAR(32) NOT NULL CHECK (format IN ('PDF', 'DOCX')),
  storage_uri VARCHAR(1000) NOT NULL,
  file_name VARCHAR(255) NOT NULL,
  content_type VARCHAR(128) NOT NULL,
  checksum VARCHAR(128) NOT NULL,
  size_bytes bigint NOT NULL CHECK (size_bytes >= 0),
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE (customer_handout_id, format),
  CONSTRAINT fk_sales_handout_file_handout FOREIGN KEY (customer_handout_id) REFERENCES sales_customer_handout(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE sales_customer_handout_review (
  id BINARY(16) PRIMARY KEY,
  customer_handout_id BINARY(16) NOT NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED')),
  active_handout_id BINARY(16)
    GENERATED ALWAYS AS (CASE WHEN status = 'PENDING' THEN customer_handout_id ELSE NULL END) STORED,
  requested_by BINARY(16) NOT NULL,
  requested_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  assigned_reviewer_id BINARY(16),
  reviewer_id BINARY(16),
  reviewed_at DATETIME(6),
  decision_reason VARCHAR(2000),
  reviewed_manifest_checksum VARCHAR(128),
  UNIQUE KEY uq_sales_handout_active_review (active_handout_id),
  CONSTRAINT fk_sales_handout_review_handout FOREIGN KEY (customer_handout_id) REFERENCES sales_customer_handout(id),
  CONSTRAINT fk_sales_handout_review_requester FOREIGN KEY (requested_by) REFERENCES identity_external_subject(id),
  CONSTRAINT fk_sales_handout_review_assignee FOREIGN KEY (assigned_reviewer_id) REFERENCES identity_external_subject(id),
  CONSTRAINT fk_sales_handout_review_reviewer FOREIGN KEY (reviewer_id) REFERENCES identity_external_subject(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE eng_solution (
  id BINARY(16) PRIMARY KEY,
  solution_number VARCHAR(255) NOT NULL UNIQUE,
  project_id BINARY(16) NOT NULL,
  sales_proposal_revision_id BINARY(16) NOT NULL UNIQUE,
  selected_by BINARY(16) NOT NULL,
  selected_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  sales_note VARCHAR(255),
  status VARCHAR(255) NOT NULL DEFAULT 'ENGINEERING_DRAFT',
  CONSTRAINT fk_053 FOREIGN KEY (project_id) REFERENCES project_project(id),
  CONSTRAINT fk_055 FOREIGN KEY (selected_by) REFERENCES identity_external_subject(id),
  CONSTRAINT fk_eng_solution_sales_revision FOREIGN KEY (sales_proposal_revision_id) REFERENCES sales_proposal_revision(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE sales_engineering_handoff (
  id BINARY(16) PRIMARY KEY,
  proposal_revision_id BINARY(16) NOT NULL UNIQUE,
  solution_id BINARY(16) NOT NULL UNIQUE,
  status VARCHAR(32) NOT NULL DEFAULT 'SUBMITTED' CHECK (status IN ('SUBMITTED', 'ACCEPTED', 'NEEDS_INFORMATION', 'CLOSED')),
  handoff_manifest JSON NOT NULL,
  submitted_by BINARY(16) NOT NULL,
  submitted_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  accepted_by BINARY(16),
  accepted_at DATETIME(6),
  engineer_note VARCHAR(4000),
  CONSTRAINT fk_sales_handoff_revision FOREIGN KEY (proposal_revision_id) REFERENCES sales_proposal_revision(id),
  CONSTRAINT fk_sales_handoff_solution FOREIGN KEY (solution_id) REFERENCES eng_solution(id),
  CONSTRAINT fk_sales_handoff_submitter FOREIGN KEY (submitted_by) REFERENCES identity_external_subject(id),
  CONSTRAINT fk_sales_handoff_acceptor FOREIGN KEY (accepted_by) REFERENCES identity_external_subject(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE eng_solution_revision (
  id BINARY(16) PRIMARY KEY,
  solution_id BINARY(16) NOT NULL,
  revision_no integer NOT NULL CHECK (revision_no > 0),
  based_on_revision_id BINARY(16),
  status VARCHAR(255) NOT NULL CHECK (status IN ('ENGINEERING_DRAFT', 'VALIDATING', 'REVIEW_REQUIRED', 'APPROVED', 'RELEASED', 'SUPERSEDED', 'WITHDRAWN')),
  title VARCHAR(255) NOT NULL,
  summary VARCHAR(255),
  assumptions JSON NOT NULL DEFAULT (JSON_ARRAY()),
  risks JSON NOT NULL DEFAULT (JSON_ARRAY()),
  created_by BINARY(16) NOT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  row_version integer NOT NULL DEFAULT 1,
  UNIQUE (solution_id, revision_no),
  CONSTRAINT fk_056 FOREIGN KEY (solution_id) REFERENCES eng_solution(id),
  CONSTRAINT fk_057 FOREIGN KEY (based_on_revision_id) REFERENCES eng_solution_revision(id),
  CONSTRAINT fk_058 FOREIGN KEY (created_by) REFERENCES identity_external_subject(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE eng_revision_node (
  id BINARY(16) PRIMARY KEY,
  revision_id BINARY(16) NOT NULL,
  node_code VARCHAR(255) NOT NULL,
  operation_type_id BINARY(16) NOT NULL,
  purpose_code VARCHAR(255),
  parameters JSON NOT NULL DEFAULT (JSON_OBJECT()),
  narrative VARCHAR(255) NOT NULL DEFAULT '',
  design_dry_tph DECIMAL(16,4),
  design_water_m3h DECIMAL(16,4),
  x DECIMAL(12,3),
  y DECIMAL(12,3),
  width DECIMAL(12,3),
  height DECIMAL(12,3),
  origin_type VARCHAR(255) NOT NULL DEFAULT 'ALGORITHM',
  origin_ref VARCHAR(255),
  UNIQUE (revision_id, node_code),
  UNIQUE (revision_id, id),
  CONSTRAINT fk_059 FOREIGN KEY (revision_id) REFERENCES eng_solution_revision(id) ON DELETE CASCADE,
  CONSTRAINT fk_060 FOREIGN KEY (operation_type_id) REFERENCES md_operation_type(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE eng_revision_edge (
  id BINARY(16) PRIMARY KEY,
  revision_id BINARY(16) NOT NULL,
  from_node_id BINARY(16) NOT NULL,
  to_node_id BINARY(16) NOT NULL,
  from_port VARCHAR(255) NOT NULL,
  to_port VARCHAR(255) NOT NULL,
  stream_role VARCHAR(255) NOT NULL,
  dry_tph DECIMAL(16,4),
  water_m3h DECIMAL(16,4),
  solids_pct DECIMAL(7,3) CHECK (solids_pct IS NULL OR solids_pct BETWEEN 0 AND 100),
  p80_mm DECIMAL(14,4),
  top_size_mm DECIMAL(14,4),
  recycle_flag TINYINT(1) NOT NULL DEFAULT false,
  properties JSON NOT NULL DEFAULT (JSON_OBJECT()),
  origin_type VARCHAR(255) NOT NULL DEFAULT 'ALGORITHM',
  origin_ref VARCHAR(255),
  CONSTRAINT fk_061 FOREIGN KEY (revision_id) REFERENCES eng_solution_revision(id) ON DELETE CASCADE,
  CONSTRAINT fk_062 FOREIGN KEY (revision_id, from_node_id)
    REFERENCES eng_revision_node(revision_id, id),
  CONSTRAINT fk_063 FOREIGN KEY (revision_id, to_node_id)
    REFERENCES eng_revision_node(revision_id, id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE eng_revision_equipment_selection (
  id BINARY(16) PRIMARY KEY,
  revision_id BINARY(16) NOT NULL,
  node_id BINARY(16) NOT NULL,
  spec_version_id BINARY(16) NOT NULL,
  quantity_total integer NOT NULL CHECK (quantity_total > 0),
  quantity_duty integer NOT NULL CHECK (quantity_duty >= 0),
  quantity_standby integer NOT NULL CHECK (quantity_standby >= 0),
  required_capacity_tph DECIMAL(16,4),
  effective_capacity_per_unit_tph DECIMAL(16,4),
  capacity_margin_pct DECIMAL(9,4),
  utilization_pct DECIMAL(7,3),
  selection_reason VARCHAR(255) NOT NULL,
  accessories JSON NOT NULL DEFAULT (JSON_ARRAY()),
  origin_type VARCHAR(255) NOT NULL DEFAULT 'ALGORITHM',
  origin_ref VARCHAR(255),
  override_reason VARCHAR(255),
  CHECK (quantity_duty + quantity_standby <= quantity_total),
  CONSTRAINT fk_064 FOREIGN KEY (revision_id) REFERENCES eng_solution_revision(id) ON DELETE CASCADE,
  CONSTRAINT fk_065 FOREIGN KEY (revision_id, node_id)
    REFERENCES eng_revision_node(revision_id, id) ON DELETE CASCADE,
  CONSTRAINT fk_066 FOREIGN KEY (spec_version_id) REFERENCES equipment_equipment_spec_version(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE eng_revision_validation_issue (
  id BINARY(16) PRIMARY KEY,
  revision_id BINARY(16) NOT NULL,
  severity VARCHAR(16) NOT NULL,
  issue_code VARCHAR(255) NOT NULL,
  rule_code VARCHAR(255),
  entity_type VARCHAR(255),
  entity_id BINARY(16),
  message VARCHAR(255) NOT NULL,
  evidence JSON NOT NULL DEFAULT (JSON_OBJECT()),
  resolution_status VARCHAR(255) NOT NULL DEFAULT 'OPEN',
  override_reason VARCHAR(255),
  overridden_by BINARY(16),
  overridden_at DATETIME(6),
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  CONSTRAINT fk_067 FOREIGN KEY (revision_id) REFERENCES eng_solution_revision(id) ON DELETE CASCADE,
  CONSTRAINT fk_068 FOREIGN KEY (overridden_by) REFERENCES identity_external_subject(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE eng_review_request (
  id BINARY(16) PRIMARY KEY,
  revision_id BINARY(16) NOT NULL,
  status VARCHAR(255) NOT NULL CHECK (status IN ('OPEN', 'APPROVED', 'CHANGES_REQUESTED', 'CANCELLED')),
  open_revision_id BINARY(16)
    GENERATED ALWAYS AS (CASE WHEN status = 'OPEN' THEN revision_id ELSE NULL END) STORED,
  submitted_by BINARY(16) NOT NULL,
  submitted_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  assigned_reviewer_id BINARY(16),
  closed_at DATETIME(6),
  UNIQUE KEY uq_revision_one_open_review (open_revision_id),
  CONSTRAINT fk_069 FOREIGN KEY (revision_id) REFERENCES eng_solution_revision(id),
  CONSTRAINT fk_070 FOREIGN KEY (submitted_by) REFERENCES identity_external_subject(id),
  CONSTRAINT fk_071 FOREIGN KEY (assigned_reviewer_id) REFERENCES identity_external_subject(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE eng_approval_record (
  id BINARY(16) PRIMARY KEY,
  review_request_id BINARY(16) NOT NULL,
  reviewer_id BINARY(16) NOT NULL,
  decision VARCHAR(24) NOT NULL,
  comment VARCHAR(255),
  decided_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  CONSTRAINT fk_072 FOREIGN KEY (review_request_id) REFERENCES eng_review_request(id),
  CONSTRAINT fk_073 FOREIGN KEY (reviewer_id) REFERENCES identity_external_subject(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE eng_release_package (
  id BINARY(16) PRIMARY KEY,
  release_number VARCHAR(255) NOT NULL UNIQUE,
  revision_id BINARY(16) NOT NULL UNIQUE,
  status VARCHAR(255) NOT NULL CHECK (status IN ('GENERATING', 'RELEASED', 'SUPERSEDED', 'WITHDRAWN')),
  manifest_schema_version integer NOT NULL,
  manifest JSON NOT NULL,
  manifest_checksum VARCHAR(255) NOT NULL,
  published_by BINARY(16) NOT NULL,
  published_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  supersedes_release_id BINARY(16),
  withdrawn_reason VARCHAR(255),
  CONSTRAINT fk_074 FOREIGN KEY (revision_id) REFERENCES eng_solution_revision(id),
  CONSTRAINT fk_075 FOREIGN KEY (published_by) REFERENCES identity_external_subject(id),
  CONSTRAINT fk_076 FOREIGN KEY (supersedes_release_id) REFERENCES eng_release_package(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE eng_release_file (
  id BINARY(16) PRIMARY KEY,
  release_package_id BINARY(16) NOT NULL,
  format VARCHAR(255) NOT NULL CHECK (format IN ('PDF', 'DOCX')),
  storage_uri VARCHAR(255) NOT NULL,
  file_name VARCHAR(255) NOT NULL,
  content_type VARCHAR(255) NOT NULL,
  checksum VARCHAR(255) NOT NULL,
  size_bytes bigint NOT NULL CHECK (size_bytes >= 0),
  generated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE (release_package_id, format),
  CONSTRAINT fk_077 FOREIGN KEY (release_package_id) REFERENCES eng_release_package(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE gov_data_source (
  id BINARY(16) PRIMARY KEY,
  source_type VARCHAR(255) NOT NULL,
  source_name VARCHAR(255) NOT NULL,
  source_date date,
  reliability_level VARCHAR(255),
  owner_subject_id BINARY(16),
  metadata JSON NOT NULL DEFAULT (JSON_OBJECT()),
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  CONSTRAINT fk_078 FOREIGN KEY (owner_subject_id) REFERENCES identity_external_subject(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE gov_source_document (
  id BINARY(16) PRIMARY KEY,
  data_source_id BINARY(16),
  project_id BINARY(16),
  historical_case_id BINARY(16),
  storage_uri VARCHAR(255) NOT NULL,
  original_filename VARCHAR(255) NOT NULL,
  document_type VARCHAR(255) NOT NULL,
  content_type VARCHAR(255) NOT NULL,
  checksum VARCHAR(255) NOT NULL,
  size_bytes bigint NOT NULL CHECK (size_bytes >= 0),
  language_code VARCHAR(255),
  classification VARCHAR(255) NOT NULL DEFAULT 'INTERNAL',
  uploaded_by BINARY(16) NOT NULL,
  uploaded_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE (checksum, size_bytes),
  CONSTRAINT fk_079 FOREIGN KEY (data_source_id) REFERENCES gov_data_source(id),
  CONSTRAINT fk_080 FOREIGN KEY (project_id) REFERENCES project_project(id),
  CONSTRAINT fk_081 FOREIGN KEY (historical_case_id) REFERENCES case_historical_case(id),
  CONSTRAINT fk_082 FOREIGN KEY (uploaded_by) REFERENCES identity_external_subject(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

ALTER TABLE equipment_equipment_spec_version
  ADD CONSTRAINT fk_equipment_spec_source_document
  FOREIGN KEY (source_document_id) REFERENCES gov_source_document(id);

CREATE TABLE gov_extracted_fact (
  id BINARY(16) PRIMARY KEY,
  source_document_id BINARY(16) NOT NULL,
  page_no integer,
  source_locator JSON NOT NULL DEFAULT (JSON_OBJECT()),
  entity_type VARCHAR(255) NOT NULL,
  field_path VARCHAR(255) NOT NULL,
  original_text VARCHAR(255),
  original_value JSON,
  proposed_value JSON,
  original_unit VARCHAR(255),
  normalized_unit VARCHAR(255),
  extraction_method VARCHAR(255) NOT NULL,
  extractor_version VARCHAR(255),
  confidence DECIMAL(6,5) CHECK (confidence IS NULL OR confidence BETWEEN 0 AND 1),
  review_status VARCHAR(255) NOT NULL DEFAULT 'PENDING',
  reviewed_by BINARY(16),
  reviewed_at DATETIME(6),
  published_entity_type VARCHAR(255),
  published_entity_id BINARY(16),
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  CONSTRAINT fk_083 FOREIGN KEY (source_document_id) REFERENCES gov_source_document(id) ON DELETE CASCADE,
  CONSTRAINT fk_084 FOREIGN KEY (reviewed_by) REFERENCES identity_external_subject(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE gov_data_change_request (
  id BINARY(16) PRIMARY KEY,
  change_number VARCHAR(255) NOT NULL UNIQUE,
  change_type VARCHAR(255) NOT NULL,
  entity_type VARCHAR(255) NOT NULL,
  entity_id BINARY(16),
  reason VARCHAR(255) NOT NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'DRAFT',
  source_document_id BINARY(16),
  submitted_by BINARY(16),
  submitted_at DATETIME(6),
  approved_by BINARY(16),
  approved_at DATETIME(6),
  published_by BINARY(16),
  published_at DATETIME(6),
  created_by BINARY(16) NOT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  CONSTRAINT fk_085 FOREIGN KEY (source_document_id) REFERENCES gov_source_document(id),
  CONSTRAINT fk_086 FOREIGN KEY (submitted_by) REFERENCES identity_external_subject(id),
  CONSTRAINT fk_087 FOREIGN KEY (approved_by) REFERENCES identity_external_subject(id),
  CONSTRAINT fk_088 FOREIGN KEY (published_by) REFERENCES identity_external_subject(id),
  CONSTRAINT fk_089 FOREIGN KEY (created_by) REFERENCES identity_external_subject(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE gov_data_change_item (
  id BINARY(16) PRIMARY KEY,
  change_request_id BINARY(16) NOT NULL,
  field_path VARCHAR(255) NOT NULL,
  old_value JSON,
  proposed_value JSON,
  original_unit VARCHAR(255),
  normalized_unit VARCHAR(255),
  confidence DECIMAL(6,5),
  validation_result JSON NOT NULL DEFAULT (JSON_OBJECT()),
  source_fact_id BINARY(16),
  CONSTRAINT fk_090 FOREIGN KEY (change_request_id) REFERENCES gov_data_change_request(id) ON DELETE CASCADE,
  CONSTRAINT fk_091 FOREIGN KEY (source_fact_id) REFERENCES gov_extracted_fact(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE gov_data_quality_issue (
  id BINARY(16) PRIMARY KEY,
  entity_type VARCHAR(255) NOT NULL,
  entity_id BINARY(16) NOT NULL,
  issue_type VARCHAR(255) NOT NULL,
  severity VARCHAR(16) NOT NULL,
  message VARCHAR(255) NOT NULL,
  detected_by VARCHAR(255) NOT NULL,
  detected_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  resolution_status VARCHAR(255) NOT NULL DEFAULT 'OPEN',
  resolved_by BINARY(16),
  resolved_at DATETIME(6),
  resolution_note VARCHAR(255),
  CONSTRAINT fk_092 FOREIGN KEY (resolved_by) REFERENCES identity_external_subject(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE gov_freshness_policy (
  entity_type VARCHAR(255) PRIMARY KEY,
  review_interval_days integer NOT NULL CHECK (review_interval_days > 0),
  stale_effect VARCHAR(255) NOT NULL CHECK (stale_effect IN ('INFO', 'WARN', 'BLOCK_RECOMMENDATION')),
  active TINYINT(1) NOT NULL DEFAULT true
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE gov_data_review_schedule (
  id BINARY(16) PRIMARY KEY,
  entity_type VARCHAR(255) NOT NULL,
  entity_id BINARY(16) NOT NULL,
  owner_subject_id BINARY(16),
  last_verified_at DATETIME(6),
  next_review_at DATETIME(6) NOT NULL,
  status VARCHAR(255) NOT NULL DEFAULT 'SCHEDULED',
  UNIQUE (entity_type, entity_id),
  CONSTRAINT fk_093 FOREIGN KEY (owner_subject_id) REFERENCES identity_external_subject(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE platform_outbox_event (
  id BINARY(16) PRIMARY KEY,
  event_type VARCHAR(255) NOT NULL,
  schema_version integer NOT NULL DEFAULT 1,
  aggregate_type VARCHAR(255) NOT NULL,
  aggregate_id BINARY(16) NOT NULL,
  correlation_id BINARY(16),
  causation_id BINARY(16),
  payload JSON NOT NULL,
  occurred_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  published_at DATETIME(6),
  unpublished_at DATETIME(6)
    GENERATED ALWAYS AS (CASE WHEN published_at IS NULL THEN occurred_at ELSE NULL END) STORED,
  publish_attempts integer NOT NULL DEFAULT 0,
  last_error VARCHAR(255)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE INDEX ix_outbox_unpublished ON platform_outbox_event(unpublished_at);

CREATE TABLE platform_job_run (
  id BINARY(16) PRIMARY KEY,
  job_type VARCHAR(255) NOT NULL,
  idempotency_key VARCHAR(255) NOT NULL,
  status VARCHAR(16) NOT NULL DEFAULT 'QUEUED',
  progress_pct DECIMAL(7,3) NOT NULL DEFAULT 0 CHECK (progress_pct BETWEEN 0 AND 100),
  stage VARCHAR(255),
  payload JSON NOT NULL DEFAULT (JSON_OBJECT()),
  result JSON,
  error_code VARCHAR(255),
  error_detail JSON,
  attempt integer NOT NULL DEFAULT 0,
  queued_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  started_at DATETIME(6),
  heartbeat_at DATETIME(6),
  completed_at DATETIME(6),
  UNIQUE (job_type, idempotency_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE platform_idempotency_record (
  id BINARY(16) PRIMARY KEY,
  subject_id BINARY(16) NOT NULL,
  route_key VARCHAR(255) NOT NULL,
  idempotency_key VARCHAR(255) NOT NULL,
  request_hash VARCHAR(255) NOT NULL,
  response_status integer,
  response_body JSON,
  resource_type VARCHAR(255),
  resource_id BINARY(16),
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  expires_at DATETIME(6) NOT NULL,
  UNIQUE (subject_id, route_key, idempotency_key),
  CONSTRAINT fk_094 FOREIGN KEY (subject_id) REFERENCES identity_external_subject(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE platform_audit_log (
  id BINARY(16) PRIMARY KEY,
  actor_subject_id BINARY(16),
  actor_type VARCHAR(255) NOT NULL,
  action VARCHAR(255) NOT NULL,
  resource_type VARCHAR(255) NOT NULL,
  resource_id VARCHAR(255) NOT NULL,
  project_id BINARY(16),
  reason VARCHAR(255),
  before_summary JSON,
  after_summary JSON,
  trace_id VARCHAR(255),
  ip_address VARCHAR(45),
  user_agent VARCHAR(255),
  occurred_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  CONSTRAINT fk_095 FOREIGN KEY (actor_subject_id) REFERENCES identity_external_subject(id),
  CONSTRAINT fk_096 FOREIGN KEY (project_id) REFERENCES project_project(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE platform_llm_run (
  id BINARY(16) PRIMARY KEY,
  project_id BINARY(16),
  purpose VARCHAR(64) NOT NULL CHECK (purpose IN ('DOCUMENT_EXTRACTION', 'FIELD_MAPPING', 'TRANSLATION_DRAFT', 'NARRATIVE_DRAFT', 'CANDIDATE_SUGGESTION')),
  provider VARCHAR(128) NOT NULL,
  model_id VARCHAR(255) NOT NULL,
  prompt_template_code VARCHAR(128) NOT NULL,
  prompt_template_version VARCHAR(64) NOT NULL,
  input_checksum VARCHAR(128) NOT NULL,
  input_summary JSON NOT NULL DEFAULT (JSON_OBJECT()),
  output_payload JSON,
  output_storage_uri VARCHAR(1000),
  status VARCHAR(32) NOT NULL CHECK (status IN ('QUEUED', 'RUNNING', 'SUCCEEDED', 'FAILED', 'BLOCKED_BY_POLICY', 'CANCELLED')),
  input_tokens bigint CHECK (input_tokens IS NULL OR input_tokens >= 0),
  output_tokens bigint CHECK (output_tokens IS NULL OR output_tokens >= 0),
  estimated_cost DECIMAL(18,8) CHECK (estimated_cost IS NULL OR estimated_cost >= 0),
  cost_currency CHAR(3),
  requested_by BINARY(16) NOT NULL,
  requested_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  started_at DATETIME(6),
  completed_at DATETIME(6),
  human_disposition VARCHAR(32) CHECK (human_disposition IS NULL OR human_disposition IN ('ACCEPTED', 'MODIFIED', 'REJECTED')),
  disposed_by BINARY(16),
  disposed_at DATETIME(6),
  CONSTRAINT fk_platform_llm_project FOREIGN KEY (project_id) REFERENCES project_project(id),
  CONSTRAINT fk_platform_llm_requester FOREIGN KEY (requested_by) REFERENCES identity_external_subject(id),
  CONSTRAINT fk_platform_llm_disposer FOREIGN KEY (disposed_by) REFERENCES identity_external_subject(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE platform_localized_text (
  id BINARY(16) PRIMARY KEY,
  resource_type VARCHAR(128) NOT NULL,
  resource_id BINARY(16) NOT NULL,
  field_path VARCHAR(255) NOT NULL,
  locale VARCHAR(16) NOT NULL,
  version_no integer NOT NULL CHECK (version_no > 0),
  text_value TEXT NOT NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'REVIEW_REQUIRED', 'PUBLISHED', 'SUPERSEDED')),
  published_resource_id BINARY(16)
    GENERATED ALWAYS AS (CASE WHEN status = 'PUBLISHED' THEN resource_id ELSE NULL END) STORED,
  published_resource_type VARCHAR(128)
    GENERATED ALWAYS AS (CASE WHEN status = 'PUBLISHED' THEN resource_type ELSE NULL END) STORED,
  published_field_path VARCHAR(255)
    GENERATED ALWAYS AS (CASE WHEN status = 'PUBLISHED' THEN field_path ELSE NULL END) STORED,
  published_locale VARCHAR(16)
    GENERATED ALWAYS AS (CASE WHEN status = 'PUBLISHED' THEN locale ELSE NULL END) STORED,
  source_locale VARCHAR(16),
  translation_method VARCHAR(32) NOT NULL CHECK (translation_method IN ('HUMAN', 'LLM_DRAFT', 'IMPORT')),
  llm_run_id BINARY(16),
  reviewed_by BINARY(16),
  reviewed_at DATETIME(6),
  created_by BINARY(16) NOT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE (resource_type, resource_id, field_path, locale, version_no),
  UNIQUE KEY uq_platform_localized_published (published_resource_type, published_resource_id, published_field_path, published_locale),
  CONSTRAINT fk_platform_localized_llm FOREIGN KEY (llm_run_id) REFERENCES platform_llm_run(id),
  CONSTRAINT fk_platform_localized_reviewer FOREIGN KEY (reviewed_by) REFERENCES identity_external_subject(id),
  CONSTRAINT fk_platform_localized_creator FOREIGN KEY (created_by) REFERENCES identity_external_subject(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE INDEX ix_requirement_project_status ON project_requirement_version(project_id, status, updated_at DESC);
CREATE INDEX ix_run_project_status ON rec_recommendation_run(project_id, status, requested_at DESC);
CREATE INDEX ix_revision_solution_status ON eng_solution_revision(solution_id, status, updated_at DESC);
CREATE INDEX ix_quality_status ON gov_data_quality_issue(resolution_status, severity, detected_at DESC);
CREATE INDEX ix_audit_resource ON platform_audit_log(resource_type, resource_id, occurred_at DESC);
CREATE INDEX ix_audit_project ON platform_audit_log(project_id, occurred_at DESC);
