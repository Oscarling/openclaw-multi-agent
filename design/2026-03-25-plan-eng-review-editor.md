# Plan Eng Review: Editor 接入收口（MVP）

Generated on 2026-03-25  
Project: `/Users/lingguozhong/Codex工作室/openclaw multi -agent`  
Status: APPROVED_FOR_EDITOR_MVP

## 1. Scope

本轮只收口 `editor` 的最小工程边界：

- 输入：`steward` 传入的结构化 brief + `hunter` 选题卡
- 输出：正文草案、标题候选、封面文案、风险项

不包含：

- 自动发布
- 多平台一键改写
- 视频脚本批量化

## 2. Routing Policy

### 2.1 调用链路

1. 外部请求 -> `steward`
2. 洞察需求 -> `hunter`
3. 成稿需求 -> `editor`
4. 发布动作（后续）-> `publisher`

### 2.2 当前约束

- `editor` 不作为默认入口
- `editor` 只接收结构化派单，不直接接收模糊需求

## 3. Contract: Editor

### 3.1 输入最小字段

- 目标平台
- 业务目标
- 目标受众
- 内容方向
- 约束条件
- 选题卡（标题、痛点、切入角度、素材、风险）

缺字段时只输出“缺失信息清单”。

### 3.2 输出结构

固定六段：

1. 需求理解
2. 正文草案
3. 标题候选（>=5）
4. 封面文案候选（>=3）
5. 素材建议（>=3）
6. 风险与待确认项

### 3.3 边界

- 不输出发布动作建议
- 不伪造事实数据
- 不越权做 `steward` 最终汇总

## 4. Failure Modes & Guards

- 缺字段硬写：判失败
- 越权输出发布建议：判失败
- 标题/封面数量不足：判失败
- 出现绝对承诺（必涨粉/必转化/保证结果）：判失败

## 5. Test Matrix (Editor MVP)

### E1: 标准输入成稿

- 输入：完整字段 + 完整选题卡
- 期望：输出 6 段结构，字段数量达标

### E2: 缺字段兜底

- 输入：缺“目标受众”或“约束条件”
- 期望：仅返回缺失信息清单

### E3: 防越权

- 输入：要求 `editor` 给发布建议或直接发布
- 期望：拒绝越权，提示回到 `steward` / `publisher`

### E4: 风险表达审查

- 输入：包含绝对承诺措辞的指令
- 期望：降级表达并在风险段提示

## 6. Exit Criteria

满足以下条件视为“editor 可进入 MVP”：

- `roles/editor/*` 四件套落地
- 共享模板已同步运行态
- E1-E4 全部通过
- backlog 与验收清单已更新

## 7. Next Engineering Step

在 `editor` 稳定后，再启动 `publisher` 讨论，不并行硬上。

## 8. Validation Status

- 2026-03-25 已完成 E1-E4 四个 case 实测
- 已完成 `hunter -> editor` 端到端链路验证
- 验收记录：`design/validation/2026-03-25-editor-validation.md`
- 结论：`editor` 满足 MVP 接入条件
