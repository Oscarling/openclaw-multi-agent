# 2026-03-28 RH-T5-B01 gstack 专家再评审纪要（根因 + 解法，v1）

日期：2026-03-28  
范围：`RH-T5-B01`（CLI 默认/显式路由口径不一致）  
评审形式：双专家复核（Root-Cause 专家 + Solution 专家）

## 1) 评审输入

- `scripts/rh_t5_b01_min_repro.sh`
- `scripts/rh_t5_b01_controlled_comparison.sh`
- `scripts/rh_t5_b01_to_path_probe.sh`
- `design/validation/artifacts/openclaw-rh-t5-b01-upstream-recheck-20260328-155702/artifacts/summary.txt`
- `design/validation/2026-03-28-rh-t5-b01-governance-action-card-v1.md`
- `design/validation/2026-03-28-rh-t5-b01-upstream-maintainer-handoff-v2.md`
- `design/validation/artifacts/openclaw-rh-t5-b01-event-runner-20260328-181754/artifacts/summary.txt`

## 2) Root-Cause 专家结论

### 2.1 根因一句话

- 根因并非模型参数或会话漂移，而是 CLI 的默认 `--to` 路径未遵循默认入口 `steward` 的选路语义，仍落入 `main`，导致默认/显式调用分裂。

### 2.2 证据链（A6/A7/A8）

- A6（最小复现）：默认 `--to` 命中 `agent:main:main`，显式 `--agent steward --to` 命中 `agent:steward:main`，`route_mismatch_detected`。
- A7（受控对比）：`provider/model/profile` 一致且同一 `session-id` 下分裂仍在，说明不是 p/m/p 漂移或 session 差异导致。
- A8（路径探针）：不带 `--to` 默认路径落在 `steward`，带 `--to` 默认路径切到 `workspace-main`，显式 `--agent steward --to` 仍在 `steward`，确认分裂集中在默认 `--to` 分支。

### 2.3 排除项

- 不是 `provider/model/profile` 漂移。
- 不是 `session-id` 变化或历史 session 粘性导致。
- 不是默认绑定未生效（默认入口仍是 `steward`）。
- 不是 A2/A17 护栏类改造失效（它们是治理动作，不是平台路由修复）。

## 3) Solution 专家建议

### 3.1 MVP 修复方向（上游建议）

- 先统一求 `effectiveAgent`，优先级为：显式 `--agent` > 默认入口代理。
- `--to` 仅作为附加路由目标，不应在未显式 `--agent` 时改写 `effectiveAgent`。
- `session/workspace` 必须基于同一个 `effectiveAgent` 生成。
- 语义口径固定为：先选默认 agent，再应用 `--to`，再生成 session/workspace。

### 3.2 长期稳健方向（上游建议）

- 把 agent 解析、`--to` 路由、session/workspace 绑定收敛到单一解析器。
- 明确并文档化参数优先级：显式 `--agent` 最高，`--to` 不是隐式 agent 覆盖。
- 在 JSON 输出暴露 `effectiveAgent` 一类观测字段，避免只能侧推。

### 3.3 回归矩阵（关单前最低要求）

- 默认 `--to` 与显式 `--agent --to` 在同一 `session-id` 下不再分裂。
- 新 `session-id` 复测仍不分裂。
- 无 `--to` 与显式 `--agent` 场景无回归。
- 同时观测 agent/workspace/session 字段，不只看单一 `sessionKey`。

## 4) 项目主线决议（本次采纳）

- 维持 `Conditional-Go`，`RH-T5-B01` 继续开启。
- 维持“事件触发、不按时间”的执行口径，主状态保持 `waiting_upstream_feedback`。
- 关闭阻断门槛保持不变，必须同时满足：
  - `a6_result=route_parity_ok`
  - `a7_result=route_split_not_detected_under_controlled_pmp`
  - `a8_result=to_path_specific_split_not_detected`
  - `blocker_close_ready=yes`
  - `final_result=ready_for_blocker_close_rereview`

## 5) 后续动作（事件触发）

- 若 maintainer 提供新反馈/候选修复版本：执行事件执行器并自动判定是否触发复检包。
- 若事件仍为 `waiting_upstream_feedback`：仅维持护栏、门禁、台账同步，不追加无事件的本地猜测修复。

