# 2026-03-28 RH-T5-B01 治理行动卡（A19，事件触发版）

适用范围：`RH-T5-B01`（CLI 默认/显式路由口径不一致）  
当前阶段：P5 阻断治理态（`Conditional-Go`）

## 1) 当前统一判断

- 阻断未关闭，继续保持开启。
- 本地治理链条已完整（A1-A17 + A18 双专家评估）。
- 当前主状态为：`waiting_upstream_feedback`。

## 2) 唯一执行入口

默认只使用事件执行器：

```bash
EVENT_REASON="upstream_feedback_check" AUTO_REOPEN_LOCAL_ISSUE="no" BUNDLE_STRICT="no" OPENCLAW_AGENT_CONTAINER=agent_argus bash scripts/rh_t5_b01_event_runner.sh
```

## 3) 事件分流口径（不按时间）

1. `next_event=reopen_local_tracking_issue`
   - 先重开本地 issue `#37`，再回到执行器主线。
2. `next_event=waiting_upstream_feedback`
   - 不触发复检包，不发起关单复评。
   - 维持护栏与门禁（见第 4 节）。
3. `next_event=upstream_feedback_received`
   - 执行器应触发复检包（A6+A7+A8 聚合复核）。
   - 读取复检包摘要中的 `blocker_close_ready` 与 `final_result`。

## 4) waiting 阶段必做项

- 护栏：关键链路继续强制显式 `--agent`，统一走 `scripts/openclaw_agent_safe.sh`。
- 门禁：`deploy/*.sh` 或 `scripts/*.sh` 有变更时，必须执行：
  - `bash scripts/agent_call_guard.sh`
  - `bash scripts/premerge_check.sh`
- 协作：仅做上游增量跟进，不重复刷新同一证据。

## 5) 进入关单复评的硬门槛

仅当复检包同时满足以下条件，才允许触发两段式关闭复评（`office-hours -> plan-eng-review`）：

- `a6_result=route_parity_ok`
- `a7_result=route_split_not_detected_under_controlled_pmp`
- `a8_result=to_path_specific_split_not_detected`
- `blocker_close_ready=yes`
- `final_result=ready_for_blocker_close_rereview`

## 6) 禁止事项

- 不得以“受控例外”方式直接关单。
- 不在无新事件时追加平台修复型本地猜测实验。
- 不绕过事件执行器手工拼接流程并直接宣告状态升级。

## 7) 关联证据

- 双专家评估：`design/2026-03-28-rh-t5-b01-gstack-dual-expert-assessment-minutes-v1.md`
- 触发卡：`design/validation/2026-03-28-rh-t5-b01-upstream-feedback-trigger-card-v1.md`
- A17 验证：`design/validation/2026-03-28-rh-t5-b01-feedback-watermark-validation.md`
