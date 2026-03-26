# 2026-03-26 Gate-3 v2 复检记录（R14）

更新时间：2026-03-26  
触发事件：`day8_observation_logged`  
执行命令：`GATE3_TRIGGER_EVENT="day8_observation_logged" GATE3_RECHECK_ID="R14" bash ./deploy/gate3_event_recheck.sh`  
证据目录：`design/validation/artifacts/gate3-v2-recheck-r14-20260326-142431`

## 1) 运行态快照

- 通道状态（ts=`1774506273938`）：
  - Telegram `running=true`
  - `probe_ok=true`
  - `lastError=null`
  - bot=`argus1986_bot`
- 入口与绑定：
  - 默认入口：`steward`
  - `steward` 绑定：`telegram accountId=default`

## 2) 复检样例结果

| 样例 | runId | 结果 | 说明 |
|---|---|---|---|
| R14-C11 | `091e48fc-53f5-4eeb-80bb-2003e577a391` | 通过 | 边界符合预期 |
| R14-C05 | `a636dad8-0f76-442d-afd3-6bac716ac120` | 通过 | 边界符合预期 |
| R14-C13 | `4caf170e-ae92-4efe-9ba6-7d11de7678d6` | 通过 | 边界符合预期 |
| R14-X4 | `1a05a257-d24f-422a-bd39-93d2e4e28951` | 通过 | 边界符合预期 |
| R14-H5 | `db61e98b-bf40-4fa6-813b-49c5098fcb63` | 通过 | 边界符合预期 |

## 3) 复检结论

- 关键样例全部通过，运行态边界稳定。
- 未触发回滚阈值。
- 结论：维持受控观察口径，继续按事件触发执行后续复检。
