# 面向客户与销售的交付物设计

## 0. 两级交付物

| 等级 | 来源 | 生成时点 | 是否可给客户 | 关键标识 |
|---|---|---|---|---|
| Preliminary Customer Handout | 销售方案修订 | 客户会谈现场或会后 | 是；须经专用权限审核 | 初步技术交流方案、未经最终工艺审核、审核人/时间 |
| Approved Release Package | 已批准工程修订 | 工艺审核完成后 | 是 | 正式发布号、审核信息和适用边界 |

二者使用不同 manifest、编号和水印。正式方案不能覆盖初步方案；必须能追溯客户当时带走的是哪个语言、PDF/DOCX、checksum 和审核版本。

## 1. 发布包组成

每次正式发布生成一个 `release_package` 和不可变 `release_manifest`：

1. 技术方案摘要
2. 设计基础与客户输入
3. 推荐工艺流程图
4. 工艺流程逐段说明
5. 每段设备选择与数量
6. 关键参数与能力余量
7. 公用工程/道路/场地适配说明
8. 方案假设、风险和待客户确认项
9. 相似案例与工程依据摘要
10. 版本、审核和适用边界
11. 附件清单

## 2. 工艺段说明模板

每个节点/工艺段至少输出：

```text
段号与名称
工艺目的
输入物流与设计流量
输出物流与目标
主要工艺参数
设备类型、型号/规格版本
总数 / 运行数 / 备用数
单机与合计有效能力
能力余量和利用率
选用理由
替代设备（如有）
关键风险、假设和客户待确认项
证据/规则引用
```

## 3. 状态与水印

| 状态 | 销售可见 | 可对客户发送 | 水印 |
|---|---|---|---|
| Algorithm Candidate | 可见 | 否 | 算法候选，未工程审核 |
| Sales Proposal Draft | 是 | 否 | 销售方案草稿 |
| Preliminary Handout | 是 | 是，按权限 | 初步技术交流方案，未经最终工艺审核 |
| Engineering Draft | 受限 | 否 | 工程草稿 |
| Under Review | 受限 | 否 | 审核中 |
| Released | 是 | 按权限 | 正式发布号 |
| Superseded | 是 | 默认否 | 已被替代 |
| Withdrawn | 是 | 否 | 已撤回 |

Preliminary Handout 在 `PENDING_REVIEW` 或 `REJECTED` 时只能内部预览；只有具备 `customer.handout.review` 权限的指定人员批准后进入 `APPROVED_FOR_DELIVERY`。审核人不要求是团队负责人或工艺工程师，默认与生成者不同。

## 4. 导出格式与语言

- PDF：对外阅读主格式，稳定排版和签字/批准信息。
- Word（DOCX）：首期支持；与 PDF 来自同一 manifest。手工编辑后的副本不再代表平台批准版本，必须保留“导出副本”标识。
- JSON：内部 manifest、API 和未来系统集成使用，不作为客户打印格式。
- Excel：设备清单/报价草稿输入（后续可选）。

首期 locale：中文 `zh-CN`、英语 `en`、俄语 `ru`、乌克兰语 `uk`。每个 locale 独立冻结、审核和生成文件；关键翻译缺失时阻止交付。LLM 可生成翻译草稿，但不能自动发布客户文件。

## 5. 设备清单字段

```text
processStageCode
processStageName
equipmentType
manufacturer
modelCode
specVersion
quantityTotal
quantityDuty
quantityStandby
requiredCapacity
effectiveCapacityPerUnit
capacityMarginPct
powerKwPerUnit
shippingWeightT
mainAccessories
selectionReason
commercialNotesPlaceholder
```

技术平台不直接给出未经商务确认的价格、交期或合同承诺。可生成报价草稿输入，但正式报价由销售/报价流程确认。

## 6. 发布前预览

预览必须来自同一 `release_manifest` 渲染，不能由页面实时读取可能变化的设备/规则表。PDF/DOCX/JSON 必须共享同一 manifest，避免多种格式内容不一致。

初步客户打印件同样从 `customer_handout.manifest` 渲染；与正式 `release_manifest` 分开，但都遵守不可变与 checksum 规则。审核决定绑定 manifest 与文件 checksum；任何变化必须重新审核。

所有文件保存 UTC 生成时间，并显示项目所在地 IANA 时区、当地时间和当时 UTC 偏移，避免跨国使用时误读。

## 7. 销售反馈

销售可对已发布方案提交：客户接受、需调整、预算不符、现场条件变化、设备偏好、暂缓/丢单等反馈。这些反馈创建新需求/修订或业务记录，不修改旧发布包。
