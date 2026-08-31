# ADR-0008：Sales Platform 独立于 BMS/CRM，并使用 BMS 认证

- Status: Proposed
- Date: 2026-08-27

## Context

Sales Platform 面向销售现场会谈、工艺推荐、初步客户文件和工程交接。它不是 BMS 或 CRM 内的业务模块，也不要求先存在一个外部销售项目。矿机人员账号、角色和权限由 BMS 管理，但 BMS 当前具体 token 与跨系统认证契约尚未确认。

## Decision

- Sales Platform 是 BMS/CRM 之外的独立系统和独立领域边界。
- 用户打开 Web/Electron 客户端时使用 BMS 认证。
- BMS 后端承接认证、权限码和 Sales Platform 身份交换适配；Sales Platform 只保存外部主体引用与本地授权映射，不保存 BMS 口令。
- Sales Platform 自己创建 `Project`，不要求 `externalProjectId`、报价 ID 或 CRM 项目 ID。
- React + Electron 前端计划放在独立仓库；正式仓库名待建立。
- Sales Platform 业务后端最终运行位置暂不决定，但无论部署在哪里，都必须保持独立 schema、API 契约和领域模块，不得把业务表混入 BMS 领域表。

## Consequences

系统边界与项目归属更清楚，现场会谈不依赖 CRM/BMS 项目先行创建。代价是需要正式设计 BMS 登录交换、权限映射、退出/刷新和故障降级契约，并额外决定平台后端部署与运维责任。

## Rejected Alternatives

- 作为 BMS 内页面实现：与已确认的独立产品边界不符。
- 作为 CRM 项目子流程实现：会让现场建项依赖 CRM 状态和 ID。
- Electron 直接持有 BMS 口令或数据库凭据：安全和审计不可接受。

