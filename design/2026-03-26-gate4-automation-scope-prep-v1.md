# Gate-4 自动化范围冻结预评审输入包（v1）

日期：2026-03-26  
阶段：M2-E2 预评审准备（事件触发）

## 1) 触发背景

- M2-E1 已形成基线：
  - CLI 路由探针已落地并可重复执行
  - 已知差异仍存在（默认 `--to` 可能落 `main`）
  - 工具层护栏已启用（`openclaw_agent_safe`）
- 为避免主线停滞，先启动 Gate-4 的“范围冻结”准备，不直接进入运行态变更。

## 2) Gate-4 要回答的核心问题

1. 哪些环节允许自动化，哪些环节必须保留人工闸门？
2. 自动化上线前的最小安全边界是什么（权限、回执、回滚）？
3. 多账号登录和自动发布是否拆阶段推进，如何定义每阶段 DoD？

## 3) 预设范围（供评审，不是最终结论）

### 候选纳入（待评审）

- 多账号登录能力（仅受控账号集）
- 自动化发布执行链路（含回执采集与失败留痕）
- 平台发布器（小红书）的小流量受控放量

### 明确不纳入（当前轮）

- 无回执的“黑盒发布”
- 无回滚能力的直接全量自动化
- 跳过人工确认的高风险账号操作

## 4) 风险与护栏草案

- R1 权限误用：
  - 护栏：账号操作白名单 + 高危动作二次确认
- R2 发布不可追溯：
  - 护栏：强制记录发布请求、平台回执、异常码
- R3 路由口径差异引发误命中：
  - 护栏：CLI 统一走 `openclaw_agent_safe`，并在关键事件后复跑 `cli_route_parity_probe`

## 5) 安全边界草案（G4-T2）

### 5.1 账号白名单（最小字段）

- `account_id`：内部账号标识
- `platform`：目标平台（当前先以小红书为主）
- `owner`：账号责任人
- `risk_level`：`low/medium/high`
- `automation_level`：`observe_only / assisted / gated_auto`

执行规则：
- 仅白名单账号可进入自动化链路
- `risk_level=high` 账号必须人工二次确认后才允许执行
- 白名单外账号一律拒绝并写入审计日志

### 5.2 高危动作二次确认

定义为高危动作的最小集合：
- 登录态刷新/替换
- 发布动作提交
- 批量账号操作

最小确认口径：
- 需要显式确认字段（`operator`、`reason`、`ticket_id`）
- 未满足确认字段则阻断执行，不允许“默认继续”

## 6) 回执与异常字段草案（G4-T3）

### 6.1 发布请求记录（request）

- `request_id`
- `account_id`
- `platform`
- `content_fingerprint`
- `submitted_at`
- `operator`

### 6.2 发布回执记录（receipt）

- `request_id`
- `platform_post_id`（如有）
- `status`（`accepted` / `rejected` / `failed`）
- `receipt_at`
- `raw_receipt_ref`（原始回执引用）

### 6.3 异常记录（error）

- `request_id`
- `error_code`
- `error_stage`（`login` / `publish` / `receipt`）
- `error_message`
- `retriable`（`true/false`）

## 7) 路由护栏执行口径（G4-T4）

- CLI 侧统一走：`scripts/openclaw_agent_safe.sh`
- 路由复检探针：`deploy/cli_route_parity_probe.sh`
- 关键触发事件（升级、恢复、路由变更）后必须复跑探针并留痕
- 在 R-03 未关闭前，不允许以“默认 `--to` 命中行为”作为放行依据

## 8) 评审输入材料清单

- 本文档：`design/2026-03-26-gate4-automation-scope-prep-v1.md`
- 当前风险台账：`design/2026-03-25-risk-register-v1.md`
- CLI 路由探针记录：`design/validation/2026-03-26-cli-route-parity-probe-validation.md`
- 主线计划：`design/2026-03-26-mainline-m2-event-driven-plan-v1.md`

## 9) 下一事件动作（触发式）

- 事件 A：用户确认“进入 Gate-4 预评审”
  - 动作：发起 `gstack office-hours`（范围冻结）
- 事件 B：预评审结论为可进入工程收敛
  - 动作：发起 `gstack plan-eng-review`（架构/边界/验收）
- 事件 C：两段评审均通过
  - 动作：进入 M2-E3（多账号自动登录受控接入）
