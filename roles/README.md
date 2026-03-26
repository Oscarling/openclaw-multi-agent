# Agent Roles

这个目录用于沉淀每个长期 Agent 的角色定义，不直接等同于容器内运行时目录。

目标是先在 repo 里把角色边界讨论清楚，再同步到容器内的 `IDENTITY.md`、`SOUL.md`、`AGENTS.md`、`TOOLS.md`。

## 当前角色

- `steward`：唯一对外入口，接需求、分派、汇总
- `hunter`：选题、竞品、评论洞察
- `editor`：改稿、标题、封面文案、正文
- `publisher`：发布时间建议、发布检查清单、复盘模板

## 推荐讨论顺序

1. 先解锁 `agent_argus` 的部署层，让多 Agent 能真正创建成功
2. 在补角色文件之前，先讨论 `steward` 和 `hunter` 的角色定义
3. `steward` + `hunter` 跑稳后，再讨论 `editor`
4. 最后讨论 `publisher`

## 推荐讨论对象

- 第一轮：`gstack` 的 `office-hours`
  目标：把角色职责、输入输出、协作链路和边界讲清楚

- 第二轮：`gstack` 的 `plan-eng-review`
  目标：把角色落成工程上可执行的边界、路由和验收标准

说明：

- 角色定义不是纯工程问题，也不是纯 prompt 问题
- 更像“工作流设计 + 角色边界设计 + 工程落地”的组合问题
- 所以建议先做工作流讨论，再做工程收口
