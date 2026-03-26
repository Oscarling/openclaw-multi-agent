# Plan Eng Review: Steward + Hunter 路由与契约收口

Generated on 2026-03-25  
Project: `/Users/lingguozhong/Codex工作室/openclaw multi -agent`  
Status: APPROVED_FOR_MVP

## 1. Scope

本轮只收口两角色 MVP 的工程边界：

- `steward`：唯一默认入口
- `hunter`：洞察与选题产出

不包含：

- `editor` / `publisher` 运行态接入
- 自动发布
- 多账号自动化

## 2. Current Runtime Facts

当前运行态验证结果（`agent_argus`）：

- `steward` 已是默认 Agent（`isDefault=true`）
- `hunter` 非默认，仅被 `steward` 调用
- `main` 保留但不作为默认入口
- 无 channel 级显式 bindings（当前镜像 channel plugin 不可用）

## 3. Routing Policy

### 3.1 路由优先级

1. 显式 `--agent <id>`（调试/验收）
2. 未来可用时的 channel 级 binding
3. 默认 agent（当前为 `steward`）

### 3.2 MVP 路由规则

- 外部入口请求默认先进入 `steward`
- `steward` 根据意图判断是否调用 `hunter`
- `hunter` 不直接对外汇总
- `main` 仅保留兼容用途，不承载新流程

## 4. Contract: Steward

### 4.1 输入最小字段

- 目标平台
- 业务目标
- 目标受众
- 内容方向
- 约束条件

缺字段时，先返回“缺失信息清单”，不进入 `hunter`。

### 4.2 输出结构

固定四段：

1. `需求理解`
2. `已执行动作`
3. `结果摘要`
4. `下一步建议`

### 4.3 边界

- 不写完整正文终稿
- 不伪造 `hunter` 未产出的结论
- 不给最终发布动作建议

## 5. Contract: Hunter

### 5.1 输入最小字段

与 `steward` 传入模板一致。缺字段时返回“缺失信息清单”。

### 5.2 输出结构（至少 3 条选题卡）

每条选题卡必须包含：

1. 选题标题
2. 目标受众
3. 核心痛点
4. 切入角度
5. 竞品观察
6. 素材清单
7. 风险点

### 5.3 边界

- 不输出完整正文
- 不做发布建议
- 不充当 `steward` 对外汇总

## 6. Failure Modes & Guards

- 串角色：用“反向指令”压测（要求 `hunter` 充当 `steward`）必须拒绝
- 模板漂移：输出缺任一核心字段即判失败
- 输入缺失硬编：出现“未给字段却直接下结论”判失败
- 过长废话：单次输出超过可读阈值时，要求收敛成结构化列表

## 7. Test Matrix (MVP)

### Case A: Steward 缺字段处理

- 输入：只给模糊目标
- 期望：返回缺失字段清单，不直接给选题

### Case B: Hunter 结构化选题输出

- 输入：完整五要素
- 期望：至少 3 条选题卡，字段齐全

### Case C: 防串角色

- 输入：要求 `steward` 扮演 `hunter` / 要求 `hunter` 扮演 `steward`
- 期望：两者都拒绝越权

## 8. Exit Criteria

满足以下条件视为“两角色收口完成”：

- `steward` 默认入口稳定
- 契约文件已落地并同步运行工作区
- 三个测试 case 全部通过
- backlog 与验收清单已更新

## 9. Next Engineering Step

进入 `editor` 之前，先保持 3-5 个真实样本压测，确认契约稳定；稳定后再启动 `editor` 角色定义讨论。

## 10. Validation Status

- 2026-03-25 已完成 A/B/C 三个 case 的实测验收
- 验收记录：`design/validation/2026-03-25-routing-validation.md`
- 结论：`steward` + `hunter` 路由与契约收口完成（MVP 范围内）
- 补充：同日已完成第一轮真实样本压测（`steward` 5 组、`hunter` 2 组）
- 补充：同日已完成第二轮回归压测（`steward` 3 组、`hunter` 3 组），未发现契约漂移
