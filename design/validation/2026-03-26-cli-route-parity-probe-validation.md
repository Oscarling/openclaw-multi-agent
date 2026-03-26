# 2026-03-26 CLI 路由口径探针验证记录

更新时间：2026-03-26  
目标：验证 `openclaw agent --to ...` 默认路径是否与显式 `--agent steward` 路径一致。

## 1) 执行脚本

- 脚本：`deploy/cli_route_parity_probe.sh`
- 命令：`bash ./deploy/cli_route_parity_probe.sh`
- 证据目录：`design/validation/artifacts/openclaw-cli-route-probe-20260326-155605/`

## 2) 关键结果

- `default_route_exit=0`
- `explicit_route_exit=0`
- `default_route_session_key=agent:main:main`
- `explicit_route_session_key=agent:steward:main`
- `default_route_agent=main`
- `explicit_route_agent=steward`
- `probe_result=route_mismatch_detected`

结论：默认 `--to` 路径与显式 `--agent steward` 路径仍不一致，已知限制仍存在。

## 3) 当前处置口径

- 联调默认使用 `scripts/openclaw_agent_safe.sh`，强制显式 `--agent`。
- 保留 `deploy/cli_route_parity_probe.sh` 作为事件触发复检工具（升级、恢复、路由相关变更后复跑）。
