# 2026-03-28 RH-T5-B01 路由整改尝试 A6（最小复现包）

日期：2026-03-28  
事件：`rh_t5_b01_route_parity_remediation_requested`  
目标：提供可复核的最小复现脚本与证据包，确认 default/explicit 路由分裂在当前主运行态仍可稳定复现。

## 1) 尝试动作

新增最小复现脚本：`scripts/rh_t5_b01_min_repro.sh`，一次执行同时采集：

1. 运行时版本与绑定基线（`openclaw --version`、`openclaw agents list --bindings --json`）
2. 默认路径调用（仅 `--to`，不显式 `--agent`）
3. 显式路径调用（`--agent steward --to`）
4. 两条路径 `sessionKey` 比对结论

执行命令：

```bash
OPENCLAW_AGENT_CONTAINER=agent_argus bash scripts/rh_t5_b01_min_repro.sh
```

## 2) 证据

- 证据目录：`design/validation/artifacts/openclaw-rh-t5-b01-min-repro-20260328-150851`
- 摘要文件：`design/validation/artifacts/openclaw-rh-t5-b01-min-repro-20260328-150851/artifacts/summary.txt`
- 关键结果：
  - `version_exit=0`
  - `agents_bindings_exit=0`
  - `default_exit=0`
  - `explicit_exit=0`
  - `default_session_key=agent:main:main`
  - `explicit_session_key=agent:steward:main`
  - `result=route_mismatch_detected`

## 3) 结论

- `attempt_id=A6`
- `attempt_result=not_resolved`
- `route_mismatch_persists=yes`
- `note=最小复现包确认 RH-T5-B01 在当前主运行态仍稳定可复现，阻断继续保持开启`

下一事件建议：保持 `rh_t5_b01_route_parity_remediation_requested`，将 A6 复现包作为 issue #37 的标准复现输入，继续推进平台级修复路径。
