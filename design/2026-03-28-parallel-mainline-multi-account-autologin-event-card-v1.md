# 2026-03-28 并行主链多账号自动登录事件执行卡（A37，v1）

scope: `parallel_mainline_multi_account_autologin_event_card_v1`  
日期：2026-03-28  
边界：仅用于“实现准备与首轮验证”，不放行自动发布链路。

## 1) 事件链路

### A37-T1：实现准备包落盘

- 触发条件：A36 结论 `Go（受控边界内）`
- 动作：落盘实现准备包 v2
- 产物：`design/2026-03-28-parallel-mainline-multi-account-autologin-implementation-prep-v2.md`

### A37-T2：执行卡落盘

- 触发条件：A37-T1 完成
- 动作：落盘事件执行卡
- 产物：`design/2026-03-28-parallel-mainline-multi-account-autologin-event-card-v1.md`

### A38-T1：配置一致性复检

- 触发条件：`parallel_mainline_multi_account_autologin_impl_prep_completed`
- 动作：复检 `xhs_demo_001/xhs_demo_002` 的 allowlist、receipt、ticket 约束一致性
- 产物：`design/validation/<date>-parallel-mainline-multi-account-config-parity-validation.md`

### A38-T2：异常注入演练

- 触发条件：A38-T1 通过
- 动作：执行 token 缺失、allowlist 漏配、回执不合法三类演练
- 产物：`design/validation/<date>-parallel-mainline-multi-account-failure-injection-validation.md`

### A38-T3：DoD 结论发布

- 触发条件：A38-T2 完成
- 动作：发布“通过/阻断”结论并回填三本账
- 产物：`design/validation/<date>-parallel-mainline-multi-account-impl-dod-validation.md`

## 2) 阻断规则

1. 任一账号出现 `blocked_account_not_allowlisted` 立即阻断。
2. 任一回执出现占位证据字符串立即阻断。
3. 触发 Stage C `halt_triggered=yes` 时立刻停机并转复评。

## 3) 回滚规则

1. 回滚到“手工登录 + 手工回执”模式。
2. 暂停自动登录入口，保留审计证据不覆盖。
3. 新一轮执行前必须重新触发 `office-hours -> plan-eng-review`。

## 4) 下一事件

`parallel_mainline_multi_account_autologin_impl_prep_completed`（当前可触发）
