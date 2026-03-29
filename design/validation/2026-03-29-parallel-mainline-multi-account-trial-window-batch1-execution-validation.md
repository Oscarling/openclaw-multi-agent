# 2026-03-29 并行主链多账号自动登录受控试运行窗口首批执行验证（A40）

## 1) 触发背景

- A39 已发布正式结论 `Go（受控窗口）`，`next_event=parallel_mainline_multi_account_trial_window_review_completed`。
- 本次执行目标：在既定边界内完成双账号首批窗口执行，并产出“通过/停机”唯一结论。

## 2) 执行边界（沿用 A39）

1. 仅允许账号：`xhs_demo_001`、`xhs_demo_002`
2. 仅允许阶段：Gate-4 Stage A/B/C 既有门禁链路，不放宽阈值
3. 仅允许受控执行：保持 `ticket/receipt/真实 evidence_ref` 约束
4. 侧线 `RH-T5-B01` 保持开启，不得绕过显式 agent 与安全调用护栏

## 3) 执行命令（首批窗口）

账号 1（`xhs_demo_001`）：

```bash
EXEC_ROOT="design/validation/artifacts/openclaw-parallel-mainline-trial-window-batch1-account1-20260329-124449" \
GATE4_ACCOUNT_ID='xhs_demo_001' \
GATE4_OPERATOR='lingguozhong' \
GATE4_STAGE_A_TICKET_ID='GATE4-A-001' \
GATE4_STAGE_B_TICKET_ID='GATE4-B-001' \
GATE4_STAGE_C_TICKET_ID='GATE4-C-REAL-001' \
GATE4_MANUAL_RECEIPT_FILE='runtime/argus/config/gate4/manual_receipt.json' \
GATE4_STAGE_B_RELEASE_ID='XHS-REL-001' \
GATE4_RELEASE_RECEIPT_FILE='runtime/argus/config/gate4/release_receipt.json' \
GATE4_PHASE_ID='C1' \
GATE4_STAGE_C_BATCH_ID='XHS-REAL-C1-BATCH-001' \
GATE4_STAGE_C_RELEASE_ID='XHS-REAL-C1-REL-001' \
GATE4_STAGE_C_RECEIPT_FILE='runtime/argus/config/gate4/stage_c_real_c1_receipt.json' \
GATE4_STAGE_C_REQUIRE_REAL_EVIDENCE='yes' \
bash ./deploy/parallel_mainline_gate4_abc_recheck.sh
```

账号 2（`xhs_demo_002`）：

```bash
EXEC_ROOT="design/validation/artifacts/openclaw-parallel-mainline-trial-window-batch1-account2-20260329-124458" \
GATE4_ACCOUNT_ID='xhs_demo_002' \
GATE4_OPERATOR='lingguozhong' \
GATE4_STAGE_A_TICKET_ID='GATE4-A-002' \
GATE4_STAGE_B_TICKET_ID='GATE4-B-002' \
GATE4_STAGE_C_TICKET_ID='GATE4-C-002' \
GATE4_MANUAL_RECEIPT_FILE='runtime/argus/config/gate4/manual_receipt_xhs_demo_002.json' \
GATE4_STAGE_B_RELEASE_ID='XHS-REL-002' \
GATE4_RELEASE_RECEIPT_FILE='runtime/argus/config/gate4/release_receipt_xhs_demo_002.json' \
GATE4_PHASE_ID='C1' \
GATE4_STAGE_C_BATCH_ID='XHS-REAL-C1-BATCH-002' \
GATE4_STAGE_C_RELEASE_ID='XHS-REAL-C1-REL-002' \
GATE4_STAGE_C_RECEIPT_FILE='runtime/argus/config/gate4/stage_c_real_c1_receipt_xhs_demo_002.json' \
GATE4_STAGE_C_REQUIRE_REAL_EVIDENCE='yes' \
bash ./deploy/parallel_mainline_gate4_abc_recheck.sh
```

## 4) 结果摘要

- 账号 1：
  - `stage_a_result=stage_a_passed`
  - `stage_b_result=stage_b_passed`
  - `stage_c_result=stage_c_passed`
  - `overall_result=parallel_gate4_abc_recheck_passed`
  - `stagec_receipt_success_rate=1.0`
  - `stagec_receipt_failure_count=0`
  - `stagec_receipt_halt_triggered=no`
- 账号 2：
  - `stage_a_result=stage_a_passed`
  - `stage_b_result=stage_b_passed`
  - `stage_c_result=stage_c_passed`
  - `overall_result=parallel_gate4_abc_recheck_passed`
  - `stagec_receipt_success_rate=1.0`
  - `stagec_receipt_failure_count=0`
  - `stagec_receipt_halt_triggered=no`

## 5) 唯一结论

- 结论：`parallel_mainline_multi_account_trial_window_batch1_passed`
- 判定：通过（不停机）
- 依据：
  - 双账号 Stage A/B/C 严格链路均通过
  - 两账号 Stage C 均满足 `success_rate >= 0.95` 且 `halt_triggered=no`
  - 证据链保持真实引用且可追溯

## 6) 证据路径

- 账号 1 总摘要：`design/validation/artifacts/openclaw-parallel-mainline-trial-window-batch1-account1-20260329-124449/artifacts/summary.txt`
- 账号 1 Stage C 摘要：`design/validation/artifacts/openclaw-parallel-mainline-trial-window-batch1-account1-20260329-124449/stage-c/artifacts/stage-c-summary.txt`
- 账号 2 总摘要：`design/validation/artifacts/openclaw-parallel-mainline-trial-window-batch1-account2-20260329-124458/artifacts/summary.txt`
- 账号 2 Stage C 摘要：`design/validation/artifacts/openclaw-parallel-mainline-trial-window-batch1-account2-20260329-124458/stage-c/artifacts/stage-c-summary.txt`

## 7) 下一事件

`parallel_mainline_multi_account_trial_window_batch1_completed`
