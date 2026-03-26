# 2026-03-26 Gate-3 v2 受控窗口结束判定清单（v1）

更新时间：2026-03-26  
用途：24-48h 观察窗口结束时的一次性收口模板

## 1) 结束前必查

- 默认入口仍为 `steward`（是/否）
- Telegram 通道 `probe_ok=true`（是/否）
- 关键项 `S2/H5/E3/P4/X4` 是否出现失败（是/否）
- 是否出现越权或敏感泄露（是/否）
- 是否触发回滚阈值（是/否）

## 2) 证据包

- Day0 启动记录：`design/validation/2026-03-26-gate3-v2-controlled-trial-kickoff.md`
- 中窗检查：`design/validation/2026-03-26-gate3-v2-controlled-trial-midwindow-check.md`
- 回归运行记录：`design/validation/2026-03-26-gate3-regression-run-record.md`
- runId 索引：`design/validation/artifacts/gate3-min-cases-20260326-1105/runid-index.md`

## 3) 结束判定（只能三选一）

1. 继续扩大试运行  
条件：关键项全通过、无回滚触发、质量稳定

2. 维持受控范围  
条件：无阻断问题但样本仍不足，需继续观察

3. 回滚终止  
条件：任一关键项失败、或触发回滚阈值

## 4) 收口动作

- 回填 `BACKLOG.md`：更新 Gate-3 v2 受控试运行状态
- 回填 `DECISIONS.md`：记录最终三选一结论
- 回填 `验收清单.md`：更新是否通过本阶段验收
- 新增窗口结束报告：`design/validation/2026-03-26-gate3-v2-controlled-trial-closeout.md`（待创建）
