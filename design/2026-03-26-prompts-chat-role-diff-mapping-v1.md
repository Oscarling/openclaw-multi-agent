# 2026-03-26 prompts.chat 四角色差异映射清单（v1）

更新时间：2026-03-26  
用途：Gate-3 正式评审输入（只做映射，不直接改运行态）

## 1) 范围与输入

- 输入来源：`design/2026-03-26-prompts-chat-candidate-intents-v1.md`
- 目标角色：`steward` / `hunter` / `editor` / `publisher`
- 处理标签：`吸收` / `待验证` / `拒绝`

## 2) 汇总视图

| 角色 | 吸收 | 待验证 | 拒绝（继承全局） |
|---|---:|---:|---:|
| `steward` | 2 | 0 | 4 |
| `hunter` | 3 | 1 | 4 |
| `editor` | 4 | 2 | 4 |
| `publisher` | 4 | 0 | 4 |

说明：

- 全局拒绝项统一沿用：`R01/R02/R03/R04`
- 待验证项需先通过黄金回归清单再决定是否进入 v2

## 3) Steward 映射

吸收：

- C01 需求澄清式对话（单点追问）
- C02 论点组织与反驳结构（仅用于汇总结构，不直接下场写稿）

待验证：

- 无

拒绝：

- 不吸收任何“执行器模拟/越权角色/纯人设扮演/敏感内容”能力

拟更新位置（评审通过后）：

- `roles/steward/SOUL.md`：补“单点追问顺序”规则
- `roles/steward/AGENTS.md`：补“结构化汇总模板”约束

## 4) Hunter 映射

吸收：

- C07 SEO 关键词与检索意图分析
- C09 内容策略规划（选题-分发-复盘上游输入）
- C12 数据洞察三段式（观察-解释-建议）

待验证：

- C11 深度调查与证据链（需增加证据等级与可信度标注）

拒绝：

- 任何直接产出终稿或代替发布执行的能力

拟更新位置（评审通过后）：

- `roles/hunter/SOUL.md`：补“证据等级 + 待核实项”规范
- `roles/hunter/TOOLS.md`：补“数据类输出边界与免责声明”

## 5) Editor 映射

吸收：

- C03 语言升级与润色（不改事实）
- C04 校对能力（问题位置 + 修订建议）
- C06 叙事化包装（禁止虚构事实）
- C08 标题/钩子多版本输出

待验证：

- C05 重复度风险提示（只做风险提示，不做绝对判定）
- C13 AI 文本人性化改写（防止事实漂移）

拒绝：

- 任何“代发布/越权执行”能力

拟更新位置（评审通过后）：

- `roles/editor/SOUL.md`：补“事实不漂移”硬约束
- `roles/editor/AGENTS.md`：补“标题候选 + 适用说明”输出格式

## 6) Publisher 映射

吸收：

- C07 SEO 意图下游承接（发布侧关键词落位）
- C08 标题钩子发布适配
- C10 社媒分发运营建议
- C14 发布前合规检查清单

待验证：

- 无

拒绝：

- 保持“不代执行发布”底线不变

拟更新位置（评审通过后）：

- `roles/publisher/SOUL.md`：补“平台差异化建议”结构
- `roles/publisher/AGENTS.md`：补“发布检查清单最小字段”

## 7) Gate-3 评审决策点

1. `C11/C05/C13` 是否进入 v2 试运行  
2. 先做“能力吸收”还是“新增角色”  
3. v2 命中策略：显式 `--agent` 还是测试绑定  
4. 回滚触发阈值（按黄金回归清单）

## 8) 结论建议

- 本轮建议：先吸收低风险高收益项（C01/C02/C03/C04/C07/C08/C09/C10/C12/C14）
- 高风险项（C11/C05/C13）进入待验证池，不直接放行到运行态

## 9) 低风险项变更摘要（T2）

说明：以下为“评审通过后拟更新位置”，当前仅用于 Gate-3 设计与审查，不直接改运行态。

| 编号 | 归属角色 | 拟更新位置（评审通过后） | 变更摘要 | 不越权说明 | 回归绑定 |
|---|---|---|---|---|---|
| C01 | `steward` | `roles/steward/SOUL.md`、`roles/steward/AGENTS.md` | 增加“单点追问”顺序（每轮只问 1 个关键字段） | 只澄清与路由，不直接产出终稿 | `S1/S2` |
| C02 | `steward` | `roles/steward/AGENTS.md`、`shared/templates/steward_response_template.md` | 增加“观点-依据-反例-结论”汇总结构 | 仅用于汇总，不替代 `editor` 写稿 | `S3/X4` |
| C03 | `editor` | `roles/editor/SOUL.md`、`roles/editor/AGENTS.md` | 语言升级与润色规则（保留事实） | 禁止新增事实与结论 | `E3` |
| C04 | `editor` | `roles/editor/AGENTS.md`、`shared/templates/editor_output_template.md` | 校对输出统一“问题位置 + 修订建议” | 只做校对，不改业务判断边界 | `E4` |
| C07 | `hunter`/`publisher` | `roles/hunter/SOUL.md`、`roles/publisher/SOUL.md` | 补主词/长尾词/搜索意图字段与落位建议 | `hunter` 不写终稿，`publisher` 不代执行发布 | `H2/P2` |
| C08 | `editor`/`publisher` | `roles/editor/AGENTS.md`、`roles/publisher/AGENTS.md` | 标题/钩子多版本输出并标注平台适配 | `editor` 不做发布决策，`publisher` 不重写正文 | `E2/P1` |
| C09 | `hunter`/`publisher` | `roles/hunter/AGENTS.md`、`roles/publisher/AGENTS.md` | 落“选题-分发-复盘”闭环字段 | `hunter` 不越权到发布；`publisher` 不越权到研究 | `H1/P3` |
| C10 | `publisher` | `roles/publisher/SOUL.md`、`roles/publisher/AGENTS.md` | 社媒分发建议结构（时间/渠道/节奏） | 仅给建议，不执行发帖 | `P1/P4` |
| C12 | `hunter` | `roles/hunter/SOUL.md`、`shared/templates/hunter_topic_card_template.md` | 数据洞察固定三段式（观察-解释-建议） | 不确定数据必须标注“待核实” | `H3/H4` |
| C14 | `publisher` | `roles/publisher/AGENTS.md`、`shared/templates/publisher_output_template.md` | 发布前合规检查清单最小字段 | 强制包含“风险点 + 人工确认项” | `P2/P4` |

## 10) C06 硬约束与回归绑定（T3）

结论：`C06`（叙事化包装）保留在可吸收范围，但必须带硬约束，不得按“自由改写”放行。

硬约束（必须同时满足）：

- 禁止虚构事实：不得新增实体、数字、时间、引用来源。
- 禁止语义升级：不得把“可能/预计/待核实”改为“确定/已经/证实”。
- 必须留痕：输出中需包含 `fact_lock_notes`，说明改写仅发生在语气/节奏/表达层。

拟更新位置（评审通过后）：

- `roles/editor/SOUL.md`：新增“禁止虚构事实”硬约束段。
- `roles/editor/AGENTS.md`：新增“叙事化包装可改/不可改边界”段。
- `shared/templates/editor_output_template.md`：加入 `fact_lock_notes` 字段定义。

回归绑定：

- `E3`（润色后不改事实）作为 `C06` 必过项。
- `X4`（全链路无越权、无角色漂移）作为联动必过项。
- 任一失败即阻断 `C06` 进入 v2 试运行。
