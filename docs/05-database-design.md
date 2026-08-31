# 数据库设计

## 1. 原则

1. 121 服务器上的独立 MySQL database/schema 作为唯一可信工程数据源。
2. 规范化写模型与算法特征快照分离。
3. 关键实体“稳定身份 + 不可变版本”。
4. BMS 用户 ID 只作为受约束身份引用，不复制身份凭据；业务 Project 由 Sales Platform 自己创建。
5. 核心可计算字段使用强类型列；长尾属性才使用 MySQL `JSON`。
6. 所有数值明确单位；必要时同时保存原始值和标准化值。
7. 附件进对象存储，数据库保存校验和、元数据、权限和血缘。
8. 软删除只用于草稿；已发布版本用状态和有效期，不物理删除。
9. 非标准工作簿先进入 Import staging；原始单元格、格式化文本、标准值和来源位置并存，审核发布后才产生新设备规格版本。

## 2. 单 Schema 与表前缀

MySQL 中 `SCHEMA` 与 `DATABASE` 在本设计里视为同一命名空间。本系统只占用 121 服务器上的 `kj_sale_platform`，模块边界改用表前缀表达。

| 表前缀 | 内容 |
|---|---|
| `identity_` | BMS 外部主体、组织、角色和外部权限码到平台逻辑权限的映射 |
| `sales_` | 结构化企业展示、媒体库、四语言翻译/发布包、问卷、会谈、销售方案修订、设备备选、初步打印件和工程交接 |
| `project_` | 平台内建项目、需求、矿石、场地、物流、目标、输入快照和项目时区 |
| `md_` | 字典、同义词、单位、工艺类型、端口类型 |
| `equipment_` | 设备型号、规格版本、能力包络、性能观察 |
| `case_` | 历史案例、流程版本、节点、边、设备配置 |
| `rule_` | 规则集、规则、条件、动作、测试 |
| `rec_` | 运行、依赖、候选、评分、解释、淘汰项 |
| `eng_` | 工程方案、修订、流程副本、设备选择、审核、发布 |
| `gov_` | 来源、文档、提取事实、变更、质量、复核 |
| `platform_` | Outbox、任务、审计、幂等键、LLM 运行和本地化文本 |

## 3. ID 与时间

- API 内部 ID 使用标准 UUID 字符串；应用层生成 UUIDv7，数据库以 `BINARY(16)` 保存。UUIDv7 不使用 `UUID_TO_BIN(uuid, 1)` 的 UUIDv1 字节交换模式。
- 所有业务时间使用 `DATETIME(6)` 并统一保存 UTC；API 传 ISO 8601，界面按用户/项目时区显示。
- `Project.site_time_zone`、`Consultation.time_zone`、`ExternalSubject.preferred_time_zone` 保存 IANA 标识（如 `Asia/Tashkent`、`Europe/Kyiv`），不只保存固定 `+05:00` 偏移。
- BMS 外部主体 ID 组合唯一：`(source_system, external_subject_id)`；Project 不需要外部销售项目 ID。
- 人可读编号单独生成，例如 `SP-2026-000123`，不能当数据库主键。

## 4. 流程版本复用模型

DDL 采用通用 `case_flowsheet_version` 存历史/模板流程；销售现场方案使用 `sales_proposal_node/edge` 保存算法候选的只读拓扑副本和销售设备选择；工程修订使用 `eng_revision_*` 保存可深化的独立工作副本。这样：

- 历史案例发布版本不被工程项目修改；
- 算法候选、销售选择和工程修订可精确比较；
- 不在一张表中混入不同生命周期和权限；
- 发布时生成固定 manifest。

若实施时重复列维护成本高，可抽象共用图仓储，但不能牺牲生命周期隔离。

## 5. MySQL JSON 使用边界

适合 JSON：

- 不同矿种的长尾化验项目；
- 节点特定参数（同时由 operation parameter schema 校验）；
- 规则 DSL 的条件树；
- 报告 manifest 和算法诊断。

不适合 JSON：

- 状态、版本、外键、审核人、发布日期；
- 容量、重量、功率、粒度、数量等高频筛选字段；
- 节点/边关系；
- 权限和审计关键字段。

## 6. 索引策略

- 所有外键建 B-tree 索引。
- MySQL 没有带 `WHERE` 条件的部分索引。单一发布版本、单一开放审核等约束使用“条件生成列 + 唯一索引”；不满足条件时生成 `NULL`。
- 平台项目状态+更新时间、需求/推荐项目范围、任务队列状态建组合索引。
- JSON 列不能直接建立普通索引；仅把稳定、确有查询需求的标量路径投影为 generated column 后索引。
- MVP 使用结构化特征精确计算。将来如确有收益，接独立向量检索服务；不能假设 121 的 MySQL 版本/版本形态支持向量能力。
- 大审计表按月或季度分区需由真实规模触发，不提前复杂化。

## 7. 约束

- 百分比 0–100、数量非负、运行数+备用数≤总数。
- 边节点同属一个流程版本：边携带流程版本 ID，并通过 `(flowsheet_version_id, node_id)` 复合外键强制同图；MySQL 外键立即检查，不依赖 deferred constraint。
- 发布版本需要 `published_at/published_by`。
- 一个实体同一时刻最多一个 PUBLISHED 版本。
- 内容页面结构由 `sales_content_revision/block` 保存；四语言由 content/block translation 表保存，禁止复制四套页面结构。
- `sales_media_asset` 只保存对象存储 URI、checksum、尺寸和权利元数据；大文件不进入 MySQL BLOB。
- `sales_content_release` 冻结多语言页面/媒体 manifest；条件生成列 + 唯一键保证每个 collection/channel 只有一个 current release。
- 已被 release 引用的媒体不能物理删除，翻译变成 `STALE` 后不得进入新 release。
- 通用 `platform_localized_text` 继续服务工程说明等通用资源；网站式企业展示使用显式 content/block translation 表，避免两套写模型同时维护同一字段。
- `from_node_id != to_node_id` 默认成立；若某特殊模型允许自环，必须由工艺类型白名单放行。
- 输入快照、推荐依赖和发布 manifest 不允许更新。
- `CustomerHandout` 只有在存在 APPROVED 审核决定且 checksum 匹配时才能进入 `APPROVED_FOR_DELIVERY`。
- PDF/DOCX、locale、免责声明或 manifest 任一变化都需要新 handout 和新审核。

## 8. 多租户/项目隔离

MySQL 不提供本设计可依赖的通用行级安全策略。所有租户和项目隔离都由 API repository 查询条件、服务端授权策略与集成测试强制执行；附件签名 URL 和导出也必须校验项目权限。数据库账号只授予该专用 schema 的最小权限。

## 9. 数据保留

- 工程发布、审核、依赖和审计：按公司合规要求长期保留。
- 草稿：可配置归档，不直接硬删除有审计价值的内容。
- 临时提取文件：发布/拒绝后按策略清理，但保留 checksum 与决定记录。
- 客户要求删除时执行受控匿名化/撤权，不破坏法定审计链；具体期限待法务确认。

## 10. DDL

初始设计 DDL 见 `database/001_initial_schema.sql`，121 上线前只读检查见 `database/000_server_121_preflight.sql`。DDL 假定管理员已创建并选中专用 schema，不包含 `CREATE DATABASE`、`DROP` 或清库语句。它是评审附件，不等于已在 121 执行；进入实现前需拆分 migration、补充权限/种子字典，并在与 121 相同版本的临时 MySQL 验证。

产品 Excel 导入设计提出 `gov_import_batch/sheet/region/record/record_diff/issue` 与 `gov_mapping_profile` 等 staging 表，已形成独立设计 migration `database/002_product_import_staging.sql`。它仍须在 `docs/product-import/design.md` 获批、确认同型号/图号业务键并完成临时空库验证后才能执行。

121 当前已存在一套 `sp_*` 产品目录原型：首批 110 条的 SQL 快照见 `database/prototype/`，2026-08-28 批准导入后共有 379 条，执行回执见 `data/product-import/applied-import-2026-08-28.json`。该原型与目标 `equipment_* / gov_*` 版本化模型之间必须先形成显式数据迁移、数量/字段核对和回退方案；不能直接执行目标 DDL 后长期并行维护两套产品主数据。

## 11. 121 服务器基线

- 目标：MySQL 8.0.16+，并保持与 8.4 兼容；正式门槛以 preflight 返回的实际版本为准。
- 引擎：InnoDB；字符集：`utf8mb4`；排序规则建议 `utf8mb4_0900_ai_ci`，若 121 不支持则先由 DBA 确认替代值再生成 migration。
- 时区：数据库连接统一 UTC；应用展示时转换为用户时区。
- 不假设 121 已安装 MySQL named time zone tables；夏令时和历史时区规则由应用的 IANA tzdata 处理。
- 先检查 `sql_mode`、字符集、排序规则、时区、`lower_case_table_names`、binlog 与 InnoDB 设置，不在设计脚本里修改全局变量。
