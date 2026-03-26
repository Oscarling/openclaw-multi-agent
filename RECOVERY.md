# GitHub 恢复指南（v1）

更新时间：2026-03-26

## 结论先行

- 仅从 GitHub 拉代码后，可以很快恢复“项目结构、角色文档、流程规则、验收基线”。
- 但不能 100% 立刻恢复“历史会话、运行态状态、密钥与登录态”，这些需要单独备份恢复。

## 场景 A：只恢复项目框架（最快）

1. 拉取仓库

```bash
git clone <your-repo-url>
cd "<repo-dir>"
```

2. 准备运行目录和可写配置

```bash
mkdir -p './runtime/argus/config' './runtime/argus/agents'
cp "$HOME/.openclaw/docker-openclaw.json" './runtime/argus/config/openclaw.json'
```

3. 应用 override 并重建

```bash
docker compose \
  -f "$HOME/.openclaw/olympus-deploy.yml" \
  -f './deploy/agent_argus.override.yml' \
  up -d --force-recreate agent_argus sidecar_argus
```

4. 验证关键状态

```bash
docker exec agent_argus openclaw config file
docker exec agent_argus openclaw agents list --bindings --json
curl -fsSL http://localhost:3001/__openclaw/control-ui-config.json
```

## 场景 B：恢复到“接近故障前状态”

除上述步骤外，还需要恢复以下内容（不在 GitHub 仓库内）：

- `runtime/argus/agents`（Agent 注册与目录状态）
- `~/.openclaw/state/argus`（会话/状态）
- `~/.openclaw/workspaces/argus`（工作区动态内容）
- 渠道账号/第三方平台登录态与 secrets

如果这些备份缺失，可以恢复框架，但要重新执行角色创建、必要初始化与回归验收。

## 角色重建最小命令（无状态备份时）

```bash
docker exec agent_argus sh -lc 'mkdir -p /root/.openclaw/workspace/steward /root/.openclaw/workspace/hunter /root/.openclaw/workspace/editor /root/.openclaw/workspace/publisher'
docker exec agent_argus openclaw agents add steward --workspace /root/.openclaw/workspace/steward --non-interactive
docker exec agent_argus openclaw agents add hunter --workspace /root/.openclaw/workspace/hunter --non-interactive
docker exec agent_argus openclaw agents add editor --workspace /root/.openclaw/workspace/editor --non-interactive
docker exec agent_argus openclaw agents add publisher --workspace /root/.openclaw/workspace/publisher --non-interactive
```

## 后续计划

- `GitHub + secrets + state backup` 恢复方案已定稿，后续进入月度回归与异常场景复测。

## 恢复演练（建议每月一次）

已提供脚本化 dry run：

```bash
bash ./deploy/recovery_drill.sh
```

特性：

- 在 `/tmp/openclaw-recovery-drill-<timestamp>` 构建演练环境
- 自动采集证据到 `artifacts/`
- 演练结束后自动回切到原项目 override

已提供月度一键回归脚本（串联 `recovery_drill + host_apply_drill + 报告落盘`）：

```bash
OPENCLAW_BACKUP_PASSPHRASE_FILE="$HOME/.openclaw/secrets/backup_passphrase.txt" bash ./deploy/monthly_recovery_drill.sh
```

输出：

- 验证报告：`design/validation/<date>-monthly-recovery-drill-validation*.md`
- 聚合证据：`design/validation/artifacts/openclaw-monthly-recovery-<timestamp>/`

建议在演练前先跑自检：

```bash
bash ./deploy/monthly_recovery_preflight.sh
```

Gate-2（channel binding）可用性探针：

```bash
bash ./deploy/gate2_readiness_probe.sh
```

Gate-2 首轮绑定（示例）：

```bash
docker exec agent_argus openclaw agents bind --agent steward --bind telegram:default --json
docker exec agent_argus openclaw agents list --bindings --json
docker exec agent_argus openclaw channels status --json --probe
```

说明：若最后一步出现 `probe.ok=false`（例如 `404`），表示绑定配置已写入但通道健康未通过，需先修复通道后再进入 Gate-2 正式收口。
建议先检查 token 文件长度是否异常：

```bash
docker exec agent_argus sh -lc 'wc -c /root/.openclaw/config/secrets/telegram_bot_token.txt'
```

参考：本项目在 token 长度从异常 `11` 字节恢复到 `46` 字节后，`probe.ok` 恢复为 `true`。

若执行了 `plugins/channels` 变更并重启了 `agent_argus`，建议同步重启 `sidecar_argus`，避免 `3001` 端口短暂不可用：

```bash
docker restart agent_argus
docker restart openclaw-sidecar_argus-1
curl -fsSL http://localhost:3001/__openclaw/control-ui-config.json
```

## 备份与恢复脚本（v0）

加密与密钥口径（已定稿）：

- 备份包采用 `openssl`（`AES-256-CBC + PBKDF2(iter=200000)`）
- 建议使用 `OPENCLAW_BACKUP_PASSPHRASE_FILE`，文件权限保持 `600`
- 恢复时优先使用同名 `manifest` 做 `sha256` 校验

1. 生成加密备份包：

```bash
OPENCLAW_BACKUP_PASSPHRASE_FILE="$HOME/.openclaw/secrets/backup_passphrase.txt" bash ./scripts/backup_state.sh
```

2. 先做“只解密预览、不覆盖”恢复检查：

```bash
ARCHIVE='/abs/path/openclaw-state-xxxx.tgz.enc' OPENCLAW_BACKUP_PASSPHRASE_FILE="$HOME/.openclaw/secrets/backup_passphrase.txt" bash ./scripts/restore_state.sh
```

3. 确认后再执行覆盖恢复（仅项目内 runtime）：

```bash
ARCHIVE='/abs/path/openclaw-state-xxxx.tgz.enc' OPENCLAW_BACKUP_PASSPHRASE_FILE="$HOME/.openclaw/secrets/backup_passphrase.txt" APPLY=1 bash ./scripts/restore_state.sh
```

4. 缺失 manifest 的紧急恢复（默认不建议）：

```bash
ARCHIVE='/abs/path/openclaw-state-xxxx.tgz.enc' OPENCLAW_BACKUP_PASSPHRASE_FILE="$HOME/.openclaw/secrets/backup_passphrase.txt" ALLOW_NO_MANIFEST=1 bash ./scripts/restore_state.sh
```

说明：`restore_state.sh` 默认强制 manifest 校验，只有紧急场景才建议显式放行。
放行时还需同时设置：

```bash
I_UNDERSTAND_NO_INTEGRITY_CHECK=1
```
