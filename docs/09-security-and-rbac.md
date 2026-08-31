# 安全、权限与审计设计

## 1. 安全目标

- 不让客户端持有数据库凭据、服务密钥或高权限 API。
- 不让用户越权查看其它项目/客户的资料、推荐和报告。
- 不让客户演示模式泄露其他客户、内部评分、规则原文、成本或管理入口。
- 不让 AI/导入任务直接覆盖正式工程数据。
- 不让单个角色无痕修改并发布高风险规则或方案。
- 每个正式结论可追溯到人、时间、输入、依赖和证据。

## 2. 身份集成

Sales Platform 是 BMS/CRM 外部系统，但打开平台时必须通过 BMS 认证。建议由 BMS 后端提供 Authentication/Permission Broker，并在 Sales Platform 定义 `IdentityProvider` 端口，支持以下候选方式之一：

1. API Gateway 验证 BMS token 后签发内部短期 JWT；
2. Node API 通过 BMS 公钥验证 JWT；
3. Node API 调用 BMS introspection/用户权限接口。

最终方式需由 BMS 负责人确认。无论哪种方式，Sales Platform 服务端必须再次执行本地角色、项目范围和状态授权，不能相信 Electron/React 传来的角色。平台只保存 BMS subject 引用，不保存口令；BMS 不成为平台业务数据存储。

BMS 内管理控制面由 BMS Vue 调用 BMS Backend BFF，再由 BFF 使用服务端凭证和用户上下文访问 Sales Platform Admin API。浏览器不得获得服务凭证，BMS 后端不得直写 Sales Platform schema。所有 BMS 页面（含表格/列表页）经菜单管理和权限接口动态注册，禁止写死在 `routes.ts`；按钮权限作为“权限”子项并与最终 `functionCode` 精确对应，但仍不能替代 Sales Platform 的资源级授权。

## 3. 授权模型

RBAC + 资源范围：

```text
permission = action × resource_type
scope = organization / project / own / assigned
condition = status / risk_level / segregation_of_duties
```

示例：

- `solution.revision.edit` + assigned project + DRAFT
- `solution.revision.approve` + reviewer role + not own submission
- `rule.publish` + rule owner/publisher separation
- `document.download` + project membership + classification policy
- `sales.presentation.view` + published/customer-safe content only
- `sales.proposal.edit` + own/assigned project + SALES_DRAFT
- `customer.handout.generate` + proposal ready + disclaimer policy
- `customer.handout.review` + assigned permission + PENDING_REVIEW + checksum unchanged + not own generation（默认）
- `sales_platform.data_maintain` + data center access；高风险 publish 仍需独立业务权限与职责分离
- `sales_platform.content_edit` / `content_translate` / `content_review` / `content_publish` / `media_manage` 分离；内容发布权不由 data maintenance 自动继承
- `sales_platform.project.view` / `audit.view` / `permission.manage` 分离；审计只在授权业务详情/版本历史中展示，不设独立菜单；“可查看全部”仍受组织、项目、客户敏感级别和字段脱敏约束
- `sales_platform.product_import.upload` / `map` / `review` / `raw_view` 与 `sales_platform.equipment.publish` 分离；上传或映射权限不自动取得发布权

## 4. 职责分离

默认建议：

- 提交人不能批准自己的高风险数据变更。
- 工程师不能批准自己提交的正式方案。
- 系统管理员不能通过数据库直接变更业务发布状态。
- 服务账号不能执行人工批准动作。
- 初步客户文件生成者默认不能批准自己生成的 handout；权限来自 BMS 映射，不依赖团队负责人职级。

具体阈值可按风险等级配置，但绕过必须有审计和事后告警。

## 5. 数据保护

- TLS 全链路；数据库/对象存储静态加密。
- 客户、项目、联系人和商业数据分级。
- 对象存储 key 不暴露原始客户名；下载使用短期签名 URL。
- 敏感字段日志脱敏；禁止记录 token、口令、完整客户文档正文。
- 报告下载可加入用户名、时间和版本水印。
- 客户展示内容必须标记 `CUSTOMER_SAFE`；授权案例发布前完成脱敏和使用权确认。
- CMS 禁止任意 HTML/JavaScript/远程脚本；区块类型、链接协议/域名和媒体 MIME 使用白名单，所有文本按内容类型转义。
- 媒体上传执行文件签名、解码、恶意内容、尺寸和压缩炸弹检查；历史 release 引用资产不可物理删除。
- 人物、客户现场和第三方素材保存授权范围与到期时间，失效资产阻止进入新 release。
- 导入文件进行类型、大小、恶意内容和压缩炸弹检查。
- LLM 请求在出域前执行数据分级与脱敏；未确认供应商/驻留策略前，敏感客户文档不得发送到外部模型。

## 6. Electron 威胁控制

- Renderer 按不可信 Web 内容处理。
- 禁止 `nodeIntegration`，启用 `contextIsolation`/sandbox。
- IPC 使用白名单函数和参数 schema，验证 sender。
- 限制 `shell.openExternal` 域名；拒绝任意协议。
- 禁止加载远程 JS；依赖锁定、SBOM 和签名更新。
- 文件路径不从 Renderer 直接拼接传给高权限 API。

## 7. API 安全

- 输入 schema 校验和最大深度/数组长度。
- 项目级授权在每次资源访问执行。
- 幂等键绑定主体和路由，防止跨用户碰撞。
- 限流：登录/上传/推荐/报告/批量导出分别配置。
- SQL 参数化；规则 DSL 不执行任意代码。
- SSRF 防护：服务端只访问白名单存储/集成端点。
- CORS 仅允许受控 Web Origin；Electron 使用自定义安全协议/本地打包策略。
- 客户演示使用服务端 customer projection；不得仅靠前端 CSS 隐藏内部字段。

## 8. 审计事件

至少记录：

- 登录身份映射和权限拒绝；
- 需求快照、推荐发起/取消；
- 候选选择；
- 客户会谈创建/完成、答案来源变化和展示内容版本；
- 销售设备切换、数量修改、初步打印件生成和工程提交；
- 初步客户文件提交审核、批准/退回、语言/格式、checksum 和交付下载；
- LLM 调用目的、模型/prompt 版本、输入 checksum、token/成本和人工接受/拒绝；
- 图/设备关键变更；
- 警告覆盖；
- 审核提交、退回、批准；
- 发布、撤回、替代和下载；
- 数据导入、变更、规则/设备/案例发布；
- 管理配置和角色映射变更。

审计记录包含 actor、action、resource、before/after 摘要、reason、IP/device、traceId、occurredAt。大 payload 存受控对象存储并用 checksum 关联。

## 9. 威胁模型摘要

| 威胁 | 控制 |
|---|---|
| 销售越权查看别的项目 | 服务端项目范围授权、测试、审计 |
| 恶意 PDF 利用解析器 | 隔离 Worker、资源限制、文件扫描、无网沙箱 |
| AI 幻觉写入设备能力 | staging + 人工审核 + 发布版本 |
| Electron XSS 变成本地代码执行 | sandbox/context isolation/CSP/IPC 白名单 |
| 规则注入任意 JS | 受限 DSL、白名单 operator、无 eval |
| 报告与当前数据不一致 | 发布 manifest 和依赖快照 |
| 演示模式泄露内部信息 | 独立 customer projection、内容分级、项目范围授权 |
| 初步打印件被误认为正式承诺 | 独立编号/manifest、醒目免责声明、不可变历史 |
| 未经权限审核直接现场交付 | `PENDING_REVIEW` 门禁、专用权限、checksum 复核、下载/打印授权 |
| LLM 泄露客户资料或产生错误翻译 | 数据分级/出域策略、最小输入、运行审计、人工翻译审核、禁止直接发布 |
| 重复点击生成重复发布 | 幂等键、唯一约束、事务 |

## 10. 安全验收

- 权限矩阵自动测试；越权 ID 枚举测试。
- Electron security checklist 自动/人工检查。
- 文件上传恶意样本测试。
- SAST、依赖扫描、secret scan、SBOM。
- 发布前渗透测试覆盖身份、授权、上传、导出和 IPC。
- BMS 认证不可用、权限映射过期和 token 刷新/退出的集成故障测试。
- BMS 菜单、按钮、BFF 与 Sales Platform 四层权限一致性测试；缓存状态下不能批准或发布。
- 恶意/超限 XLSX、隐藏 Sheet、日期误识别、外部链接和解析 Worker 资源隔离测试。
