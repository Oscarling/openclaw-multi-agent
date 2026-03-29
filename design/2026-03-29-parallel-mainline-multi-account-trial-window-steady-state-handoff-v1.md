# 2026-03-29 并行主链多账号自动登录受控窗口常态运行交接包（A45，v1）

scope: `parallel_mainline_multi_account_trial_window_steady_state_handoff_v1`  
日期：2026-03-29  
触发事件：`parallel_mainline_multi_account_trial_window_post_drill_close_review_completed`

## 1) 交接目标

将 A42~A44 已确认的受控窗口运行口径转换为常态运行交接清单，确保执行方可按统一规则“继续/停机/回归/审计”。

## 2) 职责分工

1. 运行负责人（Operator）：执行 Gate-4 A/B/C 受控回归，记录执行摘要。
2. 评审负责人（Reviewer）：在异常或停机场景触发两段式复评，给出唯一结论。
3. 审计负责人（Auditor）：检查 `ticket + receipt + evidence_ref` 完整性并回填三本账。

## 3) 常态执行入口

1. 主入口：`deploy/parallel_mainline_gate4_abc_recheck.sh`
2. 运行手册：`design/2026-03-29-parallel-mainline-multi-account-trial-window-runbook-v1.md`
3. 演练基线：`design/validation/2026-03-29-parallel-mainline-multi-account-trial-window-runbook-drill-validation.md`

## 4) 停机与恢复口径

停机触发（任一命中即停）：

1. `halt_triggered=yes`
2. 任一关键阶段 `stage_*_result != *_passed`
3. 证据链缺失或占位值未替换

恢复动作：

1. 固定失败证据到 `design/validation/artifacts/...`
2. 发起 `office-hours -> plan-eng-review`
3. 仅在复评结论 `Go` 后恢复执行

## 5) 审计与台账回填

每轮常态执行后必须执行：

1. `python3 scripts/backlog_lint.py`
2. `python3 scripts/backlog_sync.py`
3. `bash scripts/premerge_check.sh`
4. 同步 issue `#37` 当前结论与下一事件

## 6) 护栏声明

1. 不关闭 `RH-T5-B01`，保持侧线跟踪。
2. 不绕过显式 agent 与 safe wrapper。
3. 不以“提速”为由放宽阈值或省略回填。

## 7) 下一事件

`parallel_mainline_multi_account_trial_window_steady_state_handoff_completed`
