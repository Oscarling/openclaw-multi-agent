# 2026-03-29 并行主链多账号自动登录受控窗口运行手册首轮演练验证（A43）

## 1) 触发背景

- A42 已形成运行手册并给出 `next_event=parallel_mainline_multi_account_trial_window_runbook_hardened`。
- 本次目标：按手册完成双账号首轮演练，并输出“继续/停机”唯一结论。

## 2) 执行摘要

账号 1（`xhs_demo_001`）：

- `exec_root=design/validation/artifacts/openclaw-parallel-mainline-runbook-drill-account1-20260329-125328`
- `stage_a_result=stage_a_passed`
- `stage_b_result=stage_b_passed`
- `stage_c_result=stage_c_passed`
- `overall_result=parallel_gate4_abc_recheck_passed`
- Stage C 指标：`success_rate=1.0`、`failure_count=0`、`halt_triggered=no`

账号 2（`xhs_demo_002`）：

- `exec_root=design/validation/artifacts/openclaw-parallel-mainline-runbook-drill-account2-20260329-125336`
- `stage_a_result=stage_a_passed`
- `stage_b_result=stage_b_passed`
- `stage_c_result=stage_c_passed`
- `overall_result=parallel_gate4_abc_recheck_passed`
- Stage C 指标：`success_rate=1.0`、`failure_count=0`、`halt_triggered=no`

## 3) 演练结论

- 唯一结论：`parallel_mainline_multi_account_trial_window_runbook_drill_passed`
- 判定：继续（Continue）
- 判定依据：
  - 双账号均满足继续条件
  - 未命中任何停机条件
  - 审计链路与门禁阈值保持一致

## 4) 证据路径

- 账号 1 总摘要：`design/validation/artifacts/openclaw-parallel-mainline-runbook-drill-account1-20260329-125328/artifacts/summary.txt`
- 账号 1 Stage C 摘要：`design/validation/artifacts/openclaw-parallel-mainline-runbook-drill-account1-20260329-125328/stage-c/artifacts/stage-c-summary.txt`
- 账号 2 总摘要：`design/validation/artifacts/openclaw-parallel-mainline-runbook-drill-account2-20260329-125336/artifacts/summary.txt`
- 账号 2 Stage C 摘要：`design/validation/artifacts/openclaw-parallel-mainline-runbook-drill-account2-20260329-125336/stage-c/artifacts/stage-c-summary.txt`

## 5) 下一事件

`parallel_mainline_multi_account_trial_window_runbook_drill_completed`
