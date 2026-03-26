# agent_argus Rollout / Rollback Runbook

更新时间：2026-03-25

## 文件

- 基础部署文件：`/Users/lingguozhong/.openclaw/olympus-deploy.yml`
- 本项目 override：`/Users/lingguozhong/Codex工作室/openclaw multi -agent/deploy/agent_argus.override.yml`
- 可复用 override 示例：`/Users/lingguozhong/Codex工作室/openclaw multi -agent/deploy/agent_argus.override.example.yml`
- 本地运行配置：`/Users/lingguozhong/Codex工作室/openclaw multi -agent/runtime/argus/config/openclaw.json`
- 本地 agent 状态：`/Users/lingguozhong/Codex工作室/openclaw multi -agent/runtime/argus/agents`

## 当前方案

只对 `agent_argus` 叠加 override，不直接改全局 `olympus-deploy.yml`。

效果：

- 让 `agent_argus` 使用自己的可写运行配置
- 让 `/root/.openclaw/agents` 持久化到项目本地 runtime 目录
- 保留原来的只读模板 `/root/.openclaw/openclaw.json` 作为对照

## 首次准备

```bash
mkdir -p '/Users/lingguozhong/Codex工作室/openclaw multi -agent/runtime/argus/config'
mkdir -p '/Users/lingguozhong/Codex工作室/openclaw multi -agent/runtime/argus/agents'
cp '/Users/lingguozhong/.openclaw/docker-openclaw.json' '/Users/lingguozhong/Codex工作室/openclaw multi -agent/runtime/argus/config/openclaw.json'
docker cp agent_argus:/root/.openclaw/agents/. '/Users/lingguozhong/Codex工作室/openclaw multi -agent/runtime/argus/agents/'
```

## 预检

```bash
docker compose \
  -f '/Users/lingguozhong/.openclaw/olympus-deploy.yml' \
  -f '/Users/lingguozhong/Codex工作室/openclaw multi -agent/deploy/agent_argus.override.yml' \
  config
```

重点检查：

- `agent_argus` 多了 `OPENCLAW_CONFIG_PATH=/root/.openclaw/config/openclaw.json`
- `agent_argus` 多了两个挂载：
  - `runtime/argus/config:/root/.openclaw/config`
  - `runtime/argus/agents:/root/.openclaw/agents`

## Rollout

```bash
docker compose \
  -f '/Users/lingguozhong/.openclaw/olympus-deploy.yml' \
  -f '/Users/lingguozhong/Codex工作室/openclaw multi -agent/deploy/agent_argus.override.yml' \
  up -d --force-recreate agent_argus sidecar_argus
```

## Rollout 后验证

```bash
docker exec agent_argus openclaw config file
docker exec agent_argus openclaw agents list --bindings
docker exec agent_argus sh -lc 'mount | grep -E "/root/.openclaw/config|/root/.openclaw/agents|/root/.openclaw/openclaw.json"'
docker logs --tail 40 agent_argus
```

预期：

- `openclaw config file` 输出 `~/.openclaw/config/openclaw.json`
- `/root/.openclaw/config` 和 `/root/.openclaw/agents` 是 `rw`
- `/root/.openclaw/openclaw.json` 仍然是 `ro`

## 路由收口（唯一入口切到 steward）

```bash
docker exec agent_argus openclaw config set 'agents.list[1].default' 'true'
docker compose \
  -f '/Users/lingguozhong/.openclaw/olympus-deploy.yml' \
  -f '/Users/lingguozhong/Codex工作室/openclaw multi -agent/deploy/agent_argus.override.yml' \
  up -d --force-recreate agent_argus sidecar_argus
docker exec agent_argus openclaw agents list --bindings --json
curl -fsSL http://localhost:3001/__openclaw/control-ui-config.json
```

预期：

- `agents list` 中 `steward` 为 `isDefault: true`
- `control-ui-config.json` 中 `assistantAgentId` 为 `steward`

说明：

- 当前镜像里部分 channel plugin 未加载，`openclaw agents bind --bind feishu` 会报 `Unknown channel`。
- 在这种情况下，默认入口切换到 `steward` 是当前最稳的唯一入口方案。

## CLI / UI 路由口径（联调约定）

当前环境观察：

- Control UI 默认入口会走 `assistantAgentId=steward`
- `openclaw agent --to ...`（未显式 `--agent`）可能仍进入 `main`

为避免联调歧义，统一口径如下：

1. CLI 验收/联调命令必须显式带 `--agent steward`（或目标角色）
2. UI 验收以 `control-ui-config.json` 的 `assistantAgentId` 为准
3. `--to` 且不带 `--agent` 的结果仅作为“遗留路由行为”观察，不作为入口验收依据

## 创建前两个 Agent

```bash
docker exec agent_argus sh -lc 'mkdir -p /root/.openclaw/workspace/steward /root/.openclaw/workspace/hunter /root/.openclaw/workspace/shared/briefs /root/.openclaw/workspace/shared/templates /root/.openclaw/workspace/shared/outputs /root/.openclaw/workspace/shared/skills'
docker exec agent_argus sh -lc 'openclaw agents add steward --workspace /root/.openclaw/workspace/steward --non-interactive --json'
docker exec agent_argus sh -lc 'openclaw agents add hunter --workspace /root/.openclaw/workspace/hunter --non-interactive --json'
docker exec agent_argus openclaw agents list --bindings
```

## 持久化验证

```bash
docker compose \
  -f '/Users/lingguozhong/.openclaw/olympus-deploy.yml' \
  -f '/Users/lingguozhong/Codex工作室/openclaw multi -agent/deploy/agent_argus.override.yml' \
  up -d --force-recreate agent_argus sidecar_argus

docker exec agent_argus openclaw agents list --bindings
```

预期：

- `main`、`steward`、`hunter` 仍存在

## Rollback

如果要回到原来的只读共享配置模式，只用基础部署文件重建 `agent_argus`：

```bash
docker compose \
  -f '/Users/lingguozhong/.openclaw/olympus-deploy.yml' \
  up -d --force-recreate agent_argus sidecar_argus
```

说明：

- rollback 后，`agent_argus` 会重新回到原来的只读配置模式
- 那时再执行 `openclaw agents add ...`，大概率又会报 `EBUSY`
- `runtime/argus/config` 和 `runtime/argus/agents` 先不要删，保留作为备份

## 恢复演练（Dry Run）

建议每月执行一次脚本化恢复演练：

```bash
bash ./deploy/recovery_drill.sh
```

说明：

- 演练会在 `/tmp/openclaw-recovery-drill-<timestamp>` 创建临时环境
- 会短暂重建 `agent_argus` / `sidecar_argus` 到演练 runtime，再自动回切到当前 override
- 证据会自动写入演练目录下的 `artifacts/`
