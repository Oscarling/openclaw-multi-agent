# 2026-03-25 Recovery Drill Validation (Dry Run)

更新时间：2026-03-25  
类型：本地可回滚演练（不涉及线上环境）

## 1) 演练目标

- 验证“从近空环境恢复 + 重建 + 冒烟 + 回切”流程可执行
- 记录首次恢复演练耗时与证据路径，作为后续月度演练基线

## 2) 执行方式

- 脚本：`deploy/recovery_drill.sh`
- 演练临时目录：`/tmp/openclaw-recovery-drill-20260325-205311`
- 证据目录：`/tmp/openclaw-recovery-drill-20260325-205311/artifacts`
- 执行时间窗口：
  - 开始：2026-03-25 20:53:11（Asia/Shanghai）
  - 完成：2026-03-25 20:53:23（Asia/Shanghai）
  - 端到端耗时：约 12 秒（脚本日志口径）

## 3) 核验结果

### 3.1 Drill 阶段（切换到演练 runtime）

- `drill-config-file.txt`：`~/.openclaw/config/openclaw.json`
- `drill-control-ui-config.json`：`assistantAgentId=steward`
- `drill-mounts.txt`：
  - `/root/.openclaw/config` 为 `rw`
  - `/root/.openclaw/agents` 为 `rw`
  - `/root/.openclaw/openclaw.json` 为 `ro`
- `drill-agents.json`：五角色均存在，`steward.isDefault=true`
- `drill-steward-smoke.json`：
  - `runId=0f318013-090d-43a4-b979-f2f2114da4e1`
  - 返回职责边界说明，未越权

### 3.2 回切阶段（恢复到原项目 override）

- `postrollback-config-file.txt`：`~/.openclaw/config/openclaw.json`
- `postrollback-control-ui-config.json`：`assistantAgentId=steward`
- `postrollback-agents.json`：五角色均存在，`steward.isDefault=true`

## 4) 结论

- 首次恢复演练通过：恢复路径、重建步骤、回切步骤均可执行
- 当前可将“首次空机恢复演练”标记为已完成（Gate-1 证据项）
- 备份加密工具、密钥托管与脚本化能力已在后续文档中定稿并验证

## 5) Drill 覆盖范围与未覆盖项

本次已覆盖：

- 项目内 `runtime/argus/*` 的恢复演练链路
- 容器重建与自动回切
- 默认入口与五角色可见性复验

本次未覆盖（后续补齐）：

- host 侧 `~/.openclaw/state/argus` 的 apply 覆盖演练
- host 侧 `~/.openclaw/workspaces/argus` 的 apply 覆盖演练
- secrets 恢复的实操演练（仅有策略，未做全链路演练）
