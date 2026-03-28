# 2026-03-28 RH-T5-B01 上游反馈触发卡（v1）

更新时间：2026-03-28  
适用范围：`RH-T5-B01`（CLI 默认/显式路由口径不一致）  
目标：将“等待上游反馈”转为事件触发的可执行复检流程，不依赖固定时间点。

## 1) 触发条件（任一满足即触发）

- 上游 issue `openclaw/openclaw#56267` 出现 maintainer 反馈（修复建议 / 修复提交 / 候选版本）。
- 发现可验证候选版本（release/tag/changelog）明确涉及 `openclaw agent --to` 路由行为。
- 本地 issue `#37` 被人工标记“允许执行上游反馈复检”。

## 2) 触发后最小动作

1. 保持本地护栏不变（继续强制 `scripts/openclaw_agent_safe.sh`）。  
2. 运行一键复检包（A6+A7+A8）：

```bash
RECHECK_REASON="upstream_feedback" OPENCLAW_AGENT_CONTAINER=agent_argus bash scripts/rh_t5_b01_upstream_recheck_bundle.sh
```

3. 读取汇总结论：
   - `final_result=ready_for_blocker_close_rereview`：可进入阻断关闭复评
   - `final_result=blocker_still_open`：阻断继续保持开启

## 3) 复检产物

- 一键包汇总：`design/validation/artifacts/openclaw-rh-t5-b01-upstream-recheck-<ts>/artifacts/summary.txt`
- 子探针证据：
  - A6：`a6-min-repro`
  - A7：`a7-controlled-comparison`
  - A8：`a8-to-path-probe`

## 4) 关闭判定口径（全部满足）

- `a6_result=route_parity_ok`
- `a7_result=route_split_not_detected_under_controlled_pmp`
- `a8_result=to_path_specific_split_not_detected`
- `blocker_close_ready=yes`

## 5) 台账回填规则

- 复检后必须同步三本账：`BACKLOG.md`、`DECISIONS.md`、`验收清单.md`
- 本地追踪 issue：`https://github.com/Oscarling/openclaw-multi-agent/issues/37`
- 上游 issue：`https://github.com/openclaw/openclaw/issues/56267`

## 6) 专家参与口径

- `blocker_close_ready=yes` 后，必须触发 `office-hours -> plan-eng-review` 两段式关闭复评（项目级签字）。
