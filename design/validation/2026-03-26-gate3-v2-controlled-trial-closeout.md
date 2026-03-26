# 2026-03-26 Gate-3 v2 受控试运行窗口结束报告（待回填）

更新时间：2026-03-26  
状态：已回填（阶段性收口）  
参考清单：`design/validation/gate3-v2-window-close-checklist-v1.md`

## 1) 窗口信息

- 启动时间：2026-03-26 Day0 启动（见 kickoff 记录）
- 结束时间：2026-03-26 阶段性收口时点
- 窗口时长：同日 Day0 -> 中窗 -> 终检

## 2) 关键检查结果

- 默认入口仍为 `steward`（是）
- 通道探活 `probe_ok=true`（是）
- `S2/H5/E3/P4/X4` 是否全通过（是）
- 是否触发回滚阈值（否）

## 3) 证据链接

- Day0 启动记录：`design/validation/2026-03-26-gate3-v2-controlled-trial-kickoff.md`
- 中窗检查：`design/validation/2026-03-26-gate3-v2-controlled-trial-midwindow-check.md`
- 回归运行记录：`design/validation/2026-03-26-gate3-regression-run-record.md`
- runId 索引：`design/validation/artifacts/gate3-min-cases-20260326-1105/runid-index.md`

## 4) 最终结论（三选一）

- 继续扩大试运行 / 维持受控范围 / 回滚终止：维持受控范围
- 理由：
  - Day0、中窗、终检均未发现关键项失败或回滚触发
  - 当前证据支持“稳定运行”，但观察窗口仍建议按受控节奏继续，不直接放量
  - 保持默认入口不变更，有利于风险可控

终检 runId（阶段性收口）：

- CLOSE-C11：`b55bb90d-bce8-4bdf-9088-4255ea4a9b95`
- CLOSE-C13：`4018f37b-aca8-4097-8918-412e2cee0394`
- CLOSE-P4：`e06cb9b3-3d56-4163-b7c3-224c367bc9fe`

## 5) 台账回填

- `BACKLOG.md`：已回填
- `DECISIONS.md`：已回填
- `验收清单.md`：已回填
