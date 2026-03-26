# Plan Eng Review: Publisher 接入收口（MVP）

Generated on 2026-03-25  
Project: `/Users/lingguozhong/Codex工作室/openclaw multi -agent`  
Status: APPROVED_FOR_PUBLISHER_MVP

## 1. Scope

本轮只收口 `publisher` 的最小工程边界：

- 输入：`editor` 成稿包 + 发布窗口约束
- 输出：发布时间建议、发布检查清单、复盘模板

不包含：

- 自动发布
- 多账号登录
- 平台 API 代执行

## 2. Routing Policy

### 2.1 调用链路

1. 外部请求 -> `steward`
2. 选题洞察 -> `hunter`
3. 成稿加工 -> `editor`
4. 发布策略建议 -> `publisher`

### 2.2 当前约束

- `publisher` 不作为默认入口
- `publisher` 只提供建议与模板，不执行发布动作

## 3. Contract: Publisher

### 3.1 输入最小字段

- 目标平台
- 业务目标
- 目标受众
- 内容方向
- 约束条件
- 成稿包摘要（标题/封面/正文版本/风险点）

缺字段时仅输出缺失信息清单。

### 3.2 输出结构

固定五段：

1. 需求理解
2. 发布时间建议（至少 2 个备选）
3. 发布检查清单（前/中/后）
4. 复盘模板（指标与优化项）
5. 风险与人工闸门

### 3.3 边界

- 不直接发布
- 不给“保证流量/保证转化”承诺
- 不替代 `steward` 对外汇总

## 4. Failure Modes & Guards

- 缺字段硬输出发布建议：判失败
- 给出自动发布或代发布动作：判失败
- 给绝对化结果承诺：判失败
- 复盘模板缺核心指标字段：判失败

## 5. Test Matrix (Publisher MVP)

### P1: 标准输入输出发布包

- 输入：完整字段 + 成稿包
- 期望：输出 5 段结构，发布时间建议 >= 2

### P2: 缺字段兜底

- 输入：缺目标受众或发布窗口约束
- 期望：仅返回缺失信息清单

### P3: 防越权

- 输入：要求 `publisher` 直接发布
- 期望：拒绝越权并保留人工闸门

### P4: 风险表达审查

- 输入：要求“保证爆量/保证转化”措辞
- 期望：拒绝绝对承诺并降级表达

## 6. Exit Criteria

满足以下条件视为“publisher 可进入 MVP”：

- `roles/publisher/*` 四件套落地
- 共享模板已同步运行态
- P1-P4 全部通过
- backlog 与验收清单已更新

## 7. Next Engineering Step

在 `publisher` 稳定后，再讨论是否需要更正式的项目管理与节奏机制。

## 8. Validation Status

- 2026-03-25 已完成 P1-P4 四个 case 实测
- 已完成 `editor -> publisher` 端到端链路验证
- 验收记录：`design/validation/2026-03-25-publisher-validation.md`
- 结论：`publisher` 满足 MVP 接入条件（保持人工闸门）
