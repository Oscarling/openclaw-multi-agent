# 2026-03-26 Gate-4 Stage-C 真实 C1 证据引用硬门禁验证记录

更新时间：2026-03-26  
目标：验证“真实审计模式”下，`evidence_ref` 为占位值时不会被判定为 `stage_c_passed`。

## 1) 执行命令

```bash
EXEC_ROOT="design/validation/artifacts/openclaw-gate4-stagec-realc1-auditgate-20260326-194651" \
GATE4_ACCOUNT_ID='xhs_demo_001' \
GATE4_PHASE_ID='C1' \
GATE4_BATCH_ID='XHS-REAL-C1-BATCH-001' \
GATE4_RELEASE_ID='XHS-REAL-C1-REL-001' \
GATE4_OPERATOR='lingguozhong' \
GATE4_TICKET_ID='GATE4-C-REAL-001' \
GATE4_STAGE_C_RECEIPT_FILE='runtime/argus/config/gate4/stage_c_real_c1_receipt.json' \
GATE4_STAGE_C_REQUIRE_REAL_EVIDENCE='yes' \
bash ./deploy/gate4_stage_c_execute.sh
```

## 2) 证据目录

- `design/validation/artifacts/openclaw-gate4-stagec-realc1-auditgate-20260326-194651/`
- 汇总文件：`design/validation/artifacts/openclaw-gate4-stagec-realc1-auditgate-20260326-194651/artifacts/stage-c-summary.txt`

## 3) 核心结果

- `stagec_receipt_present=yes`
- `stagec_receipt_valid=yes`
- `stagec_receipt_evidence_ref=telegram:真实消息链接或证据ID`
- `stagec_receipt_evidence_ref_placeholder=yes`
- `stagec_require_real_evidence=yes`
- `stage_c_result=waiting_stage_c_receipt_fix`

## 4) 结论

- 证据引用硬门禁生效：在真实审计模式（`GATE4_STAGE_C_REQUIRE_REAL_EVIDENCE=yes`）下，占位式 `evidence_ref` 不会通过阶段判定。
- 下一动作：将 `runtime/argus/config/gate4/stage_c_real_c1_receipt.json` 的 `evidence_ref` 替换为真实引用后复跑同一命令，目标结果为 `stage_c_passed`。
