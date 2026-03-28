# 2026-03-28 并行主链 Stage A（xhs_demo_002）证据占位清理复检记录（A33）

## 1) 触发背景

- A28 通过时 `manual_receipt_xhs_demo_002.json` 的 `evidence_ref` 仍为占位字符串。
- A32 通过后进入账号 2 审计口径收口，需要将占位证据替换为真实引用并复检。

## 2) 执行动作

1. 发送 Stage A 证据确认消息，获取 `messageId=19`。
2. 更新 `runtime/argus/config/gate4/manual_receipt_xhs_demo_002.json`：
   - `evidence_ref=telegram:chatId=6189851600,messageId=19,ticket=GATE4-A-002`
3. 执行 Stage A 严格复检：

```bash
EXEC_ROOT="design/validation/artifacts/openclaw-parallel-mainline-stagea-account2-evidence-cleanup-20260328-223831" \
GATE4_ACCOUNT_ID='xhs_demo_002' \
GATE4_OPERATOR='lingguozhong' \
GATE4_TICKET_ID='GATE4-A-002' \
GATE4_MANUAL_RECEIPT_FILE='runtime/argus/config/gate4/manual_receipt_xhs_demo_002.json' \
GATE4_STAGE_A_STRICT='yes' \
bash ./deploy/gate4_stage_a_execute.sh
```

## 3) 结果摘要

- `manual_receipt_present=yes`
- `manual_receipt_valid=yes`
- `manual_receipt_login_ok=yes`
- `manual_receipt_evidence_ref=telegram:chatId=6189851600,messageId=19,ticket=GATE4-A-002`
- `stage_a_result=stage_a_passed`

## 4) 证据路径

- 执行摘要：`design/validation/artifacts/openclaw-parallel-mainline-stagea-account2-evidence-cleanup-20260328-223831/artifacts/stage-a-summary.txt`
- 回执文件：`runtime/argus/config/gate4/manual_receipt_xhs_demo_002.json`

## 5) 结论

- A28 遗留的占位证据风险已闭环。
- 账号 `xhs_demo_002` 当前 A/B/C 三段门禁均通过且证据引用为真实值。
