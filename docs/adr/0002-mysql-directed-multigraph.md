# ADR-0002：MySQL 关系表保存有向多重图

- Status: Proposed
- Date: 2026-08-27

## Context

选矿流程存在分支、平行物流和磨矿—分级循环，简单步骤数组或 DAG 不足。系统同时重视版本、审核、报告和关系查询。

## Decision

流程持久化为 `flowsheet_version/node/edge`，边保存端口和循环角色；布局坐标独立。运行时加载为 Graphology `MultiDirectedGraph`。

## Consequences

避免早引入图数据库并保留 InnoDB 事务优势；边表带流程版本 ID，并用复合外键保证两端节点属于同一流程。复杂跨图遍历优先在 Graphology 中执行，简单层级查询可用 MySQL 递归 CTE。若未来规模证明需要，可建立图数据库读模型。
