# 2026-03-29 并行主链多账号自动登录受控窗口常态策略稳定态包（A50，v1）

scope: `parallel_mainline_multi_account_trial_window_steady_strategy_package_v1`  
日期：2026-03-29  
触发事件：`parallel_mainline_multi_account_trial_window_watch_strategy_close_review_completed`

## 1) 目标

在 A49 策略收口通过后，固化“稳定态策略包”，作为后续常态运行的统一策略依据。

## 2) 稳定态定义

满足以下条件即判定处于稳定态：

1. 连续值守复核通过（至少两轮）
2. Continue/Halt 条件执行一致且无冲突
3. 审计与三本账回填无遗漏
4. 侧线阻断（`RH-T5-B01`）处于可观测治理态

## 3) 稳定态维持规则

1. 账号范围固定：`xhs_demo_001`、`xhs_demo_002`
2. 阈值固定：沿用 Gate-4 现行门禁阈值
3. 入口固定：`deploy/parallel_mainline_gate4_abc_recheck.sh`
4. 回填固定：每轮执行后必须完成三本账 + issue #37 同步

## 4) 稳定态升级策略

触发升级评审的事件：

1. `steady_strategy_expansion_requested`
2. `steady_strategy_threshold_change_requested`
3. `steady_strategy_guardrail_change_requested`

升级流程：

1. 发起 `office-hours -> plan-eng-review`
2. 形成 `Go/Conditional-Go/No-Go` 唯一结论
3. 未 `Go` 不得执行范围扩展或阈值调整

## 5) 稳定态降级/停机策略

触发降级或停机的事件：

1. 任一值守复核命中 Halt 条件
2. 审计链路出现关键字段缺失
3. 护栏脚本被绕过或失效

处置动作：

1. 进入 `steady_strategy_escalation_requested`
2. 停止扩展动作，仅保留故障定位与修复
3. 复评 `Go` 前不恢复稳定态推进

## 6) 下一事件

`parallel_mainline_multi_account_trial_window_steady_strategy_package_completed`
