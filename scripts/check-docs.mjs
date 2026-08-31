import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { join, resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');
const readme = readFileSync(join(root, 'README.md'), 'utf8');
const ddl = readFileSync(join(root, 'database/001_initial_schema.sql'), 'utf8');
const importDdl = readFileSync(join(root, 'database/002_product_import_staging.sql'), 'utf8');
const preflight = readFileSync(join(root, 'database/000_server_121_preflight.sql'), 'utf8');
const required = [
  'docs/sales-platform/design.md',
  'docs/content-management/design.md',
  'docs/bms-control-plane/design.md',
  'docs/product-import/design.md',
  'docs/16-sales-dashboard-customer-journey.md',
  ...Array.from({ length: 15 }, (_, index) => {
    const prefix = String(index + 1).padStart(2, '0');
    const names = [
      'product-requirements',
      'user-roles-and-workflows',
      'domain-model',
      'system-architecture',
      'database-design',
      'recommendation-engine',
      'api-and-events',
      'frontend-electron',
      'security-and-rbac',
      'data-governance',
      'observability-and-operations',
      'test-and-acceptance',
      'rollout-roadmap',
      'sales-deliverables',
      'open-questions',
    ];
    return `docs/${prefix}-${names[index]}.md`;
  }),
  'database/README.md',
  'database/000_server_121_preflight.sql',
  'database/001_initial_schema.sql',
  'database/002_product_import_staging.sql',
  'database/prototype/001_product_catalog_seed.sql',
  'database/prototype/003_product_import_workflow.sql',
  'database/prototype/README.md',
  'data/product-import/workbook-manifest.json',
  'data/product-import/catalog-preview-baseline.json',
  'data/product-import/applied-import-2026-08-28.json',
  'integrations/bms/README.md',
  'integrations/bms/001_dev_menu_permission_snapshot.sql',
  'integrations/bms/002_target_menu_permission_template.sql',
  'contracts/openapi.yaml',
  'contracts/events.asyncapi.yaml',
  'contracts/domain-types.ts',
];

const missing = required.filter((file) => !existsSync(join(root, file)));
if (missing.length) {
  throw new Error(`Missing required design files:\n${missing.join('\n')}`);
}

const markdownFiles = readdirSync(join(root, 'docs'), { recursive: true })
  .filter((name) => name.endsWith('.md'));
for (const file of markdownFiles) {
  const content = readFileSync(join(root, 'docs', file), 'utf8');
  if (!content.trim().startsWith('# ')) {
    throw new Error(`Markdown file must start with an H1: docs/${file}`);
  }
}

if (!readme.includes('设计评审门')) {
  throw new Error('README must preserve the design approval gate.');
}

const mysqlTableCount = [...ddl.matchAll(/^CREATE TABLE /gm)].length;
const mysqlEngineCount = [...ddl.matchAll(/ENGINE=InnoDB DEFAULT CHARSET=utf8mb4/g)].length;
if (mysqlTableCount !== 83 || mysqlEngineCount !== mysqlTableCount) {
  throw new Error(`MySQL baseline mismatch: ${mysqlTableCount} tables, ${mysqlEngineCount} InnoDB declarations.`);
}

const importTableCount = [...importDdl.matchAll(/^CREATE TABLE /gm)].length;
const importEngineCount = [...importDdl.matchAll(/ENGINE=InnoDB DEFAULT CHARSET=utf8mb4/g)].length;
if (importTableCount !== 7 || importEngineCount !== importTableCount) {
  throw new Error(`Product import migration mismatch: ${importTableCount} tables, ${importEngineCount} InnoDB declarations.`);
}

const executableImportDdl = importDdl.split('\n').filter((line) => !line.trimStart().startsWith('--')).join('\n');
for (const pattern of [/CREATE DATABASE/i, /^\s*DROP\b/im, /^\s*TRUNCATE\b/im, /^\s*INSERT\b/im, /^\s*UPDATE\b/im, /^\s*DELETE\b/im]) {
  if (pattern.test(executableImportDdl)) throw new Error(`Forbidden product import migration construct found: ${pattern}`);
}

const workbookManifest = JSON.parse(readFileSync(join(root, 'data/product-import/workbook-manifest.json'), 'utf8'));
const previewBaseline = JSON.parse(readFileSync(join(root, 'data/product-import/catalog-preview-baseline.json'), 'utf8'));
const appliedImport = JSON.parse(readFileSync(join(root, 'data/product-import/applied-import-2026-08-28.json'), 'utf8'));
if (workbookManifest.workbooks?.length !== 6) throw new Error('Workbook manifest must preserve all 6 source workbooks.');
const regionCount = workbookManifest.workbooks.reduce((total, workbook) => total + workbook.regionCount, 0);
if (regionCount !== 28) throw new Error(`Workbook manifest region mismatch: ${regionCount}.`);
if (previewBaseline.databaseWritePerformed !== false) throw new Error('Preview baseline must never claim a database write.');
if (appliedImport.result?.beforeProductCount !== 110 || appliedImport.result?.addedProductCount !== 269 || appliedImport.result?.afterProductCount !== 379) {
  throw new Error('Applied product import receipt counts do not reconcile.');
}
if (appliedImport.result?.duplicateIdentityGroupCount !== 0 || appliedImport.approval?.existingProductUpdatesAccepted !== 0) {
  throw new Error('Applied product import receipt must preserve the approved deduplication and no-update boundary.');
}

const bmsTargetTemplate = readFileSync(join(root, 'integrations/bms/002_target_menu_permission_template.sql'), 'utf8');
if (!bmsTargetTemplate.includes('__BMS_TARGET_SCHEMA__')) {
  throw new Error('BMS target transfer template must keep an explicit schema placeholder.');
}
if (/kj_sale_platform\s*\./i.test(bmsTargetTemplate)) {
  throw new Error('BMS target transfer template must not write Sales Platform tables.');
}

const prototypeSeed = readFileSync(join(root, 'database/prototype/001_product_catalog_seed.sql'), 'utf8');
const prototypeImport = readFileSync(join(root, 'database/prototype/003_product_import_workflow.sql'), 'utf8');
if (!prototypeSeed.includes('sp_equipment_product') || !prototypeSeed.includes('110')) {
  throw new Error('Current 121 product prototype snapshot is incomplete.');
}
if (!prototypeImport.includes('sp_product_import_batch') || !prototypeImport.includes('sp_product_column_schema')) {
  throw new Error('Current 121 import prototype snapshot is incomplete.');
}

const forbiddenDdl = [
  /CREATE DATABASE/i,
  /\bDROP\b/i,
  /\bTRUNCATE\b/i,
  /CREATE EXTENSION/i,
  /CREATE SCHEMA/i,
  /\bjsonb\b/i,
  /\btimestamptz\b/i,
  /::json/i,
];
for (const pattern of forbiddenDdl) {
  const executableDdl = ddl.split('\n').filter((line) => !line.trimStart().startsWith('--')).join('\n');
  if (pattern.test(executableDdl)) throw new Error(`Forbidden DDL construct found: ${pattern}`);
}

if (/\b(CREATE|ALTER|DROP|INSERT|UPDATE|DELETE|TRUNCATE)\b/i.test(
  preflight.split('\n').filter((line) => !line.trimStart().startsWith('--')).join('\n'),
)) {
  throw new Error('Server 121 preflight must remain read-only.');
}

console.log(`Design checks passed: ${required.length} required artifacts, ${markdownFiles.length} markdown documents, ${mysqlTableCount} baseline tables, ${importTableCount} import tables, ${regionCount} workbook regions.`);
