# ADR-0004：结构化受限规则 DSL，不执行任意 JS

- Status: Proposed
- Date: 2026-08-27

## Context

工艺工程师需要审核和维护规则；任意 JS/SQL 表达能力虽强，但安全、测试、迁移和解释成本高。

## Decision

规则使用版本化 JSON 条件树和动作，fact path、operator、value type、effect 白名单化。可用 `json-rules-engine` 作为内部执行适配，但对外只暴露领域 DSL。

## Consequences

规则安全、可审计和可生成决策表；高级计算需要实现受控函数或代码化校核器，而不是在 DSL 中无限扩展。

