# OpenClaw Multi-Agent（agent_argus）

这是 OpenClaw A 版的多 Agent 运营中台实验项目，当前只在 `agent_argus` 容器内演进，核心目标是先验证角色分工、路由协作和人工闸门，再逐步扩展自动化能力。

## 当前状态（2026-03-26）

- 运行角色：`main`、`steward`、`hunter`、`editor`、`publisher`
- 默认入口：`steward`
- 链路状态：`steward -> hunter -> editor -> publisher` 已完成端到端验收
- 发布边界：MVP 保留人工闸门，不做自动发帖
- Gate-2 状态：已完成 `steward -> telegram:default` 首轮绑定，通道探活恢复为 `probe.ok=true`

## 目录说明

- `deploy/`：`agent_argus` 的 rollout/rollback 和 override 文件
- `roles/`：角色定义四件套（`IDENTITY.md`、`SOUL.md`、`AGENTS.md`、`TOOLS.md`）
- `shared/`：共享模板与交接契约
- `design/`：讨论纪要、工程收口文档、验证证据、治理文档（风险台账/管理评估）
- `runtime/`：本地运行态（默认不入库）
- `BACKLOG.md` / `DECISIONS.md` / `验收清单.md`：项目推进主线

## 快速开始

1. 准备运行目录

```bash
mkdir -p './runtime/argus/config'
mkdir -p './runtime/argus/agents'
```

2. 准备可写配置文件

```bash
cp "$HOME/.openclaw/docker-openclaw.json" './runtime/argus/config/openclaw.json'
```

3. 使用 override 重建 `agent_argus`

```bash
docker compose \
  -f "$HOME/.openclaw/olympus-deploy.yml" \
  -f './deploy/agent_argus.override.yml' \
  up -d --force-recreate agent_argus sidecar_argus
```

4. 验证默认入口和角色列表

```bash
docker exec agent_argus openclaw agents list --bindings --json
curl -fsSL http://localhost:3001/__openclaw/control-ui-config.json
```

## 联调约定

- CLI 联调必须显式带 `--agent <id>`，不要用“只带 `--to`”的方式判断默认入口
- UI 验收以 `control-ui-config.json` 的 `assistantAgentId` 为准
- 当前已启用 `telegram` channel 插件并完成显式绑定（`steward -> telegram:default`）
- Gate-2 探针当前状态：`ready_for_binding_test`
- 当前通道探活状态：`channels status --probe -> probe.ok=true`
- 下一步：补 1 次真实入站/回包冒烟后，触发 gstack Gate-2 专项评审
- 若 token 发生暴露，必须先在 `@BotFather` 轮换（`/revoke` + `/token`）再继续联调

## 恢复与备份

- GitHub 恢复说明见 `RECOVERY.md`
- `runtime/` 相关状态与 secrets 不直接入库，后续按 backlog 的备份方案补齐
- 可执行恢复演练脚本：`deploy/recovery_drill.sh`
- 月度回归一键脚本：`deploy/monthly_recovery_drill.sh`
- 月度演练预检脚本：`deploy/monthly_recovery_preflight.sh`
- Gate-2 可用性探针：`deploy/gate2_readiness_probe.sh`
- 周度治理模板：`shared/templates/weekly_governance_review_template.md`
- 备份/恢复脚本（v0）：`scripts/backup_state.sh`、`scripts/restore_state.sh`
- 当前加密口径：`openssl(AES-256-CBC + PBKDF2) + manifest sha256`

## 新机器恢复（5 步）

说明：下面是“从 GitHub 拉起可用环境”的最短路径。更完整的异常场景与覆盖恢复请看 `RECOVERY.md`。

1. 拉代码

```bash
git clone https://github.com/Oscarling/openclaw-multi-agent.git
cd "openclaw-multi-agent"
```

2. 准备运行目录与本地配置

```bash
mkdir -p './runtime/argus/config' './runtime/argus/agents' './runtime/argus/config/secrets'
cp "$HOME/.openclaw/docker-openclaw.json" './runtime/argus/config/openclaw.json'
```

3. 写入 Telegram token（仅本机，不入库）

```bash
read -rs NEW_TELEGRAM_BOT_TOKEN
echo
printf '%s' "$NEW_TELEGRAM_BOT_TOKEN" > './runtime/argus/config/secrets/telegram_bot_token.txt'
chmod 600 './runtime/argus/config/secrets/telegram_bot_token.txt'
unset NEW_TELEGRAM_BOT_TOKEN
```

4. 重建容器

```bash
docker compose \
  -f "$HOME/.openclaw/olympus-deploy.yml" \
  -f './deploy/agent_argus.override.yml' \
  up -d --force-recreate agent_argus sidecar_argus
```

5. 验证入口、绑定与通道健康

```bash
docker exec agent_argus openclaw agents list --bindings --json
docker exec agent_argus openclaw channels status --json --probe
curl -fsSL http://localhost:3001/__openclaw/control-ui-config.json
```

## GitHub 协作基线（当前仓库）

- 仓库：`PRIVATE`（`Oscarling/openclaw-multi-agent`）
- 合并策略：仅允许 `squash merge`
- 已关闭：`merge commit`、`rebase merge`
- 自动清理：PR 合并后自动删除分支
- 说明：`main` 分支保护（如强制 PR review）在当前私有仓库套餐下返回 403，需升级 GitHub Pro 或改为公开仓库后再启用
