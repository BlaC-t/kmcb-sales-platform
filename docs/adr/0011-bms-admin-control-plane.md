# ADR-0011：BMS 仅承载 Sales Platform 内部管理控制面

## Status

Proposed

## Context

Sales Platform 已确定为 BMS/CRM 之外的独立系统，并使用 BMS 认证与权限。内部人员仍需要在熟悉的 BMS 管理端维护内容、多语言、设备、案例、规则，处理审核、发布和审计。如果把领域表复制进 BMS，会形成双写、版本漂移和绕过 Sales Platform 发布状态机的风险；如果只放外链，又无法集中权限、待办和运维治理。

## Decision

在 BMS 建立 `Sales Platform 管理中心`，其定位是内部控制面而不是领域数据宿主。

- BMS 前端沿用 BMS 菜单和功能权限机制；全部新增页面（含表格/列表页）在菜单管理配置，由权限接口动态生成路由，不写入 `src/store/modules/routes.ts` 或 `src/router/index.ts`；
- 菜单中将审核与发布合并为“审核与发布”，将“权限与集成”简化为“权限”，不建设单独的“审计与运行”页面；审计证据仍保留在各业务详情/版本历史，运行监控归后端运维体系；
- BMS 后端提供 BFF/Identity Adapter，执行 BMS 权限检查并调用 Sales Platform Admin API；
- Sales Platform MySQL schema、对象存储和领域审计仍是唯一可信源；
- BMS 数据库只保存既有账号/角色/菜单/权限、权限映射与必要集成配置；
- BMS 不直接写 Sales Platform 数据库，不复制项目、推荐、内容、设备、案例、规则、handout 或工程发布表；
- 全量可追溯采用“摘要列表 → 结构化详情 → 受限原始/证据视图”，不把全部列放在一张表；
- 流程图深度编辑、销售设备比较、工程深化和客户演示继续在独立 Sales Platform 中完成；BMS 使用深链进入。

## Consequences

### Positive

- 复用 BMS 人员、角色、菜单和权限分配能力；
- 保持 Sales Platform 领域模型、版本和发布链单一可信；
- 浏览器不持有跨系统服务凭据；
- 内容、翻译、数据、审核、发布和审计可按职责分离；
- BMS 页面可以聚合任务型投影，同时保留对版本与证据的追溯。

### Negative

- 需要维护 BMS BFF 与 Sales Platform Admin API 契约；
- 管理动作比直连多一跳；
- 深度工程任务会从 BMS 跳转到独立平台；
- 两套系统的审计需要通过 trace ID 和 subject 关联。

## Guardrails

- 菜单可见、按钮可用和服务端授权必须使用同一最终权限映射；
- 页面必须在 BMS 菜单管理创建“页面”记录，按钮/能力创建“权限”子项；`hasPermission(...)` 精确匹配最终 `functionCode`，不得新增 legacy `inject*` 路由；
- 所有写请求使用幂等键，编辑使用乐观锁；
- 审核/发布时重新检查权限，不信任旧缓存；
- 密钥只显示配置状态和轮换时间，不返回明文；
- BMS/Sales Platform 故障时不得用缓存执行批准或发布；
- 本 ADR 获批不等于 BMS 页面、权限或接口已实现。

## Follow-up

1. 签订 BMS token、用户上下文、组织范围与服务凭证契约；
2. 在 BMS 菜单管理创建正式页面和功能权限码，并验证动态路由；
3. 为任务型投影建立独立 Admin API/BFF 契约；
4. 先实现只读总览和内容/handout 审核，再开放高风险工程数据发布。
