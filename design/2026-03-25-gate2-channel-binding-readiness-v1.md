# 2026-03-25 Gate-2 Channel Binding Readiness（v1）

更新时间：2026-03-25  
目标：在 channel plugin 可用后，最短路径完成 binding 联调与 Gate-2 评审收口

## 1) 触发条件

满足以下条件后触发执行：

- channel plugin 已可用
- 能执行 `openclaw agents bind --agent steward --bind <channel[:accountId]>`
- 至少完成 1 个 channel 的首轮联调

## 2) 执行前检查

1. 当前默认入口确认
   - `docker exec agent_argus openclaw agents list --bindings --json`
   - `curl -fsSL http://localhost:3001/__openclaw/control-ui-config.json`
2. 当前角色列表确认
   - 五角色可见（`main/steward/hunter/editor/publisher`）
3. 回滚口径确认
   - 使用 `deploy/agent_argus-runbook.md` 中重建/回滚命令

## 3) 联调最小步骤

1. 执行首个 channel 绑定（`steward`）
2. 复核 bindings 列表是否出现目标 channel
3. 执行最小冒烟（从 channel 入站触发到 `steward`）
4. 复核默认入口与五角色列表无漂移

## 4) 最小验收 Case（Gate-2）

### Case B1：binding 生效

- 期望：`agents list --bindings` 显示目标 channel 绑定项

### Case B2：入站路由正确

- 期望：目标 channel 入站请求由 `steward` 处理

### Case B3：回归稳定

- 期望：未绑定 channel 的默认入口和既有链路不受影响

## 5) 证据落盘要求

- 验证文档：`design/validation/<date>-channel-binding-validation.md`
- 至少包含：
  - 绑定命令与结果
  - `agents list --bindings --json`
  - `control-ui-config.json`
  - 冒烟 runId（若有）
  - 回滚命令（若触发）

## 6) 评审衔接

- 联调通过后，立即触发 gstack Gate-2（路由/绑定专项评审）
- 评审前准备：
  - 本文档
  - 联调验证文档
  - 回滚记录（若有）

