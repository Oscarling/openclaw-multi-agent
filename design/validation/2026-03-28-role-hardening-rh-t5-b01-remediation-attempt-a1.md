# 2026-03-28 RH-T5-B01 路由整改尝试 A1（channel-aware 路径）

日期：2026-03-28  
事件：`rh_t5_b01_route_parity_remediation_requested`  
目标：验证“默认路径显式指定 `--channel telegram`”是否可消除 default/explicit 路由分裂。

## 1) 尝试动作

在同一环境下执行两组调用并比对 `sessionKey`：

1. 默认路径（不显式 `--agent`）  
   `openclaw agent --channel telegram --to +15550001111 ... --json`
2. 显式路径（`--agent steward`）  
   `openclaw agent --agent steward --channel telegram --to +15550001111 ... --json`

## 2) 证据

- 证据目录：`design/validation/artifacts/openclaw-rh-t5-b01-channel-route-test-20260328-135133`
- 关键结果：
  - `default_session_key=agent:main:main`
  - `explicit_session_key=agent:steward:main`
  - `same=no`

## 3) 结论

- `attempt_id=A1`
- `attempt_result=not_resolved`
- `route_mismatch_persists=yes`
- `note=显式 channel 未消除默认/显式路由分裂，RH-T5-B01 继续保持开启`

下一事件建议：继续整改尝试（A2），或升级到平台级修复申请并保留复评链路。
