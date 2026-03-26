# OpenClaw 单容器多 Agent A 版落地清单

## 1. 目标

先在现有容器 `agent_argus` 内做 MVP 验证，不改为多容器。

目标角色：

- 管家：唯一对外入口，接需求、分派任务、汇总结果
- 猎手：选题、竞品、评论洞察
- 主编：改稿、定调、标题、封面文案
- 投手：产出发布包、发布时间建议、复盘模板

第一阶段只验证：

- OpenClaw 在单容器内是否能稳定管理多个长期 Agent
- 4 个角色是否能分工清晰
- 管家是否能作为唯一入口调度其他角色

第一阶段不做：

- 自动发小红书
- 自动批量登录多个账号
- 自动化高风险抓取/发帖动作

## 2. 当前已确认状态

- 宿主机目录：`/Users/lingguozhong/Codex工作室/openclaw multi -agent`
- 测试容器：`agent_argus`
- 容器镜像：`openclaw-argus-uifix:2026.3.12-control-ui13`
- 容器端口：`3001 -> 18790`
- 容器当前健康：`healthy`
- 容器内当前只有 1 个 Agent：`main`

## 3. A 版设计原则

### 3.1 单容器，不等于单 Agent

单容器 A 版的意思是：

- 只保留一个 OpenClaw 容器进程
- 在这个 OpenClaw 里面创建多个长期 Agent

不是去安装一个额外的 “multi-agent 插件”。

### 3.2 角色隔离靠三层

- 工作区隔离：每个 Agent 独立 workspace
- 身份隔离：每个 Agent 独立 `IDENTITY.md` / `SOUL.md`
- 工具隔离：每个 Agent 独立 `TOOLS.md`

### 3.3 对外入口只留一个

建议只有 `管家` 对外接飞书或其他消息入口。

原因：

- 避免多个 Agent 同时直接回复你
- 降低路由复杂度
- 便于后续加人工审核

## 4. 建议目录结构

以下是容器内建议结构。宿主机会通过挂载持久化。

```text
/root/.openclaw/
  agents/
    main/
    steward/
    hunter/
    editor/
    publisher/
  workspace/
    main/
    steward/
      IDENTITY.md
      SOUL.md
      AGENTS.md
      TOOLS.md
      memory/
    hunter/
      IDENTITY.md
      SOUL.md
      AGENTS.md
      TOOLS.md
      memory/
    editor/
      IDENTITY.md
      SOUL.md
      AGENTS.md
      TOOLS.md
      memory/
    publisher/
      IDENTITY.md
      SOUL.md
      AGENTS.md
      TOOLS.md
      memory/
    shared/
      skills/
      templates/
      briefs/
      outputs/
```

说明：

- `shared/` 放通用模板、SOP、选题卡、发布包模板
- 各角色目录只放自己的规则、记忆和角色产出
- 不建议一开始让所有 Agent 共用同一套 `SOUL.md`

## 5. 角色边界建议

### 管家 steward

- 唯一对外
- 理解需求
- 决定是否调用猎手/主编/投手
- 汇总最终结果
- 维护团队 SOP

### 猎手 hunter

- 产出选题卡
- 观察评论区痛点
- 对比竞品笔记结构
- 输出素材清单，不直接写终稿

### 主编 editor

- 根据选题卡生成草稿
- 输出标题候选、封面文案、正文
- 做品牌调性统一
- 做内容风险初筛

### 投手 publisher

- 不直接发帖
- 输出发布时间建议
- 输出发布检查清单
- 输出数据记录模板

## 6. 最小测试范围

先在 `agent_argus` 做下面这 4 个测试即可：

1. 能否在一个容器里创建 2 到 4 个长期 Agent
2. 每个 Agent 是否能读取自己的角色文件
3. `管家` 是否能成为唯一入口
4. 各角色是否能按职责稳定输出，不串角色

## 7. 推荐测试顺序

### 第一步：只创建 2 个 Agent

先只测：

- `steward`
- `hunter`

理由：

- 最小可用链路最短
- 先验证调度和角色边界
- 出问题时更容易排查

### 第二步：补 `editor`

验证从“选题卡 -> 成稿”是否通顺。

### 第三步：补 `publisher`

验证发布包、标题、发布时间、复盘模板是否完整。

## 8. 建议的初始化命令

以下命令建议先在容器内执行，不要先改 compose。

### 8.1 进入容器

```bash
docker exec -it agent_argus /bin/sh
```

### 8.2 查看当前 Agent

```bash
openclaw agents list --bindings
```

### 8.3 创建工作区目录

```bash
mkdir -p /root/.openclaw/workspace/steward
mkdir -p /root/.openclaw/workspace/hunter
mkdir -p /root/.openclaw/workspace/editor
mkdir -p /root/.openclaw/workspace/publisher
mkdir -p /root/.openclaw/workspace/shared/skills
mkdir -p /root/.openclaw/workspace/shared/templates
mkdir -p /root/.openclaw/workspace/shared/briefs
mkdir -p /root/.openclaw/workspace/shared/outputs
```

### 8.4 先创建前两个 Agent

```bash
openclaw agents add steward --workspace /root/.openclaw/workspace/steward --non-interactive
openclaw agents add hunter --workspace /root/.openclaw/workspace/hunter --non-interactive
```

### 8.5 创建完成后复查

```bash
openclaw agents list --bindings
```

### 8.6 单独测试某个 Agent

```bash
openclaw agent --agent steward --message "你是谁？你的职责是什么？请只用中文简洁回答。"
openclaw agent --agent hunter --message "你是谁？你的职责是什么？请只用中文简洁回答。"
```

### 8.7 后续再补两个 Agent

```bash
openclaw agents add editor --workspace /root/.openclaw/workspace/editor --non-interactive
openclaw agents add publisher --workspace /root/.openclaw/workspace/publisher --non-interactive
```

## 9. 管家唯一入口建议

MVP 阶段建议：

- 保留 `main` 或新建 `steward` 作为唯一对外入口
- 其他 Agent 暂时不要绑对外 channel

建议策略：

- 如果 `main` 已经承担很多历史配置，就暂时保留 `main` 对外
- 然后新增 `hunter/editor/publisher`
- 等验证稳定后，再决定是否把 `main` 迁移为 `steward`

## 10. 新终端窗口建议

不是必须，但推荐开 2 个窗口：

### 窗口 1：进容器操作

```bash
docker exec -it agent_argus /bin/sh
```

### 窗口 2：看日志

```bash
docker logs -f agent_argus
```

如果你用 macOS 自带 Terminal，可在已有终端里执行：

```bash
osascript -e 'tell application "Terminal" to do script "docker exec -it agent_argus /bin/sh"'
osascript -e 'tell application "Terminal" to do script "docker logs -f agent_argus"'
```

如果你用 iTerm2，可自行改成 iTerm2 的 AppleScript 版本；第一阶段没必要专门为每个 Agent 再开单独窗口。

## 11. 第一天的验收标准

满足以下 5 条，就算 A 版第一步成功：

1. `agent_argus` 容器内能看到多个 Agent
2. `steward` 和 `hunter` 能稳定响应
3. 两个角色回答时职责不混乱
4. 不需要新增容器也能完成多角色测试
5. 没有改坏现有 `main` 的对外能力

## 12. 当前最值得注意的风险

1. 不要一开始就给所有 Agent 绑定飞书入口
2. 不要一开始就自动发小红书
3. 不要把发布凭证暴露给所有 Agent
4. 不要直接覆盖当前 `main` 的已有工作区规则
5. 不要把 4 个角色一次性全上，先从 2 个开始

## 13. 下一步建议

下一步最稳的动作是：

1. 先在 `agent_argus` 里创建 `steward` 和 `hunter`
2. 给这两个角色各写一版最简 `IDENTITY.md` 和 `SOUL.md`
3. 用 3 到 5 条提示词做角色边界测试
4. 通过后再补 `editor` 和 `publisher`

这份文档先作为 A 版 MVP 的执行底稿，后面可以再让 gstack 专家做二次评审。
