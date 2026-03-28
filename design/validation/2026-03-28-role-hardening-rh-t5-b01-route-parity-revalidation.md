# 2026-03-28 RH-T5-B01 路由口径复评（revalidation）

日期：2026-03-28  
范围：`RH-T5-B01`（CLI 默认/显式路由口径不一致）复评。  
触发事件：`rh_t5_route_parity_revalidated`

## 1) 执行信息

- 执行命令：`PROBE_ROOT="design/validation/artifacts/openclaw-rh-t5-b01-route-parity-20260328-133402" bash ./deploy/cli_route_parity_probe.sh`
- 证据目录：`design/validation/artifacts/openclaw-rh-t5-b01-route-parity-20260328-133402`
- 摘要文件：`design/validation/artifacts/openclaw-rh-t5-b01-route-parity-20260328-133402/artifacts/probe-summary.txt`

## 2) 复评结果

- `default_route_exit=0`
- `explicit_route_exit=0`
- `default_route_session_key=agent:main:main`
- `explicit_route_session_key=agent:steward:main`
- `probe_result=route_mismatch_detected`

## 3) 结论

- `route_parity_revalidation_result=route_mismatch_detected`
- `rh_t5_b01_blocker_closed=no`
- `note=默认/显式路由口径仍不一致，阻断项继续保持打开`

下一事件建议：`rh_t5_final_go_nogo_rereview_requested`
