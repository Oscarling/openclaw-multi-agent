# Gate-4 Stage-C 真实小流量 C1 事件执行卡（v1）

日期：2026-03-26  
适用范围：专项评审通过后的真实 C1 单批次运行。

## 1) 执行前提

- 专项评审结论至少为 `Conditional-Go`
- 账号在白名单内
- 已指定 `operator` 与 `ticket_id`
- 阶段 C 预检持续可用：`ready_for_stage_c_execution`

## 2) 事件链路（按事件触发）

### G4-C1-T1：评审结论确认

- 触发事件：专项评审纪要落盘
- 动作：确认结论与放行范围（No-Go / Conditional-Go / Go）
- 完成标准：结论与限制条件可追溯

### G4-C1-T2：真实 C1 执行前确认

- 触发事件：`G4-C1-T1` 完成且结论允许执行
- 动作：复跑 `gate4_stage_c_preflight.sh`
- 完成标准：`preflight_result=ready_for_stage_c_execution`

### G4-C1-T3：真实 C1 单批次执行

- 触发事件：`G4-C1-T2` 通过
- 动作：执行 `gate4_stage_c_execute.sh`（真实回执）
- 完成标准：生成 `stage-c-summary.txt` 与执行证据目录

### G4-C1-T4：停机阈值检查

- 触发事件：`G4-C1-T3` 完成
- 动作：核验 `failure_count/success_rate/halt_triggered`
- 完成标准：明确“继续/停机/回滚”判定

### G4-C1-T5：回滚或继续判定

- 触发事件：`G4-C1-T4` 完成
- 动作：按阈值执行停机回滚或继续下一批准备
- 完成标准：形成判定结论并写入 DoD

## 3) 强制字段

- `phase_id`
- `batch_id`
- `release_id`
- `account_id`
- `operator`
- `ticket_id`
- `success_count/failure_count/success_rate`
- `halt_triggered`
- `evidence_ref`

## 4) 禁止事项

- 无 ticket 执行真实 C1
- 无回执判定成功
- 超出 C1 批次上限直接放量
