# ADR-0012：非标准产品工作簿必须经过分区、映射、差异和版本发布

## Status

Proposed

## Context

真实产品工作簿并不是统一的一行一产品格式：一个 Sheet 可重复出现表头和多套列语义，一个文件可包含多个产品类型，合并单元格造成数据行空白，同型号可能对应不同图号，Excel 还会把工程区间误识别为日期。直接按固定列导入或让 LLM 自动写正式目录都会产生不可追溯的静默错误。

## Decision

- 任意 XLSX 先保存为不可变 SourceDocument，并创建 ImportBatch；
- 每个 Sheet 拆成一个或多个 logical regions，每个 region 独立识别产品类型、header 和 schema；
- 已批准 Mapping Profile 负责表头别名、单位、继承和解析规则；陌生格式进入人工映射，LLM 只能提供建议；
- 每个单元格相关事实保存 raw value、formatted text、number format、normalized value 和 source locator；
- 商业型号使用 `manufacturer + normalized_model_code` 匹配；同型号不同图号形成规格/配置候选，不直接覆盖；
- 导入结果分类为 NEW_MODEL、NEW_VARIANT、UPDATE、FORMAT_ONLY、NO_CHANGE、CONFLICT、INCOMPLETE 或 RETIREMENT_CANDIDATE；
- 缺席不代表下架，空白不代表零，低置信度不允许批量发布；
- 审核通过后创建新的 EquipmentSpecVersion，不原地修改历史发布版本。

## Consequences

### Positive

- 可以安全处理一个文件多 Sheet、多产品、多表头和未知模板；
- BMS 能按字段展示新增、更新、冲突和来源；
- Mapping Profile 随审核样本逐步提高自动化率；
- 历史推荐和文件继续引用原规格版本。

### Negative

- 需要额外 staging 表、异步 Worker、映射页面和设备专家审核；
- 首批文件需要人工标注为金标准；
- 同型号多图号的业务定义未确定前会产生较多待确认项。

## Guardrails

- BMS/Sales Platform 不直接覆盖 published equipment rows；
- 解析失败或权限撤销时不能发布；
- LLM 输出不能成为型号身份、单位或工程能力的唯一依据；
- 导入/发布幂等，所有决定关联源文件 checksum、Sheet/单元格和 parser/Profile 版本；
- 本 ADR 获批不等于本次三个工作簿已导入数据库。
