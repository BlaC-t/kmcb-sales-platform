# 术语表

| 中文 | Code / English | 定义 |
|---|---|---|
| 需求版本 | RequirementVersion | 销售可编辑的结构化客户/项目输入版本 |
| 平台项目 | Project | 由 Sales Platform 创建的业务聚合根，不要求外部 BMS/CRM/报价项目 ID |
| BMS 认证代理 | BMS Authentication/Permission Broker | BMS 后端提供给外部 Sales Platform 的身份验证与权限交换边界 |
| BMS 管理控制面 | BMS Sales Platform Control Plane | BMS 内面向员工的内容、数据、审核、发布、审计和运行入口；通过 BFF 调用平台 API，不保存领域数据副本 |
| 任务型投影 | Task-oriented Projection | 为管理页面按任务组织的摘要/详情读模型，不等同数据库表或全字段导出 |
| 输入快照 | InputSnapshot | 发起推荐时冻结的不可变输入 |
| 推荐运行 | RecommendationRun | 使用固定输入和依赖的一次算法执行 |
| 候选方案 | CandidateSolution | 算法生成、未经工程审核的流程与设备组合 |
| 工程方案 | Solution | 销售选择候选后进入工程深化的业务对象 |
| 工程修订 | SolutionRevision | 工程师可编辑、可校核、可审核的版本 |
| 销售看板 | Sales Dashboard | 面向客户会谈的企业展示、问诊、推荐、设备选择和打印工作台 |
| 内容页面修订 | ContentRevision | 一次语言无关的页面/区块结构版本，四种语言译文挂载其上 |
| 内容发布包 | ContentRelease | 冻结页面、四语言文本、媒体 variant、排序和 checksum 的不可变客户展示 manifest |
| 媒体资产 | MediaAsset | 对象存储中的原图/视频/文档及其 checksum、权利、尺寸和派生版本元数据 |
| 过期翻译 | STALE Translation | 源字段变化后仍保留但必须重新核对、不得直接进入新 release 的译文 |
| 销售方案修订 | SalesProposalRevision | 销售从算法候选创建并调整设备选择的结构化版本；不是工程批准版本 |
| 初步客户打印件 | CustomerHandout | 从冻结销售修订生成的多语言 PDF/DOCX，须经专用权限审核并带未经最终工艺审核声明 |
| 初步文件审核人 | PreliminaryHandoutReviewer | 持有 `customer.handout.review` 的指定人员，不绑定团队职级或工艺工程师角色 |
| 数据维护权限 | `sales_platform.data_maintain` | 进入数据更新中心和提出数据变更的逻辑权限；不自动包含高风险发布权 |
| LLM 运行 | LlmRun | 一次受控模型调用及其模型、prompt、输入 checksum、输出、成本和人工处置记录 |
| 工程交接 | SalesEngineeringHandoff | 将完整问答、算法、销售修改和已打印版本提交工艺工程师的记录 |
| 发布包 | ReleasePackage | 面向销售的不可变正式输出 |
| 工艺节点 | FlowsheetNode | 一个工艺操作，不等于具体设备型号 |
| 物流边 | FlowsheetEdge | 节点之间的物料、矿浆、水、空气或药剂流 |
| 能力包络 | CapabilityEnvelope | 设备在特定物料/工况条件下的适用能力范围 |
| 硬约束 | Hard Constraint | 失败后候选必须排除或补充必需模块的规则 |
| 证据覆盖 | Evidence Coverage | 输入、规则、案例、设备和来源的可验证覆盖程度 |
| 数据提议 | Proposed Change | 自动/人工发现但尚未发布的候选变更 |
| 导入批次 | ImportBatch | 一个源 XLSX 的不可变解析、映射、差异、审核与发布生命周期 |
| 逻辑表格区域 | Logical Region | 从一个 Sheet 中识别出的独立标题、表头、数据范围和产品类型；一个 Sheet 可有多个 |
| 字段映射配置 | Mapping Profile | 版本化的表头别名、单位、空白继承、解析和质量规则，只能经审核后复用 |
| 新配置 | NEW_VARIANT | 商业型号已存在，但图号或关键配置 fingerprint 尚不存在的导入候选 |
