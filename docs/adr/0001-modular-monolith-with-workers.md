# ADR-0001：模块化单体 API + 独立 Worker

- Status: Proposed
- Date: 2026-08-27

## Context

领域边界仍在形成，但版本、审核、发布和审计需要强事务。推荐、文档解析和报告又是长耗时任务。

## Decision

使用一个模块化 Node.js API 进程承载核心事务边界，长任务通过 Outbox + BullMQ 交给独立 Worker。模块有公开端口和依赖规则。

## Consequences

初期开发、部署和一致性更简单；需要架构测试防止跨模块直接访问。未来可按负载/团队证据拆 Worker 或模块服务。

