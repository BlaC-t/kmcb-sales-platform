-- Sales Platform 在 BMS DEV 菜单管理中的动态路由配置
-- 目标：192.168.9.120 / kj_db_prod_test_20260814
-- 注意：业务数据仍位于 192.168.9.121 / kj_sale_platform；本脚本只写 BMS DEV 菜单/权限元数据。
-- 不修改前端 routes.ts。生产环境迁移应单独评审和执行，不得直接复用目标 schema。

START TRANSACTION;

INSERT INTO kj_db_prod_test_20260814.sys_permission
  (function_code, function_name, route_path, route_name, parent_code, hidden, no_keep_alive,
   icon_code, redirect_url, function_type, remark, stop_flag, insert_time, update_time, editor)
VALUES
  ('PMS023', '销售平台', '/salesPlatform', 'SalesPlatformAdmin', '0', 0, 0,
   'briefcase-4-line', '', 0, '销售平台 BMS 管理入口', 0, NOW(), NOW(), 'Codex-销售平台初始化'),

  ('PMS023001', '管理总览', 'overview', 'SalesPlatformOverview', 'PMS023', 0, 0,
   'dashboard-line', '/@/views/salesPlatform/overview/index.vue', 1, '', 0, NOW(), NOW(), 'Codex-销售平台初始化'),
  ('PMS023002', '内容与媒体', 'content', 'SalesPlatformContent', 'PMS023', 0, 0,
   'image-2-line', '/@/views/salesPlatform/content/index.vue', 1, '', 0, NOW(), NOW(), 'Codex-销售平台初始化'),
  ('PMS023003', '多语言翻译', 'translations', 'SalesPlatformTranslations', 'PMS023', 0, 0,
   'translate-2', '/@/views/salesPlatform/translations/index.vue', 1, '', 0, NOW(), NOW(), 'Codex-销售平台初始化'),
  ('PMS023004', '数据中心', 'data-center', 'SalesPlatformDataCenterMenu', 'PMS023', 0, 0,
   'database-2-line', '', 0, '', 0, NOW(), NOW(), 'Codex-销售平台初始化'),
  ('PMS023005', '审核与发布', 'review-publish', 'SalesPlatformReviewPublish', 'PMS023', 0, 0,
   'checkbox-circle-line', '/@/views/salesPlatform/reviewPublish/index.vue', 1, '', 0, NOW(), NOW(), 'Codex-销售平台初始化'),
  ('PMS023006', '项目与推荐记录', 'project-records', 'SalesPlatformProjectRecords', 'PMS023', 0, 0,
   'file-list-3-line', '/@/views/salesPlatform/projectRecords/index.vue', 1, '', 0, NOW(), NOW(), 'Codex-销售平台初始化'),
  ('PMS023007', '工程交接与方案状态', 'engineering-handoff', 'SalesPlatformEngineeringHandoff', 'PMS023', 0, 0,
   'git-merge-line', '/@/views/salesPlatform/engineeringHandoff/index.vue', 1, '', 0, NOW(), NOW(), 'Codex-销售平台初始化'),
  ('PMS023008', '权限', 'permissions', 'SalesPlatformPermissions', 'PMS023', 0, 0,
   'shield-user-line', '/@/views/salesPlatform/permissions/index.vue', 1, '', 0, NOW(), NOW(), 'Codex-销售平台初始化'),

  ('PMS023004001', '数据中心总览', 'overview', 'SalesPlatformDataCenter', 'PMS023004', 0, 0,
   'dashboard-3-line', '/@/views/salesPlatform/dataCenter/index.vue', 1, '', 0, NOW(), NOW(), 'Codex-销售平台初始化'),
  ('PMS023004002', '设备目录', 'equipment', 'SalesPlatformEquipmentCatalog', 'PMS023004', 0, 0,
   'settings-3-line', '/@/views/salesPlatform/dataCenter/equipment/index.vue', 1, '', 0, NOW(), NOW(), 'Codex-销售平台初始化'),
  ('PMS023004003', '历史案例', 'cases', 'SalesPlatformCaseLibrary', 'PMS023004', 0, 0,
   'archive-line', '/@/views/salesPlatform/dataCenter/cases/index.vue', 1, '', 0, NOW(), NOW(), 'Codex-销售平台初始化'),
  ('PMS023004004', '工艺与规则', 'process-rules', 'SalesPlatformProcessRules', 'PMS023004', 0, 0,
   'flow-chart', '/@/views/salesPlatform/dataCenter/processRules/index.vue', 1, '', 0, NOW(), NOW(), 'Codex-销售平台初始化'),
  ('PMS023004005', '字典与术语', 'dictionaries', 'SalesPlatformDictionaries', 'PMS023004', 0, 0,
   'book-2-line', '/@/views/salesPlatform/dataCenter/dictionaries/index.vue', 1, '', 0, NOW(), NOW(), 'Codex-销售平台初始化'),
  ('PMS023004006', '来源文档与导入', 'sources', 'SalesPlatformSources', 'PMS023004', 0, 0,
   'file-upload-line', '/@/views/salesPlatform/dataCenter/sources/index.vue', 1, '', 0, NOW(), NOW(), 'Codex-销售平台初始化'),
  ('PMS023004007', '数据质量与复核', 'quality', 'SalesPlatformDataQuality', 'PMS023004', 0, 0,
   'error-warning-line', '/@/views/salesPlatform/dataCenter/quality/index.vue', 1, '', 0, NOW(), NOW(), 'Codex-销售平台初始化')
ON DUPLICATE KEY UPDATE
  function_name=VALUES(function_name), route_path=VALUES(route_path), route_name=VALUES(route_name),
  parent_code=VALUES(parent_code), hidden=VALUES(hidden), no_keep_alive=VALUES(no_keep_alive),
  icon_code=VALUES(icon_code), redirect_url=VALUES(redirect_url), function_type=VALUES(function_type),
  remark=VALUES(remark), stop_flag=0, update_time=NOW(), editor=VALUES(editor);

INSERT INTO kj_db_prod_test_20260814.sys_permission
  (function_code, function_name, route_path, route_name, parent_code, hidden, no_keep_alive,
   icon_code, redirect_url, function_type, remark, stop_flag, insert_time, update_time, editor)
VALUES
  ('PMS023008001', '进入销售平台', '', '', 'PMS023008', 0, 0, '', '', 2, 'sales_platform.access', 0, NOW(), NOW(), 'Codex-销售平台初始化'),
  ('PMS023008002', '维护内容与多语言', '', '', 'PMS023008', 0, 0, '', '', 2, 'sales_platform.content.write', 0, NOW(), NOW(), 'Codex-销售平台初始化'),
  ('PMS023008003', '维护设备与规则数据', '', '', 'PMS023008', 0, 0, '', '', 2, 'sales_platform.data.write', 0, NOW(), NOW(), 'Codex-销售平台初始化'),
  ('PMS023008004', '处理数据质量问题', '', '', 'PMS023008', 0, 0, '', '', 2, 'sales_platform.data.review', 0, NOW(), NOW(), 'Codex-销售平台初始化'),
  ('PMS023008005', '审核客户初版方案', '', '', 'PMS023008', 0, 0, '', '', 2, 'sales_platform.proposal.review', 0, NOW(), NOW(), 'Codex-销售平台初始化'),
  ('PMS023008006', '发布内容数据与方案', '', '', 'PMS023008', 0, 0, '', '', 2, 'sales_platform.publish', 0, NOW(), NOW(), 'Codex-销售平台初始化')
ON DUPLICATE KEY UPDATE function_name=VALUES(function_name), parent_code=VALUES(parent_code),
  function_type=2, remark=VALUES(remark), stop_flag=0, update_time=NOW(), editor=VALUES(editor);

COMMIT;

SELECT function_code, function_name, route_name, route_path, parent_code, function_type
FROM kj_db_prod_test_20260814.sys_permission
WHERE function_code LIKE 'PMS023%'
ORDER BY function_code;
