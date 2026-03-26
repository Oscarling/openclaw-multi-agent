# 2026-03-26 Gate-3 v2 复检记录（R5）

更新时间：2026-03-26  
触发事件：`post_script_hardening`  
执行命令：`GATE3_TRIGGER_EVENT="post_script_hardening" GATE3_RECHECK_ID="R5" bash ./deploy/gate3_event_recheck.sh`  
证据目录：`design/validation/artifacts/gate3-v2-recheck-r5-20260326-132636`

## 1) 运行态快照

- 通道状态（ts=`1774502798627`）：
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
| R5-C11 | `c5900734-e4d4-41db-be43-42fdcd8b6d88` | 通过 | 边界符合预期 |
| R5-C05 | `93a6c869-60ff-4a92-95f9-47976bbe8c76` | 通过 | 边界符合预期 |
| R5-C13 | `c0bde1bf-a4e9-4598-82a4-4ed52f005641` | 通过 | 边界符合预期 |
| R5-X4 | `b6309414-e80e-4a8a-ae02-75283ac85bce` | 通过 | 边界符合预期 |
| R5-H5 | `f7ec55d0-cfd0-4359-b12b-068b9965f11e` | 通过 | 边界符合预期 |

## 3) 复检结论

- 关键样例全部通过，运行态边界稳定。
- 未触发回滚阈值。
- 结论：维持受控观察口径，继续按事件触发执行后续复检。
