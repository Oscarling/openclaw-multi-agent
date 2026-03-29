# 2026-03-29 并行主链多账号自动登录受控窗口常态值守节奏与触发规则（A47，v1）

scope: `parallel_mainline_multi_account_trial_window_steady_watch_cadence_rules_v1`  
日期：2026-03-29  
触发事件：`parallel_mainline_multi_account_trial_window_steady_state_watch_review_completed`

## 1) 目标

把常态值守从“单次复核”提升为“可重复执行的事件规则”，确保后续推进不依赖固定时间点。

## 2) 事件触发规则

触发常态值守复核（A48+）的事件：

1. `steady_watch_manual_recheck_requested`：运营或审计手动请求复核。
2. `steady_watch_release_receipt_changed`：任一账号 release/stage-c 回执发生变更。
3. `steady_watch_guardrail_updated`：护栏脚本、运行手册或门禁规则发生更新。
4. `steady_watch_incident_recovered`：停机事件复评后恢复执行。

## 3) 继续条件与停机条件

继续（Continue）必须同时满足：

1. 双账号 `overall_result=parallel_gate4_abc_recheck_passed`
2. 双账号 Stage C：`halt_triggered=no`
3. 双账号 Stage C：`success_rate >= 0.95`
4. 三本账与 issue 回填完成

停机（Halt）命中任一条：

1. `halt_triggered=yes`
2. 任一关键阶段 `stage_*_result != *_passed`
3. 证据链缺失或占位值回归
4. allowlist/ticket 约束被破坏

## 4) 异常升级路径

1. 记录失败证据到 `design/validation/artifacts/...`
2. 发布升级事件：`steady_watch_escalation_requested`
3. 进入两段式复评：`office-hours -> plan-eng-review`
4. 仅在正式评审 `Go` 后恢复常态值守

## 5) 执行与回填纪律

每次值守复核后必须执行：

1. `python3 scripts/backlog_lint.py`
2. `python3 scripts/backlog_sync.py`
3. `bash scripts/premerge_check.sh`
4. issue `#37` 进展同步（结论 + 下一事件）

## 6) 边界声明

1. 不扩展账号范围（仍为 `xhs_demo_001` / `xhs_demo_002`）。
2. 不关闭 `RH-T5-B01` 阻断跟踪。
3. 不绕过 `scripts/openclaw_agent_safe.sh`。

## 7) 下一事件

`parallel_mainline_multi_account_trial_window_steady_watch_cadence_hardened`
