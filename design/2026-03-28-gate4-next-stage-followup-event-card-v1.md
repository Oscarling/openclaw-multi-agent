# Gate-4 下一阶段后续批次受控执行卡（v1）

日期：2026-03-28  
适用范围：下一阶段首批通过后的后续批次窗口。  
范围边界：本执行卡用于后续批次，不外推其他阶段执行。

## 1) 执行前提（必须同时满足）

- 后续批次复评结论为 `Conditional-Go` 或 `Go`。
- 下一阶段首批 DoD 已形成且通过。
- 阶段预检结果为 `ready_for_stage_c_execution`（每批前复核）。
- 人工闸门完整（`operator + ticket_id + evidence_ref`）。

## 2) 后续窗口（v1）

- 窗口上限：最多 2 批（`batch2 + batch3`）
- 目标阈值：`success_rate >= 0.97`
- 停机阈值：`failure_count >= 3` 或 `halt_triggered=true`
- 回退动作：触发停机/降级后回退为“仅首批策略”

## 3) 事件链路

### G4-NEXT-CONT-T1：窗口启动核验

- 触发事件：后续批次复评结论发布
- 动作：核验前提并冻结窗口参数
- 完成标准：形成窗口启动记录

### G4-NEXT-CONT-T2：批次 N 执行前预检

- 触发事件：`G4-NEXT-CONT-T1` 通过或上一批判定“继续”
- 动作：复跑预检与人工闸门校验
- 完成标准：`preflight_result=ready_for_stage_c_execution`

### G4-NEXT-CONT-T3：批次 N 受控执行

- 触发事件：`G4-NEXT-CONT-T2` 通过
- 动作：执行受控批次（`phase_id=NEXT`）
- 完成标准：生成批次 N 执行摘要与回执

### G4-NEXT-CONT-T4：批次 N 阈值判定

- 触发事件：`G4-NEXT-CONT-T3` 完成
- 动作：判定 `继续/停机/回滚/降级`
- 完成标准：输出唯一结论

### G4-NEXT-CONT-T5：窗口收口

- 触发事件：达到窗口上限或触发停机/降级
- 动作：回填三本台账与窗口 DoD
- 完成标准：形成可追溯收口记录
