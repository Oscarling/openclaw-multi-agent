# 2026-03-28 RH-T5-B01 护栏生效验证（阶段记录）

日期：2026-03-28  
范围：`RH-T5-B01`（CLI 默认/显式路由口径不一致）治理中的“工具护栏生效”子验证。  
触发事件：`rh_t5_route_guardrail_enforced`

## 1) 验证目标

- 验证 `scripts/openclaw_agent_safe.sh` 能阻断“未显式 `--agent`”调用。
- 验证显式 `--agent` 路径可正常执行并命中目标角色会话。

## 2) 执行证据

- 证据目录：`design/validation/artifacts/openclaw-rh-t5-b01-guardrail-20260328-132055`
- 摘要文件：`design/validation/artifacts/openclaw-rh-t5-b01-guardrail-20260328-132055/summary.txt`

摘要结果：

- `missing_agent_exit=2`
- `explicit_agent_exit=0`
- `explicit_agent_status=ok`
- `explicit_agent_session_key=agent:steward:main`
- `guardrail_block_ok=yes`
- `explicit_agent_ok=yes`

## 3) 结论

- `guardrail_enforcement_result=passed`
- `rh_t5_b01_blocker_closed=no`
- `note=已完成“护栏生效”子验证，但默认/显式路由口径一致性问题仍需后续复评闭环`

下一事件建议：`rh_t5_route_parity_revalidated`
