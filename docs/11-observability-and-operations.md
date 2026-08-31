# 可观测性、部署与运维

## 1. 环境

```text
local → dev → test/uat → production
```

生产数据不得复制到低环境，除非完成脱敏和审批。每个环境独立数据库、对象存储 bucket、Redis、密钥和身份客户端。

## 2. 部署单元

- `api`：无状态，可水平扩展；最终部署归属待定，但作为独立 Sales Platform 业务服务和 schema 运维。
- `worker-recommendation`：CPU/内存按推荐任务扩展。
- `worker-document`：隔离文档解析和 OCR。
- `worker-report`：报告渲染，可独立资源限制。
- MySQL：使用 121 上新建的专用 schema；Redis、对象存储使用公司平台服务或独立受管实例。
- Electron：前端计划独立仓库；Windows/macOS 同批次签名安装包、分渠道更新和可回滚版本。

## 3. 日志

结构化 JSON，统一字段：`timestamp`（UTC）、`timeZone`（业务上下文 IANA zone）、`level`、`service`、`environment`、`traceId`、`spanId`、`actorId`（可脱敏）、`projectId`、`runId`、`jobId`、`eventType`、`code`。

禁止记录 token、口令、完整文档内容、联系人敏感信息和未脱敏规则事实 payload。

## 4. Metrics

### API

- 请求率、P50/P95/P99、错误率
- 数据库连接池、慢查询、事务冲突
- 上传/下载大小与失败

### 推荐

- 队列等待与总耗时
- 各阶段耗时
- 输入完整度
- 初始候选/硬约束淘汰/最终候选数量
- 人工设计回退原因
- 规则冲突与图校验失败

### Worker/Queue

- 活跃、等待、重试、失败、死信
- 心跳丢失、stalled job、幂等冲突
- Outbox backlog 和最大滞后

### LLM 实验

- 按 purpose/model 的调用量、成功率、P50/P95 延迟、token 与估算成本
- 人工接受/修改/拒绝率和字段级准确率
- 敏感数据策略阻止次数、超时/限流和 provider 故障

### 业务

- 推荐采用、工程改动、审核退回、发布耗时
- 内容翻译完整度/STALE 数量、媒体处理失败、ContentRelease 发布时间、回滚次数和客户端旧 release 使用率
- 过期/质量问题与影响推荐数量

## 5. Tracing

从 Electron/Web → Gateway → API → Outbox → Worker → DB/Storage 传播 correlation/trace ID。每个推荐阶段作为独立 span，避免只看到一个 60 秒黑盒任务。

## 6. 告警

- 推荐失败率或等待时间超阈值
- Outbox/队列积压
- 发布/报告生成失败
- ContentRelease manifest/checksum 不一致、媒体权利到期、派生图片失败或客户端连续无法切换 current release
- 数据库容量、连接、复制/备份异常
- 对象存储不可用/签名失败
- 身份验证异常峰值和越权拒绝峰值
- 初步客户文件审核积压、checksum 变化和未批准下载尝试
- 规则发布后 blocker/回退比例异常上升

## 7. 备份与恢复

- MySQL binlog/PITR 能力（取决于 121 当前配置）+ 定期全备；对象存储版本/跨域策略按公司要求。
- Redis 可重建，不作为唯一事实源。
- 至少季度做恢复演练，验证 DB、对象清单、报告和 checksum 一致。
- 定义 RPO/RTO；设计建议初始 RPO ≤ 15 分钟、RTO ≤ 4 小时，需业务评审。

## 8. 发布策略

- 数据库 migration 先向后兼容，再部署代码，再清理旧字段。
- 推荐算法/规则/特征 Schema 独立版本化和灰度。
- Electron 支持稳定/测试渠道和紧急回滚。
- 新矿种/工艺按 feature flag + 白名单上线。
- 变更前跑金标准回归，输出候选和解释差异报告。

## 9. Runbook 最小集合

- 推荐任务卡住/失败
- Outbox/队列积压
- 报告生成失败
- BMS/身份集成不可用
- BMS 权限同步过期或专用权限映射错误
- LLM provider 故障、成本异常或数据出域策略触发
- 客户文件当地时间/时区显示错误
- 对象存储文件缺失/checksum 不符
- 错误规则或设备版本发布
- 销售方案误发布/需撤回
- Electron 更新失败
- 数据库恢复与一致性检查
