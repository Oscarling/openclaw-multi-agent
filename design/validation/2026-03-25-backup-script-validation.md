# 2026-03-25 Backup Script Validation (v1)

更新时间：2026-03-25  
范围：`scripts/backup_state.sh` + `scripts/restore_state.sh`

## 1) 目标

- 验证 `openssl` 加密备份脚本可产出可校验归档
- 验证恢复脚本在 `APPLY=0` 下可解密并预览结构，且不覆盖本地

## 2) 执行记录

### 2.1 备份脚本执行

- 命令：`OPENCLAW_BACKUP_PASSPHRASE_FILE=/tmp/openclaw_backup_passphrase.txt bash ./scripts/backup_state.sh`
- 结果：成功生成加密备份和 manifest
- 产物：
  - `artifacts/backups/openclaw-state-20260325-212851.tgz.enc`
  - `artifacts/backups/openclaw-state-20260325-212851.manifest.txt`
- manifest 关键字段：
  - `sha256=274b8d78016bc900595a13804333f63790d429514305bb91e43d0bcba988bb00`
  - `encryption=openssl-aes-256-cbc-pbkdf2-iter200000`

### 2.2 恢复脚本执行（stage-only）

- 命令：`ARCHIVE=<latest>.tgz.enc OPENCLAW_BACKUP_PASSPHRASE_FILE=/tmp/openclaw_backup_passphrase.txt STAGE_DIR=/tmp/openclaw-restore-stage-openssl-20260325-2129 bash ./scripts/restore_state.sh`
- 结果：成功通过 `manifest sha256` 校验并提取到临时目录，`APPLY=0` 未覆盖本地文件
- 预览确认包含：
  - `project-runtime/argus/agents`
  - `project-runtime/argus/config`
  - `host-openclaw/state/argus`（若存在）
  - `host-openclaw/workspaces/argus`（若存在）
- 安全确认：
  - 临时解密包 `restored.tgz` 在提取后已自动删除（stage 目录中不存在）

### 2.3 异常场景验证

- 错误口令：
  - 结果：失败（符合预期）
  - 关键输出：`bad decrypt`
- 损坏包（截断后的 `.tgz.enc`）：
  - 结果：失败（符合预期）
  - 关键输出：`sha256 mismatch`
- 缺失 manifest（默认）：
  - 结果：失败（符合预期）
  - 关键输出：`manifest is required by default`
- 缺失 manifest（紧急放行）：
  - 命令：`ALLOW_NO_MANIFEST=1 I_UNDERSTAND_NO_INTEGRITY_CHECK=1 ...`
  - 结果：成功进入 stage-only 恢复（符合预期）

### 2.4 应急开关误用防护验证

- 场景：只设置 `ALLOW_NO_MANIFEST=1`，不设置二次确认变量
  - 结果：失败（符合预期）
  - 关键输出：`missing explicit confirmation: set I_UNDERSTAND_NO_INTEGRITY_CHECK=1 ...`
- 场景：同时设置 `ALLOW_NO_MANIFEST=1` 与 `I_UNDERSTAND_NO_INTEGRITY_CHECK=1`
  - 结果：成功（符合预期）
  - 关键输出：日志包含 `AUDIT emergency restore without manifest ...`

### 2.5 明文残留清理

- 已清理文件：`artifacts/backups/openclaw-state-20260325-205759.tgz`
- 清理前校验：
  - `sha256=7c2ec7ceefd9376854a911c17d9944fcb671d04ccf7f396d7c9ade1612f23d82`
  - `size=1315755 bytes`
- 清理后结果：`artifacts/backups/` 不再存在明文 `.tgz` 包
- 额外清理：历史 `.tgz.gpg` 调试包已按口径清理，仅保留 `.tgz.enc` + `.manifest.txt`
  - `openclaw-state-20260325-210925.tgz.gpg`（`sha256=c17d23cf2cd18d1499a9e77811b54015d5518a2faa447c155d11a6c6c025b106`）
  - `openclaw-state-20260325-212403.tgz.gpg`（`sha256=4946300fd9516b2700eace919da47d49adcfb22982b9961cec2c6aa1d3859571`）
  - `openclaw-state-20260325-212505.tgz.gpg`（`sha256=b6a746c7fb1f50759100e487def79c8fd1be64512febae6c599426d2cebf6045`）
- 当前目录状态：`artifacts/backups/` 仅保留一组有效对（`openclaw-state-20260325-212851.tgz.enc` + 同名 manifest）

## 3) 结论

- 备份/恢复脚本 v0 可执行，且当前加密口径已收敛为 `openssl + manifest sha256`
- 明文残留已清理，且脚本在失败时会自动删除临时明文归档
