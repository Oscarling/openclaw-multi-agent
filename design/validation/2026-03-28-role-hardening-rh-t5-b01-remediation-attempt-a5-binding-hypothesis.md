# 2026-03-28 RH-T5-B01 路由整改尝试 A5（绑定假设验证）

日期：2026-03-28  
事件：`rh_t5_b01_route_parity_remediation_requested`  
目标：验证“通过绑定策略微调”是否可消除 default/explicit 路由分裂。

## 1) 测试环境

- 隔离影子容器：`agent_argus_a4_shadow`
- 版本：`OpenClaw 2026.3.24`
- 现有绑定基线：`steward -> telegram accountId=default`

## 2) 假设与动作

动作 A：补充 `--bind telegram`（不带 account）  
命令：`openclaw agents bind --agent steward --bind telegram --json`  
结果：`skipped=["telegram"]`（未产生新绑定）

动作 B：尝试 `--bind last`  
命令：`openclaw agents bind --agent steward --bind last --json`  
结果：`Unknown channel "last"`（不支持）

动作 C：动作 A/B 后重跑 route parity  
命令：`OPENCLAW_AGENT_CONTAINER=agent_argus_a4_shadow bash ./deploy/cli_route_parity_probe.sh`

## 3) 证据

- parity 证据目录：`design/validation/artifacts/openclaw-rh-t5-b01-remediation-a5-binding-hypothesis-20260328-141825`
- parity 摘要：
  - `default_route_session_key=agent:main:main`
  - `explicit_route_session_key=agent:steward:main`
  - `probe_result=route_mismatch_detected`

## 4) 结论

- `attempt_id=A5`
- `attempt_result=not_resolved`
- `binding_hypothesis_supported=no`
- `note=绑定微调未改变 default/explicit 路由分裂，RH-T5-B01 继续保持开启`
