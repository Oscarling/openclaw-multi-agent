# 2026-03-28 并行主链多账号异常注入演练记录（A38-T2）

## 1) 验证目标

验证 A37 定义的三类高频异常是否能被门禁正确阻断，并输出明确状态码。

## 2) 异常场景与结果

1. allowlist 漏配（移除 `xhs_demo_002`）  
   - 摘要：`design/validation/artifacts/openclaw-parallel-mainline-a38-failure-allowlist-missing-20260328-233520/artifacts/stage-a-summary.txt`  
   - 期望：`blocked_account_not_allowlisted`  
   - 实际：`stage_a_result=blocked_account_not_allowlisted`（命中）

2. 发布回执 `release_id` 错配  
   - 摘要：`design/validation/artifacts/openclaw-parallel-mainline-a38-failure-invalid-release-receipt-20260328-233520/artifacts/stage-b-summary.txt`  
   - 期望：`waiting_release_receipt_fix`  
   - 实际：`stage_b_result=waiting_release_receipt_fix`（命中）

3. `gated_auto` 账号缺少 ticket  
   - 摘要：`design/validation/artifacts/openclaw-parallel-mainline-a38-failure-missing-ticket-20260328-233520/artifacts/stage-b-summary.txt`  
   - 期望：`blocked_need_ticket`  
   - 实际：`stage_b_result=blocked_need_ticket`（命中）

## 3) 结论

- 异常注入演练通过：`parallel_mainline_multi_account_failure_injection_passed`
- 门禁行为与 A37 事件执行卡定义一致，未出现静默放行。
