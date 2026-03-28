# 2026-03-28 并行主链多账号自动登录受控试运行输入包（A39，v1）

scope: `parallel_mainline_multi_account_trial_window_prep_v1`  
日期：2026-03-28  
触发事件：`parallel_mainline_multi_account_exec_validation_completed`

## 1) 目标

在 A38 执行验证通过后，为“多账号自动登录受控试运行窗口”提供统一输入材料，确保试运行具备可执行边界与阻断口径。

## 2) 输入材料

1. `design/2026-03-28-parallel-mainline-multi-account-autologin-implementation-prep-v2.md`
2. `design/2026-03-28-parallel-mainline-multi-account-autologin-event-card-v1.md`
3. `design/validation/2026-03-28-parallel-mainline-multi-account-config-parity-validation.md`
4. `design/validation/2026-03-28-parallel-mainline-multi-account-failure-injection-validation.md`
5. `design/validation/2026-03-28-parallel-mainline-multi-account-impl-dod-validation.md`

## 3) 试运行边界（候选）

1. 仅允许账号：`xhs_demo_001`、`xhs_demo_002`
2. 仅允许阶段：Stage A/B/C 既有门禁链路，不放开阈值
3. 单窗口最大批次：沿用 `C1 max_batch_size=5`
4. 必须满足：真实证据引用、ticket、回执链路完整

## 4) 通过/阻断口径

通过（Go）：

1. 双账号执行成功率 >= 0.95
2. `halt_triggered=no`
3. 无越权调用、无默认路由绕过

阻断（No-Go）：

1. 任一账号触发 `halt_triggered=yes`
2. 任一账号出现占位证据或回执不合法
3. 出现 `blocked_account_not_allowlisted` 或 `blocked_need_ticket` 且未在窗口内修复

## 5) 下一事件建议

`parallel_mainline_multi_account_trial_window_review_requested`
