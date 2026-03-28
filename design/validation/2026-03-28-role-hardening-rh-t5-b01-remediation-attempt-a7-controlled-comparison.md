# 2026-03-28 RH-T5-B01 路由整改尝试 A7（受控对比：provider/model/profile + session-id）

日期：2026-03-28  
事件：`rh_t5_b01_route_parity_remediation_requested`  
目标：在受控条件下验证路由分裂是否由 `provider/model/profile` 或 session 维度差异引起。

## 1) 尝试动作

新增并执行脚本：`scripts/rh_t5_b01_controlled_comparison.sh`

脚本在同一容器、同一输入下执行四组调用：

1. `explicit_fixed`：`--agent steward` + 固定 `session-id`
2. `default_fixed`：不带 `--agent` + 同一固定 `session-id`
3. `default_new`：不带 `--agent` + 新 `session-id`
4. `explicit_new`：`--agent steward` + 同一新 `session-id`

并同时采集每组：

- `sessionKey`
- `provider/model/profile`
- `runId/status`

执行命令：

```bash
OPENCLAW_AGENT_CONTAINER=agent_argus bash scripts/rh_t5_b01_controlled_comparison.sh
```

## 2) 证据

- 证据目录：`design/validation/artifacts/openclaw-rh-t5-b01-a7-controlled-comparison-20260328-153046`
- 摘要文件：`design/validation/artifacts/openclaw-rh-t5-b01-a7-controlled-comparison-20260328-153046/artifacts/summary.txt`
- 关键结果：
  - `default_agent_ids=steward`
  - `explicit_fixed_session_key=agent:steward:main`
  - `default_fixed_session_key=agent:main:main`
  - `default_new_session_key=agent:main:main`
  - `explicit_new_session_key=agent:steward:main`
  - `same_sid_route_split=yes`
  - `pmp_consistent=yes`
  - `result=route_split_confirmed_under_controlled_pmp`

## 3) 结论

- `attempt_id=A7`
- `attempt_result=not_resolved`
- `route_mismatch_persists=yes`
- `inference=路由分裂在受控 provider/model/profile 与受控 session-id 条件下仍稳定复现`
- `note=当前证据支持“问题不由 provider/model/profile 差异或 session-id 变化直接导致”的判断，RH-T5-B01 继续保持开启`

下一事件建议：保持 `rh_t5_b01_route_parity_remediation_requested`，将 A7 作为 issue #37 平台修复讨论的根因缩小证据（routing 选择层优先）。
