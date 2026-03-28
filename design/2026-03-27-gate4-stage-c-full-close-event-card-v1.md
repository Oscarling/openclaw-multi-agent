# Gate-4 Stage-C 全阶段收口事件卡（项目级，v1）

日期：2026-03-27  
适用范围：Stage-C 项目级收口复核与结论回填。  
决策边界：本事件卡仅覆盖 Stage-C 收口，不直接放行后续阶段执行。

## 1) 执行前提

- C1/C2/C3 各阶段 DoD 已形成且结果可追溯。
- C2/C3 连续窗口均已形成收口验证记录。
- 三本台账可定位到对应评审纪要与执行证据。

## 2) 事件链路（按事件触发）

### G4-C-CLOSE-T1：收口前提核验

- 触发事件：Stage-C 收口复核启动
- 动作：核验 C1/C2/C3 DoD 与窗口收口证据完整性
- 完成标准：形成“可进入项目级复核”的核验记录

### G4-C-CLOSE-T2：项目级复核（office-hours）

- 触发事件：`G4-C-CLOSE-T1` 通过
- 动作：执行 Stage-C 项目级收口预评审
- 完成标准：形成 `No-Go/Conditional-Go/Go` 预评审结论

### G4-C-CLOSE-T3：项目级工程复核（plan-eng-review）

- 触发事件：`G4-C-CLOSE-T2` 完成
- 动作：执行 Stage-C 项目级正式工程复核
- 完成标准：形成最终收口结论与后续阶段入口建议

### G4-C-CLOSE-T4：三本台账回填

- 触发事件：`G4-C-CLOSE-T3` 完成
- 动作：回填 `BACKLOG/DECISIONS/验收清单`
- 完成标准：结论可追溯且可复核

## 3) 强制字段（收口纪要）

- `scope`（固定 `Stage-C full closeout`）
- `decision`（`No-Go/Conditional-Go/Go`）
- `blocking_items`（如有）
- `next_stage_entry_recommendation`
- `evidence_refs`

## 4) 禁止事项

- 未完成 C1/C2/C3 链路证据闭环即宣告 Stage-C 收口完成。
- 跳过项目级复核直接放行后续阶段执行。
