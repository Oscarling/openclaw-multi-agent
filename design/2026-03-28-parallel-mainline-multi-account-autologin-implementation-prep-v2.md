# 2026-03-28 并行主链多账号自动登录实现准备包 v2（A37）

scope: `parallel_mainline_multi_account_autologin_impl_prep_v2`  
日期：2026-03-28  
触发事件：`parallel_mainline_multi_account_autologin_impl_prep_requested`  
阶段：实现准备（不含自动发布执行）

## 1) 目标

在 A36 评审通过后，固化“多账号自动登录能力”执行前所需的契约、目录、模板、异常处理与 DoD 判定口径，确保后续执行可复核、可回滚、可审计。

## 2) 输入基线

1. `design/2026-03-28-parallel-mainline-multi-account-autologin-scope-breakdown-v1.md`
2. `design/2026-03-28-parallel-mainline-multi-account-autologin-plan-eng-review-minutes-v1.md`
3. `runtime/argus/config/gate4/account_allowlist.json`
4. `shared/templates/gate4_account_allowlist_template.json`
5. `shared/templates/gate4_stage_a_manual_receipt_template.json`
6. `shared/templates/gate4_release_receipt_template.json`
7. `shared/templates/gate4_stage_c_receipt_template.json`

## 3) 字段契约（账号与回执）

### 3.1 账号契约（allowlist）

必填字段：

1. `account_id`
2. `platform`
3. `owner`
4. `risk_level`（`low|medium|high`）
5. `automation_level`（`observe_only|assisted|gated_auto`）

### 3.2 回执契约（按阶段）

1. Stage A：`account_id/login_ok/occurred_at/evidence_ref/operator/ticket_id`
2. Stage B：`release_id/account_id/publish_ok/occurred_at/evidence_ref/operator/ticket_id`
3. Stage C：`phase_id/batch_id/release_id/account_id/batch_size/success_count/failure_count/success_rate/publish_ok/halt_triggered/occurred_at/evidence_ref/operator/ticket_id`

统一约束：

1. `evidence_ref` 必须为真实可追溯引用，不允许占位字符串。
2. `ticket_id` 在 `gated_auto` 或 `require_manual_gate=yes` 场景为必填。

## 4) 目录规范

1. 模板目录：`shared/templates/`
2. 运行态配置：`runtime/argus/config/gate4/`
3. 验证产物：`design/validation/`
4. 执行摘要：`design/validation/artifacts/`

命名规范（账号维度）：

1. `manual_receipt_<account_id>.json`
2. `release_receipt_<account_id>.json`
3. `stage_c_real_<phase>_receipt_<account_id>.json`

## 5) 异常处理口径

1. token 缺失：
   - 结果：阻断执行，状态置为 `blocked_preflight` 或 `waiting_channel_credentials`
   - 动作：补 token 后重跑，不允许跳过探针。
2. allowlist 漏配：
   - 结果：`blocked_account_not_allowlisted`
   - 动作：补 allowlist 后重跑并留痕。
3. 回执不合法：
   - 结果：`waiting_*_receipt_fix`
   - 动作：修正回执并保留修订前后证据。
4. 成功率/阈值不达标（Stage C）：
   - 结果：`blocked_success_rate_below_threshold` 或 `halt_triggered`
   - 动作：立刻停机，进入复评，不允许继续放量。

## 6) DoD 判定口径（A37 完成标准）

1. 字段契约清晰且与现有脚本校验逻辑一致。
2. 目录规范与命名规范明确，新增账号可按同口径接入。
3. 异常处理矩阵覆盖 token/allowlist/receipt/阈值四类高频故障。
4. 形成事件执行卡并定义下一触发点（A38）。

## 7) 下一事件

`parallel_mainline_multi_account_autologin_impl_prep_completed` -> 启动 A38（首轮执行验证：配置一致性复检 + 异常注入演练）。
