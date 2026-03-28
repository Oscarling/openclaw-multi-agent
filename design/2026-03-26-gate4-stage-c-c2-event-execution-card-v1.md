# Gate-4 Stage-C C2 受控放量事件执行卡（v1）

日期：2026-03-26  
适用范围：C2 放量前评审与放行执行。  

## 1) 执行前提

- C2 专项评审结论至少为 `Conditional-Go`
- C1 连续 2 批真实成功（成功率均 >= 95%）
- C1 审计项关闭（`evidence_ref` 为真实引用）
- 阶段 C 预检结果持续为 `ready_for_stage_c_execution`

## 2) 事件链路（按事件触发）

### G4-C2-T1：触发条件核验

- 触发事件：C2 专项评审启动
- 动作：核验 C1 连续两批成功与审计项关闭
- 完成标准：形成“可进入评审决策”的核验记录

### G4-C2-T2：预检复跑

- 触发事件：`G4-C2-T1` 通过
- 动作：复跑 `gate4_stage_c_preflight.sh`
- 完成标准：`preflight_result=ready_for_stage_c_execution`

### G4-C2-T3：C2 单批次执行（仅放行后）

- 触发事件：专项评审结论允许执行
- 动作：执行 `gate4_stage_c_execute.sh`（`phase_id=C2`）
- 完成标准：生成 C2 执行摘要与回执证据

### G4-C2-T4：阈值判定与停机检查

- 触发事件：`G4-C2-T3` 完成
- 动作：核验 `failure_count/success_rate/halt_triggered`
- 完成标准：明确“继续/停机/回滚”结论

### G4-C2-T5：会后结论回填

- 触发事件：`G4-C2-T4` 完成
- 动作：回填三本台账与 C2 DoD
- 完成标准：结论可追溯且可复核

## 3) 强制字段

- `phase_id`（固定 `C2`）
- `batch_id`
- `release_id`
- `account_id`
- `operator`
- `ticket_id`
- `success_count/failure_count/success_rate`
- `halt_triggered`
- `evidence_ref`

## 4) 禁止事项

- 未满足 C2 触发条件即执行 C2
- 无回执或回执字段缺失即判定成功
- 触发停机阈值后继续放量
