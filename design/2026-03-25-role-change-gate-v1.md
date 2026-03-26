# 2026-03-25 角色变更门禁（v1）

更新时间：2026-03-25  
适用范围：`agent_argus` 运行链路中的角色新增、删减、合并、拆分

## 1) 目标

- 把“新增/删减角色”从临场决策变成固定流程
- 在实现前完成两段式 gstack 评审，降低角色边界漂移和路由回归风险
- 保证每次角色变更都有可复盘证据

## 2) 触发条件

满足任一条件即触发门禁：

- 新增角色（例如新增 `reviewer`）
- 删减角色（例如合并 `editor` 与 `publisher`）
- 角色边界发生实质性变化（职责上收/下放）
- 默认入口角色变更（例如 `steward -> main`）

## 3) 两段式评审流程（必须顺序执行）

1. `office-hours`（问题重定义）
   - 明确“为什么要改角色”，不是“怎么改文档”
   - 输出：目标、约束、备选方案、放弃方案
2. `plan-eng-review`（工程收口）
   - 锁定架构、路由、模板、验收和回滚口径
   - 输出：可执行清单、风险点、验收 case、回滚命令

执行原则：

- 未完成 `office-hours` 不进入 `plan-eng-review`
- 未完成 `plan-eng-review` 不进入运行态变更（不改 Agent、不改默认入口）

## 4) 变更前输入包（DoR）

- 角色变更申请单：`shared/templates/role_change_request_template.md`
- 当前链路快照：
  - `openclaw agents list --bindings --json`
  - `http://localhost:3001/__openclaw/control-ui-config.json`
- 影响范围：
  - 受影响角色四件套（`roles/<id>/*`）
  - 受影响交接模板（`shared/templates/*`）
  - 受影响验收 case

## 5) 变更后验收（DoD）

- 角色四件套已更新并同步运行态
- 至少通过 3 类 case：
  - 标准输入链路 case
  - 缺字段兜底 case
  - 越权防护 case
- 默认入口与角色可见性复核通过
- 回滚命令可执行且有记录
- 验证文档落盘到 `design/validation/`

## 6) 证据要求

每次角色变更至少沉淀以下证据：

- `office-hours` 纪要（`design/`）
- `plan-eng-review` 收口文档（`design/`）
- 验证报告（`design/validation/`）
- 看板/验收回填（`BACKLOG.md`、`验收清单.md`）

## 7) 首次执行建议

- 在首次新增/删减角色需求出现时，先用模板起草申请单，再触发 gstack 两段式评审
- 评审通过前，不提前修改运行态 Agent 结构

