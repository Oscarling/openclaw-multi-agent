# M2-E5 平台受控放量准备包（v1）

日期：2026-03-26  
阶段：M2-E5（阶段 C 准备）  
状态：C2 单批次已通过，待发起 C2 连续批次复评

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

2. 事件：阶段 C 预检就绪（已满足）  
动作：执行阶段 C 首轮受控验证并形成 DoD 记录  
产物：`design/validation/2026-03-26-gate4-stage-c-preflight-validation.md`、`design/validation/2026-03-26-gate4-stage-c-dryrun-validation.md`、`design/validation/2026-03-26-gate4-stage-c-dod-validation.md`

当前进展：阶段 C 首轮受控验证结果 `stage_c_passed`，DoD 结论 `Conditional-Go`。

3. 事件：阶段 C DoD 形成（已满足）  
动作：发起“真实小流量 C1 运行”专项评审准备（gstack）  
产物：`design/2026-03-26-gate4-stage-c-real-c1-review-prep-v1.md`、`design/2026-03-26-gate4-stage-c-real-c1-event-execution-card-v1.md`、`design/2026-03-26-gate4-stage-c-real-c1-plan-eng-review-agenda-v1.md`

当前进展：专项评审已完成，结论 `Conditional-Go`（允许进入真实 C1 单批次执行）。

4. 事件：专项评审结论落盘（已满足）  
动作：执行真实 C1 单批次并回填结果  
产物：`design/validation/2026-03-26-gate4-stage-c-real-c1-pass-validation.md`、`design/validation/2026-03-26-gate4-stage-c-real-c1-dod-validation.md`

当前进展：真实 C1 单批次结果 `stage_c_passed`，阶段结论 `Conditional-Go`（可进入 C2 评审准备）。

5. 事件：真实 C1 审计收口  
动作：将 `stage_c_real_c1_receipt.json` 的 `evidence_ref` 替换为真实引用并复核  
产物：`design/validation/2026-03-26-gate4-stage-c-real-c1-audit-close-validation.md`

6. 事件：C2 专项评审结论落盘（已满足）  
动作：按 `No-Go` 结论先关闭阻断项（C1 连续两批成功 + 审计收口），不直接执行 C2  
产物：`design/2026-03-26-gate4-stage-c-c2-office-hours-minutes-v1.md`、`design/2026-03-26-gate4-stage-c-c2-plan-eng-review-minutes-v1.md`

当前进展：已完成真实 C1 第 2 批并通过，阻断项关闭记录见 `design/validation/2026-03-26-gate4-stage-c-c2-blockers-close-validation.md`。

7. 事件：C2 阻断项 A/B 全部关闭（已满足）  
动作：触发 C2 复评（`office-hours -> plan-eng-review`）并形成最新放行结论  
产物：`design/2026-03-26-gate4-stage-c-c2-office-hours-rereview-minutes-v1.md`、`design/2026-03-26-gate4-stage-c-c2-plan-eng-rereview-minutes-v1.md`

当前进展：复评发现新增一致性阻断项 C，已完成关闭并通过最终复评。

8. 事件：阻断项 C 关闭并完成最终复评（已满足）  
动作：按最终放行结论执行 C2 单批次闭环（`G4-C2-T2 -> T3 -> T4 -> T5`）  
产物：`design/2026-03-26-gate4-stage-c-c2-office-hours-final-minutes-v1.md`、`design/2026-03-26-gate4-stage-c-c2-plan-eng-final-minutes-v1.md`、`design/validation/2026-03-26-gate4-stage-c-real-c2-batch1-pass-validation.md`、`design/validation/2026-03-26-gate4-stage-c-c2-dod-validation.md`

当前进展：C2 单批次执行结果 `stage_c_passed`，未触发停机阈值。

9. 事件：C2 单批次 DoD 形成（已满足）  
动作：发起“是否进入 C2 连续批次”的下一轮复评  
产物：C2 连续批次复评纪要（待创建）
