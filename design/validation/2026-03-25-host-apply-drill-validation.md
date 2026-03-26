# 2026-03-25 Host Apply Drill Validation (Gate-1 C1)

更新时间：2026-03-25  
类型：本地可回滚演练（host `state/workspaces` 覆盖 apply）

## 1) 演练目标

- 关闭 gstack Gate-1 条件 C1：验证 host 侧 `~/.openclaw/state/argus` 与 `~/.openclaw/workspaces/argus` 的 apply 覆盖链路可执行
- 在 apply 后执行自动回滚，确认运行态可恢复到原口径（默认入口、角色可见性不漂移）

## 2) 执行方式

- 脚本：`deploy/host_apply_drill.sh`
- 备份包：`artifacts/backups/openclaw-state-20260325-220936.tgz.enc`
- 清单文件：`artifacts/backups/openclaw-state-20260325-220936.manifest.txt`
- 演练目录：`/tmp/openclaw-host-apply-drill-20260325-2220`
- 证据目录（已固化到项目内）：
  - `design/validation/artifacts/openclaw-host-apply-drill-20260325-2220/artifacts`
- 执行窗口（Asia/Shanghai）：
  - 约 `2026-03-25 22:18` 到 `2026-03-25 22:19`（脚本完成后立即落盘）

## 3) 核验结果

### 3.1 完整性与覆盖范围

- `stage-restore.log` 显示：
  - `manifest sha256 verified`
  - 已解密并展开 `host-openclaw/state/argus`
  - 已解密并展开 `host-openclaw/workspaces/argus`
- 脚本日志显示：
  - `HAD_STATE=1`
  - `HAD_WORKSPACES=1`
- host 目录量化指标（`preapply-host-metrics.txt`）：
  - `state_files=4`，`workspaces_files=83`
  - 目录体积：`~/.openclaw/state/argus=16K`，`~/.openclaw/workspaces/argus=352K`

### 3.2 Apply 阶段（覆盖后）

- `applied-config-file.txt`：`~/.openclaw/config/openclaw.json`
- `applied-control-ui-config.json`：`assistantAgentId=steward`
- `applied-agents.json`：`main/steward/hunter/editor/publisher` 均存在，`steward.isDefault=true`
- `applied-compose.up.log`：已采集 compose 重建全量输出（含 orphan warning 与容器重建过程）
- `applied-host-metrics.txt`：
  - `state_files=4`，`workspaces_files=83`
- `applied-steward-smoke.json`：
  - `runId=64c24013-a757-4c64-aeed-1c4373b4f520`
  - `status=ok`，返回职责边界说明，未越权

### 3.3 Rollback 阶段（自动回滚后）

- 脚本日志显示：`rollback completed`
- `postrollback-config-file.txt`：`~/.openclaw/config/openclaw.json`
- `postrollback-control-ui-config.json`：`assistantAgentId=steward`
- `postrollback-agents.json`：五角色仍存在，默认入口仍为 `steward`
- `postrollback-compose.up.log`：已采集回切重建全量输出
- `postrollback-host-metrics.txt`：
  - `state_files=4`，`workspaces_files=83`
- `diff` 结果：
  - `applied-agents.json` vs `postrollback-agents.json` 无差异
  - `applied-control-ui-config.json` vs `postrollback-control-ui-config.json` 无差异

## 4) 回滚后运行态复核

- `docker exec agent_argus openclaw agents list --bindings --json`：五角色可见，`steward.isDefault=true`
- `curl -fsSL http://localhost:3001/__openclaw/control-ui-config.json`：`assistantAgentId=steward`

## 5) 结论

- Gate-1 条件 C1 已满足：host `state/workspaces` apply 覆盖与回滚闭环已验证并留痕
- 当前 Gate-1 剩余待关闭项仅 C2：下一次月度回归演练记录
