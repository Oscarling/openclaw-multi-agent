# 2026-03-28 RH-T5-B01 Upstream Maintainer Handoff（v2）

目标：给上游 maintainer 提供最短可执行复现路径与关闭判定口径，减少来回沟通成本。

## 1) 问题定义（单句）

- 在 OpenClaw `2026.3.12` 环境，`openclaw agent --to ...`（未显式 `--agent`）会命中 `agent:main:main`，而显式 `--agent steward --to ...` 命中 `agent:steward:main`，存在默认/显式路由口径不一致。

## 2) 最短复现

在目标容器（本项目为 `agent_argus`）执行：

```bash
OPENCLAW_AGENT_CONTAINER=agent_argus bash scripts/rh_t5_b01_min_repro.sh
```

关注摘要：

- `default_session_key`
- `explicit_session_key`
- `result`（预期目前为 `route_mismatch_detected`）

## 3) 受控排除（已做）

```bash
OPENCLAW_AGENT_CONTAINER=agent_argus bash scripts/rh_t5_b01_controlled_comparison.sh
OPENCLAW_AGENT_CONTAINER=agent_argus bash scripts/rh_t5_b01_to_path_probe.sh
```

已有结论：

- 分裂与 `provider/model/profile`、`session-id` 差异无直接关联（A7）。
- 分裂主要集中在默认 `--to` 路径分支（A8）。

## 4) 期望语义（请求 maintainer 明确）

- 当用户未显式传 `--agent` 且传入 `--to` 时，默认路由是否应与默认入口代理一致（本项目默认入口为 `steward`）？
- 若当前行为是预期，请提供稳定规约与兼容策略；若非预期，请给出修复路径或候选版本。

## 5) 关闭判定（本地复检口径）

仅当以下同时满足才进入关单复评：

- `a6_result=route_parity_ok`
- `a7_result=route_split_not_detected_under_controlled_pmp`
- `a8_result=to_path_specific_split_not_detected`
- `blocker_close_ready=yes`

## 6) 关联

- 上游 issue：`https://github.com/openclaw/openclaw/issues/56267`
- 本地追踪：`https://github.com/Oscarling/openclaw-multi-agent/issues/37`
- 触发卡：`design/validation/2026-03-28-rh-t5-b01-upstream-feedback-trigger-card-v1.md`
