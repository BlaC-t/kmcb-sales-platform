# Sales Platform（销售平台）

Customer Engagement, Mineral Process Recommendation & Engineering Handoff

这是一个面向销售、客户沟通、工艺流程工程师、数据管理员和审核人的销售平台设计项目。选矿工艺与设备推荐是平台的核心业务模块，而不是整个产品名称。销售通过“销售看板”完成企业展示、客户问诊、方案生成、设备选择和现场打印，再把完整记录交给工艺工程师深化。

```text
销售录入客户需求
  → 系统生成多个候选工艺及设备方案
  → 销售逐段比较多个设备并形成销售方案修订
  → 具备指定权限的审核人检查冻结版本
  → 打印初步流程图 + 设备列表给客户
  → 提交销售方案和会谈记录
  → 工艺流程工程师优化、细化和校核
  → 审核人批准并发布不可变版本
  → 销售获得工艺流程说明、分段设备选择和依据
```

## 当前状态

- 阶段：设计基线（Draft / In Review）
- 已包含：完整设计文档、数据库 DDL、OpenAPI、事件契约和 ADR
- 尚未包含：可运行的业务实现、已批准的工程规则、真实客户数据、生产集成
- 已保存：六份产品工作簿的文件指纹、逻辑区域、原始列标题和只读目录差异基线。
- 已执行：经确认后，121 的 `kj_sale_platform` 原型目录新增 269 个唯一型号，现有 110 条未覆盖；当前共 379 条、12 类产品、4 个导入批次和 5,403 条原始字段记录。执行回执见 `data/product-import/applied-import-2026-08-28.json`。
- 重要边界：Sales Platform 是 BMS/CRM 之外的独立系统。用户打开平台时使用 BMS 认证；BMS 后端承接认证与权限交互适配，平台领域数据和推荐逻辑保持独立。平台业务后端最终部署归属仍待确认。
- BMS 内规划独立的 `Sales Platform 管理中心` 作为内部控制面：提供内容、翻译、工程数据治理、审核与发布、项目/工程记录和权限页面；不设独立“审计与运行”菜单。BMS 不复制平台业务表，也不直接写 121 的 Sales Platform schema。
- 产品 Excel 导入采用多区域识别、版本化字段映射、字段级新增/更新/冲突对比和人工审核；陌生 XLSX 可进入手工映射兜底，但不能无审核直接更新正式产品库。

## 目录

```text
apps/
  api/                 Node.js/TypeScript API（待设计批准后实现）
  worker/              推荐、导入、质量检查后台任务（待实现）
  desktop/             React + Electron 桌面端占位（计划迁入独立前端仓库）
packages/
  domain/              共享领域模型（待实现）
  contracts/           API/事件生成物（待实现）
database/
  000_server_121_preflight.sql
  001_initial_schema.sql
  002_product_import_staging.sql
  prototype/            当前 121 `sp_*` 产品目录与导入原型快照
  README.md
data/product-import/
  workbook-manifest.json
  catalog-preview-baseline.json
  applied-import-2026-08-28.json
integrations/bms/
  001_dev_menu_permission_snapshot.sql
  002_target_menu_permission_template.sql
  README.md
contracts/
  openapi.yaml
  events.asyncapi.yaml
  domain-types.ts
docs/
  sales-platform/design.md
  content-management/design.md
  bms-control-plane/design.md
  product-import/design.md
  01-product-requirements.md ... 15-open-questions.md
  adr/
```

## 推荐阅读顺序

1. [主设计文档](docs/sales-platform/design.md)
2. [BMS 内管理控制面](docs/bms-control-plane/design.md)
3. [非标准产品 Excel 导入与差异发布](docs/product-import/design.md)
4. [多语言企业展示内容管理](docs/content-management/design.md)
5. [产品需求](docs/01-product-requirements.md)
6. [角色与工作流](docs/02-user-roles-and-workflows.md)
7. [领域模型](docs/03-domain-model.md)
8. [系统架构](docs/04-system-architecture.md)
9. [数据库设计](docs/05-database-design.md)
10. [推荐引擎](docs/06-recommendation-engine.md)
11. [API 与事件](docs/07-api-and-events.md)
12. [桌面端设计](docs/08-frontend-electron.md)
13. [安全与权限](docs/09-security-and-rbac.md)
14. [数据治理](docs/10-data-governance.md)
15. [测试验收](docs/12-test-and-acceptance.md)
16. [实施路线图](docs/13-rollout-roadmap.md)
17. [销售交付物](docs/14-sales-deliverables.md)
18. [待确认问题](docs/15-open-questions.md)
19. [销售看板与客户沟通完整旅程](docs/16-sales-dashboard-customer-journey.md)

## 核心技术决策

- TypeScript + Node.js；建议 NestJS + Fastify 作为 API 基座。
- Sales Platform 自己创建项目，不要求关联 BMS、CRM 或其它销售项目 ID。
- BMS 提供打开平台时的认证与权限来源；同时通过 BFF/Adapter 承载内部管理控制面。具体 token、组织范围和正式权限码仍需 BMS 负责人确认。
- BMS 管理端每个新增页面（含表格/列表页）都必须在菜单管理配置，由权限接口动态生成路由；禁止写入 `src/store/modules/routes.ts`、`src/router/index.ts` 或新增 legacy `inject*`，按钮权限精确匹配最终 `functionCode`。
- 121 服务器上的 `kj_sale_platform` 是 Sales Platform 规范化工程数据的唯一可信源；BMS 菜单/权限数据保留在 BMS DEV/PROD 数据库，不进入 121。模块以表前缀隔离，流程图采用有向多重图的节点/边关系表。
- 当前 121 `sp_*` 产品目录的初始 110 条种子 SQL 与后续 269 条导入回执均已归档；目标版 `equipment_* / gov_*` 上线前必须先完成现有 379 条原型数据的迁移与核对方案，不能并行维护两套产品主数据。
- Electron 只做薄桌面壳；Renderer 不直接访问数据库或 Node.js 高权限 API。
- Windows 与 macOS 在同一首发批次交付；React 功能复用，安装、签名、更新和本地文件能力分别适配。
- 企业展示采用结构化多语言 CMS：页面结构与四语言文本分离，图片进入对象存储媒体库，发布为不可变 ContentRelease；改字换图不需要重新发布 Electron 安装包。
- 推荐采用“硬约束规则 + 历史案例相似度 + 流程模块组合 + 设备能力校核 + 多目标评分”。
- 产品工作簿先拆分 Sheet/逻辑区域，再进行字段映射、原值/显示值/标准值保存、型号/图号身份匹配和字段级 diff；只有审核后的新规格版本可发布。
- Phase 1 加入受控 LLM 实验，用于文档提取、翻译/说明草稿和候选建议；任何工程事实仍需规则校核与人工审核。
- 自动推荐只产生候选版本；工程师编辑、审核和销售发布均版本化且可追溯。
- 算法候选、销售现场方案、工程修订和正式发布四层分离；客户初步打印件须由具备 `customer.handout.review` 权限的指定人员审核，且不可冒充正式方案。
- 客户输出首期覆盖中文、英语、俄语和乌克兰语，并支持 PDF 与 DOCX；所有持久化时间存 UTC，同时保存并使用 IANA 时区显示当地时间。
- 发布版本不可原地修改；需求变化或规则更新产生新分支/新修订。

## 设计评审门

进入实现前至少需要产品负责人、工艺负责人、销售代表、数据负责人和 BMS/身份集成人员共同确认：

1. BMS token 验证/交换、权限码映射和测试环境契约。
2. 第一批矿种、工艺段、设备类别和强制工程校核规则。
3. 工艺工程师修改权限、双人审核门槛和正式发布模板。
4. 历史资料的来源、保密等级、清洗责任和可用性。
5. MVP 的验收案例与“不允许系统自动决定”的安全边界。
6. Sales Platform 业务后端最终部署在独立服务还是其它受控运行环境。
7. 内容编辑、四语言审核、媒体权利审核和最终发布分别由谁负责，以及第一批网站图文资料何时提供。
8. BMS 管理中心页面编码、跳转路径、`functionCode`、BFF 归属与第一批上线页面（菜单名称与合并关系已确认）。
9. 同型号不同图号、参考重量/报价重量/运输重量和产品价格字段的正式业务定义。
