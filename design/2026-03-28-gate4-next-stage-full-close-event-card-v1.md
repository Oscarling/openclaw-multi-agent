# Gate-4 阶段 NEXT 项目级收口事件卡（v1）

日期：2026-03-28  
适用范围：阶段 NEXT 项目级收口复核与结论回填。  
决策边界：本事件卡仅覆盖阶段 NEXT 项目级收口，不直接放行下一阶段执行。

## 1) 执行前提

- 阶段 NEXT 首批执行 DoD 已形成且可追溯。
- 阶段 NEXT 后续窗口（`batch2 + batch3`）已按边界收口。
- 三本台账可定位到后续复评纪要与执行证据。

## 2) 事件链路（按事件触发）

### G4-NEXT-CLOSE-T1：收口前提核验

- 触发事件：阶段 NEXT 收口复核启动
- 动作：核验首批 DoD、后续窗口收口与证据链完整性
- 完成标准：形成“可进入项目级复核”的核验结论

### G4-NEXT-CLOSE-T2：项目级预复核（office-hours）

- 触发事件：`G4-NEXT-CLOSE-T1` 通过
- 动作：执行阶段 NEXT 项目级预评审
- 完成标准：形成 `No-Go/Conditional-Go/Go` 预评审结论

### G4-NEXT-CLOSE-T3：项目级工程复核（plan-eng-review）

- 触发事件：`G4-NEXT-CLOSE-T2` 完成
- 动作：执行阶段 NEXT 项目级正式工程复核
- 完成标准：形成项目级最终结论与下一阶段入口建议

### G4-NEXT-CLOSE-T4：三本台账回填与下一事件切换

- 触发事件：`G4-NEXT-CLOSE-T3` 完成
- 动作：回填 `BACKLOG/DECISIONS/验收清单` 并切换下一主线事件
- 完成标准：结论可追溯、下一事件可执行

## 3) 强制字段（收口纪要）

- `scope`（固定 `next_stage_full_close`）
- `decision`（`No-Go/Conditional-Go/Go`）
- `blocking_items`（如有）
- `next_stage_entry_recommendation`
- `evidence_refs`

## 4) 禁止事项

- 未完成后续窗口收口即宣告阶段 NEXT 项目级收口完成。
- 跳过项目级两段式复核直接切换下一阶段执行。
- 将“评审结论”误当“自动执行许可”。
