# 2026-03-28 RH-T5-B01 上游反馈水位线去重验证（A17）

## 1) 背景

- 现状：上游反馈触发逻辑基于“存在外部评论”。
- 风险：同一条外部反馈在后续轮次可能重复触发复检包，造成冗余执行。
- 目标：增加“已处理反馈水位线”能力，仅在“新外部反馈”出现时触发复检包。

## 2) 代码改动

- `scripts/rh_t5_b01_upstream_feedback_probe.sh`
  - 新增 `STATE_FILE` 输入（默认：`runtime/argus/config/rh_t5_b01/upstream_feedback_state.env`）
  - 新增字段：
    - `upstream_new_feedback_detected`
    - `state_present`
    - `processed_*`（已处理水位线）
    - `upstream_last_external_comment_*`
  - 事件判定改为：
    - `local issue` 未开 -> `reopen_local_tracking_issue`
    - 存在“未处理的新外部反馈” -> `upstream_feedback_received`
    - 其他 -> `waiting_upstream_feedback`
- `scripts/rh_t5_b01_event_runner.sh`
  - 透传 `STATE_FILE` 给 probe
  - 摘要新增：
    - `upstream_new_feedback_detected`
    - `state_write_result`
  - 仅当 `run_upstream_recheck_bundle` 且 `bundle_exit_0` 时写入水位线状态文件。

## 3) 实测验证

### 3.1 真实口径基线（无新反馈）

```bash
EVENT_REASON="a17_watermark_baseline" AUTO_REOPEN_LOCAL_ISSUE="no" BUNDLE_STRICT="no" OPENCLAW_AGENT_CONTAINER=agent_argus STATE_FILE="runtime/argus/config/rh_t5_b01/upstream_feedback_state.env" bash scripts/rh_t5_b01_event_runner.sh
```

结果：

- `next_event=waiting_upstream_feedback`
- `upstream_feedback_detected=no`
- `upstream_new_feedback_detected=no`
- `action_taken=wait`

证据：

- `design/validation/artifacts/openclaw-rh-t5-b01-event-runner-20260328-170850/artifacts/summary.txt`

### 3.2 去重能力双跑（隔离态，临时 state）

说明：使用临时 `STATE_FILE=/tmp/rh_t5_b01_watermark_test.env`，并用测试 owner login 触发“外部评论”路径，仅用于验证去重行为，不影响正式口径。

第 1 跑（应触发复检包并写状态）：

```bash
ISSUE_OWNER_LOGIN="__watermark_test__" EVENT_REASON="a17_watermark_synthetic_run1" AUTO_REOPEN_LOCAL_ISSUE="no" BUNDLE_STRICT="no" OPENCLAW_AGENT_CONTAINER=agent_argus STATE_FILE="/tmp/rh_t5_b01_watermark_test.env" EXEC_ROOT="design/validation/artifacts/openclaw-rh-t5-b01-event-runner-a17-sim-run1-20260328-171001" bash scripts/rh_t5_b01_event_runner.sh
```

结果：

- `next_event=upstream_feedback_received`
- `upstream_new_feedback_detected=yes`
- `action_taken=run_upstream_recheck_bundle`
- `action_result=bundle_exit_0`
- `state_write_result=written`

第 2 跑（同输入，应去重等待）：

```bash
ISSUE_OWNER_LOGIN="__watermark_test__" EVENT_REASON="a17_watermark_synthetic_run2" AUTO_REOPEN_LOCAL_ISSUE="no" BUNDLE_STRICT="no" OPENCLAW_AGENT_CONTAINER=agent_argus STATE_FILE="/tmp/rh_t5_b01_watermark_test.env" EXEC_ROOT="design/validation/artifacts/openclaw-rh-t5-b01-event-runner-a17-sim-run2-20260328-171514" bash scripts/rh_t5_b01_event_runner.sh
```

结果：

- `next_event=waiting_upstream_feedback`
- `upstream_feedback_detected=yes`
- `upstream_new_feedback_detected=no`
- `action_taken=wait`
- `state_write_result=not_applicable`

证据：

- `design/validation/artifacts/openclaw-rh-t5-b01-event-runner-a17-sim-run1-20260328-171001/artifacts/summary.txt`
- `design/validation/artifacts/openclaw-rh-t5-b01-event-runner-a17-sim-run2-20260328-171514/artifacts/summary.txt`

## 4) 结论

- A17 去重逻辑有效：同一外部反馈不会在后续轮次重复触发复检包。
- 不改变 `RH-T5-B01` 阻断结论；当前仍需等待上游 maintainer 新反馈。
