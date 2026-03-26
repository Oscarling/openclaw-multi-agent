# 主线 M2（事件触发）执行计划 v1

日期：2026-03-26  
定位：在“当前阶段已收口”基础上，进入下一里程碑（全自动能力扩展前置段）。

## 1) 目标

把当前“已知限制 + 暂不纳入项”转成可执行主线，继续保持事件驱动推进。

## 2) 事件触发任务（不按时间）

### M2-E1：CLI 默认路由差异收敛（R-03 根因层）

- 触发事件：确认上游/镜像具备可验证的默认路由收敛能力，或本项目形成可替代修复方案
- 当前进展：
  - 已落地探针：`deploy/cli_route_parity_probe.sh`
  - 首轮基线：`probe_result=route_mismatch_detected`（默认路径仍落 `main`）
  - 记录：`design/validation/2026-03-26-cli-route-parity-probe-validation.md`
- 完成标准：
  - `openclaw agent --to ...` 与 UI 默认入口口径一致
  - 验收证据回填 `验收清单.md` 与 `DECISIONS.md`

### M2-E2：自动化发布链路范围冻结（Gate-4 预评审）

- 触发事件：M2-E1 完成后，主线进入“能力扩展”分支
- 当前进展：
  - 预评审输入包已落地：`design/2026-03-26-gate4-automation-scope-prep-v1.md`
  - `office-hours` 预评审纪要已落地：`design/2026-03-26-gate-4-automation-scope-office-hours-minutes-v1.md`
  - 事件执行卡已落地：`design/2026-03-26-gate4-event-execution-card-v1.md`
  - `plan-eng-review` 议程已落地：`design/2026-03-26-gate-4-automation-plan-eng-review-agenda-v1.md`
  - `plan-eng-review` 正式评审纪要已落地：`design/2026-03-26-gate-4-automation-plan-eng-review-minutes-v1.md`
  - 当前状态：`Conditional-Go`（允许进入 M2-E3 受控实现准备）
- 执行动作：
  - 先走 `gstack office-hours`
  - 再走 `gstack plan-eng-review`
  - 冻结“哪些动作自动化、哪些动作保留人工闸门”
- 完成标准：形成 Gate-4 边界文档与验证清单

### M2-E3：多账号自动登录能力（受控接入）

- 触发事件：M2-E2 完成并通过评审
- 当前进展：
  - 实现准备包已落地：`design/2026-03-26-m2-e3-login-implementation-prep-v1.md`
  - 阶段 A 通过记录：`design/validation/2026-03-26-gate4-stage-a-pass-validation.md`
  - 阶段 A DoD：`design/validation/2026-03-26-gate4-stage-a-dod-validation.md`
  - 当前状态：阶段 A 已通过（`stage_a_passed`），进入 M2-E4 准备态
- 完成标准：
  - 至少 1 个受控账号链路可复现
  - secrets 与权限边界明确，不把敏感值入库

### M2-E4：自动发布执行链路（含回执）

- 触发事件：M2-E3 完成且安全护栏验证通过
- 当前进展：
  - 准备包已落地：`design/2026-03-26-m2-e4-release-chain-prep-v1.md`
  - 阶段 B 预检记录：`design/validation/2026-03-26-gate4-stage-b-preflight-validation.md`
  - 阶段 B dry-run：`design/validation/2026-03-26-gate4-stage-b-dryrun-validation.md`
  - 阶段 B DoD：`design/validation/2026-03-26-gate4-stage-b-dod-validation.md`
  - 当前状态：首轮 dry-run 通过，结论 `Conditional-Go`
- 完成标准：
  - “发布动作 + 发布回执”链路可复核
  - 异常回滚与人工接管流程可执行

### M2-E5：自动发小红书（受控放量）

- 触发事件：M2-E4 完成并通过专项评审
- 当前进展：
  - 准备包已落地：`design/2026-03-26-m2-e5-xhs-scaleup-prep-v1.md`
  - 放量策略卡：`design/2026-03-26-m2-e5-rollout-strategy-card-v1.md`
  - 阶段 C 预检：`design/validation/2026-03-26-gate4-stage-c-preflight-validation.md`
  - 阶段 C dry-run：`design/validation/2026-03-26-gate4-stage-c-dryrun-validation.md`
  - 阶段 C DoD：`design/validation/2026-03-26-gate4-stage-c-dod-validation.md`
  - 专项评审输入包：`design/2026-03-26-gate4-stage-c-real-c1-review-prep-v1.md`
  - 专项执行卡：`design/2026-03-26-gate4-stage-c-real-c1-event-execution-card-v1.md`
  - 专项议程：`design/2026-03-26-gate4-stage-c-real-c1-plan-eng-review-agenda-v1.md`
  - 专项预评审纪要：`design/2026-03-26-gate4-stage-c-real-c1-office-hours-minutes-v1.md`
  - 专项正式评审纪要：`design/2026-03-26-gate4-stage-c-real-c1-plan-eng-review-minutes-v1.md`
  - 真实 C1 执行准备验证：`design/validation/2026-03-26-gate4-stage-c-real-c1-execution-prep-validation.md`
  - 真实 C1 通过记录：`design/validation/2026-03-26-gate4-stage-c-real-c1-pass-validation.md`
  - 真实 C1 审计收口记录：`design/validation/2026-03-26-gate4-stage-c-real-c1-audit-close-validation.md`
  - 真实 C1 第二批通过记录：`design/validation/2026-03-26-gate4-stage-c-real-c1-batch2-pass-validation.md`
  - C2 阻断项关闭记录：`design/validation/2026-03-26-gate4-stage-c-c2-blockers-close-validation.md`
  - 真实 C1 DoD：`design/validation/2026-03-26-gate4-stage-c-real-c1-dod-validation.md`
  - C2 评审输入包：`design/2026-03-26-gate4-stage-c-c2-review-prep-v1.md`
  - C2 专项执行卡：`design/2026-03-26-gate4-stage-c-c2-event-execution-card-v1.md`
  - C2 专项议程：`design/2026-03-26-gate4-stage-c-c2-plan-eng-review-agenda-v1.md`
  - C2 专项预评审纪要：`design/2026-03-26-gate4-stage-c-c2-office-hours-minutes-v1.md`
  - C2 专项正式评审纪要：`design/2026-03-26-gate4-stage-c-c2-plan-eng-review-minutes-v1.md`
  - C2 复评纪要：`design/2026-03-26-gate4-stage-c-c2-office-hours-rereview-minutes-v1.md`、`design/2026-03-26-gate4-stage-c-c2-plan-eng-rereview-minutes-v1.md`
  - C2 最终放行纪要：`design/2026-03-26-gate4-stage-c-c2-office-hours-final-minutes-v1.md`、`design/2026-03-26-gate4-stage-c-c2-plan-eng-final-minutes-v1.md`
  - C2 单批次执行记录：`design/validation/2026-03-26-gate4-stage-c-real-c2-batch1-pass-validation.md`
  - C2 DoD：`design/validation/2026-03-26-gate4-stage-c-c2-dod-validation.md`
  - 当前状态：C2 单批次闭环已完成，进入“C2 连续批次是否放行”复评触发态
- 完成标准：
  - 先小流量受控运行，再按事件放量
  - 成功/失败回执可追溯，留痕完整

## 3) 执行原则

- 仍采用“本地阶段收口 -> 分段上 GitHub”
- 每完成一个事件节点，必须同步三本账：
  - `BACKLOG.md`
  - `DECISIONS.md`
  - `验收清单.md`
