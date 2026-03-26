# 月度恢复演练记录模板（C2）

更新时间：2026-03-25  
用途：用于关闭 Gate-1 条件 C2（形成下一次月度回归演练记录）

## 1) 基本信息

- 演练日期（Asia/Shanghai）：
- 执行人：
- 演练类型：`recovery_drill` / `host_apply_drill` / 组合演练
- 备份包：
- manifest：

## 2) 执行口径

- 推荐命令：
  - `OPENCLAW_BACKUP_PASSPHRASE_FILE="$HOME/.openclaw/secrets/backup_passphrase.txt" bash ./deploy/monthly_recovery_drill.sh`
- 使用脚本：
- 是否包含自动回滚：
- 是否包含 host `state/workspaces` apply：
- 加密与完整性校验方式：`openssl + manifest sha256`

## 3) 关键命令与耗时

- 开始时间：
- 结束时间：
- 端到端耗时：
- 关键命令（可贴 3-8 条）：

## 4) 结果核验

- `openclaw config file`：
- `openclaw agents list --bindings --json`（默认入口与角色可见性）：
- `control-ui-config.json`（`assistantAgentId`）：
- 冒烟 runId（如有）：

## 5) 异常与修复

- 是否失败：是/否
- 失败点：
- 根因：
- 修复动作：
- 是否需要追加回归：是/否

## 6) 证据索引

- 证据目录：
- 验证文档：
- 关联看板回填：
  - `BACKLOG.md`
  - `验收清单.md`
  - `DECISIONS.md`（如需）

## 7) 结论

- 本次是否满足 C2 关闭条件：是/否
- 下一次演练建议窗口：
