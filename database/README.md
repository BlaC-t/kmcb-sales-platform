# MySQL 数据库交付说明

## 目标边界

- 部署目标是 121 服务器上的一个全新 MySQL database/schema。
- 已确认目标 schema 名：`kj_sale_platform`。本目录仍不通过脚本自动创建 schema。
- 本目录没有连接信息、密码，也不会自动连接 121。
- `001_initial_schema.sql` 不创建 database、不删除表、不清库，只在“当前已选中的 schema”中建表。
- `002_product_import_staging.sql` 增加工作簿、逻辑区域、原始列标题、候选记录、字段差异和质量问题 staging；它不导入 Excel，也不修改已发布设备规格。
- `prototype/` 保存 121 当前 `sp_*` 产品目录/导入原型及首批 110 条产品种子快照；它是迁移输入，不是目标模型的可重复初始化脚本。
- BMS 菜单/权限 SQL 不属于本目录，保存在 `integrations/bms/`，不得在 121 上执行。

## 建议执行顺序

1. DBA 在 121 上运行 `000_server_121_preflight.sql` 的只读查询，并保存结果。
2. 核对 MySQL 版本、字符集、排序规则、时区、`sql_mode`、`lower_case_table_names`、InnoDB 与 binlog/备份能力。
3. DBA 创建专用 schema 和最小权限应用账号；Electron 客户端不得获得该账号。
4. 在与 121 相同版本的临时空库执行设计 DDL，形成正式 migration 并通过评审。
5. 对现有 `sp_*` 的 379 条产品、来源文件、质量问题和导入记录形成迁移映射、数量/字段校验及回退方案；原始 110 条备份可用于回退核对。
6. 备份/变更窗口批准后，再由发布流程对 121 执行 migration；不得直接并行启用两套产品主数据。

## 当前原型与目标模型

| 范围 | 当前原型 | 目标模型 | 当前处理 |
|---|---|---|---|
| 产品目录 | `sp_equipment_product` | `equipment_model` / `equipment_spec_version` | 先设计迁移，不直接覆盖 |
| 文件与质量 | `sp_product_source_file` / `sp_equipment_quality_issue` | `gov_source_document` / `gov_data_quality_issue` | 保留来源与审核证据 |
| Excel 导入 | `sp_product_import_*` | `gov_import_*` | 新导入先预览和审核，再发布版本 |
| BMS 菜单权限 | BMS DEV `sys_permission` | BMS PROD `sys_permission` | 独立迁移包，不进入 121 |

## DBA 创建示例

下面只是建议值，不由设计脚本自动执行：

```sql
CREATE DATABASE `kj_sale_platform`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;

USE `kj_sale_platform`;
```

如果 preflight 表明 121 不支持 `utf8mb4_0900_ai_ci`，必须先确认兼容排序规则，再同步修改 migration；不能静默降级。

## ID 与连接约定

- 应用生成 UUIDv7；API 使用 UUID 字符串，MySQL 使用 `BINARY(16)`。
- 应用通过明确的字节转换函数读写 UUIDv7，不启用只为 UUIDv1 设计的 `UUID_TO_BIN(..., 1)` 交换模式。
- Node.js 使用 `mysql2` 连接池；所有连接设置 UTC。
- 业务 Project 由 Sales Platform 创建；不要求外部销售/CRM/报价项目 ID。
- Project、会谈和主体保存 IANA 时区标识；夏令时换算由应用 tzdata 完成。
- 只允许 API/Worker 服务账号访问，禁止 React/Electron 直连。
