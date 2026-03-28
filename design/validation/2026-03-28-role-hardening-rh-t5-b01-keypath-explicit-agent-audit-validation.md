# 2026-03-28 RH-T5-B01 关键链路显式 Agent 审计验证

日期：2026-03-28  
范围：`RH-T5-B01` 治理中的关键链路执行口径审计。  
触发事件：`rh_t5_route_guardrail_enforced`

## 1) 验证目标

- 验证关键脚本中的 `openclaw agent` 调用均包含显式 `--agent` 语义。
- 验证 `openclaw_agent_safe.sh` 对“未显式 `--agent`”调用持续阻断。

## 2) 证据目录

- `design/validation/artifacts/openclaw-rh-t5-b01-keypath-audit-20260328-134226/summary.txt`
- `design/validation/artifacts/openclaw-rh-t5-b01-keypath-audit-20260328-134226/keypath-audit.tsv`
- `design/validation/artifacts/openclaw-rh-t5-b01-keypath-audit-20260328-134226/wrapper-block.err.log`

## 3) 审计范围与结果

关键脚本：

1. `deploy/recovery_drill.sh`
2. `deploy/host_apply_drill.sh`
3. `deploy/gate3_event_recheck.sh`

审计摘要：

- `keypath_all_ok=yes`
- `wrapper_blocks_missing_agent=yes`
- `result=pass`

## 4) 结论

- `keypath_explicit_agent_audit=passed`
- `guardrail_enforcement_continues=yes`
- `rh_t5_b01_blocker_closed=no`
- `note=关键链路显式 agent 约束已审计通过，但默认/显式路由口径差异仍需在最终复评中决定是否关单`
