# 2026-03-25 Recreate + Smoke Validation (5 Agents)

更新时间：2026-03-25  
环境：`agent_argus + sidecar_argus`（OpenClaw 2026.3.12）

## 1) 验证目标

在完成四角色链路接入后，补一轮强制重建与冒烟，确认以下基线未漂移：

- `agent_argus` 可写运行配置仍生效
- 默认入口仍是 `steward`
- `main/steward/hunter/editor/publisher` 五个 Agent 均可响应

## 2) 重建执行

- 命令：`docker compose -f ~/.openclaw/olympus-deploy.yml -f deploy/agent_argus.override.yml up -d --force-recreate agent_argus sidecar_argus`
- 结果：`agent_argus` 与 `sidecar_argus` 均重建并成功启动

## 3) 基础状态检查

- 配置路径：
  - 命令：`docker exec agent_argus openclaw config file`
  - 输出：`~/.openclaw/config/openclaw.json`
- Agent 列表与默认入口：
  - 命令：`docker exec agent_argus openclaw agents list --bindings --json`
  - 结果：共 5 个 Agent；`steward.isDefault=true`
- 挂载读写状态：
  - 命令：`docker exec agent_argus sh -lc 'mount | grep -E "/root/.openclaw/config|/root/.openclaw/agents|/root/.openclaw/openclaw.json"'`
  - 结果：`/root/.openclaw/config`、`/root/.openclaw/agents` 为 `rw`；`/root/.openclaw/openclaw.json` 为 `ro`
- Control UI 默认入口：
  - 命令：`curl -fsSL http://localhost:3001/__openclaw/control-ui-config.json`
  - 输出：`assistantAgentId=steward`

## 4) 五角色冒烟（职责边界问询）

- `main`：`runId=4c94c8aa-6d66-48d4-a680-4a12f083eb20`
- `steward`：`runId=3ea351ee-eac8-4d0a-9d39-d0c8971a3d7f`
- `hunter`：`runId=cf75a158-d7c7-4502-ad4f-dd88467a2927`
- `editor`：`runId=a391d7fd-0cef-413e-8682-dfd3e89efc03`
- `publisher`：`runId=c90e9578-f916-4fb2-84a4-4fb6c34158e4`

结果：五个 Agent 均返回与其职责边界一致的响应，无越权迹象。

## 5) 结论

- 重建后运行态稳定，关键基线（可写配置、默认入口、角色可用性）全部通过
- 可继续按 backlog 推进下一阶段（优先等待 channel plugin 可用后补显式绑定）
