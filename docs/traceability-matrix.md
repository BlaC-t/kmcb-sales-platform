# 需求—设计—验收追踪矩阵

| 需求 | 设计位置 | 验收 |
|---|---|---|
| 销售输入矿石/产能/泥水/道路/基础设施 | PRD §3；Domain §5；OpenAPI RequirementPayload | Acceptance A/C |
| Sales Platform 独立于 BMS/CRM，并通过 BMS 认证 | ADR-0008；Architecture §3；Security §2 | BMS 认证与平台建项 E2E |
| BMS 内提供管理页面但不复制业务数据 | BMS Control Plane Design；ADR-0011；Architecture §3 | 菜单/权限/BFF/API/无双库 E2E |
| BMS 新页面/表格列表均由菜单管理配置，不写死路由 | BMS Control Plane §Constraints/§2；ADR-0011；Frontend §1 | 权限接口动态路由、菜单禁用、`functionCode` 精确匹配与 routes 静态检查 |
| 有权人员可查看全部业务事实，但不是全字段平铺 | BMS Control Plane §3；Security；Data Governance | 摘要/详情/受限原始视图和脱敏验收 |
| 内容、数据、审核与发布、项目/工程记录、权限可在 BMS 管理 | BMS Control Plane §2–7 | 分权、状态机、发布/回滚和故障门禁 E2E；审计在详情历史中追溯 |
| 平台自行创建 Project，不依赖外部销售项目 | ADR-0008；Domain Project；OpenAPI POST /projects | Project 无 externalProjectId 验收 |
| 展示公司、乌兹别克斯坦子公司、生产与产品能力 | Sales Dashboard §3；Frontend 销售看板；sales_content_* | 客户演示模式 E2E |
| 非开发人员改字换图并同步四语言 | Content Management Design；ADR-0010；sales_content/media/release_* | 内容编辑、STALE 翻译、媒体权利、发布/回滚 E2E |
| Web/Electron 内容更新不重新发安装包 | ContentRelease API；Frontend 缓存；manifest/ETag | 原子切换、断网/校验失败回退验收 |
| 引导式客户问诊并保留原话/单位/来源 | Sales Dashboard §4；sales_consultation/answer；OpenAPI SalesConsultation | 会谈完整性与版本追溯 |
| 利用历史案例与知识推荐流程 | Recommendation §2–3；DB case/knowledge schemas | 金标准 Top-K、硬约束 0 违规 |
| 推荐每个工艺段多个设备 | Domain 流程/配置；Recommendation Layer 4；EquipmentOption | 多设备比较与硬约束验收 |
| 销售选择/修改后保留记录 | Workflow 主流程；SalesProposalRevision；selection API | 销售修订差异 E2E |
| 打印流程图和设备列表给客户 | Sales Dashboard §6；CustomerHandout；generate-handout API | manifest/水印/重复打印验收 |
| 指定权限审核初步文件，不绑定职级 | ADR-0009；Workflow §5；Security RBAC；handout review API | 权限、非自审、checksum 和交付门禁 |
| 把会谈和销售方案交给工艺工程师 | Sales Dashboard §6.2；sales_engineering_handoff | 工程交接完整性 E2E |
| 工艺工程师优化细化 | Engineering revision；React Flow 工作台 | E2E A/D/F |
| 最终给销售流程说明和设备选择 | Sales Deliverables；Release API/manifest | Report acceptance |
| 数据持续更新 | Data Governance；Change Request tables | 版本变化 E |
| 任意 XLSX、多 Sheet、多产品可进入受控导入 | Product Import Design；ADR-0012 | 3 份真实工作簿、4 Sheet、9 region 金标准验收 |
| 导入后显示新增/更新/冲突及字段来源 | Product Import §7–8；BMS Control Plane | 状态汇总、字段 diff、单元格追溯和发布门禁 E2E |
| 专用数据维护权限 | Roles；Security；Data Governance | `sales_platform.data_maintain` 权限隔离 |
| JS 后端 | Architecture 技术基线 | 构建/架构约束测试 |
| React + Electron | Frontend/Electron | Electron 安全验收 |
| Windows 与 macOS 同批次 | Frontend §6；Rollout Phase 1/3 | 两平台安装、签名、更新和 E2E |
| 中文/英语/俄语/乌克兰语 + PDF/DOCX | Sales Deliverables §4；Frontend i18n；CustomerHandout | 四 locale、两格式、翻译缺失门禁 |
| Phase 1 受控 LLM 实验 | ADR-0006；Data Governance §8；platform_llm_run | 模型/prompt/成本/人工处置与禁止直接发布 |
| 跨时区一致时间线 | Architecture §7；Database §3；报告设计 | UTC + IANA zone + DST 验收 |
| 可解释、可追溯、可复现 | Run dependency/explanation/audit | 相同快照重现、报告一致 |
