# 2026-03-28 RH-T5-B01 外部阻断下的并行主链策略（v1）

更新时间：2026-03-28  
适用范围：`RH-T5-B01` 未关闭期间的项目推进策略  
目标：在不绕过阻断治理的前提下，允许其它主链并行推进

## 1) 当前边界

- `RH-T5-B01` 继续保持开启，不做例外关单。
- 路由相关外部阻断与其它业务主链解耦，采用“双轨并行”：
  - 轨道 A：`RH-T5-B01` 事件驱动治理（等待上游反馈触发）
  - 轨道 B：不依赖“默认 `--to` 选路语义”的其它主链持续推进

## 2) 并行推进准入规则

满足以下条件即可进入并行主链开发：

- 新任务不依赖“默认 `openclaw agent --to` 自动选 agent”行为。
- 新任务可在“显式 `--agent` 强制”前提下完成。
- 任何路由相关改动仍需回到 `RH-T5-B01` 侧线治理流程，不得在业务主链里隐式放行。

## 3) 强制护栏（并行期间持续生效）

- 关键链路一律使用 `scripts/openclaw_agent_safe.sh`。
- 禁止在关键路径提交“`--to` 但无 `--agent`”的直连调用。
- 若 `scripts/*.sh` 或 `deploy/*.sh` 发生变更，必须执行：
  - `bash scripts/agent_call_guard.sh`
  - `bash scripts/premerge_check.sh`

## 4) 上游事件触发口径（侧线）

- 上游追踪使用新单：`openclaw/openclaw#56370`（`#56267` 已关闭）。
- 仅当上游出现新反馈或候选修复时，执行：

```bash
UPSTREAM_ISSUE_NUMBER=56370 EVENT_REASON="upstream_feedback_check" AUTO_REOPEN_LOCAL_ISSUE="no" BUNDLE_STRICT="no" OPENCLAW_AGENT_CONTAINER=agent_argus bash scripts/rh_t5_b01_event_runner.sh
```

- 关单门槛保持不变：`a6/a7/a8` 全绿 + `blocker_close_ready=yes` + `final_result=ready_for_blocker_close_rereview`。

## 5) 本轮并行启动记录

- 并行主链分支：`codex/parallel-mainline-next01`
- 触发来源：用户确认“P5 保持开启，但允许转入其它分支主链并行推进”
- 结论：并行策略生效，主线继续事件驱动，不按时间推进

