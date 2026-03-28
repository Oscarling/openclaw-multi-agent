# Gate-4 Stage-C C3 后续批次受控执行卡（v1）

日期：2026-03-27  
适用范围：C3 首批已通过后的“后续批次窗口”执行。  
决策边界：本执行卡仅用于 C3 后续批次，不外推到后续阶段。

## 1) 执行前提（必须同时满足）

- 已完成“是否允许 C3 后续批次”的专项复评，结论为 `Conditional-Go` 或 `Go`。
- C3 首批 DoD 已形成且结论为通过。  
  证据：`design/validation/2026-03-27-gate4-stage-c-c3-dod-validation.md`
- 阶段 C 预检结果为 `ready_for_stage_c_execution`（每批前均需复核）。
- 执行账号仍在阶段 C 白名单，且 `operator + ticket_id` 人工闸门完整。

## 2) 后续批次窗口（v1）

- 窗口上限：最多 2 批后续批次（`batch2 + batch3`），每批均需独立回执与判定。
- 每批目标阈值：`success_rate >= 0.97`。
- 停机阈值：`failure_count >= 3` 或 `halt_triggered=true` 即立即停机。
- 回滚动作：触发停机后回退为“仅 C3 首批策略”，并发起阻断项复评。

## 3) 事件链路（按事件触发）

### G4-C3-CONT-T1：后续窗口启动核验

- 触发事件：C3 后续批次复评结论发布为可执行（`Conditional-Go/Go`）
- 动作：核验执行前提、锁定窗口参数（批次数上限/阈值/停机规则）
- 完成标准：形成“C3 后续窗口启动记录”

### G4-C3-CONT-T2：批次 N 执行前预检

- 触发事件：`G4-C3-CONT-T1` 通过，或上一批判定为“继续”
- 动作：复跑 `gate4_stage_c_preflight.sh`
- 完成标准：`preflight_result=ready_for_stage_c_execution`

### G4-C3-CONT-T3：批次 N 受控执行

- 触发事件：`G4-C3-CONT-T2` 通过
- 动作：执行 `gate4_stage_c_execute.sh`（`phase_id=C3`，批次号递增）
- 完成标准：生成批次 N 执行摘要与回执（含真实 `evidence_ref`）

### G4-C3-CONT-T4：批次 N 阈值判定

- 触发事件：`G4-C3-CONT-T3` 完成
- 动作：核验 `success_rate/failure_count/halt_triggered`
- 完成标准：输出唯一结论：`继续` / `停机` / `回滚` / `降级`

### G4-C3-CONT-T5：窗口收口

- 触发事件：达到窗口上限，或在任意批次触发停机/回滚/降级
- 动作：回填三本台账与 C3 后续窗口 DoD，冻结下一阶段入口
- 完成标准：形成可追溯收口记录并冻结后续入口

## 4) 强制字段（每批）

- `phase_id`（固定 `C3`）
- `batch_id`
- `release_id`
- `account_id`
- `operator`
- `ticket_id`
- `success_count/failure_count/success_rate`
- `halt_triggered`
- `evidence_ref`（必须真实，不得占位值）

## 5) 禁止事项

- 未完成后续批次专项复评即直接执行 C3 后续批次。
- 任一批次未出回执或字段缺失即判定成功。
- 触发停机阈值后继续推进下一批次。
- 将 C3 后续批次放行结论视为后续阶段放行结论。
