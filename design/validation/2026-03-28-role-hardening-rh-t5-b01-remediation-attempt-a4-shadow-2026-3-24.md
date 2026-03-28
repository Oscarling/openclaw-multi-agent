# 2026-03-28 RH-T5-B01 路由整改尝试 A4（影子版本 2026.3.24）

日期：2026-03-28  
事件：`rh_t5_b01_route_parity_remediation_requested`  
目标：验证在影子升级到 `OpenClaw 2026.3.24` 后，default/explicit 路由分裂是否消失。

## 1) 测试方法

- 创建隔离影子容器：`agent_argus_a4_shadow`
- 影子版本：`OpenClaw 2026.3.24`
- 使用拷贝的运行态数据，不改现网 `agent_argus`
- 在影子容器上执行 route parity 探针：
  - `OPENCLAW_AGENT_CONTAINER=agent_argus_a4_shadow bash ./deploy/cli_route_parity_probe.sh`

## 2) 证据

- 探针目录：`design/validation/artifacts/openclaw-rh-t5-b01-remediation-a4-shadow2026324-20260328-141426`
- 摘要文件：`design/validation/artifacts/openclaw-rh-t5-b01-remediation-a4-shadow2026324-20260328-141426/artifacts/probe-summary.txt`
- 关键结果：
  - `default_route_session_key=agent:main:main`
  - `explicit_route_session_key=agent:steward:main`
  - `probe_result=route_mismatch_detected`

## 3) 结论

- `attempt_id=A4`
- `attempt_result=not_resolved`
- `version_under_test=2026.3.24`
- `route_mismatch_persists=yes`
- `note=影子升级未消除 default/explicit 路由分裂，RH-T5-B01 继续保持开启`
