# 2026-03-26 Channel Binding Validation

更新时间：2026-03-26  
类型：Gate-2 首轮绑定联调验证（telegram）

## 1) 基本信息

- 联调日期（Asia/Shanghai）：2026-03-26
- channel：`telegram`
- accountId：`default`（`telegram-main`）
- 执行人：`lingguozhong + codex`

## 2) 执行命令

- 绑定命令：

```bash
docker exec agent_argus openclaw agents bind --agent steward --bind telegram:default --json
```

- 查询命令：

```bash
docker exec agent_argus openclaw agents list --bindings --json
curl -fsSL http://localhost:3001/__openclaw/control-ui-config.json
```

- 通道探活命令：

```bash
docker exec agent_argus openclaw channels status --json --probe
bash ./deploy/gate2_readiness_probe.sh
```

## 3) 结果

### 3.1 首轮绑定（首次执行）

- binding 生效：是
  - `steward.bindings=1`
  - `bindingDetails` 包含 `telegram accountId=default`
- 默认入口是否漂移：否
  - `assistantAgentId=steward`
- 角色列表是否漂移：否
  - `main/steward/hunter/editor/publisher` 均在
- 通道健康探活：未通过
  - `channels.status.probe.ok=false`
  - `status=404`
  - `lastError=Call to 'deleteWebhook' failed! (404: Not Found)`

### 3.2 纠偏复测（token 轮换 + 重配后）

- token 文件长度：`46` 字节（由异常 `11` 字节恢复）
- 通道健康探活：通过
  - `channels.status.probe.ok=true`
  - `channels.telegram.running=true`
  - `channels.telegram.lastError=null`
- Gate-2 探针：通过
  - `gate2_probe_result=ready_for_binding_test`

### 3.3 真实入站/回包留痕（当前状态）

- 当前状态：已完成（日志留痕 + 主动回包）
- 入站证据：
  - 网关日志出现 `telegram pairing request`，含 `chatId=6189851600` 与 `senderUserId=6189851600`
- 出站证据：
  - 执行 `openclaw message send --channel telegram --target 6189851600 ... --json` 返回 `ok=true`、`messageId=3`
- 运行态观察（复查）：
  - `channelAccounts.telegram[0].lastInboundAt=null`
  - `channelAccounts.telegram[0].lastOutboundAt=null`
- 解释：真实收发链路已验证通过；`lastInboundAt/lastOutboundAt` 当前作为观测字段仍未回填，记录为已知限制，不阻塞 Gate-2 收口

## 4) 证据路径

- 首轮绑定阶段探针：
  - `design/validation/artifacts/openclaw-gate2-probe-20260326-084233/artifacts/probe-summary.txt`
- 纠偏后探针：
  - `design/validation/artifacts/openclaw-gate2-probe-20260326-091734/artifacts/probe-summary.txt`
  - `design/validation/artifacts/openclaw-gate2-probe-20260326-091948/artifacts/probe-summary.txt`
  - `design/validation/artifacts/openclaw-gate2-probe-20260326-093356/artifacts/probe-summary.txt`
- 插件启用与早期状态证据：
  - `design/validation/artifacts/openclaw-gate2-plugin-enable-20260326-081842/`
- 真实消息留痕证据：
  - `design/validation/2026-03-26-telegram-message-smoke-validation.md`

## 5) 回滚（本次未触发）

- 触发原因：无
- 回滚命令：无
- 回滚后验证：无

## 6) 结论

- Gate-2 绑定联调前置是否通过：是（已完成显式绑定 + 通道探活恢复）
- 是否可进入 gstack Gate-2 评审：是（可按里程碑立即触发）
- 后续建议（不阻塞本次关口触发）：
  - 跟踪 `lastInboundAt/lastOutboundAt` 回填行为（当前作为观测侧已知限制）
