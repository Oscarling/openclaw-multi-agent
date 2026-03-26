# 2026-03-26 Channel Onboarding Checklist（Gate-2 前置）

更新时间：2026-03-26  
用途：把 `waiting_channel_configuration / waiting_channel_credentials` 转成可执行 onboarding 步骤

## 1) 目标

- 完成至少 1 个 channel/account 配置
- 为 Gate-2 binding 联调提供真实目标（`<channel[:accountId]>`）

## 2) 执行顺序

1. 确认目标 channel 插件已启用（示例为 Telegram）

```bash
docker exec agent_argus openclaw plugins enable telegram
docker restart agent_argus
docker restart openclaw-sidecar_argus-1
```

2. 查看当前 channel 配置

```bash
docker exec agent_argus openclaw channels list --json
docker exec agent_argus openclaw channels status --json
```

3. 添加 channel 账号配置（示例为 Telegram）

```bash
docker exec agent_argus openclaw channels add --channel telegram --token <BOT_TOKEN> --name telegram-main
```

安全提示：若 token 曾出现在聊天记录、截图或终端明文回显，先在 `@BotFather` 执行 `/revoke` + `/token` 轮换，再继续后续步骤。

可选校验（不打印 token 内容）：

```bash
docker exec agent_argus sh -lc 'wc -c /root/.openclaw/config/secrets/telegram_bot_token.txt'
```

若长度明显异常（例如十几字节），优先判定为 token 写入错误。

4. 若该 channel 需要登录会话（按 provider 支持情况）

```bash
docker exec agent_argus openclaw channels login --channel telegram --account default --verbose
```

5. 验证 channel 在线状态

```bash
docker exec agent_argus openclaw channels status --json --probe
```

6. 若需要 target id，执行解析

```bash
docker exec agent_argus openclaw channels resolve --channel telegram --account default --kind group --json "<group_or_user_name>"
```

7. 若出现 Telegram 组消息被静默丢弃风险（默认 `groupPolicy=allowlist`），补齐 allowlist 或按需改策略

```bash
docker exec agent_argus openclaw config set channels.telegram.groupAllowFrom '["<sender_id_1>","<sender_id_2>"]'
# 或者（按需评估后）：
docker exec agent_argus openclaw config set channels.telegram.groupPolicy open
```

## 3) Gate-2 联调前确认

- `channels list --json` 中不再为空
- `channels status --json --probe` 返回可用账号，且账号 `configured=true`
- `tokenStatus` 不再是 `missing`
- `channels.status.probe.ok=true`，且 `lastError=null`
- `deploy/gate2_readiness_probe.sh` 结果为 `ready_for_binding_test`（不是 `waiting_channel_configuration` 或 `waiting_channel_credentials`）

## 4) 通过后动作

- 按 `design/2026-03-25-gate2-channel-binding-readiness-v1.md` 执行绑定联调
- 使用 `design/validation/channel-binding-validation-template.md` 落盘证据
- 联调通过后触发 gstack Gate-2 专项评审
