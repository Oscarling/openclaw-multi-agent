# 2026-03-28 角色全面固化 RH-T5 项目级收口复核输入包（v1）

scope: `role_hardening_rh_t5_full_close`  
日期：2026-03-28  
模式：事件触发（event-driven），不使用固定时间节点。

## 1) 复核目标

- 对 RH-T1~RH-T4 的执行结果做项目级收口判定。
- 明确是否允许从“角色固化验证态”进入“收口后持续治理态”。
- 固化放行边界、阻断项与下一事件，避免语义外推。

## 2) 输入证据（本轮有效）

1. `design/2026-03-28-role-hardening-event-driven-plan-v1.md`
2. `design/2026-03-28-role-hardening-scope-freeze-v1.md`
3. `design/validation/2026-03-28-role-hardening-rh-t3-runtime-sync-validation.md`
4. `design/validation/2026-03-28-role-hardening-rh-t4-regression-validation.md`
5. `design/validation/2026-03-28-gate3-v2-recheck-r19.md`

## 3) 已知限制（需在评审中显式处理）

- `route_mismatch_detected`：CLI 默认 `--to` 路径与显式 `--agent` 路径不一致（默认落点 `main`，显式落点 `steward`）。
- 当前口径：此项为“已知限制，暂不阻断 RH-T3/RH-T4 通过”，但必须依赖显式 `--agent` 与 `safe wrapper` 护栏。

## 4) 收口评审问题

1. 在现有证据下，RH-T5 是否应给出 `Go / Conditional-Go / No-Go`？
2. 如为 `Conditional-Go`，放行边界应允许到哪一步、禁止到哪一步？
3. 已知限制应否转为项目级阻断项？若是，关闭标准是什么？
4. 下一事件如何命名，才能保持纯事件触发且不误导为自动执行？
