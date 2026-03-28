# 角色全面固化范围冻结（RH-T1，v1）

日期：2026-03-28  
阶段：`RH-T1`（范围冻结）  
目标：冻结“本轮要固化什么/不固化什么”，作为 `RH-T2` 的唯一改动边界。

## 1) 输入依据

- `design/2026-03-28-role-hardening-event-driven-plan-v1.md`
- `design/2026-03-26-prompts-chat-role-diff-mapping-v1.md`
- `design/2026-03-26-gate-3-prompts-chat-plan-eng-review-minutes-v1.md`
- `design/validation/2026-03-26-gate3-min-cases-validation.md`
- 现行角色契约：
  - `roles/steward/*`
  - `roles/hunter/*`
  - `roles/editor/*`
  - `roles/publisher/*`

## 2) 冻结结论（按能力标签）

### 2.1 本轮“吸收并固化”能力

- `steward`：`C01/C02`
- `hunter`：`C07/C09/C12/C11`
- `editor`：`C03/C04/C06/C08/C05/C13`
- `publisher`：`C07/C08/C10/C14`

说明：

- `C11/C05/C13` 已完成最小样例与复测闭环，本轮进入“受控固化”。
- 受控固化含义：能力可写入正式契约，但必须保留硬约束与回归门禁。

### 2.2 本轮“明确拒绝/保持禁用”能力

- `R01/R02/R03/R04` 保持拒绝，不进入运行态。
- 不引入“自动发布执行”能力。
- 不引入“跨角色越权代办”能力。

## 3) 冻结边界（本轮不做）

- 不新增角色，不删减角色，不改角色总数。
- 不改默认入口（继续 `steward` 对外）。
- 不将评审结论外推为自动执行许可。

## 4) RH-T2 目标改动清单（冻结版）

### `steward`

- `roles/steward/SOUL.md`：补“单点追问”执行规则与上限。
- `roles/steward/AGENTS.md`：补“观点-依据-反例-结论”汇总结构。

### `hunter`

- `roles/hunter/SOUL.md`：补“观察-解释-建议”与证据纪律。
- `roles/hunter/AGENTS.md`：固化 `C11` 字段要求（`source_trace/evidence_level/confidence/to_verify`）。
- `shared/templates/hunter_topic_card_template.md`：补齐洞察字段与待核实口径。

### `editor`

- `roles/editor/SOUL.md`：固化事实锁定与语义降级约束。
- `roles/editor/AGENTS.md`：固化 `C05/C13/C06` 边界与输出字段。
- `shared/templates/editor_output_template.md`：固化 `fact_lock_notes`、免责声明、风险提示字段。

### `publisher`

- `roles/publisher/SOUL.md`：固化平台差异建议与人工闸门约束。
- `roles/publisher/AGENTS.md`：固化发布检查清单最小字段。
- `shared/templates/publisher_output_template.md`：固化“风险点 + 人工确认项”必填项。

## 5) 验收标准（RH-T1）

- 形成“四角色吸收/拒绝/边界”冻结清单：完成。
- 形成 RH-T2 文件级改动范围：完成。
- 明确“可做/不可做”边界并可追溯到输入依据：完成。

## 6) 下一事件

`RH-T2`：四角色契约全面固化（正式四件套 + 共享模板）
