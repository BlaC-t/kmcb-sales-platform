# ADR-0005：Electron 薄客户端，共享 React Web UI

- Status: Proposed
- Date: 2026-08-27

## Context

需要桌面文件/导出/更新体验，但业务数据集中协作、权限和审计不能分散在客户端。

## Decision

业务逻辑、规则、推荐和数据库访问全部在中央 API/Worker。Electron Main/Preload 只暴露白名单桌面能力；Renderer 复用 React Web UI，启用 sandbox/context isolation，禁用 Node integration。

前端计划放在独立仓库，并在同一首发批次交付 Windows 与 macOS。两端共享 React 功能和 API 契约，但分别完成安装包、代码签名、自动更新、打印/文件保存和系统安全验收。打开客户端时通过 BMS 认证。

## Consequences

安全和多人一致性更好，也保留浏览器版；需要中央服务可用性、桌面签名更新和离线体验明确降级。
