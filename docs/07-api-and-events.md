# API 与事件设计

## 1. API 风格

- REST + JSON，OpenAPI 3.1 作为契约源。
- URL 使用复数资源；动作仅用于状态转换，例如 `:submit-review`。
- 所有写请求支持 `Idempotency-Key`。
- 乐观锁使用 `If-Match`/`rowVersion`。
- 错误使用稳定 `code` + 按请求 locale 本地化的 `message` + `details` + `traceId`；机器判断不得依赖翻译文字。
- 所有时间字段传 ISO 8601；项目/会谈同时传 IANA `timeZone`，不能只传浏览器固定偏移。
- 长任务返回 `202 Accepted` 和任务资源 URL。
- 进度通知 MVP 使用 SSE；离线或断线后仍可 GET 任务状态。

## 2. 资源分组

### 销售看板与客户会谈

```text
GET    /sales-content
GET    /sales-content/releases/current
GET    /content-pages
POST   /content-pages
POST   /content-pages/{pageId}/revisions
PUT    /content-revisions/{revisionId}/blocks
PUT    /content-revisions/{revisionId}/translations/{locale}
POST   /content-revisions/{revisionId}:submit-review
POST   /content-revisions/{revisionId}:approve
POST   /media-assets
POST   /content-releases
POST   /content-releases/{releaseId}:publish
POST   /content-releases/{releaseId}:rollback
POST   /sales-consultations
PUT    /sales-consultations/{consultationId}/answers
POST   /sales-consultations/{consultationId}:complete
```

### 项目与需求

```text
POST   /projects
GET    /projects/{projectId}
POST   /projects/{projectId}/requirement-versions
PATCH  /requirement-versions/{versionId}
POST   /requirement-versions/{versionId}:validate
POST   /requirement-versions/{versionId}:snapshot
```

### 推荐

```text
POST   /recommendation-runs
GET    /recommendation-runs/{runId}
GET    /recommendation-runs/{runId}/events
GET    /recommendation-runs/{runId}/candidates
GET    /candidate-solutions/{candidateId}
POST   /candidate-solutions/{candidateId}:select
```

### 销售方案与客户打印件

```text
GET    /sales-proposal-revisions/{proposalRevisionId}
PUT    /sales-proposal-revisions/{proposalRevisionId}/equipment-selections
POST   /sales-proposal-revisions/{proposalRevisionId}:generate-handout
POST   /sales-proposal-revisions/{proposalRevisionId}:submit-engineering
GET    /customer-handouts/{handoutId}
POST   /customer-handouts/{handoutId}:submit-review
POST   /customer-handouts/{handoutId}:approve
POST   /customer-handouts/{handoutId}:reject
```

### 工程方案

```text
GET    /solutions/{solutionId}
POST   /solutions/{solutionId}/revisions
GET    /solution-revisions/{revisionId}
PUT    /solution-revisions/{revisionId}/flowsheet
PUT    /solution-revisions/{revisionId}/equipment-selections
POST   /solution-revisions/{revisionId}:validate
POST   /solution-revisions/{revisionId}:submit-review
POST   /solution-revisions/{revisionId}:approve
POST   /solution-revisions/{revisionId}:reject
POST   /solution-revisions/{revisionId}:release
```

### 数据治理

```text
POST   /source-documents
GET    /extracted-facts
POST   /data-change-requests
POST   /data-change-requests/{id}:submit
POST   /data-change-requests/{id}:approve
POST   /data-change-requests/{id}:publish
GET    /data-quality-issues
GET    /llm-runs
```

产品工作簿导入是数据治理的专用子资源：上传返回 `202`，后台完成 Sheet/region 发现、映射、提取和 diff；BMS 可以订阅任务进度。建议契约见 `docs/product-import/design.md`。发布动作只接受已批准 change manifest，并创建新的设备型号/规格版本；不得以导入接口直接 PATCH 已发布设备记录。

### BMS 管理控制面投影

BMS Vue 不直接调用这些资源，也不拼接领域查询；它通过 BMS 后端 BFF 获取任务型投影。建议的契约组包括 `DashboardSummary`、`ContentWorkspace`、`TranslationMatrix`、`CatalogList/Detail`、合并后的 `ReviewAndReleaseWorkspace`、`ProjectRecord`、`EngineeringHandoffRecord` 和 `PermissionMapping`。审计证据随资源详情/版本历史返回，运行监控不做 BMS 菜单投影。正式 URL 在 BMS/Sales Platform 集成契约中确定，不能以本文示例冒充已实现接口。

BFF 必须传递经验证 subject、组织/资源范围、精确权限、locale、IANA 时区和 trace ID。写命令继续使用 `Idempotency-Key` 与 `If-Match`；文件只返回短期签名 URL。领域写入和发布只能由 Sales Platform API 完成，禁止 BMS 后端直接 SQL。

## 3. 关键命令语义

### 获取和发布企业展示内容

客户模式只调用 `/sales-content/releases/current`，并携带 locale/channel；响应包含 ETag、release number、manifest checksum、页面区块和媒体 variant。`If-None-Match` 命中返回 304。编辑 API 只保存草稿；发布 API 校验结构、翻译、媒体权利、客户安全和预览门禁后原子切换 current release。回滚不会修改旧 manifest，而是恢复前一 release 或创建后继 release。

`SalesContentReleasePublished` 事件包含 release ID/number、locale 列表、manifest checksum、UTC 发布时间和发布人。客户端接到通知后仍需通过 current API 和 checksum 验证，不信任事件携带完整内容。

### 发起推荐

请求只传 `inputSnapshotId` 和场景偏好，服务端解析已发布依赖。重复幂等键返回同一 Run。

### 选择候选

原子操作：

1. 校验候选属于项目且可见；
2. 记录销售选择和备注；
3. 创建 `sales_proposal` 和 `sales_proposal_revision 1`；
4. 克隆候选图、每段设备备选和默认选择；
5. 写 Outbox `CandidateSelectedBySales`。

### 生成初步客户打印件

原子冻结销售修订的客户安全投影、免责声明版本、流程图、设备选择和风险摘要，生成唯一 handout 编号与 checksum，再异步渲染 PDF/DOCX。渲染完成后进入 `PENDING_REVIEW`，不能直接交付。重复幂等键返回同一 handout。

### 审核初步客户文件

`submit-review` 创建针对具体 manifest/locale/file checksum 的审核请求；`approve`/`reject` 仅允许具有 `customer.handout.review` 权限的主体调用。批准时再次核对 checksum，状态转 `APPROVED_FOR_DELIVERY` 后才返回客户交付下载能力。默认生成者不能审核自己生成的文件。

### 提交工程

冻结销售修订，校验交接清单，创建 `solution`、`solution_revision 1` 和 `sales_engineering_handoff`。工程师看到算法候选、销售修改和客户已打印版本之间的差异。

### 发布

原子操作：

1. revision 必须 APPROVED；
2. 不存在未关闭 BLOCKER；
3. 创建唯一发布号和 manifest；
4. 状态转 RELEASED；
5. 写报告任务和 Outbox；
6. 重复调用返回同一发布资源。

## 4. 错误模型

```json
{
  "code": "ENGINEERING_VALIDATION_FAILED",
  "message": "方案仍有 2 个必须处理的问题",
  "details": [
    {
      "path": "flowsheet.nodes[CRUSH-01]",
      "ruleCode": "CAPACITY-004",
      "severity": "BLOCKER",
      "message": "运行设备合计有效能力低于该节点设计流量"
    }
  ],
  "traceId": "..."
}
```

## 5. 事件契约

事件信封：

```json
{
  "eventId": "uuid",
  "eventType": "SalesPackageReleased",
  "schemaVersion": 1,
  "occurredAt": "2026-08-27T00:00:00Z",
  "aggregateType": "ReleasePackage",
  "aggregateId": "uuid",
  "correlationId": "uuid",
  "causationId": "uuid",
  "data": {}
}
```

规则：

- 事件只追加，不修改。
- 消费者以 `eventId` 幂等。
- 破坏性字段变更提升 `schemaVersion`；新可选字段不必。
- 事件不携带客户敏感全文，消费者按授权回查。
- 对外集成失败不回滚已完成业务事务；进入重试/死信并告警。

## 6. BMS 与外部系统边界

BMS 交互承担两类边界：打开独立平台时的认证/权限交换，以及 BMS 内管理控制面 BFF。Sales Platform 自己创建 Project，不要求 `externalProjectId`、报价 ID 或 CRM 项目 ID；BMS 不成为领域数据存储。具体 BMS token、刷新/退出、组织范围、服务凭证和正式权限码仍需签订契约。

如果未来需要向其它系统同步正式发布结果，可使用以下最小投影，但它不是 MVP 建项前置条件：

```text
projectId
releaseId / releaseNumber
status
title
summary
processStageCount
equipmentLineCount
riskLevel
publishedAt
publishedBy
viewUrl
downloadUrl（短期签名）
supersedesReleaseId
```

具体回传采用 webhook、上游拉取还是内部网关事件，待实际目标系统确认；不在没有契约时硬编码。

初步客户文件只在 Sales Platform 中作为会谈交付物管理；任何外部同步都只能同步 `handoutId/handoutNumber/status`，不得与正式 `releaseId` 混用。

## 7. 合约文件

- REST：`contracts/openapi.yaml`
- 事件：`contracts/events.asyncapi.yaml`
- 共享概念类型：`contracts/domain-types.ts`

OpenAPI 标准：<https://spec.openapis.org/oas/>
