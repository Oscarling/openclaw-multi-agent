# 2026-03-25 Backup + Recovery Plan（v1 定稿）

状态：Approved（2026-03-25）  
适用范围：`agent_argus` 单容器多 Agent 方案

## 1) 目标

- 目标 1：设备故障后，30 分钟内恢复“可继续协作”的最小环境（代码+文档+部署模板）
- 目标 2：2 小时内恢复到“接近故障前状态”（角色目录+工作区+会话状态+默认入口配置）

## 2) 资产分层

| 资产类别 | 示例内容 | 存放位置 | 是否进 GitHub |
|---|---|---|---|
| 可公开工程资产 | `roles/`、`shared/`、`design/`、`deploy/`、`README.md` | GitHub 仓库 | 是 |
| 运行态状态资产 | `runtime/argus/agents`、`~/.openclaw/state/argus`、`~/.openclaw/workspaces/argus` | 加密备份（本地 + 异地） | 否 |
| 敏感配置/密钥 | API keys、渠道 token、账号登录态、cookies | 密码管理器或加密 secret 库 | 否 |

## 3) 备份策略（建议）

### 3.1 GitHub（代码与流程）

- 频率：有结构性改动就提交（角色文件、模板、runbook、验收文档）
- 目标：保证“无运行态备份时”仍可快速重建框架

### 3.2 State（运行态）

- 目录范围：
  - `runtime/argus/agents`
  - `~/.openclaw/state/argus`
  - `~/.openclaw/workspaces/argus`
  - `runtime/argus/config/openclaw.json`
- 频率：
  - 每次角色结构变更后立即备份一次
  - 每周固定一次全量备份
- 介质：本地加密包 + 一份异地加密副本

### 3.3 Secrets（密钥与登录态）

- 不入库、不放明文
- 用独立 secret 管理（如 1Password / Bitwarden / 本地加密 vault）
- 与 state 备份分开存放，避免“单点泄漏”

### 3.4 加密与密钥托管（定稿）

- 备份加密工具：`openssl`（`AES-256-CBC` + `PBKDF2`，迭代 `200000`）
- 归档完整性：`manifest` 中记录 `sha256`，恢复时默认校验
- 密钥托管：
  - 主存：密码管理器（推荐 1Password/Bitwarden）中单独条目 `openclaw-backup-passphrase`
  - 机内副本：`$HOME/.openclaw/secrets/backup_passphrase.txt`（`chmod 600`）
- 运行口径：
  - 优先使用 `OPENCLAW_BACKUP_PASSPHRASE_FILE`
  - 不建议在长期 shell 配置中明文导出 passphrase

## 4) 备份执行模板（手动版）

以下命令仅作模板，执行前请替换路径与密钥参数：

```bash
ts="$(date +%Y%m%d-%H%M)"
mkdir -p "$HOME/openclaw-backups"
tar -czf "$HOME/openclaw-backups/openclaw-state-$ts.tgz" \
  "/Users/lingguozhong/Codex工作室/openclaw multi -agent/runtime/argus/agents" \
  "$HOME/.openclaw/state/argus" \
  "$HOME/.openclaw/workspaces/argus" \
  "/Users/lingguozhong/Codex工作室/openclaw multi -agent/runtime/argus/config/openclaw.json"
```

脚本已内置加密与明文归档清理逻辑。

## 4.1 脚本化实现（v0）

当前已提供 v0 脚本（默认使用 `openssl` 对归档做加密）：

- `scripts/backup_state.sh`
- `scripts/restore_state.sh`

说明：

- `restore_state.sh` 默认 `APPLY=0`，仅解密到临时目录做预览，不会覆盖本地
- 需要覆盖恢复时显式设置 `APPLY=1`
- 当前只自动回写项目内 `runtime/argus/*`；`~/.openclaw` 仍建议人工确认后恢复
- `backup_state.sh` 在失败时会自动清理明文临时归档，避免残留 `.tgz`

## 5) 恢复顺序（建议）

1. 从 GitHub 拉取仓库并切到目标版本
2. 恢复 secrets（API key、渠道 token、账号配置）
3. 恢复 state 目录（`agents/state/workspaces/config`）
4. 按 runbook 重建：`agent_argus + sidecar_argus`
5. 运行验收：
   - `openclaw config file`
   - `openclaw agents list --bindings --json`
   - `control-ui-config.assistantAgentId`
   - 五角色最小冒烟

## 6) 演练与验收口径

- 每月至少一次“空机恢复演练”
- 演练通过标准：
  - 默认入口恢复为 `steward`
  - 五角色均可响应
  - 四角色链路可跑通
  - 已知限制（CLI `--to` 默认路由）不扩大

## 7) 当前缺口（待下一轮）

- 已提供“一键备份/恢复”脚本 v0，后续进入小范围稳定性回归
- 已完成首次恢复演练（dry run，约 12 秒），证据见：
  - `design/validation/2026-03-25-recovery-drill-validation.md`
- 明文归档清理与脚本链路验证见：
  - `design/validation/2026-03-25-backup-script-validation.md`
- 异常场景（错误口令、损坏包、缺失 manifest）已验证通过，详见同一验证文档

## 8) 威胁模型与完整性边界（我们防什么/不防什么）

当前方案重点防护：

- 误操作：默认强制 manifest 校验，降低拿错包/错版本恢复概率
- 数据损坏：通过密文 `sha256` 比对快速识别截断或篡改
- 常见恢复失误：`restore_state.sh` 默认 `APPLY=0`，先 stage 再人工确认

当前方案不主打防护（需额外建设）：

- 强对抗攻击场景（备份包与 manifest 同时被替换）
- 多人协作下的细粒度权限追踪与审计归责

若后续要增强抗篡改能力，可评估：

- 将 manifest 存放到独立只读介质
- 引入带认证的加密方案或额外 HMAC/签名校验链

## 9) 异地备份与保留策略（位置/轮转/取回验证）

建议执行口径：

- 备份位置：
  - 本地：`artifacts/backups/`
  - 异地：团队约定的加密对象存储或受控网盘目录
- 保留策略：
  - 日常保留最近 7 份
  - 每周保留最近 4 份
  - 每月保留最近 3 份
- 取回验证：
  - 每月至少随机抽取 1 份异地备份执行 stage-only 恢复
  - 记录耗时、失败原因、修复动作到验证文档

## 10) host ~/.openclaw 恢复 apply Runbook（可控覆盖与回滚）

目标：把 host 侧 `state/workspaces` 恢复纳入“可控覆盖 + 可回滚 + 可验收”流程。

最小流程：

1. 先执行 stage-only 恢复，确认目录结构与版本正确
2. 备份当前 host 目录（回滚点）：
   - `~/.openclaw/state/argus`
   - `~/.openclaw/workspaces/argus`
3. 停止相关容器（避免写入竞争）
4. 按清单覆盖恢复 host 目录
5. 重建 `agent_argus + sidecar_argus`
6. 运行验收（配置路径、默认入口、五角色冒烟）
7. 若失败，按第 2 步回滚点回退并复验

注意：

- host 侧 apply 不建议默认自动化“一键覆盖”
- 每次 apply 必须有执行记录和回滚点记录
