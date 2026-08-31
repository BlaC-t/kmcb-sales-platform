# ADR-0010：企业展示采用结构化多语言 CMS 与不可变内容发布包

- Status: Proposed
- Date: 2026-08-27

## Context

Sales Platform 第一部分需要像公司网站一样展示大量图片和说明，并允许非开发人员持续更新中文、英语、俄语和乌克兰语。如果内容写死在 React/Electron，换图改字都需要重新构建客户端，四语言页面也容易发生结构漂移。

## Decision

- 页面结构和区块顺序与语言文本分离；四种 locale 共享结构，各自维护翻译状态。
- 只允许白名单结构化区块，不保存或执行任意 HTML/JavaScript。
- 图片/视频二进制存对象存储，MySQL 保存资产、派生尺寸、checksum、权利和引用元数据。
- 发布冻结不可变 `ContentRelease` manifest，Web/Electron 通过版本号与 ETag 更新，不因内容变化重新发布安装包。
- 会谈固定使用的 release/page/locale/checksum，后续内容更新不改写历史。
- LLM 翻译只能生成草稿；对应语言审核和内容发布权限不得被绕过。

## Consequences

平台需要内容编辑器、媒体库、四语言矩阵、预览、审核、定时发布、回滚和客户端离线缓存。结构化区块牺牲部分自由布局，但显著降低 XSS、跨端不一致、翻译漂移和发布不可追溯风险。

## Rejected Alternatives

- 写死在前端代码：每次内容更新都依赖开发和重新发版。
- 四语言复制四套页面：结构与媒体会快速漂移。
- 任意 HTML/JavaScript CMS：客户模式和 Electron 安全风险过高。
- 首期直接引入独立通用 CMS：增加第二套身份、权限和运维边界；未来可在 API 后替换。
