# 2026-03-26 prompts.chat 候选意图清单（v1）

更新时间：2026-03-26  
用途：Gate-3 预评审输入包（不直接改运行态）

## 1) 使用原则

- 外部来源只作为“意图样本库”，不直接拷贝角色全文
- 映射目标是现有四角色：`steward` / `hunter` / `editor` / `publisher`
- 先做“吸收/待验证/拒绝”分流，再进入正式评审

## 2) 来源快照

- 项目：`prompts.chat`（原 Awesome ChatGPT Prompts）
  - README：`https://raw.githubusercontent.com/f/awesome-chatgpt-prompts/main/README.md`
  - 数据：`https://raw.githubusercontent.com/f/prompts.chat/main/prompts.csv`
- License：CC0 1.0（可复制、修改、分发、使用）
- 说明：以下 line 仅用于定位来源，不代表直接采用原始提示词全文

## 3) 候选清单（映射四角色）

| ID | 候选意图（来源） | 建议归属 | 建议 | 最小验收口径 |
|---|---|---|---|---|
| C01 | 需求澄清式对话（`Job Interviewer`，`prompts.csv` L3-L4） | `steward` | 吸收 | 能逐条追问缺失字段，且每次只问一个关键问题 |
| C02 | 论点组织与反驳结构（`Debate Coach`，L20-L21） | `steward`/`editor` | 吸收 | 输出“观点-依据-反例-结论”四段结构 |
| C03 | 语言升级与润色（`English Translator and Improver`，L2-L3） | `editor` | 吸收 | 同义升级但不改事实，不新增结论 |
| C04 | 语法/标点校对（`Proofreader`，L162） | `editor` | 吸收 | 输出“问题位置 + 修订建议”并保留原意 |
| C05 | 重复度/同质化检查（`Plagiarism Checker`，L10-L11） | `editor` | 待验证 | 给出高重复风险段落提示，不做“绝对判定” |
| C06 | 叙事化包装（`Storyteller` L13-L14 / `Screenwriter` L21-L23） | `editor` | 吸收（有边界） | 允许增强可读性，不允许虚构事实 |
| C07 | SEO 关键词与检索意图（`SEO specialist`，L223） | `hunter`/`publisher` | 吸收 | 输出主关键词、长尾词、意图分类与使用位置 |
| C08 | 标题/钩子优化（`Google Ads Title Copywriter`，L1765-L1767） | `editor`/`publisher` | 吸收 | 给出多版本短标题并标注适用平台 |
| C09 | 内容策略规划（`SEO Content Strategist`，L2279；`Elite SEO ...`，L4334） | `hunter`/`publisher` | 吸收 | 产出“选题-分发-复盘”闭环表 |
| C10 | 社媒分发运营建议（`Social Media Manager`，L90） | `publisher` | 吸收 | 输出发布时间、渠道差异、检查清单 |
| C11 | 深度调查与证据链（`Investigative Research Assistant`，L2977-L2979） | `hunter` | 待验证（风险高） | 明确“证据等级 + 可信度 + 待核实项” |
| C12 | 数据洞察与解释（`Data Analyst` L752-L754 / `Lead Data Analyst` L755） | `hunter` | 吸收 | 输出关键指标、异常点、行动建议三段 |
| C13 | AI 文本人性化改写（`Prompt for Humanizing AI Text`，L4404-L4405） | `editor` | 待验证 | 保留事实与逻辑，不引入夸张营销语 |
| C14 | 发布前合规检查（由 C07/C08/C10 组合） | `publisher` | 吸收 | 发布包必须含“风险点 + 人工确认项” |

## 4) 明确拒绝项（不进入运行态）

| ID | 来源角色 | 拒绝原因 |
|---|---|---|
| R01 | `Linux Terminal`（L2） | 与业务目标不匹配，易诱导“伪执行输出” |
| R02 | `Unconstrained AI model DAN`（L156-L160） | 明确越权/越界风险，违反项目边界 |
| R03 | `Character`（L11-L12）等纯人设扮演 | 容易造成角色漂移与输出不稳定 |
| R04 | 成人/高争议内容角色（多处） | 与当前项目目标和风险口径不一致 |

## 5) 预评审建议顺序（先小后大）

1. 先审低风险高收益：`C01/C03/C04/C07/C08/C10/C12`  
2. 再审中风险能力：`C05/C06/C13`  
3. 最后审高风险项：`C11`（需额外证据边界）

## 6) 会后产物建议

- `RoleSpec` 模板（四角色共用）
- 四角色差异清单（吸收/拒绝/待验证）
- 黄金回归清单（逐角色 + 端到端）
- v2 试运行边界与回滚条件
