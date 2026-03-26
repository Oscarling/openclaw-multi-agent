# OpenClaw Multi-Agent 项目契约

更新时间：2026-03-26

## 1) 主线执行总则

- 主线推进采用事件触发，不按固定时间节点。
- 每完成一个关键事件，必须同步三本账：
  - `BACKLOG.md`
  - `DECISIONS.md`
  - `验收清单.md`
- secrets/token/runtime 状态不得入库，按既定备份恢复方案管理。

## 2) Local-First 阶段上传协作口径

当网络慢或 GitHub 交互成本偏高时，启用“本地优先 + 阶段上传”模式。

1. 本地阶段允许连续推进，但必须保持小步提交（单一目的）。
2. 每个阶段结束前必须本地执行：
   - `python3 scripts/backlog_lint.py`
   - `python3 scripts/backlog_sync.py`
   - `bash scripts/premerge_check.sh`
3. 阶段上传触发（事件制）：
   - 完成一个 blocker
   - 完成一个风险项收口
   - 形成一个可回滚检查点（代码+证据+三本账对齐）
4. 每次 push 前必须先对齐远端：
   - `git fetch origin`
   - 检查 `main` 与 `origin/main` 差异，避免积累大冲突
5. 结果汇报口径：
   - 明确标注“当前处于本地阶段”或“当前进入上传阶段”

## 3) 恢复策略（provider/model/profile 受控对比）

当发生恢复演练异常、模型行为漂移、或用户触发升级评估时，执行受控对比：

1. 先固定基线快照：
   - `docker exec agent_argus openclaw channels status --json --probe`
   - `docker exec agent_argus openclaw agents list --bindings --json`
2. 明确对比矩阵：
   - baseline：当前 `provider/model/profile`
   - candidate：待评估 `provider/model/profile`
3. 两组都跑同一套回归样例（禁止换样）：
   - `GATE3_TRIGGER_EVENT="<event>" GATE3_RECHECK_ID="<id>" bash ./deploy/gate3_event_recheck.sh`
4. 路由口径复检（防默认入口漂移）：
   - `bash ./deploy/cli_route_parity_probe.sh`
5. 结论标准：
   - 关键样例全通过
   - 默认入口和通道探活不漂移
   - 无新增越权/不确定性表达退化
6. 证据留痕：
   - 记录到 `design/validation/` 新增对比报告
   - 回填三本账后再进入下一步变更或回滚决策
