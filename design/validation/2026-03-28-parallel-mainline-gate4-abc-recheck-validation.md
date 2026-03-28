# 2026-03-28 并行主链 Gate-4 A/B/C 严格复检记录（A25）

## 1) 触发背景

- A23 并行主链策略已生效：`RH-T5-B01` 侧线保持开启，业务主链允许并行推进。
- 需要验证“非默认 `--to` 路由依赖”的 Gate-4 执行链路在当前环境仍可稳定通过。

## 2) 执行范围

- Stage A（多账号登录受控接入）
- Stage B（发布执行链路含回执）
- Stage C（受控放量回执校验）

全部执行均使用严格模式：

- `GATE4_STAGE_A_STRICT=yes`
- `GATE4_STAGE_B_STRICT=yes`
- `GATE4_STAGE_C_STRICT=yes`

## 3) 执行命令

```bash
EXEC_ROOT="design/validation/artifacts/openclaw-parallel-mainline-stagea-recheck-<ts>" \
GATE4_ACCOUNT_ID='xhs_demo_001' \
GATE4_OPERATOR='lingguozhong' \
GATE4_TICKET_ID='GATE4-A-001' \
GATE4_MANUAL_RECEIPT_FILE='runtime/argus/config/gate4/manual_receipt.json' \
GATE4_STAGE_A_STRICT='yes' \
bash ./deploy/gate4_stage_a_execute.sh

EXEC_ROOT="design/validation/artifacts/openclaw-parallel-mainline-stageb-recheck-<ts>" \
GATE4_ACCOUNT_ID='xhs_demo_001' \
GATE4_RELEASE_ID='XHS-REL-001' \
GATE4_OPERATOR='lingguozhong' \
GATE4_TICKET_ID='GATE4-B-001' \
GATE4_RELEASE_RECEIPT_FILE='runtime/argus/config/gate4/release_receipt.json' \
GATE4_STAGE_B_STRICT='yes' \
bash ./deploy/gate4_stage_b_execute.sh

EXEC_ROOT="design/validation/artifacts/openclaw-parallel-mainline-stagec-recheck-<ts>" \
GATE4_ACCOUNT_ID='xhs_demo_001' \
GATE4_PHASE_ID='C1' \
GATE4_BATCH_ID='XHS-REAL-C1-BATCH-001' \
GATE4_RELEASE_ID='XHS-REAL-C1-REL-001' \
GATE4_OPERATOR='lingguozhong' \
GATE4_TICKET_ID='GATE4-C-REAL-001' \
GATE4_STAGE_C_RECEIPT_FILE='runtime/argus/config/gate4/stage_c_real_c1_receipt.json' \
GATE4_STAGE_C_REQUIRE_REAL_EVIDENCE='yes' \
GATE4_STAGE_C_STRICT='yes' \
bash ./deploy/gate4_stage_c_execute.sh
```

## 4) 结果摘要

- Stage A：
  - `preflight_result=ready_for_stage_a_execution`
  - `manual_receipt_valid=yes`
  - `stage_a_result=stage_a_passed`
- Stage B：
  - `preflight_result=ready_for_stage_b_execution`
  - `release_receipt_valid=yes`
  - `stage_b_result=stage_b_passed`
- Stage C：
  - `preflight_result=ready_for_stage_c_execution`
  - `stagec_receipt_valid=yes`
  - `stagec_receipt_evidence_ref_placeholder=no`
  - `stage_c_result=stage_c_passed`

## 5) 证据路径

- Stage A：
  - `design/validation/artifacts/openclaw-parallel-mainline-stagea-recheck-20260328-201438/artifacts/stage-a-summary.txt`
- Stage B：
  - `design/validation/artifacts/openclaw-parallel-mainline-stageb-recheck-20260328-201519/artifacts/stage-b-summary.txt`
- Stage C：
  - `design/validation/artifacts/openclaw-parallel-mainline-stagec-recheck-20260328-201547/artifacts/stage-c-summary.txt`

## 6) 结论

- Gate-4 A/B/C 在并行主链模式下复检通过，当前环境可继续推进“非默认 `--to` 路由依赖”的业务链路工作。
- `RH-T5-B01` 侧线状态不变，继续事件驱动等待上游 `#56370` 新反馈。

