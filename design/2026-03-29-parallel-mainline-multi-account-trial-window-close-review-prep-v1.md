# 2026-03-29 并行主链多账号自动登录受控试运行窗口收口评审输入包（A41，v1）

scope: `parallel_mainline_multi_account_trial_window_close_review_prep_v1`  
日期：2026-03-29  
触发事件：`parallel_mainline_multi_account_trial_window_batch1_completed`

## 1) 目标

在 A40 首批窗口执行通过后，形成“窗口阶段是否可收口、后续是否维持受控或扩展”的评审输入材料，确保下一步继续事件驱动推进。

## 2) 输入材料

1. `design/validation/2026-03-29-parallel-mainline-multi-account-trial-window-batch1-execution-validation.md`
2. `design/2026-03-28-parallel-mainline-multi-account-trial-window-prep-v1.md`
3. `design/2026-03-28-parallel-mainline-multi-account-trial-window-event-card-v1.md`
4. `design/2026-03-28-parallel-mainline-multi-account-trial-window-office-hours-minutes-v1.md`
5. `design/2026-03-28-parallel-mainline-multi-account-trial-window-plan-eng-review-minutes-v1.md`

## 3) 收口判定问题

1. 双账号首批窗口是否达到“可收口”阈值（成功率、停机阈值、证据链完整）？
2. 是否允许直接扩展账号范围，还是继续维持双账号受控窗口？
3. 侧线 `RH-T5-B01` 未闭环情况下，主线应如何保持不跑偏推进？

## 4) 建议口径（候选）

1. 收口结论优先：先给“窗口阶段收口”唯一判定，再谈扩展路径。
2. 范围控制：维持双账号受控窗口，不自动扩展新账号。
3. 推进方式：以事件触发推进 A42，不按时间节点硬编码。

## 5) 下一事件建议

`parallel_mainline_multi_account_trial_window_close_review_requested`
