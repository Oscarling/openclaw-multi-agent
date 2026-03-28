# 2026-03-28 RH-T5-B01 路由整改尝试 A8（`--to` 路径特异性探针）

日期：2026-03-28  
事件：`rh_t5_b01_route_parity_remediation_requested`  
目标：确认路由分裂是否主要出现在 `--to` 路径，而非所有默认路径。

## 1) 尝试动作

新增并执行脚本：`scripts/rh_t5_b01_to_path_probe.sh`

在同一容器、同一模型配置下执行四组对照：

1. `default_no_to`：默认调用，不带 `--to`
2. `explicit_no_to`：显式 `--agent steward`，不带 `--to`
3. `default_with_to`：默认调用，带 `--to`
4. `explicit_with_to`：显式 `--agent steward`，带 `--to`

统一采集：`sessionKey`、`workspaceDir`、`provider/model/profile`、`runId/status`。

执行命令：

```bash
OPENCLAW_AGENT_CONTAINER=agent_argus bash scripts/rh_t5_b01_to_path_probe.sh
```

## 2) 证据

- 证据目录：`design/validation/artifacts/openclaw-rh-t5-b01-a8-to-path-probe-20260328-153942`
- 摘要文件：`design/validation/artifacts/openclaw-rh-t5-b01-a8-to-path-probe-20260328-153942/artifacts/summary.txt`
- 关键结果：
  - `default_no_to_workspace=/root/.openclaw/workspace/steward`
  - `default_with_to_workspace=/root/.openclaw/workspace-main`
  - `default_with_to_session_key=agent:main:main`
  - `explicit_with_to_session_key=agent:steward:main`
  - `pmp_consistent=yes`
  - `to_path_split_confirmed=yes`
  - `result=to_path_specific_split_confirmed`

## 3) 结论

- `attempt_id=A8`
- `attempt_result=not_resolved`
- `route_mismatch_persists=yes`
- `inference=在 provider/model/profile 受控一致条件下，默认不带 --to 与默认带 --to 命中的工作区不同，分裂集中在 --to 路径`
- `note=RH-T5-B01 继续保持开启；下一步应优先定位 --to 路由分支的默认 agent 选择逻辑`

下一事件建议：保持 `rh_t5_b01_route_parity_remediation_requested`，将 A8 证据补充到 issue #37，推动平台侧针对 `--to` 路径修复。
