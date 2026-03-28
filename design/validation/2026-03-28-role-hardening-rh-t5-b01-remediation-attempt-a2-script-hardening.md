# 2026-03-28 RH-T5-B01 路由整改尝试 A2（关键脚本护栏硬化）

日期：2026-03-28  
事件：`rh_t5_b01_route_parity_remediation_requested`  
目标：将关键执行链的 `openclaw agent` 调用统一收敛到 `openclaw_agent_safe.sh`，降低误用默认路由风险。

## 1) 本次改动

已将以下脚本中的关键 agent 调用改为通过 wrapper 执行：

1. `deploy/recovery_drill.sh`
2. `deploy/host_apply_drill.sh`
3. `deploy/gate3_event_recheck.sh`

## 2) 审计证据

- 证据目录：`design/validation/artifacts/openclaw-rh-t5-b01-remediation-a2-20260328-135825`
- 摘要：`summary.txt`
  - `all_key_files_use_wrapper=yes`
  - `any_direct_openclaw_agent_call=no`
  - `result=pass`
- 明细：`key-files.tsv`

## 3) 结论

- `attempt_id=A2`
- `attempt_result=guardrail_hardening_passed`
- `direct_keypath_call_removed=yes`
- `route_mismatch_resolved=no`
- `note=A2 降低了关键链路误用风险，但未直接消除 default/explicit 路由分裂，RH-T5-B01 继续保持开启`
