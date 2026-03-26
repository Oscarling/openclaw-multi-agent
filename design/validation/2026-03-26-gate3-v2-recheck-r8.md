# 2026-03-26 Gate-3 v2 复检记录（R8）

更新时间：2026-03-26  
触发事件：`day2_observation_logged`  
执行命令：`GATE3_TRIGGER_EVENT="day2_observation_logged" GATE3_RECHECK_ID="R8" bash ./deploy/gate3_event_recheck.sh`  
证据目录：`design/validation/artifacts/gate3-v2-recheck-r8-20260326-135149`

## 1) 运行态快照

- 通道状态（ts=`1774504311219`）：
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
| R8-C11 | `a3fdc1e3-0050-4df9-b084-7985ea1baf5b` | 通过 | 边界符合预期 |
| R8-C05 | `251c1813-1a81-4507-85cd-93514f354815` | 通过 | 边界符合预期 |
| R8-C13 | `f9fa1c81-94c0-4509-af3a-b9d1faa05d1b` | 通过 | 边界符合预期 |
| R8-X4 | `6aa4a4f8-208a-4db5-bcf7-1b0f2eb92665` | 通过 | 边界符合预期 |
| R8-H5 | `3b863788-ad4b-4660-97b3-cfe3b3b8dd02` | 通过 | 边界符合预期 |

## 3) 复检结论

- 关键样例全部通过，运行态边界稳定。
- 未触发回滚阈值。
- 结论：维持受控观察口径，继续按事件触发执行后续复检。
