# 2026-03-26 Gate-3 会后 24h 执行卡（v1）

更新时间：2026-03-26  
适用范围：prompts.chat 角色优化（Gate-3 预评审后）  
目标：在 24 小时内完成正式 `plan-eng-review` 前置就绪

## 1) 执行节奏

- 启动条件：`office-hours` 预评审结论为 `Conditional-Go`（已满足）
- 执行窗口：启动后 24 小时内
- 输出要求：每项任务必须有可复核产物路径

## 2) 任务卡（谁做 / 做什么 / 验收）

| 编号 | 负责人（建议） | 动作 | 产物 | 验收标准 |
|---|---|---|---|---|
| T1 | 角色架构 owner（建议：`steward` owner） | 产出四角色 RoleSpec 草案（最小可用） | `roles/*` 对应草案备注 + `shared/templates/role_spec_template.md` 实例化稿 | 四角色都包含：使命、Do/Don't、输入输出契约、越权防线、回归编号 |
| T2 | 内容策略 owner（建议：`hunter` + `publisher` owner） | 补低风险项变更摘要（C01/C02/C03/C04/C07/C08/C09/C10/C12/C14） | `design/2026-03-26-prompts-chat-role-diff-mapping-v1.md` 更新段落 | 每个低风险项都明确：归属角色、拟更新位置、不越权说明 |
| T3 | 编辑质量 owner（建议：`editor` owner） | 为 C06 增加“禁止虚构事实”硬约束并绑定回归 | `design/2026-03-26-prompts-chat-role-diff-mapping-v1.md` + 回归编号 | C06 在文档中从“可讨论”变为“带硬约束可试运行候选” |
| T4 | 研究质量 owner（建议：`hunter` owner） | 定义 C11 最小验证格式与样例 | 新增 `design/validation/gate3-c11-min-cases-v1.md` | 包含证据等级/可信度/待核实项 + 3 条样例（2 正 1 反） |
| T5 | 编辑质量 owner（建议：`editor` owner） | 定义 C05 风险提示格式与免责声明 | 新增 `design/validation/gate3-c05-min-cases-v1.md` | 明确“不构成法律判断” + 3 条样例（2 高同质化 1 低同质化） |
| T6 | 编辑质量 owner（建议：`editor` owner） | 定义 C13 事实锁定检查与样例 | 新增 `design/validation/gate3-c13-min-cases-v1.md` | 包含事实锁定规则 + 3 条样例（数字/引用/不确定表述各 1） |
| T7 | QA owner | 把黄金回归清单落成测试记录模板 | 新增 `design/validation/gate3-regression-run-record-template-v1.md` | 关键项 `S2/H5/E3/P4/X4` 支持一票否决记录 |
| T8 | 平台/运行态 owner | 明确 v2 命中策略 + kill-switch 入口 | 新增 `design/2026-03-26-gate3-v2-routing-and-killswitch-v1.md` | 明确“默认入口不变、v2 默认不自动命中、可一键回滚” |
| T9 | 会议主持人（Gate-3 负责人） | 发起正式 `plan-eng-review` 会议 | 会议议程文档 + 会议时间记录 | 满足触发条件后 24-48 小时内排会，最晚不超过 5 个自然日 |

## 3) 会后状态判定

- `Ready for plan-eng-review`：
  - T1-T9 全部完成，且产物路径齐全
- `Conditional-ready`：
  - T1/T7/T8 完成，T4/T5/T6 至少完成 2 项并有明确补齐计划
- `Not ready`：
  - T1 或 T8 任一未完成（禁止进入正式评审）

## 4) 风险提醒（执行期）

- 不新增第五个角色
- 不变更默认入口 `steward`
- 不把 prompts.chat 原始角色全文直接写入运行态
- `C11/C05/C13` 未完成验证前不得进入 v2 试运行

## 5) 执行进展（滚动）

- [x] T1 已完成（2026-03-26）
  - `roles/steward/ROLE_SPEC_DRAFT.md`
  - `roles/hunter/ROLE_SPEC_DRAFT.md`
  - `roles/editor/ROLE_SPEC_DRAFT.md`
  - `roles/publisher/ROLE_SPEC_DRAFT.md`
- [x] T2 已完成（2026-03-26）
  - `design/2026-03-26-prompts-chat-role-diff-mapping-v1.md`（低风险项变更摘要）
- [x] T3 已完成（2026-03-26）
  - `design/2026-03-26-prompts-chat-role-diff-mapping-v1.md`（C06 硬约束 + `E3/X4` 绑定）
- [x] T4 已完成（2026-03-26）
  - `design/validation/gate3-c11-min-cases-v1.md`
- [x] T5 已完成（2026-03-26）
  - `design/validation/gate3-c05-min-cases-v1.md`
- [x] T6 已完成（2026-03-26）
  - `design/validation/gate3-c13-min-cases-v1.md`
- [x] T7 已完成（2026-03-26）
  - `design/validation/gate3-regression-run-record-template-v1.md`
- [x] T8 已完成（2026-03-26）
  - `design/2026-03-26-gate3-v2-routing-and-killswitch-v1.md`
- [x] T9 已完成（2026-03-26）
  - `design/2026-03-26-gate-3-prompts-chat-plan-eng-review-agenda-v1.md`
  - `design/2026-03-26-gate-3-prompts-chat-plan-eng-review-minutes-v1.md`
