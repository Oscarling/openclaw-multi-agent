# 2026-03-28 RH-T5-B01 路由整改尝试 A3（channel=last 路径）

日期：2026-03-28  
事件：`rh_t5_b01_route_parity_remediation_requested`  
目标：验证默认路径指定 `--channel last` 是否可与显式 `--agent steward` 路径对齐。

## 1) 尝试动作

执行两组调用并比对 `sessionKey`：

1. 默认路径  
   `openclaw agent --channel last --to +15550001111 ... --json`
2. 显式路径  
   `openclaw agent --agent steward --channel last --to +15550001111 ... --json`

## 2) 证据

- 证据目录：`design/validation/artifacts/openclaw-rh-t5-b01-channel-last-test-20260328-140046`
- 摘要结果：
  - `default_exit=0`
  - `explicit_exit=0`
  - `default_session_key=agent:main:main`
  - `explicit_session_key=agent:steward:main`
  - `same=no`

## 3) 结论

- `attempt_id=A3`
- `attempt_result=not_resolved`
- `route_mismatch_persists=yes`
- `note=channel=last 仍未消除 default/explicit 路由分裂，RH-T5-B01 继续保持开启`
