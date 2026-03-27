# Gate-4 Stage-C C2 连续批次受控执行卡（v1）

日期：2026-03-26  
适用范围：C2 单批次已闭环后的“连续批次窗口”执行。  
决策边界：本执行卡仅用于 C2 连续批次，不外推到 C3。

## 1) 执行前提（必须同时满足）

- 已完成“是否进入 C2 连续批次”的专项复评，结论为 `Conditional-Go` 或 `Go`。
- C2 单批次 DoD 已形成且结论为通过。  
  证据：`design/validation/2026-03-26-gate4-stage-c-c2-dod-validation.md`
- 阶段 C 预检结果为 `ready_for_stage_c_execution`（每批前均需复核）。
- 执行账号仍在阶段 C 白名单，且 `operator + ticket_id` 有人工闸门确认。

## 2) 连续批次窗口（v1）

- 窗口上限：最多 2 批连续批次（`batch2 + batch3`），每批均需独立回执与判定。
- 每批阈值：`success_rate >= 0.95`。
- 停机阈值：`failure_count >= 2` 或 `halt_triggered=true` 即立即停机。
- 回滚动作：触发停机后回退为“仅 C2 单批次策略”，并发起阻断项复评。

## 3) 事件链路（按事件触发）

### G4-C2-CONT-T1：连续窗口启动核验

- 触发事件：C2 连续批次复评结论发布为可执行（`Conditional-Go/Go`）
- 动作：核验执行前提、锁定窗口参数（批次数上限/阈值/停机规则）
- 完成标准：形成“连续窗口启动记录”

### G4-C2-CONT-T2：批次 N 执行前预检

- 触发事件：`G4-C2-CONT-T1` 通过，或上一批判定为“继续”
- 动作：复跑 `gate4_stage_c_preflight.sh`
- 完成标准：`preflight_result=ready_for_stage_c_execution`

### G4-C2-CONT-T3：批次 N 受控执行

- 触发事件：`G4-C2-CONT-T2` 通过
- 动作：执行 `gate4_stage_c_execute.sh`（`phase_id=C2`，批次号递增）
- 完成标准：生成批次 N 执行摘要与回执（含真实 `evidence_ref`）

### G4-C2-CONT-T4：批次 N 阈值判定

- 触发事件：`G4-C2-CONT-T3` 完成
- 动作：核验 `success_rate/failure_count/halt_triggered`
- 完成标准：输出唯一结论：`继续` / `停机` / `回滚`

### G4-C2-CONT-T5：窗口收口

- 触发事件：达到窗口上限，或在任意批次触发停机/回滚
- 动作：回填三本台账与连续批次 DoD，发起“是否进入 C3”的独立评审准备
- 完成标准：形成可追溯收口记录并冻结下一事件入口

## 4) 强制字段（每批）

- `phase_id`（固定 `C2`）
- `batch_id`
- `release_id`
- `account_id`
- `operator`
- `ticket_id`
- `success_count/failure_count/success_rate`
- `halt_triggered`
- `evidence_ref`（必须真实，不得占位值）

## 5) 禁止事项

- 未完成连续批次专项复评即直接执行 C2 连续批次。
- 任一批次未出回执或字段缺失即判定成功。
- 触发停机阈值后继续推进下一批次。
- 将 C2 连续批次放行结论视为 C3 放行结论。
