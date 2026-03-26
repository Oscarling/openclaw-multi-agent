# M2-E5 平台受控放量准备包（v1）

日期：2026-03-26  
阶段：M2-E5（阶段 C 准备）  
状态：准备中（由 Stage-B 首轮 dry-run `Conditional-Go` 触发）

## 1) 目标

在保留人工闸门与可回滚能力的前提下，建立“小流量 -> 受控放量 -> 快速停机”执行框架，作为自动发小红书能力的上线前置。

## 2) 触发前提

- Stage-B DoD：`Conditional-Go`
- Stage-B DoD 记录：`design/validation/2026-03-26-gate4-stage-b-dod-validation.md`
- Stage-B dry-run 记录：`design/validation/2026-03-26-gate4-stage-b-dryrun-validation.md`

## 3) 实现边界（本阶段）

允许：
- 定义小流量批次与放量阈值
- 定义失败回滚阈值与停机动作
- 定义阶段 C DoD 模板化留痕

禁止：
- 未达阈值即跨级放量
- 无回执即判定发布成功
- 未定义停机动作即放量

## 4) 最小交付物（事件触发）

1. 阶段 C 放量策略卡（流量梯度 + 触发条件）
2. 阶段 C 预检脚手架
3. 阶段 C DoD 验证记录草案
4. 停机与回滚操作清单

## 5) 验收标准（阶段 C 准备态）

- 放量阈值、停机阈值可执行且可审计
- 成功/失败回执字段与阶段 B 口径一致
- 形成可复核的阶段 C DoD 草案

## 6) 下一事件动作

1. 事件：M2-E5 准备包落盘（已满足）  
动作：补齐阶段 C 放量策略卡与预检脚手架  
产物：`design/2026-03-26-m2-e5-rollout-strategy-card-v1.md`、`deploy/gate4_stage_c_preflight.sh`

2. 事件：阶段 C 预检就绪  
动作：执行阶段 C 首轮受控验证并形成 DoD 记录  
产物：`design/validation/2026-03-26-gate4-stage-c-preflight-validation.md`
