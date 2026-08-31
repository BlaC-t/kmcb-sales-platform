# 当前 121 产品目录原型快照

本目录保存此前为 BMS 产品数据中心原型形成的 `sp_*` SQL，现已从 BMS 仓库迁回 Sales Platform 仓库。它们用于追踪 121 产品目录的初始结构和首批 110 条产品记录，不是目标数据库模型的重复 migration。

2026-08-28 经确认执行增量导入后，121 当前原型目录为 379 条产品、6 个来源文件、4 个导入批次；原始 110 条保存在 `kj_sale_platform_backup_20260828_01`。执行结果以 `data/product-import/applied-import-2026-08-28.json` 为准。

## 文件

- `001_product_catalog_seed.sql`：现有 `sp_product_source_file`、`sp_equipment_product`、`sp_equipment_quality_issue` 结构和首批三份 Excel 的 110 条产品种子快照。
- `003_product_import_workflow.sql`：现有 `sp_product_import_batch`、动态原始列标题、型号属性和字段变化原型结构。

## 使用限制

- 两份脚本保留原始内容和历史目标说明，仅作为可追溯原型；不要把它们当作新环境初始化脚本重复执行。
- 目标版 `database/001_initial_schema.sql` 和 `database/002_product_import_staging.sql` 使用 `equipment_*`、`gov_*` 等版本化领域模型，与当前 `sp_*` 原型不是同一套表。
- 在 121 上部署目标模型前，必须先形成并评审 `sp_* → equipment_*/gov_*` 数据迁移与核对方案，避免产生两套互不一致的产品主数据。
- 本次原型导入已完成同版本临时 schema 验证、110 条记录备份和迁移后核对；未来目标模型迁移仍需单独验证、备份、审批和回退方案。
- BMS 菜单与权限不属于本目录，保存在 `integrations/bms/` 和 BMS 自身 DEV 数据库。
