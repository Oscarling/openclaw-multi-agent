# 2026-03-26 Gate-4 Stage-C 真实 C2 单批次执行通过记录

更新时间：2026-03-26  
目标：在 C2 最终放行后，完成 C2 首批（单批次）受控执行闭环验证。

## 1) 执行前证据动作

发送 C2 证据消息并取得 `messageId=7`：

```bash
docker exec agent_argus openclaw message send \
  --channel telegram \
  --target 6189851600 \
  --message "gate4-c2-batch1-evidence XHS-REAL-C2-BATCH-001 2026-03-26 20:37:xx +0800" \
  --json
```

`evidence_ref`：

```text
telegram:chatId=6189851600,messageId=7,batch=XHS-REAL-C2-BATCH-001
```

## 2) 执行命令

```bash
NOW_TS="$(date '+%Y-%m-%dT%H:%M:%S%z')"
C2_RECEIPT="runtime/argus/config/gate4/stage_c_real_c2_receipt_batch1.json"
jq \
  --arg phase "C2" \
  --arg batch "XHS-REAL-C2-BATCH-001" \
  --arg rel "XHS-REAL-C2-REL-001" \
  --arg occ "$NOW_TS" \
  --arg ev "telegram:chatId=6189851600,messageId=7,batch=XHS-REAL-C2-BATCH-001" \
  --arg ticket "GATE4-C2-REAL-001" \
  --arg notes "real c2 batch1 run" \
  '.phase_id=$phase
   | .batch_id=$batch
   | .release_id=$rel
   | .occurred_at=$occ
   | .evidence_ref=$ev
   | .ticket_id=$ticket
   | .batch_size=10
   | .success_count=10
   | .failure_count=0
   | .success_rate=1.0
   | .publish_ok=true
   | .halt_triggered=false
   | .notes=$notes' \
  runtime/argus/config/gate4/stage_c_real_c1_receipt_batch2.json > "$C2_RECEIPT"

chmod 600 "$C2_RECEIPT"

EXEC_ROOT="design/validation/artifacts/openclaw-gate4-stagec-realc2-batch1-20260326-203722"
EXEC_ROOT="$EXEC_ROOT" \
GATE4_ACCOUNT_ID='xhs_demo_001' \
GATE4_PHASE_ID='C2' \
GATE4_BATCH_ID='XHS-REAL-C2-BATCH-001' \
GATE4_RELEASE_ID='XHS-REAL-C2-REL-001' \
GATE4_OPERATOR='lingguozhong' \
GATE4_TICKET_ID='GATE4-C2-REAL-001' \
GATE4_STAGE_C_RECEIPT_FILE="$C2_RECEIPT" \
GATE4_STAGE_C_REQUIRE_REAL_EVIDENCE='yes' \
bash ./deploy/gate4_stage_c_execute.sh
```

## 3) 证据目录

- `design/validation/artifacts/openclaw-gate4-stagec-realc2-batch1-20260326-203722/`
- 汇总文件：`design/validation/artifacts/openclaw-gate4-stagec-realc2-batch1-20260326-203722/artifacts/stage-c-summary.txt`
- 回执文件：`runtime/argus/config/gate4/stage_c_real_c2_receipt_batch1.json`

## 4) 核心结果（T3/T4）

- `phase_id=C2`
- `preflight_result=ready_for_stage_c_execution`
- `stagec_receipt_success_rate=1.0`
- `stagec_receipt_failure_count=0`
- `stagec_receipt_halt_triggered=no`
- `stagec_receipt_evidence_ref_placeholder=no`
- `stage_c_result=stage_c_passed`

## 5) 结论（T5 前置）

- C2 单批次受控执行通过，未触发停机阈值。
- 下一动作：回填三本账与 C2 DoD，并触发“是否进入 C2 连续批次”复评。
