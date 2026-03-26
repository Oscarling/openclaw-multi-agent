# 2026-03-26 Readiness Preflight Validation

更新时间：2026-03-26  
类型：执行前置检查 + 同日 Gate-2 onboarding 进展补记

## 1) 目标

- 在不触发运行态变更前，确认 Gate-2 与 C2 的执行前置条件
- 固化今日基线，避免后续在触发窗口临场排查

## 2) 执行项

### 2.1 Gate-2 可用性探针

- 脚本：`deploy/gate2_readiness_probe.sh`
- 证据目录：
  - `design/validation/artifacts/openclaw-gate2-probe-20260326-080448/artifacts`
- 核心结果：
  - `agents_list_exit=0`
  - `control_ui_exit=0`
  - `bind_help_exit=0`
  - `channels_list_exit=0`
  - `channels_status_exit=0`
  - `bind_command_available=yes`
  - `channel_configured=no`
  - `gate2_probe_result=waiting_channel_configuration`

说明：当前命令可用，但尚无已配置 channel/account，需先完成 channel 侧配置，再执行正式 binding 联调。

### 2.2 Gate-2 插件启用与状态细化（同日追加）

- 执行动作：
  - `openclaw plugins enable telegram`
  - `docker restart agent_argus`
  - `docker restart openclaw-sidecar_argus-1`（避免 `3001` 端口转发短暂异常）
- 证据目录：
  - `design/validation/artifacts/openclaw-gate2-plugin-enable-20260326-081842/`
  - `design/validation/artifacts/openclaw-gate2-probe-20260326-082211/artifacts`
- 核心结果：
  - `plugins-info-telegram.json`：`enabled=true`、`status=loaded`
  - `channels-add-telegram.exitcode=1`，错误为 `Telegram requires token or --token-file (or --use-env).`
  - `channels-status.json`：存在 `telegram/default` 账号，但 `configured=false`、`tokenStatus=missing`
  - 新版探针：`channel_present=yes`、`channel_configured=no`、`gate2_probe_result=waiting_channel_credentials`

说明：`Unknown channel` 阻塞已解除，当前阻塞点已收敛为“凭据缺失（token 未配置）”。

### 2.3 C2 月度演练预检

- 脚本：`deploy/monthly_recovery_preflight.sh`
- 证据目录：
  - `design/validation/artifacts/openclaw-monthly-preflight-20260326-080011/artifacts`
- 核心结果：
  - `archive_ok=yes`
  - `manifest_ok=yes`
  - `sha256_ok=yes`
  - `passphrase_ok=yes`（权限 `600`）
  - `agent_container_ok=yes`
  - `preflight_result=ready_for_monthly_window`

### 2.4 Gate-2 首轮绑定联调（同日收口动作）

- 执行动作：
  - `openclaw agents bind --agent steward --bind telegram:default --json`
  - 复核 `agents list --bindings --json`
  - 复跑 `deploy/gate2_readiness_probe.sh`
- 证据目录：
  - `design/validation/artifacts/openclaw-gate2-probe-20260326-084233/artifacts`
  - `design/validation/2026-03-26-channel-binding-validation.md`
- 核心结果：
  - `steward.bindings=1`，`bindingDetails` 包含 `telegram accountId=default`
  - 探针结果：`gate2_probe_result=ready_for_binding_test`
  - 默认入口保持 `assistantAgentId=steward`
  - 但 `channels status --probe` 仍为 `probe.ok=false`，`status=404`
  - 补充排查：token 文件长度仅 `11` 字节，疑似错误 token

### 2.5 Gate-2 探活恢复复测（同日二次收口）

- 执行动作：
  - 轮换 Telegram token 并重配 channel
  - 复测 `channels status --json --probe`
  - 复跑 `deploy/gate2_readiness_probe.sh`
- 证据目录：
  - `design/validation/artifacts/openclaw-gate2-probe-20260326-091734/artifacts`
  - `design/validation/artifacts/openclaw-gate2-probe-20260326-091948/artifacts`
  - `design/validation/2026-03-26-channel-binding-validation.md`
- 核心结果：
  - token 文件长度：`46` 字节（恢复正常）
  - `channels.status.probe.ok=true`
  - `channels.telegram.running=true`
  - `channels.telegram.lastError=null`
  - `gate2_probe_result=ready_for_binding_test`

## 3) 结论

- Gate-2：已完成首轮显式绑定并通过探活恢复复测；当前技术前置阻塞已关闭，可触发 Gate-2 专项评审。
- C2：已达到“可进入下一个月度窗口演练”的状态，按既定窗口执行即可。
