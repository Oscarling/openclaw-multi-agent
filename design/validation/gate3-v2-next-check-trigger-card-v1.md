# 2026-03-26 Gate-3 v2 下一轮复检触发卡（v1）

更新时间：2026-03-26  
当前状态：维持受控范围（不放量）  
用途：明确“何时必须复检 / 何时可考虑扩大试运行”

## 1) 必须复检触发条件（任一满足即触发）

- `roles/hunter/*`、`roles/editor/*` 或 `shared/templates/*` 发生修改
- 路由策略、默认入口、绑定关系发生修改
- 运行期出现任一边界异常（越权、事实漂移、代发布倾向）
- Telegram 通道探活出现 `probe_ok=false` 或 `lastError != null`

## 2) 可考虑扩大试运行的触发条件（全部满足）

- 连续两轮复检关键项 `S2/H5/E3/P4/X4` 全通过
- 连续两轮无回滚触发
- `C11/C05/C13` 抽检稳定通过，且证据链完整

## 3) 每轮复检最小动作

1. 运行态快照（通道探活 + 默认入口 + bindings）  
2. 关键边界抽检（至少 4 条）  
3. 回填 runId 到索引与复检记录  
4. 更新 `BACKLOG/DECISIONS/验收清单`

推荐一键执行（事件触发）：

```bash
GATE3_TRIGGER_EVENT="role_boundary_changed" GATE3_RECHECK_ID="R4" bash ./deploy/gate3_event_recheck.sh
```

## 4) 复检产物路径

- 复检记录：`design/validation/` 下按日期新增 `gate3-v2-recheck-r*.md`
- 复检索引：`design/validation/gate3-v2-recheck-index.md`
- runId 索引（历史沿用）：`design/validation/artifacts/gate3-min-cases-20260326-1105/runid-index.md`
- 总回归记录：`design/validation/2026-03-26-gate3-regression-run-record.md`
- 一键脚本证据目录：`design/validation/artifacts/gate3-v2-recheck-<r#>-<timestamp>/`
