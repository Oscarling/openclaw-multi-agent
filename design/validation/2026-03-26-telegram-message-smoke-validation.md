# 2026-03-26 Telegram Message Smoke Validation

更新时间：2026-03-26  
类型：Gate-2 运营侧入站/回包留痕补证

## 1) 目标

- 证明 Telegram 链路已存在真实入站事件
- 证明系统可向真实目标完成一次主动回包

## 2) 入站证据（日志）

命令：

```bash
docker exec agent_argus sh -lc "grep -n 'telegram pairing request' /tmp/openclaw/openclaw-2026-03-26.log | tail -n 5"
```

结果（节选）：

```text
443:{"0":"{\"module\":\"telegram-auto-reply\"}","1":{"chatId":"6189851600","senderUserId":"6189851600","username":"Oscar_ling","firstName":"ling","lastName":"Oscar","matchKey":"none","matchSource":"none"},"2":"telegram pairing request",...,"time":"2026-03-26T01:30:31.540+00:00"}
```

结论：

- 已出现真实入站事件，且可提取可回包目标 `chatId=6189851600`

## 3) 回包证据（主动发送）

命令：

```bash
docker exec agent_argus openclaw message send \
  --channel telegram \
  --target 6189851600 \
  --message "smoke-reply 2026-03-26 09:35 Asia/Shanghai" \
  --json
```

结果（节选）：

```json
{
  "action": "send",
  "channel": "telegram",
  "dryRun": false,
  "handledBy": "plugin",
  "payload": {
    "ok": true,
    "messageId": "3",
    "chatId": "6189851600"
  }
}
```

结论：

- 主动回包成功（`ok=true`）

## 4) 运行态字段复查

命令：

```bash
docker exec agent_argus openclaw channels status --json --probe
```

观察：

- `channelAccounts.telegram[0].lastInboundAt=null`
- `channelAccounts.telegram[0].lastOutboundAt=null`

说明：

- 该两项统计字段当前未随消息收发回填，记录为观测侧已知限制
- 不影响本次 Gate-2 运营侧“真实入站 + 回包”留痕结论
