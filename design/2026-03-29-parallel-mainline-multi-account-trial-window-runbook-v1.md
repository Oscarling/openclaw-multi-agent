# 2026-03-29 并行主链多账号自动登录受控窗口运行手册（A42，v1）

scope: `parallel_mainline_multi_account_trial_window_runbook_v1`  
日期：2026-03-29  
触发事件：`parallel_mainline_multi_account_trial_window_close_review_completed`

## 1) 目标

将 A39~A41 已确认的受控窗口边界固化为可执行运行口径，确保后续推进以“事件触发 + 可停机 + 可回归”为唯一模式。

## 2) 运行范围

1. 账号范围：仅 `xhs_demo_001`、`xhs_demo_002`
2. 执行链路：仅 Gate-4 Stage A/B/C 既有门禁
3. 阈值纪律：保持 C1 口径（`success_rate >= 0.95`，异常触发停机）
4. 审计要求：必须具备 `ticket + receipt + 真实 evidence_ref`

## 3) 入口与预检

执行入口：`deploy/parallel_mainline_gate4_abc_recheck.sh`

执行前必须确认：

1. allowlist 可识别目标账号（`account_found=yes`）
2. 必填 ticket 已提供（`needs_ticket=yes` 时必须传入）
3. 回执文件存在且可解析（`*_receipt_present=yes`、`*_receipt_valid=yes`）
4. Stage C 真实证据开关启用：`GATE4_STAGE_C_REQUIRE_REAL_EVIDENCE=yes`

## 4) 继续条件（Continue）

满足以下全部条件才允许继续进入下一事件：

1. 双账号 `overall_result=parallel_gate4_abc_recheck_passed`
2. 两账号 Stage C：`halt_triggered=no`
3. 两账号 Stage C：`success_rate >= 0.95` 且 `failure_count` 未触发阈值
4. 三本账同步通过：
   - `python3 scripts/backlog_lint.py`
   - `python3 scripts/backlog_sync.py`
   - `bash scripts/premerge_check.sh`

## 5) 停机条件（Halt）

命中任一条即刻停机并回到评审环节：

1. 任一账号出现 `halt_triggered=yes`
2. 任一账号 `stage_c_result != stage_c_passed`
3. 任一关键证据为占位值或不可追溯
4. 出现 `blocked_account_not_allowlisted` 或 `blocked_need_ticket` 且窗口内未修复

## 6) 停机后的动作

1. 记录失败摘要到 `design/validation/artifacts/...`
2. 回填三本账并标注“停机原因”
3. 发起两段式复评（`office-hours -> plan-eng-review`）
4. 未完成复评前不得继续执行下一批

## 7) 回归入口

1. 单账号回归：按账号参数调用 `deploy/parallel_mainline_gate4_abc_recheck.sh`
2. 双账号回归：分别执行两次并汇总摘要
3. 结果汇总：统一落盘到 `design/validation/` 并更新 issue #37

## 8) 护栏约束（必须遵守）

1. 不得以提速为由绕过 `scripts/openclaw_agent_safe.sh`
2. 不得关闭或跳过 `RH-T5-B01` 侧线阻断跟踪
3. 不得在证据链不完整时宣布“通过”

## 9) 下一事件

`parallel_mainline_multi_account_trial_window_runbook_hardened`
