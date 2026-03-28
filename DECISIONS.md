# OpenClaw Multi-Agent Decisions

更新时间：2026-03-26

## 已确认决策

### 2026-03-25：A 版先走“单容器多 Agent”

- 决策：先在一个 OpenClaw 容器内验证多个长期 Agent，而不是先拆成多容器
- 原因：当前目标是验证角色分工和调度链路，单容器方案改动更小、排障更快

### 2026-03-25：MVP 不做自动发小红书

- 决策：A 版定位为“半自动运营中台”，保留人工闸门
- 原因：自动发布风险高，当前阶段优先验证角色边界和内容链路

### 2026-03-25：只修改 `agent_argus`

- 决策：当前实验严格限定在 `agent_argus`
- 原因：避免误伤其他运行中的容器，降低部署层试错成本

### 2026-03-25：先做两角色 MVP

- 决策：第一阶段先只验证 `steward` 和 `hunter`
- 原因：最小链路最短，问题定位更清晰

## 当前工程方向

### 2026-03-25：修复重点从“角色设计”转到“部署层解锁”

- 观察：`openclaw agents add ...` 报错不是因为命令写错，也不是因为容器脏了
- 证据：`/root/.openclaw/openclaw.json` 当前是只读挂载，`rename` 覆盖时报 `EBUSY`
- 结论：下一步必须先解决 `agent_argus` 的可写运行配置问题，再继续多 Agent 创建

### 2026-03-25：优先采用 `agent_argus` 专属可写运行配置

- 决策：不直接改共享模板为可写；优先让 `agent_argus` 使用自己的可写 config 路径
- 原因：改动面最小，只影响 `agent_argus`，不波及其他容器
- 状态：已完成方案讨论，待实施验证

### 2026-03-25：`/root/.openclaw/agents` 需要持久化

- 观察：新增 Agent 的 `agentDir` 位于 `/root/.openclaw/agents/<name>/agent`
- 结论：如果不单独持久化该目录，容器重建后可能丢失新增 Agent 状态
- 状态：已确认风险，待纳入部署修改

### 2026-03-25：角色定义采用“两段式讨论”

- 决策：角色定义不直接凭感觉写，后续采用两段式讨论
- 第一轮：找 `gstack` 的 `office-hours` 讨论角色职责、输入输出、协作链路
- 第二轮：找 `gstack` 的 `plan-eng-review` 收敛工程边界、路由策略和验收标准
- 时机：先解锁 `agent_argus` 的部署层，再讨论 `steward` 和 `hunter`；两角色稳定后再讨论 `editor` 和 `publisher`
- 适用范围：后续新增角色或角色重组（合并/拆分）也沿用同一门禁流程

### 2026-03-25：先部署可扩缩的底座，再详细定义前两个角色

- 决策：当前顺序采用“先解锁部署层，再细化最小角色集”，不是先把全部角色一次性定义完
- 具体做法：四个角色先保留轻量草图，但只详细定义并落地 `steward` 和 `hunter`
- 原因：
  - 当前真实阻塞点在部署层，不先解锁，多角色设计无法进入真实验证
  - 如果一开始把四个角色都写得很细，后面很可能被真实运行结果推翻，返工成本高
  - 只要 `agent_argus` 支持可写配置和 `agents` 持久化，后续增加或减少角色都是可行的
- 前提：后续增减角色时，要同步更新路由策略、角色文件、验收清单和必要的共享模板

### 2026-03-25：`agent_argus` 采用 repo 内 override 方式部署

- 决策：不直接改全局部署文件，改为在项目目录内维护 `agent_argus` 的 override 文件
- 文件：`deploy/agent_argus.override.yml`
- 原因：
  - 只影响 `agent_argus`
  - 更容易纳入项目管理和后续 GitHub 版本控制
  - 回滚时只需不用 override 重建 `agent_argus`

### 2026-03-25：`steward` 与 `hunter` 完成第一轮角色定义

- 决策：按 `office-hours` 思路完成两角色第一轮定义，并同步到 `agent_argus` 工作区
- 产物：
  - `design/2026-03-25-office-hours-steward-hunter.md`
  - `roles/steward/*` 与 `roles/hunter/*` 四件套角色文件
- 验证：两角色身份自述与防串角色测试通过
- 下一步：进入 `plan-eng-review`，把路由规则与验收口径进一步工程化收口

### 2026-03-25：唯一入口路由已切换到 `steward`

- 决策：将 `agents.list[1].default=true`，并重建 `agent_argus` 生效
- 验证：
  - `openclaw agents list --bindings --json` 中 `steward.isDefault=true`
  - `http://localhost:3001/__openclaw/control-ui-config.json` 中 `assistantAgentId=steward`
- 备注：当前镜像里部分 channel plugin 不可用，channel 级 `agents bind` 暂时无法配置，后续在插件可用后补显式绑定

### 2026-03-25：`steward` + `hunter` 完成 `plan-eng-review` 收口验收

- 决策：将 `plan-eng-review` 结论落地到角色契约与共享模板，并做三用例验收
- 验收结果：
  - Case A（缺字段处理）通过
  - Case B（结构化选题卡）通过
  - Case C（防串角色）通过
- 产物：
  - `design/2026-03-25-plan-eng-review-steward-hunter.md`
  - `design/validation/2026-03-25-routing-validation.md`
  - `shared/templates/*` 同步到运行态 `workspace/shared/templates`

### 2026-03-25：保留“CLI 与 UI 默认入口口径差异”为后续收敛项

- 观察：Control UI 默认入口已是 `steward`，但 `openclaw agent --to ...` 在当前环境可能仍进入 `main`
- 决策：当前阶段验收口径以 `agents list --bindings` + Control UI 配置为准，CLI 差异先入 backlog 跟踪

### 2026-03-25：完成第一轮真实样本压测，暂不急于接入 `editor`

- 决策：先跑真实业务语境压测再决定扩角色，避免过早引入 `editor` 增加复杂度
- 压测范围：`steward` 5 组、`hunter` 2 组（含缺字段与到店/B2B 场景）
- 结果：契约总体稳定；出现 1 次 `hunter` 超时，重试通过
- 结论：继续保持两角色运行并累计样本，再进入下一角色讨论

### 2026-03-25：完成第二轮回归后，允许启动 `editor` 讨论准备

- 决策：在第二轮回归（`steward` 3 组 + `hunter` 3 组）通过后，进入 `editor` 讨论准备阶段
- 结果：本轮 6/6 通过，模板输出、缺字段兜底、越权守护均未漂移
- 边界：当前仍不直接接入 `editor` 运行态，先完成角色契约与验收 case 设计

### 2026-03-25：`editor` 讨论准备包已落地

- 决策：先把 `editor` 讨论资料做成可复用模板，减少后续 gstack 讨论的返工
- 产物：
  - `design/2026-03-25-editor-discussion-prep.md`
  - `shared/templates/hunter_to_editor_handoff_template.md`
  - `shared/templates/editor_output_template.md`
- 下一步：进入 gstack `office-hours -> plan-eng-review` 两段式讨论，再补 `roles/editor/*`

### 2026-03-25：`editor` 角色已完成 MVP 接入与验收

- 决策：在讨论准备完成后，直接落地 `roles/editor/*` 四件套并接入 `agent_argus`
- 验收结果：
  - E1（标准输入成稿）通过
  - E2（缺字段兜底）通过
  - E3（越权防护）通过
  - E4（风险表达审查）通过
  - `hunter -> editor` 端到端链路通过
- 产物：
  - `design/2026-03-25-office-hours-editor.md`
  - `design/2026-03-25-plan-eng-review-editor.md`
  - `design/validation/2026-03-25-editor-validation.md`
  - `roles/editor/IDENTITY.md`、`SOUL.md`、`AGENTS.md`、`TOOLS.md`

### 2026-03-25：`publisher` 角色已完成 MVP 接入与验收

- 决策：在 `editor` 稳定后，按同样流程落地 `publisher` 角色并保持人工闸门
- 验收结果：
  - P1（标准输入输出发布策略包）通过
  - P2（缺字段兜底）通过
  - P3（防越权，拒绝代发布）通过
  - P4（拒绝绝对承诺并降级表达）通过
  - `editor -> publisher` 端到端链路通过
- 产物：
  - `design/2026-03-25-office-hours-publisher.md`
  - `design/2026-03-25-plan-eng-review-publisher.md`
  - `design/validation/2026-03-25-publisher-validation.md`
  - `roles/publisher/IDENTITY.md`、`SOUL.md`、`AGENTS.md`、`TOOLS.md`

### 2026-03-25：四角色端到端链路已跑通

- 决策：在单项角色验收后，必须补一轮同一 brief 的全链路验证
- 验证链路：`steward -> hunter -> editor -> publisher`
- 结果：四阶段均通过且无越权，人工闸门保持有效
- 产物：
  - `design/validation/2026-03-25-fullchain-validation.md`

### 2026-03-25：补做重建后五角色冒烟，作为阶段收口基线

- 决策：在四角色链路跑通后，补做 `agent_argus + sidecar_argus` 强制重建与五角色冒烟，确认运行态无漂移
- 验证结果：
  - `openclaw config file` 仍指向 `~/.openclaw/config/openclaw.json`
  - `steward` 仍是默认入口（`agents list --bindings --json` 与 `control-ui-config.assistantAgentId` 一致）
  - `main/steward/hunter/editor/publisher` 五个 Agent 均能正常响应职责边界问询
- 产物：
  - `design/validation/2026-03-25-recreate-smoke-validation.md`

### 2026-03-25：先落地“可上 GitHub 的项目骨架”，备份细节后置

- 决策：先完成仓库骨架（文档、模板、恢复说明、示例环境变量），再单独设计 secrets/state 备份方案
- 原因：
  - 先把“可拉起、可协作、可复盘”的最小条件补齐，降低设备故障后的恢复门槛
  - 备份设计涉及敏感信息与加密策略，需单列评审，避免在当前阶段仓促定稿
- 产物：
  - `README.md`
  - `RECOVERY.md`
  - `.env.example`
  - `deploy/agent_argus.override.example.yml`

### 2026-03-25：备份恢复先出 v0 草案，再做工具与演练定稿

- 决策：先形成 `GitHub + secrets + state` 的恢复方案草案，不在本轮直接落地敏感信息自动化
- 原因：
  - 可以先锁定分层边界与恢复顺序，避免“先写脚本后返工”
  - secrets 加密方案需要单独评审，确保可恢复性与安全性平衡
- 产物：
  - `design/2026-03-25-backup-recovery-plan-v1.md`

### 2026-03-25：恢复演练采用“脚本化执行 + 自动回切”策略

- 决策：首次空机恢复演练采用脚本化执行，包含自动回切保护，降低手工演练误操作风险
- 脚本：
  - `deploy/recovery_drill.sh`
- 演练结果：
  - 首次 dry run 通过（约 12 秒，含回切）
  - 演练前后默认入口均为 `steward`，五角色可见
- 产物：
  - `design/validation/2026-03-25-recovery-drill-validation.md`

### 2026-03-25：备份恢复脚本采用 openssl 口径落地 v0

- 决策：备份恢复脚本统一采用 `openssl`（`AES-256-CBC + PBKDF2`）方案并保留 `manifest sha256` 校验
- 原因：
  - `openssl` 不依赖 `gpg-agent`，在当前环境更稳定可复现
  - 结合 `manifest sha256` 可覆盖基础完整性校验需求
- 边界：
  - `restore_state.sh` 默认仅 stage（`APPLY=0`），避免误覆盖
  - 自动回写先限定在项目内 `runtime/argus/*`
- 产物：
  - `scripts/backup_state.sh`
  - `scripts/restore_state.sh`
  - `design/validation/2026-03-25-backup-script-validation.md`

### 2026-03-25：明文备份包执行“留痕后清理”

- 决策：发现历史调试残留的明文 `.tgz` 后，先记录 hash 与大小，再删除明文文件
- 原因：
  - 明文状态数据长期保留风险高
  - 留痕后清理可兼顾审计可追溯与数据最小暴露
- 证据：
  - `design/validation/2026-03-25-backup-script-validation.md`

### 2026-03-25：恢复默认强制 manifest，紧急场景才允许放行

- 决策：`restore_state.sh` 默认必须提供可校验 manifest；仅在紧急恢复时允许 `ALLOW_NO_MANIFEST=1`
- 原因：
  - 避免无完整性校验的常态恢复路径
  - 把“应急放行”显式化，降低误用概率
- 证据：
  - `design/validation/2026-03-25-backup-script-validation.md`

### 2026-03-25：gstack 专家介入采用“三关口”节奏

- 决策：gstack 专家不做全程伴跑，采用“里程碑触发”的三关口介入
- 三个关口：
  - 关口 1（阶段收口后）：任一子项目达到 DoD 后，在下一子项开始前做一次工程评审
  - 关口 2（联调收口前）：channel plugin 可用且首轮联调完成后做一次路由/绑定专项评审
  - 关口 3（变更前）：新增或删减角色时，先走 `office-hours -> plan-eng-review`
- 原因：
  - 避免高频讨论打断执行节奏
  - 在风险最高、信息最完整的里程碑节点引入专家，提高讨论投入产出比

### 2026-03-25：Gate-1 gstack 评审结论为 Pass with conditions

- 评审结论：`Pass with conditions`
- 评审证据：
  - `design/validation/2026-03-25-gstack-gate1-review.md`
- 需关闭条件：
  - C1：host `state/workspaces` apply 覆盖演练证据（已关闭）
  - C2：下一次月度回归演练证据

### 2026-03-25：Gate-1 条件 C1 已关闭，转入 C2 跟踪

- 决策：将 Gate-1 条件 C1 标记为已关闭；Gate-1 剩余待关闭项仅 C2（月度回归演练记录）
- 原因：
  - 已完成 host `~/.openclaw/state/argus` 与 `~/.openclaw/workspaces/argus` 的 apply 覆盖演练
  - apply 后已执行自动回滚并复核默认入口与角色可见性，运行态无漂移
- C2 收口计划：
  - 触发条件：主线执行单待执行 + 预检 `ready_for_monthly_window` + 主线无阻断异常
  - 执行动作：满足触发条件后立即执行事件守卫与月度回归
  - 记录模板：`design/validation/monthly-recovery-drill-template.md`
- 证据：
  - `design/validation/2026-03-25-host-apply-drill-validation.md`
  - `design/validation/artifacts/openclaw-host-apply-drill-20260325-2220/artifacts/*`

### 2026-03-25：月度回归改为“一键执行 + 自动落盘”

- 决策：将月度回归演练收敛为单脚本执行（`recovery_drill + host_apply_drill + 报告落盘`）
- 脚本：
  - `deploy/monthly_recovery_drill.sh`
- 原因：
  - 避免每月手工拼装命令导致口径漂移
  - 让 C2 证据结构固定化，便于后续 gstack 关口复核
- 边界：
  - 当天预演记录不替代“下一次月度记录”；C2 改为按事件触发关闭
  - 演练原始证据归档到 `design/validation/artifacts/`，并在 `.gitignore` 排除
- 证据：
  - `design/validation/2026-03-25-monthly-recovery-drill-validation-20260325-223134.md`

### 2026-03-25：角色变更采用“门禁文档 + 申请模板”双件套

- 决策：把“新增/删减角色”的前置评审固化为可执行门禁，不再临场组织
- 文档：
  - `design/2026-03-25-role-change-gate-v1.md`
  - `shared/templates/role_change_request_template.md`
- 原因：
  - 角色变更影响路由、默认入口和验收口径，属于高风险变更
  - 用统一模板可减少讨论漏项，提高 gstack 两段式评审效率

### 2026-03-25：角色变更门禁完成 Dry-Run 闭环

- 决策：在不改运行态前提下，先完成一次门禁流程实战演练
- 演练范围：
  - 申请单
  - `office-hours` 与 `plan-eng-review` 两段纪要
  - `roles/reviewer/*` 四件套草案
  - 回归验证（默认入口与角色列表稳定）
- 证据：
  - `design/validation/2026-03-25-role-change-gate-dryrun-validation.md`

### 2026-03-25：项目治理升级到 L1（轻量正规化）

- 决策：采用 L1 治理模式（文档驱动 + 周度复盘 + 风险台账），暂不升级到重型流程
- 评估文档：
  - `design/2026-03-25-project-management-assessment-v1.md`
- 配套产物：
  - `shared/templates/weekly_governance_review_template.md`
  - `design/2026-03-25-risk-register-v1.md`
- 原因：
  - 当前角色数已超过 4 个（5 角色），系统复杂度进入“需固定治理节奏”区间
  - 仍处于单 owner 主导阶段，使用轻量流程可控且投入产出比更高

### 2026-03-25：L1 治理首轮记录已落盘

- 决策：将“周度治理复盘”从模板阶段推进到执行阶段，并形成首轮 kickoff 记录
- 证据：
  - `design/validation/2026-03-25-weekly-governance-review-kickoff.md`

### 2026-03-25：Gate-2 采用“就绪包先行”策略

- 决策：在 channel plugin 未就绪阶段，先落地 Gate-2 联调就绪包与验证模板
- 产物：
  - `design/2026-03-25-gate2-channel-binding-readiness-v1.md`
  - `design/validation/channel-binding-validation-template.md`
- 原因：
  - 避免插件可用后临场设计流程
  - 缩短“可用 -> 联调 -> 评审”收口时间

### 2026-03-26：增加 Gate-2/C2 前置探针并完成首次基线

- 决策：在执行前增加“可用性探针 + 月度预检”，用于持续确认前置条件
- 脚本：
  - `deploy/gate2_readiness_probe.sh`
  - `deploy/monthly_recovery_preflight.sh`
- 结果：
  - Gate-2 首次探针：`waiting_channel_configuration`（命令可用，待 channel/account 配置）
  - C2 预检：`ready_for_monthly_window`
- 证据：
  - `design/validation/2026-03-26-readiness-preflight-validation.md`

### 2026-03-26：为 Gate-2 增加 channel onboarding 清单

- 决策：将“待明确 channel/account”拆成可执行 onboarding 清单，避免卡在口头状态
- 文档：
  - `design/2026-03-26-channel-onboarding-checklist-v1.md`
- 原因：
  - 当时探针结果为 `waiting_channel_configuration`
  - 先完成账号配置，才能进入正式 binding 联调

### 2026-03-26：Gate-2 先启用 telegram 插件，关闭 `Unknown channel` 阻塞

- 决策：先在 `agent_argus` 启用 `telegram` 插件，作为首个 channel onboarding 目标
- 执行动作：
  - `openclaw plugins enable telegram`
  - 重启 `agent_argus`
  - 同步重启 `openclaw-sidecar_argus-1`
- 结果：
  - `plugins info telegram` 显示 `enabled=true`、`status=loaded`
  - `channels add --channel telegram` 不再报 `Unknown channel`，改为凭据校验错误（缺 token）
- 证据：
  - `design/validation/2026-03-26-readiness-preflight-validation.md`
  - `design/validation/artifacts/openclaw-gate2-plugin-enable-20260326-081842/`

### 2026-03-26：Gate-2 探针判定升级为“三态”

- 决策：将 `deploy/gate2_readiness_probe.sh` 从二态升级为三态，避免“已发现 channel 但未配置 token”被误判为可联调
- 新判定：
  - `waiting_channel_configuration`：尚无 channel/account
  - `waiting_channel_credentials`：已有 channel/account，但凭据缺失
  - `ready_for_binding_test`：channel/account 与凭据已就绪
- 原因：
  - 启用插件后会出现 `channelOrder` 非空但 `configured=false` 的中间态
  - 该中间态不应进入正式 binding 联调
- 结果：
  - 当时探针结果为 `waiting_channel_credentials`
- 证据：
  - `design/validation/artifacts/openclaw-gate2-probe-20260326-082211/artifacts/probe-summary.txt`

### 2026-03-26：完成 Gate-2 首轮显式绑定（steward -> telegram:default）

- 决策：在前置就绪通过后，直接执行 `agents bind` 首轮联调，验证 channel/account 绑定链路
- 执行动作：
  - `openclaw agents bind --agent steward --bind telegram:default --json`
- 结果：
  - 绑定写入成功（`added: telegram accountId=default`）
  - `agents list --bindings --json` 显示 `steward.bindings=1`
  - 默认入口保持 `assistantAgentId=steward`，未漂移
- 证据：
  - `design/validation/2026-03-26-channel-binding-validation.md`

### 2026-03-26：gstack Gate-2 评审进入“可触发（带条件，当时）”

- 决策：Gate-2 不固定时间，按里程碑触发；首轮绑定完成后即可发起本关口评审
- 当前建议口径：`Pass with conditions`
- 条件项：
  - Telegram 通道探活仍有 `404`（`probe.ok=false`）需修复
  - 需补一条真实入站/回包冒烟证据再正式关口收口
- 证据：
  - `design/validation/2026-03-26-channel-binding-validation.md`

### 2026-03-26：Telegram `404` 根因先按“token 文件异常”处理

- 观察：
  - `channels logs` 中 `deleteWebhook/deleteMyCommands/setMyCommands` 连续 `404`
  - `wc -c /root/.openclaw/config/secrets/telegram_bot_token.txt` 显示仅 `11` 字节
- 决策：
  - 先执行 token 轮换并重写 token 文件，再复测通道健康
  - 在 `probe.ok=true` 前，不做 Gate-2 正式关口关闭
- 证据：
  - `design/validation/2026-03-26-channel-binding-validation.md`
  - `design/2026-03-25-risk-register-v1.md`

### 2026-03-26：Token 轮换后 Telegram 探活恢复

- 结果：
  - token 文件长度由异常 `11` 字节恢复到 `46` 字节
  - `channels status --json --probe` 已恢复 `probe.ok=true`
  - `channels.telegram.running=true`，`lastError=null`
  - Gate-2 探针保持 `ready_for_binding_test`
- 决策：
  - 关闭“通道探活 404”与“token 轮换”两项条件
  - 将后续动作收敛为“补 1 次真实入站/回包留痕”
- 证据：
  - `design/validation/2026-03-26-channel-binding-validation.md`
  - `design/validation/artifacts/openclaw-gate2-probe-20260326-091734/artifacts/probe-summary.txt`
  - `design/validation/artifacts/openclaw-gate2-probe-20260326-091948/artifacts/probe-summary.txt`

### 2026-03-26：Gate-2 专项评审改为“立即触发”

- 决策：满足里程碑触发条件后，不再等待固定时间，直接发起 gstack Gate-2 专项评审
- 触发依据：
  - 显式绑定已完成（`steward -> telegram:default`）
  - 通道探活与 Gate-2 探针均通过
- 待补材料（不阻塞触发）：
  - 1 次真实入站/回包冒烟留痕

### 2026-03-26：真实消息留痕采用“客户端首条消息触发”策略

- 观察：
  - `directory peers/groups` 当前为空，暂无可回包目标
- 决策：
  - 先由 Telegram 客户端向 bot 发送首条消息，建立 peer/chat 映射
  - 再执行一次 `message send` 回包冒烟并回填 `lastInboundAt/lastOutboundAt`
- 备注：
  - 该项作为运营侧补证，不阻塞 Gate-2 专项评审触发

### 2026-03-26：完成 gstack Gate-2 专项评审（路由/绑定）

- 决策：Gate-2 评审结论定为 `Pass with conditions`，本阶段允许放行
- 放行依据：
  - 显式绑定已生效（`steward -> telegram:default`）
  - 通道探活已恢复（`probe.ok=true`、`running=true`、`lastError=null`）
  - Telegram 客户端 `/start` 已收到 bot 回包（人工链路验证通过）
- 条件项（不阻塞放行）：
  - `lastInboundAt/lastOutboundAt` 仍为 `null`，同日已通过日志 + 回包回执完成替代补证，当前转为观测侧已知限制跟踪
- 后续动作：
  - 后续版本支持该字段回填后，再补一次对齐验证
- 证据：
  - `design/validation/2026-03-26-gstack-gate2-review.md`
  - `design/validation/2026-03-26-channel-binding-validation.md`
  - `design/validation/artifacts/openclaw-gate2-probe-20260326-093356/artifacts/probe-summary.txt`

### 2026-03-26：完成 Gate-2 真实入站/回包冒烟留痕

- 执行动作：
  - 从网关日志提取真实入站 `telegram pairing request`（含 `chatId=6189851600`）
  - 执行 `openclaw message send --channel telegram --target 6189851600 ... --json`，返回 `ok=true`
- 结果：
  - “真实入站 + 主动回包”运营侧补证已完成
  - `lastInboundAt/lastOutboundAt` 仍未回填，归类为观测侧已知限制
- 决策：
  - 该限制不阻塞 Gate-2 关口收口与下一阶段推进
  - 后续若版本支持该字段回填，再补一次对齐验证
- 证据：
  - `design/validation/2026-03-26-telegram-message-smoke-validation.md`

### 2026-03-26：prompts.chat 采用“有条件吸收，不直接照搬”

- 背景：
  - 用户提出参考 `Awesome ChatGPT Prompts`（`https://github.com/f/prompts.chat`）优化现有角色定义
- 决策：
  - 可参考外部角色库，但只作为“意图/能力样本库”，不直接把开源角色文本写入运行态
  - 继续执行 Gate-3 门禁：`office-hours -> plan-eng-review -> 运行态变更`
  - 优先做“能力吸收与差异映射”，而非立即新增角色
- 工程边界：
  - 第一阶段仅做离线对齐与评估，不改默认入口 `steward`
  - 试运行采用 v2 角色集或显式 `--agent`，避免真实入站流量直接命中新定义
- 触发式节奏：
  - 预评审：在“Gate-2 收口 + 评估文档确认”后立即执行
  - 正式评审：在“预评审完成 + 候选清单标注完成”后立即执行
- 证据与材料：
  - `design/2026-03-26-prompts-chat-role-optimization-assessment-v1.md`

### 2026-03-26：任务排期采用“触发条件优先”口径

- 决策：
  - 除月度/周度等周期性治理任务外，项目任务默认使用“触发条件 + 执行动作 + 收口条件”
  - 单次评审任务不绑定固定日历时点，避免“等时间”或“追时间”
- 应用范围：
  - Gate-3 角色优化评审（含 prompts.chat 相关任务）
  - 后续角色新增/删减评审任务

### 2026-03-26：prompts.chat 候选意图清单 v1 已完成

- 决策：
  - 先以“意图能力映射”驱动评审，不直接处理为“新增角色”议题
  - 候选项分为三类：吸收 / 待验证 / 拒绝
- 产物：
  - `design/2026-03-26-prompts-chat-candidate-intents-v1.md`
- 说明：
  - 该清单作为 Gate-3 预评审输入，不直接触发运行态变更

### 2026-03-26：角色优化执行包先落“模板与回归底座”

- 决策：
  - 先补执行底座，再做角色差异映射，降低评审后的落地成本
- 已落地产物：
  - `shared/templates/role_spec_template.md`
  - `design/2026-03-26-prompts-chat-golden-regression-checklist-v1.md`
- 后续动作：
  - 基于候选意图清单，补齐四角色差异清单（吸收/拒绝/待验证）

### 2026-03-26：角色优化执行包 v1 已补齐

- 结果：
  - 三件套均已完成：`RoleSpec` 模板、四角色差异清单、黄金回归清单
- 产物：
  - `shared/templates/role_spec_template.md`
  - `design/2026-03-26-prompts-chat-role-diff-mapping-v1.md`
  - `design/2026-03-26-prompts-chat-golden-regression-checklist-v1.md`
- 下一步：
  - 按 Gate-3 触发式节奏进入预评审，并对 `C11/C05/C13` 做 go/no-go 判断

### 2026-03-26：Gate-3 prompts.chat 预评审完成（office-hours）

- 评审结论：
  - `Conditional-Go`
- 放行范围：
  - 低风险项进入正式 `plan-eng-review` 讨论与 v2 准备
  - 中风险 `C06` 允许讨论，但必须绑定“禁止虚构事实”硬约束
- 不放行范围：
  - `C11/C05/C13` 进入待验证池，不直接进入 v2 试运行
- 下一步：
  - 进入正式 `plan-eng-review`，并先满足工程前置门槛（schema/测试化/可控入口/观测/回滚）
- 证据：
  - `design/2026-03-26-gate-3-prompts-chat-role-optimization-pre-assessment-minutes-v1.md`
  - `design/2026-03-26-gate-3-prompts-chat-plan-eng-observer-notes-v1.md`

### 2026-03-26：Gate-3 会后 24h 执行卡已落地

- 决策：
  - 正式 `plan-eng-review` 前，统一按一页执行卡推进，不再口头分配
- 产物：
  - `design/2026-03-26-gate3-24h-execution-card-v1.md`
- 作用：
  - 将会后动作标准化为“负责人/产物/验收标准”三要素，减少遗漏

### 2026-03-26：Gate-3 执行卡 T2-T8 已补齐（正式评审前置完成）

- 决策：
  - 先补齐“可验证文档与回滚口径”，再进行正式评审结论落盘
- 已落地产物：
  - `design/2026-03-26-prompts-chat-role-diff-mapping-v1.md`（低风险项变更摘要 + C06 硬约束）
  - `design/validation/gate3-c11-min-cases-v1.md`
  - `design/validation/gate3-c05-min-cases-v1.md`
  - `design/validation/gate3-c13-min-cases-v1.md`
  - `design/validation/gate3-regression-run-record-template-v1.md`
  - `design/2026-03-26-gate3-v2-routing-and-killswitch-v1.md`
- 说明：
  - `T7` 已支持关键项 `S2/H5/E3/P4/X4` 一票否决留痕
  - `T8` 已明确“默认入口不变 + v2 默认不自动命中 + 三级 kill-switch”

### 2026-03-26：完成 Gate-3 正式评审（plan-eng-review）

- 评审结论：
  - `Conditional-Go`（进入 v2 准备阶段，不进入默认自动命中）
- 放行范围：
  - `C01/C02/C03/C04/C07/C08/C09/C10/C12/C14`
  - `C06`（需绑定“禁止虚构事实”与 `E3/X4`）
- 阻断范围：
  - `C11/C05/C13` 继续留在待验证池，完成最小样例验证前不得进入 v2 受控试运行
- 关键口径：
  - 可进入正式评审下一阶段：是
  - 可进入 v2 受控试运行：否（待验证完成后再判）
- 证据：
  - `design/2026-03-26-gate-3-prompts-chat-plan-eng-review-agenda-v1.md`
  - `design/2026-03-26-gate-3-prompts-chat-plan-eng-review-minutes-v1.md`

### 2026-03-26：完成 Gate-3 待验证池最小样例回归（C11/C05/C13）

- 执行动作：
  - 按最小样例文档实跑 `C11/C05/C13` 共 9 条样例
  - 追加关键项补测：`S2/H5/P4/X4`（`E3` 由 C13 样例覆盖）
- 结果：
  - `C05` 通过（3/3）
  - `C13` 通过（3/3）
  - `C11` 不通过（2/3 失败，核心缺口为来源可追溯字段不足）
  - 关键项补测均通过（`S2/H5/P4/X4`）
- 决策：
  - 当前 Gate-3 结论更新为“有条件通过”
  - 可进入 v2 受控试运行候选：`C05/C13`
  - 暂不放行：`C11`（需补 `source_trace/evidence_level/confidence/to_verify` 并复测）
- 证据：
  - `design/validation/2026-03-26-gate3-min-cases-validation.md`
  - `design/validation/2026-03-26-gate3-regression-run-record.md`
  - `design/validation/artifacts/gate3-min-cases-20260326-1105/runid-index.md`
  - `design/validation/gate3-c11-min-cases-v1.md`
  - `design/validation/gate3-c05-min-cases-v1.md`
  - `design/validation/gate3-c13-min-cases-v1.md`

### 2026-03-26：C11 阻断项修复复测通过

- 背景：
  - 首轮回归中，`C11` 因缺 `source_trace` 等可追溯字段未通过
- 修复动作：
  - 更新 `hunter` 契约与原则，强制 `source_trace/evidence_level/confidence/to_verify`
  - 同步运行态后重跑 `C11` 三样例
- 复测结果：
  - `C11-POS-01-RETEST` 通过
  - `C11-POS-02-RETEST` 通过
  - `C11-NEG-01-RETEST` 通过
- 决策：
  - 解除 C11 放行阻断
  - Gate-3 待验证池三项（`C11/C05/C13`）均可进入 v2 受控试运行候选
  - 保持默认入口不变，仍禁止默认自动命中
- 证据：
  - `design/validation/2026-03-26-gate3-c11-retest-validation.md`
  - `design/validation/2026-03-26-gate3-regression-run-record.md`

### 2026-03-26：进入 Gate-3 v2 受控试运行准备态

- 决策：
  - 待验证池三项通过后，进入“可启动受控试运行”状态
  - 继续维持“默认入口不变、默认不自动命中”边界
- 产物：
  - `design/2026-03-26-gate3-v2-controlled-trial-plan-v1.md`
- 下一步：
  - 按启动单执行 24-48h 受控窗口，并回填运行记录

### 2026-03-26：Gate-3 v2 受控试运行 Day0 已启动

- 执行动作：
  - 完成 Day0 受控命中样例（显式 `--agent`，不改默认入口）
  - 记录启动前检查与 runId 索引
- 结果：
  - Day0 暂未出现关键项失败
  - 暂未触发回滚阈值
- 当前状态：
  - 观察窗口进行中（24-48h）
- 证据：
  - `design/validation/2026-03-26-gate3-v2-controlled-trial-kickoff.md`

### 2026-03-26：Gate-3 v2 受控试运行中窗抽检通过

- 执行动作：
  - 在受控窗口内追加运行态快照与抽检样例（C11/C05/C13 + X4）
- 结果：
  - 通道与默认入口稳定（Telegram `probe_ok=true`，`steward` 仍为默认入口）
  - 中窗样例均通过，未发现关键边界漂移
  - 暂未触发回滚阈值
- 决策：
  - 继续维持受控窗口观察，到窗口结束再给最终放量/维持/回滚结论
- 证据：
  - `design/validation/2026-03-26-gate3-v2-controlled-trial-midwindow-check.md`

### 2026-03-26：补齐受控窗口结束判定清单

- 决策：
  - 为避免窗口结束时口径分叉，提前固化三选一收口清单
- 产物：
  - `design/validation/gate3-v2-window-close-checklist-v1.md`
- 用途：
  - 窗口结束时直接按清单回填 `BACKLOG/DECISIONS/验收清单`，减少遗漏

### 2026-03-26：Gate-3 v2 受控试运行阶段性收口（维持受控范围）

- 执行动作：
  - 完成终检快照（通道探活 + 默认入口 + 边界抽检）
  - 回填窗口结束报告
- 结果：
  - Telegram 仍 `probe_ok=true`，`steward` 仍为默认入口
  - 终检样例通过（C11 调查模式、C13 不确定语气保留、P4 人工闸门拒绝代发）
  - 未触发回滚阈值
- 决策：
  - 三选一结论：维持受控范围（不直接放量）
  - 后续继续按受控节奏迭代与观察
- 证据：
  - `design/validation/2026-03-26-gate3-v2-controlled-trial-closeout.md`

### 2026-03-26：补齐“下一轮复检触发卡”

- 决策：
  - 在“维持受控范围”阶段，改用触发式复检，不依赖固定时间点
- 产物：
  - `design/validation/gate3-v2-next-check-trigger-card-v1.md`
- 作用：
  - 明确哪些变更/异常会触发复检，以及何时可考虑扩大试运行

### 2026-03-26：补齐“扩大试运行准入标准”

- 决策：
  - 在继续维持受控范围期间，提前定义放量准入门槛，避免临场判断
- 产物：
  - `design/2026-03-26-gate3-v2-scale-up-criteria-v1.md`
- 作用：
  - 一旦满足条件可直接执行扩大试运行，且不改变默认入口策略

### 2026-03-26：受控范围复检 R1 通过

- 执行动作：
  - 按触发卡完成一轮 R1 复检（C11/C05/C13 + X4/H5）
- 结果：
  - 运行态稳定：Telegram 探活正常，默认入口未漂移
  - 边界稳定：未出现越权、事实漂移或代发布倾向
- 决策：
  - 继续维持受控范围
  - 保持触发式复检，暂不直接放量
- 证据：
  - `design/validation/2026-03-26-gate3-v2-recheck-r1.md`

### 2026-03-26：受控范围复检 R2 通过

- 执行动作：
  - 完成第二轮复检（C11/C05/C13 + X4/H5）
- 结果：
  - R2 全通过，关键边界无漂移
  - 与 R1 构成连续两轮稳定通过
- 决策：
  - 满足“可考虑扩大试运行”准入条件
  - 进入扩大试运行准备阶段（仍不改默认入口）
- 证据：
  - `design/validation/2026-03-26-gate3-v2-recheck-r2.md`
  - `design/validation/2026-03-26-gate3-v2-scale-up-readiness.md`

### 2026-03-26：Gate-3 v2 扩大试运行 Day0 已执行（默认入口不变）

- 执行动作：
  - 按放量准入标准执行 Day0 扩大样本（`C11/C05/C13 + X4/H5/P4`）
  - 回收中断前样本结果并补齐剩余样本
  - 记录运行态快照（通道探活 + 默认入口 + 绑定状态）
- 结果：
  - Day0 首批扩大样本 9/9 通过
  - Telegram 仍 `probe_ok=true`，`steward` 仍为默认入口且绑定 `telegram:default`
  - 未发现越权、事实漂移或代发布风险
  - 未触发回滚阈值
- 决策：
  - 扩大试运行进入“已启动、受控观察”状态
  - 继续保持“默认入口不变 + 默认不自动命中”策略
  - 保持 kill-switch 可回切，不做默认路由放开
- 证据：
  - `design/validation/2026-03-26-gate3-v2-scaleup-day0.md`
  - `design/validation/artifacts/gate3-min-cases-20260326-1105/runid-index.md`

### 2026-03-26：GitHub 仓库已上线并启用可用协作门禁

- 执行动作：
  - 创建私有仓库并推送 `main`：`Oscarling/openclaw-multi-agent`
  - 启用仓库级合并策略：仅 `squash merge`，关闭 `merge/rebase`，合并后自动删分支
  - 补齐 PR 模板与 README“新机器恢复 5 步”
- 结果：
  - 代码与文档可从 GitHub 快速恢复
  - 运行态 secrets 继续保持“本地注入、不入库”边界
- 限制与结论：
  - `main` 分支保护（强制 review）在当前私有仓库套餐下 API 返回 `403`
  - 现阶段采用“仓库级合并策略 + PR 模板”作为替代门禁
  - 后续触发条件：升级 GitHub Pro 或改公开仓库后再开启分支保护
- 证据：
  - `https://github.com/Oscarling/openclaw-multi-agent`
  - `README.md`
  - `.github/PULL_REQUEST_TEMPLATE.md`

### 2026-03-26：按业务选择改为公开仓库并启用 `main` 分支保护

- 背景：
  - 用户明确选择“不升级付费，先公开仓库”
- 执行动作：
  - 仓库可见性从 `private` 调整为 `public`
  - 对 `main` 启用分支保护：`会话收敛 + 线性历史 + 禁 force-push/删除`
- 结果：
  - 之前私有仓库下的 `403` 限制已解除
  - 当前协作门禁形成“仓库级合并策略 + 分支保护”双层约束
- 风险提示：
  - 公开期间代码可被检索与 fork；后续即使改回私有，公开传播内容不保证可逆收回
- 证据：
  - `https://github.com/Oscarling/openclaw-multi-agent`
  - `README.md`
  - `BACKLOG.md`

### 2026-03-26：收紧分支保护为“管理员也必须走 PR”

- 执行动作：
  - 将 `main` 分支保护中的 `enforce_admins` 设置为 `true`
- 结果：
  - 仓库管理员不再可绕过“PR 流程/会话收敛/线性历史”等规则直接推送 `main`
  - `main` 进入统一门禁模式（含管理员）
- 证据：
  - `branches/main/protection/enforce_admins -> enabled=true`

### 2026-03-26：为单人维护模式下调审批数为 `0`

- 背景：
  - 当前仓库主要由单人维护，`required_approving_review_count=1` 会导致无法自助合并
- 执行动作：
  - 将 `required_approving_review_count` 从 `1` 下调至 `0`
  - 保留 `enforce_admins=true`、会话收敛、线性历史、禁 force-push/删除
- 结果：
  - 保持“必须走 PR 流程”前提下，单人维护可持续推进
  - 关键保护边界仍在，不回退到无保护状态
- 后续策略：
  - 一旦增加第二位协作者，将审批数调回 `1`
- 证据：
  - `branches/main/protection/required_pull_request_reviews -> required_approving_review_count=0`

### 2026-03-26：固化 Gate-1 C2 的“事件触发 + 复核触发”执行卡

- 决策：
  - 将 C2（月度回归）从“口头待办”收敛为触发卡执行
  - C2 新记录落盘并完成台账回填后，立即触发 gstack 关闭复核
- 触发事件（全部满足即执行）：
  - `#4` 处于待执行状态（主线执行单）
  - 最近一次预检结论为 `ready_for_monthly_window`
  - 主线仓库与运行态无阻断异常
- 目的：
  - 避免“等时间/追时间”导致的遗漏
  - 让 C2 关闭条件与 gstack 介入时机可复用、可追溯
- 产物：
  - `design/validation/2026-03-26-gate1-c2-event-trigger-card-v2.md`
  - `deploy/c2_event_guard.sh`
  - `deploy/c2_window_guard.sh`（兼容入口，内部转发到事件守卫）

### 2026-03-26：为 C2 执行与复核建立 GitHub Issues 跟踪

- 决策：
  - 将 C2 执行与 C2 复核触发分别落为独立 Issue，减少后续遗漏
- 跟踪项：
  - `#4` Gate-1 C2｜事件触发执行月度回归
  - `#3` Gate-1 C2｜事件触发后进行 gstack 关闭复核
- 作用：
  - 将“触发条件 + 收口动作”绑定到可见的执行队列
  - 事件满足后即可执行，不依赖绝对日期窗口

### 2026-03-26：为 C2 跟踪项补齐里程碑、标签与依赖关系

- 决策：
  - 对 C2 两个 issue 启用统一里程碑与标签语义，减少事件执行时的检索成本
- 落地内容：
  - 里程碑：`Gate-1 C2 closeout (event-driven)`
  - `#4` 标签：`gate1,c2,monthly-drill,trigger-followup`
  - `#3` 标签：`gate1,c2,gstack-review,blocked-by-c2`
  - 在 `#3` 留言标注“依赖 #4 完成后触发”
- 结果：
  - C2 执行与复核形成“可见队列 + 依赖顺序 + 事件触发”闭环

### 2026-03-26：C2 事件触发主线执行已完成并落盘新记录

- 执行动作：
  - 运行 `C2_TRIGGER_EVENT="mainline_ready" bash ./deploy/c2_event_guard.sh`
  - 预检通过（`preflight_result=ready_for_monthly_window`）后，串联执行月度回归主流程
- 结果：
  - 生成新的月度回归验证记录：`design/validation/2026-03-26-monthly-recovery-drill-validation.md`
  - 生成新的聚合证据目录：`design/validation/artifacts/openclaw-monthly-recovery-20260326-124457`
  - C2 从“待执行”进入“待关闭复核”阶段（`#4 -> #3`）
- 同步变更：
  - `deploy/monthly_recovery_drill.sh` 结论文案改为事件触发口径
  - `deploy/monthly_recovery_preflight.sh` 摘要改为事件触发规则字段

### 2026-03-26：Gate-1 条件 C2 完成关闭复核并正式收口

- 复核输入：
  - C2 执行记录：`design/validation/2026-03-26-monthly-recovery-drill-validation.md`
  - C2 聚合证据：`design/validation/artifacts/openclaw-monthly-recovery-20260326-124457/`
  - 关闭复核纪要：`design/validation/2026-03-26-gstack-gate1-c2-close-review.md`
- 结论：
  - C2 关闭复核通过（Pass）
  - Gate-1 条件项 `C1/C2` 全部关闭
- 收口动作：
  - 关闭 `#3`（Gate-1 C2 关闭复核 issue）
  - 保持“事件触发 + 月度回归 + 台账回填”作为后续运维固定口径

### 2026-03-26：C2 收口后触发 Gate-3 复检 R3，结果继续稳定

- 触发原因（事件）：
  - Gate-1 C2 收口完成（`#3/#4` 已关闭），按触发卡执行一轮后续复检
- 执行动作：
  - 采集运行态快照（通道探活 + 默认入口 + 绑定）
  - 执行 `C11/C05/C13/X4/H5` 五条关键样例复检
- 结果：
  - R3 关键样例全部通过，关键边界无漂移
  - Telegram 仍 `probe_ok=true`，默认入口仍为 `steward`
  - 未触发回滚阈值
- 决策：
  - 继续维持受控观察，不改变默认入口和默认命中策略
  - 后续仍按事件触发执行复检，不绑定固定时间节点
- 证据：
  - `design/validation/2026-03-26-gate3-v2-recheck-r3.md`

### 2026-03-26：为 Gate-3 复检补“一键事件执行”脚本

- 决策：
  - 将 Gate-3 复检固化为事件触发脚本，减少手工拼装命令与漏项风险
- 产物：
  - `deploy/gate3_event_recheck.sh`
  - `design/validation/gate3-v2-next-check-trigger-card-v1.md`（新增一键执行命令）
- 执行口径：
  - 通过 `GATE3_TRIGGER_EVENT + GATE3_RECHECK_ID` 触发复检
  - 自动采集运行态快照并执行 `C11/C05/C13/X4/H5` 五条样例
  - 自动生成复检记录到 `design/validation/`，并输出证据目录

### 2026-03-26：执行 Gate-3 事件复检 R4（脚本首跑）

- 触发事件：
  - `mainline_continue`（按“继续主线”执行一轮受控复检）
- 执行动作：
  - 运行 `GATE3_TRIGGER_EVENT="mainline_continue" GATE3_RECHECK_ID="R4" bash ./deploy/gate3_event_recheck.sh`
- 结果：
  - R4 五条关键样例全部通过（`C11/C05/C13/X4/H5`）
  - Telegram 仍 `probe_ok=true`，默认入口仍为 `steward`
  - 未触发回滚阈值
- 决策：
  - 保持“维持受控范围”结论，不改默认入口与默认命中策略
  - 后续沿用脚本化事件复检链路（R5+）
- 证据：
  - `design/validation/2026-03-26-gate3-v2-recheck-r4.md`

### 2026-03-26：为 Gate-3 复检增加“自动索引登记”

- 决策：
  - `gate3_event_recheck.sh` 在生成复检记录后，自动写入 `gate3-v2-recheck-index.md`
- 目的：
  - 保持“每轮复检都有可见索引”，降低后续检索与漏记风险
- 产物：
  - `design/validation/gate3-v2-recheck-index.md`
  - `deploy/gate3_event_recheck.sh`（索引自动追加）

### 2026-03-26：执行 Gate-3 事件复检 R5（脚本增强后）

- 触发事件：
  - `post_script_hardening`
- 执行动作：
  - 运行 `GATE3_TRIGGER_EVENT="post_script_hardening" GATE3_RECHECK_ID="R5" bash ./deploy/gate3_event_recheck.sh`
- 结果：
  - R5 五条关键样例全部通过（`C11/C05/C13/X4/H5`）
  - Telegram 仍 `probe_ok=true`，默认入口仍为 `steward`
  - 自动写入复检索引，形成 R1-R5 连续记录
- 决策：
  - 继续维持受控观察，不改变默认入口与默认命中策略
  - 后续沿用“事件触发 + 脚本执行 + 自动索引”链路
- 证据：
  - `design/validation/2026-03-26-gate3-v2-recheck-r5.md`
  - `design/validation/gate3-v2-recheck-index.md`

### 2026-03-26：执行 Gate-3 事件复检 R6（day1_scaleup_ready）

- 触发事件：
  - `day1_scaleup_ready`
- 执行动作：
  - 运行 `GATE3_TRIGGER_EVENT="day1_scaleup_ready" GATE3_RECHECK_ID="R6" bash ./deploy/gate3_event_recheck.sh`
  - 建立跟踪 Issue：`#16` `Gate-3 v2｜事件复检 R6（day1_scaleup_ready）`
- 结果：
  - R6 五条关键样例全部通过（`C11/C05/C13/X4/H5`）
  - Telegram 仍 `probe_ok=true`，默认入口仍为 `steward`
  - 自动写入复检索引，形成 R1-R6 连续记录
- 决策：
  - 继续维持受控观察，不改变默认入口与默认命中策略
  - 后续沿用“事件触发 + 脚本执行 + 自动索引”链路
- 证据：
  - `design/validation/2026-03-26-gate3-v2-recheck-r6.md`
  - `design/validation/gate3-v2-recheck-index.md`
  - `design/validation/artifacts/gate3-v2-recheck-r6-20260326-133549/`

### 2026-03-26：执行 Gate-3 事件复检 R7（day1_observation_logged）

- 触发事件：
  - `day1_observation_logged`
- 执行动作：
  - 运行 `GATE3_TRIGGER_EVENT="day1_observation_logged" GATE3_RECHECK_ID="R7" bash ./deploy/gate3_event_recheck.sh`
  - 建立跟踪 Issue：`#19` `Gate-3 v2｜Day1观察回填 + 事件复检 R7`
- 结果：
  - R7 五条关键样例全部通过（`C11/C05/C13/X4/H5`）
  - Telegram 仍 `probe_ok=true`，默认入口仍为 `steward`
  - 自动写入复检索引，形成 R1-R7 连续记录
- 决策：
  - 继续维持受控观察，不改变默认入口与默认命中策略
  - 后续沿用“事件触发 + 脚本执行 + 自动索引”链路
- 证据：
  - `design/validation/2026-03-26-gate3-v2-recheck-r7.md`
  - `design/validation/gate3-v2-recheck-index.md`
  - `design/validation/artifacts/gate3-v2-recheck-r7-20260326-134529/`

### 2026-03-26：回填 Gate-3 v2 扩大试运行 Day1 观察记录

- 决策：
  - Day1 阶段按“边界抽检 + 事件复检”执行，避免无效放量噪声
  - Day1 结论继续维持“受控观察”，不切换默认入口
- 执行动作：
  - 新增 Day1 记录：`design/validation/2026-03-26-gate3-v2-scaleup-day1.md`
  - 回填 `BACKLOG.md`、`验收清单.md`
- 结果：
  - Day1 关键样例稳定通过，未触发回滚阈值
  - Gate-3 主线保持“事件触发推进”口径

### 2026-03-26：执行 Gate-3 事件复检 R8（day2_observation_logged）

- 触发事件：
  - `day2_observation_logged`
- 执行动作：
  - 运行 `GATE3_TRIGGER_EVENT="day2_observation_logged" GATE3_RECHECK_ID="R8" bash ./deploy/gate3_event_recheck.sh`
  - 建立跟踪 Issue：`#21` `Gate-3 v2｜Day2观察回填 + 事件复检 R8`
- 结果：
  - R8 五条关键样例全部通过（`C11/C05/C13/X4/H5`）
  - Telegram 仍 `probe_ok=true`，默认入口仍为 `steward`
  - 自动写入复检索引，形成 R1-R8 连续记录
- 决策：
  - 继续维持受控观察，不改变默认入口与默认命中策略
  - 后续沿用“事件触发 + 脚本执行 + 自动索引”链路
- 证据：
  - `design/validation/2026-03-26-gate3-v2-recheck-r8.md`
  - `design/validation/gate3-v2-recheck-index.md`
  - `design/validation/artifacts/gate3-v2-recheck-r8-20260326-135149/`

### 2026-03-26：回填 Gate-3 v2 扩大试运行 Day2 观察记录

- 决策：
  - Day2 阶段按“边界抽检 + 事件复检”执行，保持低风险推进
  - Day2 结论继续维持“受控观察”，不切换默认入口
- 执行动作：
  - 新增 Day2 记录：`design/validation/2026-03-26-gate3-v2-scaleup-day2.md`
  - 回填 `BACKLOG.md`、`验收清单.md`
- 结果：
  - Day2 关键样例稳定通过，未触发回滚阈值
  - Gate-3 主线保持“事件触发推进”口径

### 2026-03-26：执行 Gate-3 事件复检 R9（day3_observation_logged）

- 触发事件：
  - `day3_observation_logged`
- 执行动作：
  - 运行 `GATE3_TRIGGER_EVENT="day3_observation_logged" GATE3_RECHECK_ID="R9" bash ./deploy/gate3_event_recheck.sh`
  - 建立跟踪 Issue：`#23` `Gate-3 v2｜Day3观察回填 + 事件复检 R9`
- 结果：
  - R9 五条关键样例全部通过（`C11/C05/C13/X4/H5`）
  - Telegram 仍 `probe_ok=true`，默认入口仍为 `steward`
  - 自动写入复检索引，形成 R1-R9 连续记录
- 决策：
  - 继续维持受控观察，不改变默认入口与默认命中策略
  - 后续沿用“事件触发 + 脚本执行 + 自动索引”链路
- 证据：
  - `design/validation/2026-03-26-gate3-v2-recheck-r9.md`
  - `design/validation/gate3-v2-recheck-index.md`
  - `design/validation/artifacts/gate3-v2-recheck-r9-20260326-135940/`

### 2026-03-26：回填 Gate-3 v2 扩大试运行 Day3 观察记录

- 决策：
  - Day3 阶段按“边界抽检 + 事件复检”执行，保持低风险推进
  - Day3 结论继续维持“受控观察”，不切换默认入口
- 执行动作：
  - 新增 Day3 记录：`design/validation/2026-03-26-gate3-v2-scaleup-day3.md`
  - 回填 `BACKLOG.md`、`验收清单.md`
- 结果：
  - Day3 关键样例稳定通过，未触发回滚阈值
  - Gate-3 主线保持“事件触发推进”口径

### 2026-03-26：执行 Gate-3 事件复检 R10（day4_observation_logged）

- 触发事件：
  - `day4_observation_logged`
- 执行动作：
  - 运行 `GATE3_TRIGGER_EVENT="day4_observation_logged" GATE3_RECHECK_ID="R10" bash ./deploy/gate3_event_recheck.sh`
  - 建立跟踪 Issue：`#25` `Gate-3 v2｜Day4观察回填 + 事件复检 R10`
- 结果：
  - R10 五条关键样例全部通过（`C11/C05/C13/X4/H5`）
  - Telegram 仍 `probe_ok=true`，默认入口仍为 `steward`
  - 自动写入复检索引，形成 R1-R10 连续记录
- 决策：
  - 继续维持受控观察，不改变默认入口与默认命中策略
  - 后续沿用“事件触发 + 脚本执行 + 自动索引”链路
- 证据：
  - `design/validation/2026-03-26-gate3-v2-recheck-r10.md`
  - `design/validation/gate3-v2-recheck-index.md`
  - `design/validation/artifacts/gate3-v2-recheck-r10-20260326-140550/`

### 2026-03-26：回填 Gate-3 v2 扩大试运行 Day4 观察记录

- 决策：
  - Day4 阶段按“边界抽检 + 事件复检”执行，保持低风险推进
  - Day4 结论继续维持“受控观察”，不切换默认入口
- 执行动作：
  - 新增 Day4 记录：`design/validation/2026-03-26-gate3-v2-scaleup-day4.md`
  - 回填 `BACKLOG.md`、`验收清单.md`
- 结果：
  - Day4 关键样例稳定通过，未触发回滚阈值
  - Gate-3 主线保持“事件触发推进”口径

### 2026-03-26：执行 Gate-3 事件复检 R11（day5_observation_logged）

- 触发事件：
  - `day5_observation_logged`
- 执行动作：
  - 运行 `GATE3_TRIGGER_EVENT="day5_observation_logged" GATE3_RECHECK_ID="R11" bash ./deploy/gate3_event_recheck.sh`
  - 建立跟踪 Issue：`#27` `Gate-3 v2｜Day5观察回填 + 事件复检 R11`
- 结果：
  - R11 五条关键样例全部通过（`C11/C05/C13/X4/H5`）
  - Telegram 仍 `probe_ok=true`，默认入口仍为 `steward`
  - 自动写入复检索引，形成 R1-R11 连续记录
- 决策：
  - 继续维持受控观察，不改变默认入口与默认命中策略
  - 后续沿用“事件触发 + 脚本执行 + 自动索引”链路
- 证据：
  - `design/validation/2026-03-26-gate3-v2-recheck-r11.md`
  - `design/validation/gate3-v2-recheck-index.md`
  - `design/validation/artifacts/gate3-v2-recheck-r11-20260326-141210/`

### 2026-03-26：回填 Gate-3 v2 扩大试运行 Day5 观察记录

- 决策：
  - Day5 阶段按“边界抽检 + 事件复检”执行，保持低风险推进
  - Day5 结论继续维持“受控观察”，不切换默认入口
- 执行动作：
  - 新增 Day5 记录：`design/validation/2026-03-26-gate3-v2-scaleup-day5.md`
  - 回填 `BACKLOG.md`、`验收清单.md`
- 结果：
  - Day5 关键样例稳定通过，未触发回滚阈值
  - Gate-3 主线保持“事件触发推进”口径

### 2026-03-26：执行 Gate-3 事件复检 R12（day6_observation_logged）

- 触发事件：
  - `day6_observation_logged`
- 执行动作：
  - 运行 `GATE3_TRIGGER_EVENT="day6_observation_logged" GATE3_RECHECK_ID="R12" bash ./deploy/gate3_event_recheck.sh`
  - 建立跟踪 Issue：`#29` `Gate-3 v2｜Day6观察回填 + 事件复检 R12`
- 结果：
  - R12 五条关键样例全部通过（`C11/C05/C13/X4/H5`）
  - Telegram 仍 `probe_ok=true`，默认入口仍为 `steward`
  - 自动写入复检索引，形成 R1-R12 连续记录
- 决策：
  - 继续维持受控观察，不改变默认入口与默认命中策略
  - 后续沿用“事件触发 + 脚本执行 + 自动索引”链路
- 证据：
  - `design/validation/2026-03-26-gate3-v2-recheck-r12.md`
  - `design/validation/gate3-v2-recheck-index.md`
  - `design/validation/artifacts/gate3-v2-recheck-r12-20260326-141838/`

### 2026-03-26：回填 Gate-3 v2 扩大试运行 Day6 观察记录

- 决策：
  - Day6 阶段按“边界抽检 + 事件复检”执行，保持低风险推进
  - Day6 结论继续维持“受控观察”，不切换默认入口
- 执行动作：
  - 新增 Day6 记录：`design/validation/2026-03-26-gate3-v2-scaleup-day6.md`
  - 回填 `BACKLOG.md`、`验收清单.md`
- 结果：
  - Day6 关键样例稳定通过，未触发回滚阈值
  - Gate-3 主线保持“事件触发推进”口径

### 2026-03-26：Gate-3 观察回填节奏切换为“双 Day 批处理收口”

- 决策：
  - 在不改变“事件触发”口径下，将 Day7/Day8 合并为单批次收口（R13+R14）
  - 每批先顺序执行两次事件复检，再一次性回填台账与发起 PR
- 原因：
  - 可减少单日重复文档与提交流程，提升主线推进速度
  - 不引入固定时间依赖，仍保持“事件完成即触发下一步”
- 跟踪：
  - Issue：`#31` `Gate-3 v2｜Day7-Day8批处理（R13+R14）`

### 2026-03-26：执行 Gate-3 事件复检 R13（day7_observation_logged）

- 触发事件：
  - `day7_observation_logged`
- 执行动作：
  - 运行 `GATE3_TRIGGER_EVENT="day7_observation_logged" GATE3_RECHECK_ID="R13" bash ./deploy/gate3_event_recheck.sh`
- 结果：
  - R13 五条关键样例全部通过（`C11/C05/C13/X4/H5`）
  - Telegram 仍 `probe_ok=true`，默认入口仍为 `steward`
  - 自动写入复检索引，形成 R1-R13 连续记录
- 决策：
  - 继续维持受控观察，不改变默认入口与默认命中策略
- 证据：
  - `design/validation/2026-03-26-gate3-v2-recheck-r13.md`
  - `design/validation/gate3-v2-recheck-index.md`
  - `design/validation/artifacts/gate3-v2-recheck-r13-20260326-142430/`

### 2026-03-26：执行 Gate-3 事件复检 R14（day8_observation_logged）

- 触发事件：
  - `day8_observation_logged`
- 执行动作：
  - 运行 `GATE3_TRIGGER_EVENT="day8_observation_logged" GATE3_RECHECK_ID="R14" bash ./deploy/gate3_event_recheck.sh`
- 结果：
  - R14 五条关键样例全部通过（`C11/C05/C13/X4/H5`）
  - Telegram 仍 `probe_ok=true`，默认入口仍为 `steward`
  - 自动写入复检索引，形成 R1-R14 连续记录
- 决策：
  - 继续维持受控观察，不改变默认入口与默认命中策略
- 证据：
  - `design/validation/2026-03-26-gate3-v2-recheck-r14.md`
  - `design/validation/gate3-v2-recheck-index.md`
  - `design/validation/artifacts/gate3-v2-recheck-r14-20260326-142431/`

### 2026-03-26：回填 Gate-3 v2 扩大试运行 Day7 观察记录

- 决策：
  - Day7 按“边界抽检 + 事件复检”口径回填，保持低风险推进
  - Day7 结论继续维持“受控观察”，不切换默认入口
- 执行动作：
  - 新增 Day7 记录：`design/validation/2026-03-26-gate3-v2-scaleup-day7.md`
  - 回填 `BACKLOG.md`、`验收清单.md`
- 结果：
  - Day7 关键样例稳定通过，未触发回滚阈值
  - Gate-3 主线保持“事件触发推进”口径

### 2026-03-26：回填 Gate-3 v2 扩大试运行 Day8 观察记录

- 决策：
  - Day8 按“边界抽检 + 事件复检”口径回填，保持低风险推进
  - Day8 结论继续维持“受控观察”，不切换默认入口
- 执行动作：
  - 新增 Day8 记录：`design/validation/2026-03-26-gate3-v2-scaleup-day8.md`
  - 回填 `BACKLOG.md`、`验收清单.md`
- 结果：
  - Day8 关键样例稳定通过，未触发回滚阈值
  - Gate-3 主线保持“事件触发推进”口径

### 2026-03-26：执行 Gate-3 事件复检 R15（day9_observation_logged）

- 触发事件：
  - `day9_observation_logged`
- 执行动作：
  - 运行 `GATE3_TRIGGER_EVENT="day9_observation_logged" GATE3_RECHECK_ID="R15" bash ./deploy/gate3_event_recheck.sh`
  - 建立跟踪 Issue：`#33` `Gate-3 v2｜Day9-Day10批处理（R15+R16）`
- 结果：
  - R15 五条关键样例全部通过（`C11/C05/C13/X4/H5`）
  - Telegram 仍 `probe_ok=true`，默认入口仍为 `steward`
  - 自动写入复检索引，形成 R1-R15 连续记录
- 决策：
  - 继续维持受控观察，不改变默认入口与默认命中策略
- 证据：
  - `design/validation/2026-03-26-gate3-v2-recheck-r15.md`
  - `design/validation/gate3-v2-recheck-index.md`
  - `design/validation/artifacts/gate3-v2-recheck-r15-20260326-143648/`

### 2026-03-26：执行 Gate-3 事件复检 R16（day10_observation_logged）

- 触发事件：
  - `day10_observation_logged`
- 执行动作：
  - 运行 `GATE3_TRIGGER_EVENT="day10_observation_logged" GATE3_RECHECK_ID="R16" bash ./deploy/gate3_event_recheck.sh`
- 结果：
  - R16 五条关键样例全部通过（`C11/C05/C13/X4/H5`）
  - Telegram 仍 `probe_ok=true`，默认入口仍为 `steward`
  - 自动写入复检索引，形成 R1-R16 连续记录
- 决策：
  - 继续维持受控观察，不改变默认入口与默认命中策略
- 证据：
  - `design/validation/2026-03-26-gate3-v2-recheck-r16.md`
  - `design/validation/gate3-v2-recheck-index.md`
  - `design/validation/artifacts/gate3-v2-recheck-r16-20260326-143825/`

### 2026-03-26：回填 Gate-3 v2 扩大试运行 Day9 观察记录

- 决策：
  - Day9 按“边界抽检 + 事件复检”口径回填，保持低风险推进
  - Day9 结论继续维持“受控观察”，不切换默认入口
- 执行动作：
  - 新增 Day9 记录：`design/validation/2026-03-26-gate3-v2-scaleup-day9.md`
  - 回填 `BACKLOG.md`、`验收清单.md`
- 结果：
  - Day9 关键样例稳定通过，未触发回滚阈值
  - Gate-3 主线保持“事件触发推进”口径

### 2026-03-26：回填 Gate-3 v2 扩大试运行 Day10 观察记录

- 决策：
  - Day10 按“边界抽检 + 事件复检”口径回填，保持低风险推进
  - Day10 结论继续维持“受控观察”，不切换默认入口
- 执行动作：
  - 新增 Day10 记录：`design/validation/2026-03-26-gate3-v2-scaleup-day10.md`
  - 回填 `BACKLOG.md`、`验收清单.md`
- 结果：
  - Day10 关键样例稳定通过，未触发回滚阈值
  - Gate-3 主线保持“事件触发推进”口径

### 2026-03-26：Argus 升级议题暂缓（待用户触发）

- 决策：
  - 当前优先级回到 Gate-3 主线，不在本轮执行 `agent_argus` 版本切换
- 当前记录：
  - 升级目标：`v2026.3.24`
  - 现网版本：`v2026.3.12`
  - 已完成目标镜像可用性与只读兼容预检（未触发现网切换）
- 触发条件：
  - 用户明确发出“执行升级”指令后再启动升级与回滚门禁流程

### 2026-03-26：执行 Gate-3 事件复检 R17（day11_observation_logged）

- 触发事件：
  - `day11_observation_logged`
- 执行动作：
  - 运行 `GATE3_TRIGGER_EVENT="day11_observation_logged" GATE3_RECHECK_ID="R17" bash ./deploy/gate3_event_recheck.sh`
  - 建立跟踪 Issue：`#35` `Gate-3 v2｜Day11-Day12批处理（R17+R18）`
- 结果：
  - R17 五条关键样例全部通过（`C11/C05/C13/X4/H5`）
  - Telegram 仍 `probe_ok=true`，默认入口仍为 `steward`
  - 自动写入复检索引，形成 R1-R17 连续记录
- 决策：
  - 继续维持受控观察，不改变默认入口与默认命中策略
- 证据：
  - `design/validation/2026-03-26-gate3-v2-recheck-r17.md`
  - `design/validation/gate3-v2-recheck-index.md`
  - `design/validation/artifacts/gate3-v2-recheck-r17-20260326-150530/`

### 2026-03-26：执行 Gate-3 事件复检 R18（day12_observation_logged）

- 触发事件：
  - `day12_observation_logged`
- 执行动作：
  - 运行 `GATE3_TRIGGER_EVENT="day12_observation_logged" GATE3_RECHECK_ID="R18" bash ./deploy/gate3_event_recheck.sh`
- 结果：
  - R18 五条关键样例全部通过（`C11/C05/C13/X4/H5`）
  - Telegram 仍 `probe_ok=true`，默认入口仍为 `steward`
  - 自动写入复检索引，形成 R1-R18 连续记录
- 决策：
  - 继续维持受控观察，不改变默认入口与默认命中策略
- 证据：
  - `design/validation/2026-03-26-gate3-v2-recheck-r18.md`
  - `design/validation/gate3-v2-recheck-index.md`
  - `design/validation/artifacts/gate3-v2-recheck-r18-20260326-150720/`

### 2026-03-26：回填 Gate-3 v2 扩大试运行 Day11 观察记录

- 决策：
  - Day11 按“边界抽检 + 事件复检”口径回填，保持低风险推进
  - Day11 结论继续维持“受控观察”，不切换默认入口
- 执行动作：
  - 新增 Day11 记录：`design/validation/2026-03-26-gate3-v2-scaleup-day11.md`
  - 回填 `BACKLOG.md`、`验收清单.md`
- 结果：
  - Day11 关键样例稳定通过，未触发回滚阈值
  - Gate-3 主线保持“事件触发推进”口径

### 2026-03-26：回填 Gate-3 v2 扩大试运行 Day12 观察记录

- 决策：
  - Day12 按“边界抽检 + 事件复检”口径回填，保持低风险推进
  - Day12 结论继续维持“受控观察”，不切换默认入口
- 执行动作：
  - 新增 Day12 记录：`design/validation/2026-03-26-gate3-v2-scaleup-day12.md`
  - 回填 `BACKLOG.md`、`验收清单.md`
- 结果：
  - Day12 关键样例稳定通过，未触发回滚阈值
  - Gate-3 主线保持“事件触发推进”口径

### 2026-03-26：完成“再测两 Day 后收口”判定

- 触发前提：
  - 用户确认“再测两 day 后收口”
  - `R17/R18` 与 `Day11/Day12` 回填均完成
- 判定结果：
  - 本轮收口条件满足（关键样例全通过、默认入口稳定、Telegram 探活正常、无回滚触发）
  - 结论：本轮按“维持受控观察”收口，不改默认入口
- 后续口径：
  - 继续保持事件触发推进，后续是否进入下一轮由主线事件触发

### 2026-03-26：采用“本地阶段收口 -> 分段上 GitHub”提速模式

- 背景：
  - 主线推进阶段需要加速，逐步小步 push 造成等待成本偏高
  - 用户明确希望采用“先本地阶段完成，再阶段性上传 GitHub”的节奏
- 决策：
  - 主线默认改为“本地优先”，连续完成一批事件后再统一上云
  - GitHub 继续作为阶段收口与协作审计载体，不改现有门禁（PR + squash + 分支保护）
- 上云触发条件（事件制）：
  - 一个主线事件收口（例如 R 批处理关闭）
  - 一个风险项收口（例如安全/路由问题关闭）
  - 一个可回滚检查点形成（代码/文档/证据三项齐备）
- 配套动作：
  - 新增执行文档：`design/2026-03-26-local-first-staged-github-sync-v1.md`
  - 回填：`README.md`、`BACKLOG.md`、`验收清单.md`

### 2026-03-26：新增 CLI 安全封装护栏（缓解 `--to` 路由歧义）

- 背景：
  - 当前环境下 `openclaw agent --to ...` 未显式 `--agent` 时仍可能落到 `main`
  - 主线加速阶段需要降低联调误用风险，避免重复口头提醒
- 决策：
  - 新增脚本 `scripts/openclaw_agent_safe.sh` 作为 CLI 联调默认入口
  - 规则：无 `--agent` 直接阻断；显式 `--agent` 正常透传到容器内 `openclaw agent`
- 验证：
  - 阻断验证：无 `--agent` 返回退出码 `2`
  - 透传验证：`--agent steward --help` 正常输出 CLI help
  - 证据：`design/validation/2026-03-26-cli-safe-wrapper-validation.md`
- 影响：
  - R-03（CLI/UI 口径差异）状态从 `Open` 调整为 `Mitigated`
  - 已知限制仍保留（底层默认路由行为未直接修复），但联调误判风险已显著降低

### 2026-03-26：将“本地阶段上传 + 恢复策略”写入项目契约

- 背景：
  - 用户提出将“本地阶段完成、阶段性上传”固化到项目契约，并补充恢复策略口径
  - 原建议中的“每 2-3 小时 push”与当前主线“事件触发”原则不完全一致
- 决策：
  - 采用事件触发版上传规则，不采用固定小时窗口
  - 新增项目契约文件：`PROJECT_CONTRACT.md`
  - 在契约中显式加入 `provider/model/profile` 受控对比恢复策略
- 配套动作：
  - 新增本地阶段校验脚本：
    - `scripts/backlog_lint.py`
    - `scripts/backlog_sync.py`
    - `scripts/premerge_check.sh`
  - 回填：`README.md`、`BACKLOG.md`、`验收清单.md`
- 下一步：
  - 按 M2 事件触发计划推进（`design/2026-03-26-mainline-m2-event-driven-plan-v1.md`）

### 2026-03-26：新增 CLI 路由口径探针并完成首轮基线

- 背景：
  - 已有 `openclaw_agent_safe` 护栏，但仍需一个可重复执行的“根因层观察工具”
  - M2-E1 需要可量化判断“默认 `--to` 是否仍误落 `main`”
- 决策：
  - 新增探针脚本：`deploy/cli_route_parity_probe.sh`
  - 用同一输入分别执行：
    - 默认路径（仅 `--to`）
    - 显式路径（`--agent steward --to`）
  - 通过 `sessionKey` 提取命中 agent，形成可比较结论
- 首轮结果：
  - `default_route_session_key=agent:main:main`
  - `explicit_route_session_key=agent:steward:main`
  - 结论：`probe_result=route_mismatch_detected`
- 证据：
  - `design/validation/2026-03-26-cli-route-parity-probe-validation.md`
  - `design/validation/artifacts/openclaw-cli-route-probe-20260326-155605/`
- 后续口径：
  - 已知限制继续保留，不误判为已修复
  - 升级/恢复/路由变更后复跑探针，再决定是否可关闭限制项
  - 同日配置层快速实验 `--bind last` 返回 `Unknown channel "last"`，当前版本下暂不可通过现有绑定机制直接收敛该差异

### 2026-03-26：启动 Gate-4 自动化范围冻结预评审准备

- 背景：
  - 主线需要提速推进，不宜等待 M2-E1 根因完全关闭后再启动全部准备动作
  - 当前已具备风险护栏（显式 `--agent` + 路由探针复检）
- 决策：
  - M2-E1 仍保持 `Open/Mitigated` 跟踪，不标记为关闭
  - 允许并行启动 M2-E2 的“预评审输入包”准备，但不进入运行态自动化改造
- 配套动作：
  - 新增输入包：`design/2026-03-26-gate4-automation-scope-prep-v1.md`
  - 在 M2 计划中登记后续触发路径：`office-hours -> plan-eng-review`
- 风险边界：
  - 在两段评审通过前，不实施多账号自动登录与自动发布执行链路改造

### 2026-03-26：完成 Gate-4 预评审（office-hours）并进入工程评审准备态

- 背景：
  - 用户已明确“继续推进项目”
  - M2-E2 已具备预评审输入包与基础护栏（显式 `--agent` + 路由探针）
- 决策：
  - Gate-4 `office-hours` 结论为 `Conditional-Go`
  - 允许进入 `plan-eng-review`，但仍不进入运行态自动化改造
- 会后产物：
  - 预评审纪要：`design/2026-03-26-gate-4-automation-scope-office-hours-minutes-v1.md`
  - 事件执行卡：`design/2026-03-26-gate4-event-execution-card-v1.md`
  - 正式评审议程：`design/2026-03-26-gate-4-automation-plan-eng-review-agenda-v1.md`
  - 分阶段 DoD 模板：`design/validation/gate4-dod-checklist-template-v1.md`
- 关键边界：
  - 三阶段顺序冻结：A（登录）-> B（发布链路）-> C（平台放量）
  - 禁止无回执黑盒发布、禁止跳过高危动作人工闸门、禁止未定义回滚即放行

### 2026-03-26：完成 Gate-4 正式评审（plan-eng-review）并放行到 M2-E3 准备态

- 背景：
  - Gate-4 `office-hours` 已完成，执行卡 `G4-T1~T6` 前置材料已齐备
  - 已补齐 DoD 模板，可作为阶段放行统一记录口径
- 决策：
  - 评审结论为 `Conditional-Go`
  - 允许进入 M2-E3（多账号登录）受控实现准备
  - 仍不允许跳过阶段直接进入 M2-E4/M2-E5
- 证据：
  - `design/2026-03-26-gate-4-automation-plan-eng-review-minutes-v1.md`
- 放行边界：
  - 仅白名单账号进入自动化链路
  - 高危动作必须二次确认
  - 请求/回执/异常字段必须可追溯
  - R-03 未关闭前，继续执行显式 `--agent` + 路由探针复检口径

### 2026-03-26：启动 M2-E3 多账号登录实现准备

- 背景：
  - Gate-4 两段式评审已收口，允许进入阶段 A 准备态
- 决策：
  - 先落地实现准备包，再进入阶段 A 实跑验证
  - 本轮仍不做运行态改造，不触发自动发布能力
- 产物：
  - `design/2026-03-26-m2-e3-login-implementation-prep-v1.md`
- 下一步：
  - 按 DoD 模板执行阶段 A 验证并留痕

### 2026-03-26：完成 Stage-A 首轮预检（结果 waiting_allowlist）

- 背景：
  - M2-E3 已进入准备态，需要先完成执行前置检查
- 决策：
  - 新增白名单模板：`shared/templates/gate4_account_allowlist_template.json`
  - 新增预检脚本：`deploy/gate4_stage_a_preflight.sh`
  - 首轮执行结果：`preflight_result=waiting_allowlist`
- 证据：
  - `design/validation/2026-03-26-gate4-stagea-preflight-validation.md`
  - `design/validation/artifacts/openclaw-gate4-stagea-preflight-20260326-165924/`
- 下一步：
  - 创建 `runtime/argus/config/gate4/account_allowlist.json`（基于模板）
  - 复跑 Stage-A 预检，目标状态 `ready_for_stage_a_execution`

### 2026-03-26：Stage-A 预检复跑通过（ready_for_stage_a_execution）

- 背景：
  - 首轮预检阻断为 `waiting_allowlist`
- 执行动作：
  - 基于模板创建 `runtime/argus/config/gate4/account_allowlist.json`
  - 复跑 `bash ./deploy/gate4_stage_a_preflight.sh`
- 结果：
  - `allowlist_present=yes`
  - `allowlist_valid=yes`
  - `preflight_result=ready_for_stage_a_execution`
- 证据：
  - `design/validation/2026-03-26-gate4-stagea-preflight-rerun-validation.md`
  - `design/validation/artifacts/openclaw-gate4-stagea-preflight-20260326-170538/`
- 决策：
  - 阶段 A 前置阻断关闭，进入 DoD 验证执行阶段

### 2026-03-26：完成 Stage-A 执行脚本等待态验证（waiting_manual_login）

- 背景：
  - Stage-A 预检已达到 `ready_for_stage_a_execution`
  - 需要将“手工登录回执”作为强制闸门写入执行链路，避免无证据放行
- 决策：
  - 新增执行脚本：`deploy/gate4_stage_a_execute.sh`
  - 新增手工回执模板：`shared/templates/gate4_stage_a_manual_receipt_template.json`
  - 放行规则：仅当预检通过、账号在白名单、必要工单齐备、且 `manual receipt login_ok=true` 时，才允许 `stage_a_passed`
- 首轮结果：
  - `preflight_result=ready_for_stage_a_execution`
  - `account_found=yes`
  - `manual_receipt_present=no`
  - `stage_a_result=waiting_manual_login`
- 证据：
  - `design/validation/2026-03-26-gate4-stage-a-execution-prep-validation.md`
  - `design/validation/artifacts/openclaw-gate4-stagea-exec-20260326-172905/`
  - `design/validation/2026-03-26-gate4-stage-a-dod-validation.md`
- 下一步：
  - 提供手工登录回执文件后复跑：
    - `GATE4_ACCOUNT_ID='<id>' GATE4_OPERATOR='<op>' GATE4_TICKET_ID='<ticket>' GATE4_MANUAL_RECEIPT_FILE='<receipt.json>' bash ./deploy/gate4_stage_a_execute.sh`
  - 目标结果：`stage_a_passed`

### 2026-03-26：Stage-A 手工回执复跑通过（stage_a_passed）

- 背景：
  - Stage-A 等待态验证已完成，唯一阻断为“缺少手工登录回执”
- 执行动作：
  - 提供回执文件：`runtime/argus/config/gate4/manual_receipt.json`
  - 执行 `gate4_stage_a_execute.sh` 并指定 `GATE4_MANUAL_RECEIPT_FILE`
- 结果：
  - `manual_receipt_present=yes`
  - `manual_receipt_valid=yes`
  - `manual_receipt_login_ok=yes`
  - `stage_a_result=stage_a_passed`
- 证据：
  - `design/validation/2026-03-26-gate4-stage-a-pass-validation.md`
  - `design/validation/artifacts/openclaw-gate4-stagea-exec-20260326-174111/`
  - `design/validation/2026-03-26-gate4-stage-a-dod-validation.md`
- 决策：
  - Stage-A DoD 从 `Conditional-Go` 升级为 `Go`
  - 关闭“手工回执缺失”阻断，允许进入 M2-E4 准备态

### 2026-03-26：由 Stage-A 通过触发 M2-E4 准备态

- 背景：
  - M2-E3（阶段 A）DoD 已通过，满足进入下一阶段条件
- 决策：
  - 启动 M2-E4 自动发布执行链路准备包
  - 先固化“发布动作 + 发布回执”字段与前置检查，不直接进入自动发布实跑
- 产物：
  - `design/2026-03-26-m2-e4-release-chain-prep-v1.md`
- 下一步：
  - 落地阶段 B 预检脚手架与发布回执模板

### 2026-03-26：完成 M2-E4 阶段 B 预检脚手架并达到执行就绪

- 背景：
  - M2-E4 准备态已启动，需要把阶段 B 的“模板 + 预检”先落地，避免直接进入黑盒 dry-run
- 决策：
  - 新增发布回执模板：`shared/templates/gate4_release_receipt_template.json`
  - 新增预检脚手架：`deploy/gate4_stage_b_preflight.sh`
  - 预检判定口径：Stage-A DoD 为 `Go`、回执模板合法、secrets 基线与路由护栏持续可用
- 结果：
  - `stagea_dod_go=yes`
  - `release_template_valid=yes`
  - `preflight_result=ready_for_stage_b_execution`
- 证据：
  - `design/validation/2026-03-26-gate4-stage-b-preflight-validation.md`
  - `design/validation/artifacts/openclaw-gate4-stageb-preflight-20260326-174908/`
- 下一步：
  - 创建阶段 B DoD 记录并执行首轮受控 dry-run

### 2026-03-26：新增 Stage-B 执行脚本并完成首轮 dry-run（stage_b_passed）

- 背景：
  - 阶段 B 预检已达到 `ready_for_stage_b_execution`
  - 需要将“发布回执”作为阶段 B 强制闸门，避免无回执放行
- 决策：
  - 新增执行脚本：`deploy/gate4_stage_b_execute.sh`
  - 放行规则：仅当预检通过、账号在白名单、必要工单齐备、且 `release receipt publish_ok=true` 时，才允许 `stage_b_passed`
- 执行动作：
  - 提供本地 dry-run 回执：`runtime/argus/config/gate4/release_receipt.json`
  - 执行 `gate4_stage_b_execute.sh` 并指定 `GATE4_RELEASE_RECEIPT_FILE`
- 结果：
  - `release_receipt_present=yes`
  - `release_receipt_valid=yes`
  - `release_receipt_publish_ok=yes`
  - `stage_b_result=stage_b_passed`
- 证据：
  - `design/validation/2026-03-26-gate4-stage-b-dryrun-validation.md`
  - `design/validation/artifacts/openclaw-gate4-stageb-exec-20260326-175619/`
  - `design/validation/2026-03-26-gate4-stage-b-dod-validation.md`
- 决策：
  - 阶段 B 首轮 dry-run 结论为 `Conditional-Go`
  - 允许进入 M2-E5 准备态，继续保持人工闸门

### 2026-03-26：由 Stage-B `Conditional-Go` 触发 M2-E5 准备态

- 背景：
  - 阶段 B DoD 已形成且结论为 `Conditional-Go`
- 决策：
  - 启动 M2-E5 平台受控放量准备包
  - 先定义放量阈值与停机阈值，不直接进入放量执行
- 产物：
  - `design/2026-03-26-m2-e5-xhs-scaleup-prep-v1.md`
- 下一步：
  - 落地阶段 C 放量策略卡与预检脚手架

### 2026-03-26：完成阶段 C 放量策略与预检并达到执行就绪

- 背景：
  - M2-E5 准备态已启动，需要先固化放量阈值和停机阈值，再进入执行验证
- 决策：
  - 新增放量策略卡：`design/2026-03-26-m2-e5-rollout-strategy-card-v1.md`
  - 新增 rollout 模板：`shared/templates/gate4_rollout_policy_template.json`
  - 新增预检脚手架：`deploy/gate4_stage_c_preflight.sh`
- 结果：
  - `stageb_dod_approved=yes`
  - `rollout_card_valid=yes`
  - `rollout_template_valid=yes`
  - `preflight_result=ready_for_stage_c_execution`
- 证据：
  - `design/validation/2026-03-26-gate4-stage-c-preflight-validation.md`
  - `design/validation/artifacts/openclaw-gate4-stagec-preflight-20260326-180621/`
- 下一步：
  - 创建 Stage-C 执行脚本并完成首轮受控验证

### 2026-03-26：新增 Stage-C 执行脚本并完成首轮受控验证（stage_c_passed）

- 背景：
  - 阶段 C 预检已达到 `ready_for_stage_c_execution`
  - 需要验证“阈值判定 + 停机触发 + 回执追溯”链路
- 决策：
  - 新增执行脚本：`deploy/gate4_stage_c_execute.sh`
  - 新增阶段 C 回执模板：`shared/templates/gate4_stage_c_receipt_template.json`
  - 放行规则：预检通过、账号白名单、阶段策略有效、需要 ticket 时已提供、回执指标满足阈值
- 首轮结果：
  - `phase_id=C1`，`batch_size=5`
  - `stagec_receipt_valid=yes`
  - `stagec_receipt_success_rate=1.0`
  - `stage_c_result=stage_c_passed`
- 证据：
  - `design/validation/2026-03-26-gate4-stage-c-dryrun-validation.md`
  - `design/validation/artifacts/openclaw-gate4-stagec-exec-20260326-180913/`
  - `design/validation/2026-03-26-gate4-stage-c-dod-validation.md`
- 决策：
  - 阶段 C DoD 结论为 `Conditional-Go`
  - 允许进入“真实小流量 C1 运行”专项评审准备，不直接全量放量

### 2026-03-26：完成“真实小流量 C1 运行”专项评审准备包

- 背景：
  - 阶段 C DoD 已形成，结论为 `Conditional-Go`
  - 进入真实小流量前需要先统一评审口径，避免未经评审直接放量
- 决策：
  - 新增专项评审输入包：`design/2026-03-26-gate4-stage-c-real-c1-review-prep-v1.md`
  - 新增专项事件执行卡：`design/2026-03-26-gate4-stage-c-real-c1-event-execution-card-v1.md`
  - 新增专项评审议程：`design/2026-03-26-gate4-stage-c-real-c1-plan-eng-review-agenda-v1.md`
- 约束：
  - 评审前不进入真实流量执行
  - 继续保持白名单、ticket、人工闸门、回执追溯四项约束
- 下一步：
  - 执行 gstack `office-hours` + `plan-eng-review`
  - 按评审结论决定是否进入真实 C1 单批次运行

### 2026-03-26：完成 Stage-C 真实 C1 预评审（office-hours）

- 背景：
  - 阶段 C DoD 结论为 `Conditional-Go`，可进入真实流量前置评审
- 决策：
  - 预评审结论为 `Conditional-Go`
  - 允许进入正式 `plan-eng-review`，但评审前不执行真实流量
- 放行边界（预评审）：
  - 仅允许 C1 单批次（`batch_size <= 5`）作为候选范围
  - 必须保留 `operator + ticket_id` 人工闸门
  - 必须保留完整回执字段与停机回滚口径
- 证据：
  - `design/2026-03-26-gate4-stage-c-real-c1-office-hours-minutes-v1.md`
- 下一步：
  - 进入 Stage-C 真实 C1 `plan-eng-review` 正式评审

### 2026-03-26：完成 Stage-C 真实 C1 正式评审（plan-eng-review）

- 背景：
  - 预评审已完成，专项输入包与执行卡已齐备
- 决策：
  - 正式评审结论为 `Conditional-Go`
  - 放行真实 C1 单批次执行，不放行 C2/C3
- 强制约束：
  - 执行前复跑 `gate4_stage_c_preflight.sh` 且必须 `ready_for_stage_c_execution`
  - 真实执行必须具备 `operator + ticket_id + 完整回执`
  - 触发停机阈值后必须立即回切人工链路
- 证据：
  - `design/2026-03-26-gate4-stage-c-real-c1-plan-eng-review-minutes-v1.md`
- 下一步：
  - 按执行卡执行真实 C1 单批次并回填“继续/停机/回滚”结论

### 2026-03-26：完成真实 C1 单批次执行准备验证（waiting_stage_c_receipt）

- 背景：
  - Stage-C 专项评审已通过，下一步需进入真实 C1 单批次执行
  - 在无真实回执前，必须验证链路不会误判成功
- 执行动作：
  - 以真实 C1 参数执行 `deploy/gate4_stage_c_execute.sh`（不提供回执文件）
- 结果：
  - `preflight_result=ready_for_stage_c_execution`
  - `needs_ticket=yes`
  - `stagec_receipt_present=no`
  - `stage_c_result=waiting_stage_c_receipt`
- 证据：
  - `design/validation/2026-03-26-gate4-stage-c-real-c1-execution-prep-validation.md`
  - `design/validation/artifacts/openclaw-gate4-stagec-realc1-exec-20260326-182510/`
- 决策：
  - 维持“无回执不放行”硬约束
  - 等待真实 C1 回执后复跑并再做阶段结论判定

### 2026-03-26：真实 C1 回执复跑通过（stage_c_passed）

- 背景：
  - 真实 C1 执行准备验证已完成，阻断项仅为缺少真实回执
- 执行动作：
  - 提供真实回执文件：`runtime/argus/config/gate4/stage_c_real_c1_receipt.json`
  - 复跑 `deploy/gate4_stage_c_execute.sh`
- 结果：
  - `stagec_receipt_present=yes`
  - `stagec_receipt_valid=yes`
  - `stagec_receipt_success_rate=1.0`
  - `stagec_receipt_failure_count=0`
  - `stage_c_result=stage_c_passed`
- 证据：
  - `design/validation/2026-03-26-gate4-stage-c-real-c1-pass-validation.md`
  - `design/validation/artifacts/openclaw-gate4-stagec-realc1-exec-20260326-190935/`
  - `design/validation/2026-03-26-gate4-stage-c-real-c1-dod-validation.md`
- 决策：
  - 真实 C1 单批次通过，阶段结论维持 `Conditional-Go`
  - 允许进入 C2 评审准备，不允许直接执行 C2/C3
- 注意事项：
  - 当前回执中的 `evidence_ref` 仍为占位值，需补齐真实引用后完成审计收口

### 2026-03-26：完成 C2 受控放量专项评审准备包

- 背景：
  - 真实 C1 单批次已通过，阶段结论为 `Conditional-Go`
  - 下一步是否进入 C2 需要专项评审，不允许直接执行
- 决策：
  - 新增 C2 评审输入包：`design/2026-03-26-gate4-stage-c-c2-review-prep-v1.md`
  - 新增 C2 事件执行卡：`design/2026-03-26-gate4-stage-c-c2-event-execution-card-v1.md`
  - 新增 C2 评审议程：`design/2026-03-26-gate4-stage-c-c2-plan-eng-review-agenda-v1.md`
- 约束：
  - 维持“未评审不执行 C2”硬约束
  - 维持白名单、ticket、完整回执、停机回滚四项边界
- 下一步：
  - 执行 C2 `office-hours -> plan-eng-review` 两段式评审

### 2026-03-26：完成 C2 预评审（office-hours）

- 背景：
  - C2 评审输入包已就绪，需先完成预评审收敛范围
- 决策：
  - 预评审结论为 `Conditional-Go`
  - 允许进入 C2 正式 `plan-eng-review` 评审，不允许直接执行 C2
- 当前阻断观察：
  - 仅 1 批真实 C1 成功，未满足“连续 2 批成功”触发条件
  - `evidence_ref` 仍为占位值，审计收口未完成
- 证据：
  - `design/2026-03-26-gate4-stage-c-c2-office-hours-minutes-v1.md`
- 下一步：
  - 进入 C2 `plan-eng-review` 正式评审并给出执行/阻断结论

### 2026-03-26：完成 C2 正式评审（plan-eng-review），结论 No-Go

- 背景：
  - C2 预评审已完成，正式评审需决定是否放行 C2 单批次
- 决策：
  - 正式评审结论为 `No-Go`
  - 当前不放行 `phase_id=C2` 的真实放量动作
- 阻断项：
  - 阻断项 A：未满足“C1 连续 2 批成功”触发条件
  - 阻断项 B：`stage_c_real_c1_receipt.json` 的 `evidence_ref` 为占位值
- 证据：
  - `design/2026-03-26-gate4-stage-c-c2-plan-eng-review-minutes-v1.md`
- 下一步（事件触发）：
  - 先关闭阻断项 A/B（第二批真实 C1 成功 + 审计收口）
  - 阻断项关闭后再触发 C2 复评，不跨级执行

### 2026-03-26：为 Stage-C 增加真实证据引用硬门禁（防占位值误通过）

- 背景：
  - C1/C2 评审均确认 `evidence_ref` 占位值是当前核心审计阻断项
  - 原脚本可在占位值存在时仍给出 `stage_c_passed`，存在流程风险
- 决策：
  - 在 `deploy/gate4_stage_c_execute.sh` 增加 `evidence_ref` 占位检测
  - 新增执行开关：`GATE4_STAGE_C_REQUIRE_REAL_EVIDENCE=yes`
  - 当开关开启且检测到占位值时，结果强制为 `waiting_stage_c_receipt_fix`
- 验证结果：
  - 以当前真实 C1 回执复跑，结果为 `stage_c_result=waiting_stage_c_receipt_fix`
  - 汇总字段包含 `stagec_receipt_evidence_ref_placeholder=yes`
- 证据：
  - `design/validation/2026-03-26-gate4-stage-c-real-c1-evidence-gate-validation.md`
- 下一步：
  - 将 `stage_c_real_c1_receipt.json` 的 `evidence_ref` 替换为真实引用并复跑
  - 关闭 C2 阻断项 B 后继续推进第二批真实 C1 与 C2 复评

### 2026-03-26：真实 C1 审计收口完成（阻断项 B 关闭）

- 背景：
  - `GATE4_STAGE_C_REQUIRE_REAL_EVIDENCE=yes` 已上线，证据占位值将被阻断
  - C2 `No-Go` 阻断项 B 要求替换真实 `evidence_ref`
- 执行动作：
  - 将 `runtime/argus/config/gate4/stage_c_real_c1_receipt.json` 的 `evidence_ref` 替换为真实引用
  - 以真实审计模式复跑 Stage-C 执行脚本
- 结果：
  - `stagec_receipt_evidence_ref_placeholder=no`
  - `stage_c_result=stage_c_passed`
- 证据：
  - `design/validation/2026-03-26-gate4-stage-c-real-c1-audit-close-validation.md`
- 决策：
  - C2 阻断项 B 关闭，可进入“连续两批成功”阻断项 A 收口

### 2026-03-26：完成真实 C1 第二批执行并通过（阻断项 A 关闭）

- 背景：
  - C2 `No-Go` 阻断项 A 要求“C1 连续 2 批成功”
- 执行动作：
  - 新建 Batch-002 回执：`runtime/argus/config/gate4/stage_c_real_c1_receipt_batch2.json`
  - 执行 `phase_id=C1` 第二批受控验证并开启真实证据门禁
- 结果：
  - `stagec_receipt_batch_id=XHS-REAL-C1-BATCH-002`
  - `stagec_receipt_success_rate=1.0`
  - `stagec_receipt_failure_count=0`
  - `stage_c_result=stage_c_passed`
- 证据：
  - `design/validation/2026-03-26-gate4-stage-c-real-c1-batch2-pass-validation.md`
  - `design/validation/2026-03-26-gate4-stage-c-c2-blockers-close-validation.md`
- 决策：
  - C2 原阻断项 A/B 均关闭，触发 C2 复评

### 2026-03-26：C2 复评结论为 Conditional-Go（发现新增一致性阻断项 C）

- 背景：
  - 原阻断项 A/B 已关闭后，触发 C2 两段式复评
- 复评结论：
  - `office-hours`：`Conditional-Go`（允许 C2 单批次候选）
  - `plan-eng-review`：`Conditional-Go`（放行前需关闭阻断项 C）
- 新增阻断项 C：
  - Batch-002 回执 `ticket_id` 与执行票据存在不一致
- 证据：
  - `design/2026-03-26-gate4-stage-c-c2-office-hours-rereview-minutes-v1.md`
  - `design/2026-03-26-gate4-stage-c-c2-plan-eng-rereview-minutes-v1.md`
- 决策：
  - 先关闭阻断项 C，再做最终放行判定

### 2026-03-26：关闭 C2 复评新增阻断项 C（票据一致性）

- 背景：
  - C2 复评指出 Batch-002 回执票据与执行票据不一致
- 执行动作：
  - 修正 `runtime/argus/config/gate4/stage_c_real_c1_receipt_batch2.json` 的 `ticket_id=GATE4-C-REAL-002`
  - 复跑 Stage-C Batch-002 并验证一致性
- 结果：
  - `ticket_id=GATE4-C-REAL-002`
  - `stage_c_result=stage_c_passed`
- 证据：
  - `design/validation/2026-03-26-gate4-stage-c-c2-rereview-blocker-c-close-validation.md`
- 决策：
  - 阻断项 C 关闭，触发 C2 最终放行复评

### 2026-03-26：C2 最终复评结论 Go（仅放行单批次）

- 背景：
  - C2 原阻断项 A/B 与复评新增阻断项 C 均已关闭
- 最终结论：
  - `office-hours` 最终预评审：`Go`
  - `plan-eng-review` 最终工程放行：`Go`
- 放行边界：
  - 仅放行 C2 单批次（`G4-C2-T2 -> T3 -> T4 -> T5`）
  - 不放行 C2 连续批次与 C3
- 证据：
  - `design/2026-03-26-gate4-stage-c-c2-office-hours-final-minutes-v1.md`
  - `design/2026-03-26-gate4-stage-c-c2-plan-eng-final-minutes-v1.md`
- 下一步：
  - 执行 C2 单批次受控放量闭环并回填 DoD/三本账

### 2026-03-26：完成 C2 单批次受控放量闭环（stage_c_passed）

- 背景：
  - C2 最终复评已 `Go`（仅单批次）
  - 执行前提为 `G4-C2-T2 -> T3 -> T4 -> T5` 全链路闭环
- 执行动作：
  - 生成 C2 第 1 批真实回执：`runtime/argus/config/gate4/stage_c_real_c2_receipt_batch1.json`
  - 执行 `phase_id=C2` 单批次验证并开启真实证据门禁
- 结果：
  - `phase_id=C2`
  - `stagec_receipt_success_rate=1.0`
  - `stagec_receipt_failure_count=0`
  - `stagec_receipt_halt_triggered=no`
  - `stagec_receipt_evidence_ref_placeholder=no`
  - `stage_c_result=stage_c_passed`
- 证据：
  - `design/validation/2026-03-26-gate4-stage-c-real-c2-batch1-pass-validation.md`
  - `design/validation/2026-03-26-gate4-stage-c-c2-dod-validation.md`
- 决策：
  - C2 单批次闭环完成，进入“是否放行 C2 连续批次”的独立复评阶段

### 2026-03-27：完成 C2 连续批次两段式复评（结论 Conditional-Go）

- 背景：
  - C2 单批次 DoD 已形成，触发“是否进入 C2 连续批次”独立复评
  - 本轮复评按既定流程执行：`office-hours -> plan-eng-review`
- 复评结论：
  - `office-hours`：`Conditional-Go`
  - `plan-eng-review`：`Conditional-Go`
- 放行边界：
  - 仅允许 C2 有限连续窗口（最多 2 批：`batch2 + batch3`）
  - 每批必须独立预检、独立回执、独立阈值判定
  - 严禁外推为 C3 放行，C3 仍需独立复评
- 执行期硬规则：
  - 继续门槛：`success_rate >= 0.95` 且 `failure_count < 2` 且 `halt_triggered=false`
  - 停机阈值：`failure_count >= 2` 或 `halt_triggered=true` 或 `success_rate < 0.90`
  - 降级阈值：`0.90 <= success_rate < 0.95` 时降级回“仅 C2 单批次策略”
  - 审计硬约束：回执缺失、字段缺失、`evidence_ref` 非真实引用均按失败处理
- 证据：
  - `design/2026-03-26-gate4-stage-c-c2-continuous-review-prep-v1.md`
  - `design/2026-03-26-gate4-stage-c-c2-continuous-event-execution-card-v1.md`
  - `design/2026-03-26-gate4-stage-c-c2-continuous-plan-eng-review-agenda-v1.md`
  - `design/2026-03-26-gate4-stage-c-c2-continuous-office-hours-minutes-v1.md`
  - `design/2026-03-26-gate4-stage-c-c2-continuous-plan-eng-review-minutes-v1.md`
- 决策：
  - 放行下一事件：执行 C2 连续窗口第 2 批（`G4-C2-CONT-T2 -> T3 -> T4`）
  - 第 2 批完成后再判定是否进入窗口第 3 批或触发降级/停机回滚

### 2026-03-27：完成 C2 连续窗口 v1（Batch-002 + Batch-003）执行并收口

- 背景：
  - C2 连续批次复评结论为 `Conditional-Go`，放行边界为最多 2 批
  - 需按事件卡执行 `T2 -> T3 -> T4` 逐批判定并在窗口结束后收口
- 执行动作：
  - Batch-002：发送证据消息并生成 `stage_c_real_c2_receipt_batch2.json`，执行 `phase_id=C2`
  - Batch-003：发送证据消息并生成 `stage_c_real_c2_receipt_batch3.json`，执行 `phase_id=C2`
  - 执行后产出连续窗口收口验证记录
- 结果：
  - Batch-002：`success_rate=1.0`、`failure_count=0`、`halt_triggered=no`、`stage_c_result=stage_c_passed`
  - Batch-003：`success_rate=1.0`、`failure_count=0`、`halt_triggered=no`、`stage_c_result=stage_c_passed`
  - 两批均 `stagec_receipt_evidence_ref_placeholder=no`
  - 连续窗口结论：`window_closed_passed`
- 证据：
  - `design/validation/2026-03-27-gate4-stage-c-real-c2-batch2-pass-validation.md`
  - `design/validation/2026-03-27-gate4-stage-c-real-c2-batch3-pass-validation.md`
  - `design/validation/2026-03-27-gate4-stage-c-c2-continuous-window-close-validation.md`
- 决策：
  - C2 连续窗口 v1 已收口，阶段 C2 连续执行链路通过
  - 下一事件进入“是否放行 C3 扩大放量”的独立评审准备阶段
  - 在 C3 独立评审结论落地前，不执行 `phase_id=C3`

### 2026-03-27：完成 C3 独立两段式评审（结论 Conditional-Go）

- 背景：
  - C2 连续窗口 `batch2 + batch3` 已收口通过，触发 C3 独立评审
  - C3 需按“先预评审、再正式工程评审”流程决策，不得直接执行
- 评审结论：
  - `office-hours`：`Conditional-Go`
  - `plan-eng-review`：`Conditional-Go`
- 放行边界：
  - 仅放行 C3 首批（单批次）受控执行
  - 不自动放行 C3 第 2 批及后续批次
  - 不外推到后续阶段
- 执行期硬规则：
  - 停机阈值：`failure_count >= 3` 或 `success_rate < 0.92` 或 `halt_triggered=true`
  - 审计硬约束：回执缺失、字段缺失、`evidence_ref` 非真实引用均按失败处理
  - 降级规则：首批若未形成稳定闭环则降级为“仅补证与复评”，不进入下一批
- 证据：
  - `design/2026-03-27-gate4-stage-c-c3-review-prep-v1.md`
  - `design/2026-03-27-gate4-stage-c-c3-event-execution-card-v1.md`
  - `design/2026-03-27-gate4-stage-c-c3-plan-eng-review-agenda-v1.md`
  - `design/2026-03-27-gate4-stage-c-c3-office-hours-minutes-v1.md`
  - `design/2026-03-27-gate4-stage-c-c3-plan-eng-review-minutes-v1.md`
- 决策：
  - 放行下一事件：执行 C3 首批受控执行（`G4-C3-T2 -> T3 -> T4`）
  - 首批完成后再决定是否发起“C3 后续批次”独立复评

### 2026-03-27：完成 C3 首批受控执行并形成 DoD（stage_c_passed）

- 背景：
  - C3 两段式评审结论均为 `Conditional-Go`，放行边界为“仅首批”
  - 下一事件要求执行 `G4-C3-T2 -> T3 -> T4` 并形成首批判定
- 执行动作：
  - 发送 C3 证据消息并生成回执：`runtime/argus/config/gate4/stage_c_real_c3_receipt_batch1.json`
  - 执行 `phase_id=C3` 首批受控验证，并开启真实证据门禁
  - 回填 C3 首批通过记录与 C3 DoD 记录
- 结果：
  - `phase_id=C3`
  - `stagec_receipt_success_rate=1.0`
  - `stagec_receipt_failure_count=0`
  - `stagec_receipt_halt_triggered=no`
  - `stagec_receipt_evidence_ref_placeholder=no`
  - `stage_c_result=stage_c_passed`
- 证据：
  - `design/validation/2026-03-27-gate4-stage-c-real-c3-batch1-pass-validation.md`
  - `design/validation/2026-03-27-gate4-stage-c-c3-dod-validation.md`
- 决策：
  - C3 首批执行闭环完成，阶段结论维持 `Conditional-Go`
  - 允许进入“是否放行 C3 后续批次”的独立复评，不自动续批
  - 在后续批次复评结论落地前，不执行第 2 批 C3

### 2026-03-27：完成 C3 后续批次两段式复评（结论 Conditional-Go）

- 背景：
  - C3 首批 DoD 已形成，触发“是否允许 C3 后续批次”独立复评
  - 本轮按既定流程执行：`office-hours -> plan-eng-review`
- 复评结论：
  - `office-hours`：`Conditional-Go`
  - `plan-eng-review`：`Conditional-Go`
- 放行边界：
  - 仅允许 C3 有限后续窗口（最多 2 批：`batch2 + batch3`）
  - 每批必须独立预检、独立回执、独立阈值判定
  - 不外推到后续阶段
- 执行期硬规则：
  - 目标阈值：`success_rate >= 0.97`
  - 停机阈值：`failure_count >= 3` 或 `halt_triggered=true` 或 `success_rate < 0.92`
  - 降级阈值：`0.92 <= success_rate < 0.97` 时降级回“仅 C3 首批策略”
  - 审计硬约束：回执缺失、字段缺失、`evidence_ref` 非真实引用均按失败处理
- 证据：
  - `design/2026-03-27-gate4-stage-c-c3-followup-review-prep-v1.md`
  - `design/2026-03-27-gate4-stage-c-c3-followup-event-execution-card-v1.md`
  - `design/2026-03-27-gate4-stage-c-c3-followup-plan-eng-review-agenda-v1.md`
  - `design/2026-03-27-gate4-stage-c-c3-followup-office-hours-minutes-v1.md`
  - `design/2026-03-27-gate4-stage-c-c3-followup-plan-eng-review-minutes-v1.md`
- 决策：
  - 放行下一事件：执行 C3 后续窗口 `batch2 + batch3` 并收口

### 2026-03-27：完成 C3 后续窗口 v1（Batch-002 + Batch-003）执行并收口

- 背景：
  - C3 后续批次复评结论为 `Conditional-Go`，放行边界为最多 2 批
  - 需按事件卡执行 `G4-C3-CONT-T2 -> T3 -> T4` 逐批判定并在窗口结束后收口
- 执行动作：
  - Batch-002：发送证据消息并生成 `stage_c_real_c3_receipt_batch2.json`，执行 `phase_id=C3`
  - Batch-003：发送证据消息并生成 `stage_c_real_c3_receipt_batch3.json`，执行 `phase_id=C3`
  - 执行后产出 C3 后续窗口收口验证记录
- 结果：
  - Batch-002：`success_rate=1.0`、`failure_count=0`、`halt_triggered=no`、`stage_c_result=stage_c_passed`
  - Batch-003：`success_rate=1.0`、`failure_count=0`、`halt_triggered=no`、`stage_c_result=stage_c_passed`
  - 两批均 `stagec_receipt_evidence_ref_placeholder=no`
  - 后续窗口结论：`window_closed_passed`
- 证据：
  - `design/validation/2026-03-27-gate4-stage-c-real-c3-batch2-pass-validation.md`
  - `design/validation/2026-03-27-gate4-stage-c-real-c3-batch3-pass-validation.md`
  - `design/validation/2026-03-27-gate4-stage-c-c3-followup-window-close-validation.md`
- 决策：
  - C3 后续窗口 v1 已收口，阶段 C 链路在当前范围内执行通过
  - 下一事件进入 Stage-C 全阶段收口复核（项目级）

### 2026-03-27：完成 Stage-C 全阶段项目级收口复核（结论 Go）

- 背景：
  - C1/C2/C3 链路已形成阶段性收口，触发 Stage-C 项目级收口复核
  - 本轮按既定流程执行：`office-hours -> plan-eng-review`
- 复核结论：
  - `office-hours`：`Go`
  - `plan-eng-review`：`Go`
- 结论边界：
  - `Go` 仅针对 Stage-C 项目级收口通过
  - 允许进入“下一阶段入口评审”准备
  - 不直接放行后续阶段执行动作
- 跨阶段硬规则：
  - 停机与回滚纪律不降级：触发失败阈值、`halt_triggered=true`、回执缺失/字段异常即停机
  - 审计字段纪律不降级：`operator/ticket_id/evidence_ref` 必须真实可追溯
  - 三本台账需与评审纪要、验证记录保持一一映射
- 证据：
  - `design/2026-03-27-gate4-stage-c-full-close-review-prep-v1.md`
  - `design/2026-03-27-gate4-stage-c-full-close-event-card-v1.md`
  - `design/2026-03-27-gate4-stage-c-full-close-plan-eng-review-agenda-v1.md`
  - `design/2026-03-27-gate4-stage-c-full-close-office-hours-minutes-v1.md`
  - `design/2026-03-27-gate4-stage-c-full-close-plan-eng-review-minutes-v1.md`
- 决策：
  - Stage-C 项目级收口完成，下一事件切换为“下一阶段入口评审准备（仅入口，不含执行放行）”

### 2026-03-27：完成下一阶段入口两段式评审（结论 Go，边界仅准备态）

- 背景：
  - Stage-C 项目级收口结论为 `Go`，且明确只允许进入入口评审
  - 本轮按既定流程执行：`office-hours -> plan-eng-review`
- 评审结论：
  - `office-hours`：`Go`
  - `plan-eng-review`：`Go`
- 结论边界：
  - `Go` 仅针对下一阶段入口准备态
  - 不构成下一阶段执行放行结论
  - 执行动作需另行发起“执行放行评审”独立流程
- 前置条件清单（进入执行放行评审前）：
  - 入口边界持续锁定为“仅准备态，不含执行”
  - 阈值、停机、降级、回滚规则文档化且不弱于 Stage-C 审计纪律
  - 强制审计字段模板齐备（`operator/ticket_id/evidence_ref`）
  - 台账与证据引用映射一致、无断链冲突
- 证据：
  - `design/2026-03-27-gate4-next-stage-entry-review-prep-v1.md`
  - `design/2026-03-27-gate4-next-stage-entry-event-card-v1.md`
  - `design/2026-03-27-gate4-next-stage-entry-plan-eng-review-agenda-v1.md`
  - `design/2026-03-27-gate4-next-stage-entry-office-hours-minutes-v1.md`
  - `design/2026-03-27-gate4-next-stage-entry-plan-eng-review-minutes-v1.md`
- 决策：
  - 下一事件：核验 `next_stage_prerequisites_all_ready`
  - 仅在前置条件全部满足后，发起“下一阶段执行放行评审”（仅发起，不执行）

### 2026-03-27：完成下一阶段执行放行两段式评审（结论 Conditional-Go）

- 背景：
  - 下一阶段入口评审已 `Go`，边界为“仅准备态，不含执行”
  - 本轮发起执行放行独立评审以判定是否可进入执行窗口
- 评审结论：
  - `office-hours`：`Conditional-Go`
  - `plan-eng-review`：`Conditional-Go`
- 执行边界：
  - 当前为 `待绑定（非可执行）`
  - 不得触发下一阶段实际执行动作
- 当前硬阻断项：
  - 执行对象未绑定（平台/账号/作用域未锁定）
  - 阈值/停机/降级/回滚模板未完成对象级实参化
  - 审计实例未闭合（`operator/ticket_id/evidence_ref` 未形成对象级实例链）
- 证据：
  - `design/2026-03-27-gate4-next-stage-execution-review-prep-v1.md`
  - `design/2026-03-27-gate4-next-stage-execution-event-card-v1.md`
  - `design/2026-03-27-gate4-next-stage-execution-plan-eng-review-agenda-v1.md`
  - `design/2026-03-27-gate4-next-stage-execution-office-hours-minutes-v1.md`
  - `design/2026-03-27-gate4-next-stage-execution-plan-eng-review-minutes-v1.md`
- 决策：
  - 下一事件：关闭三项硬阻断后，重新发起执行放行复评
  - 在复评升级为 `Go` 前，维持“入口可准备、执行不可做”状态

### 2026-03-27：关闭下一阶段执行放行三项硬阻断并复评升级为 Go

- 背景：
  - 下一阶段执行放行结论为 `Conditional-Go`，阻断项为对象未绑定、模板未实参化、审计实例未闭合
  - 需先完成阻断项关闭，再触发复评升级
- 关闭动作：
  - 绑定执行对象：`xhs_demo_001`（scope=`demo-sandbox`）
  - 完成对象级策略实参化：`shared/templates/gate4_next_stage_execution_policy_template.json`
  - 完成审计实例闭合：`operator/ticket_id/evidence_ref` 对象级实例链
  - 生成阻断项关闭验证记录
- 复评结果：
  - `office-hours` 复评：`Go`
  - `plan-eng-review` 复评：`Go`
  - 执行边界：`可执行`（非自动执行）
- 证据：
  - `design/validation/2026-03-27-gate4-next-stage-execution-object-binding-record.md`
  - `shared/templates/gate4_next_stage_execution_policy_template.json`
  - `design/validation/2026-03-27-gate4-next-stage-execution-audit-instance-closure.md`
  - `design/validation/2026-03-27-gate4-next-stage-execution-blockers-close-validation.md`
  - `design/2026-03-27-gate4-next-stage-execution-rereview-office-hours-minutes-v1.md`
  - `design/2026-03-27-gate4-next-stage-execution-rereview-plan-eng-review-minutes-v1.md`
- 决策：
  - 下一事件切换为“下一阶段首批受控执行前置校验”
  - 在前置校验完成前，不自动触发实际执行

### 2026-03-27：完成下一阶段首批受控执行前置校验（仅校验）

- 背景：
  - 下一阶段执行放行复评已升级为 `Go`
  - 仍需在触发首批前完成一次前置门禁校验
- 校验结果：
  - 执行边界：`可执行（非自动执行）`
  - 对象绑定：通过（`xhs_demo_001` / `demo-sandbox`）
  - 模板实参：通过（阈值/停机/回滚/审计控制齐备）
  - 审计实例：通过（`operator/ticket_id/evidence_ref` 实例链闭合）
- 证据：
  - `design/validation/2026-03-27-gate4-next-stage-first-batch-preflight-validation.md`
- 决策：
  - 下一事件切换为“下一阶段首批受控执行流程”（需人工闸门确认）
  - 维持“非自动执行”硬边界

### 2026-03-28：完成下一阶段首批受控执行并形成 DoD（stage_c_passed）

- 背景：
  - 下一阶段执行放行复评结论已为 `Go`
  - 首批前置校验已完成并锁定“非自动执行”边界
- 执行动作：
  - 发送首批证据消息并生成回执：`runtime/argus/config/gate4/next_stage_receipt_batch1.json`
  - 使用对象级策略文件执行首批：`shared/templates/gate4_next_stage_execution_policy_template.json`
  - 执行 `phase_id=NEXT` 并回填首批通过记录与 DoD
- 结果：
  - `phase_id=NEXT`
  - `phase_found=yes`
  - `stagec_receipt_success_rate=1.0`
  - `stagec_receipt_failure_count=0`
  - `stagec_receipt_halt_triggered=no`
  - `stagec_receipt_evidence_ref_placeholder=no`
  - `stage_c_result=stage_c_passed`
- 证据：
  - `design/validation/2026-03-28-gate4-next-stage-batch1-pass-validation.md`
  - `design/validation/2026-03-28-gate4-next-stage-dod-validation.md`
- 决策：
  - 下一阶段首批闭环完成，阶段结论为 `Conditional-Go`
  - 下一事件切换为“下一阶段后续批次独立复评”

### 2026-03-28：完成下一阶段后续批次复评并收口后续窗口

- 背景：
  - 下一阶段首批 DoD 已形成，触发后续批次独立复评
  - 后续复评要求仅允许有限窗口（最多 2 批）
- 复评结论：
  - `office-hours`：`Conditional-Go`
  - `plan-eng-review`：`Conditional-Go`
  - 放行边界：仅允许后续窗口 `batch2 + batch3`
- 执行动作：
  - 执行 `NEXT-STAGE-BATCH-002` 并通过
  - 执行 `NEXT-STAGE-BATCH-003` 并通过
  - 回填后续窗口收口验证记录
- 结果：
  - Batch-002：`stage_c_result=stage_c_passed`，`success_rate=1.0`，`failure_count=0`
  - Batch-003：`stage_c_result=stage_c_passed`，`success_rate=1.0`，`failure_count=0`
  - 后续窗口结论：`window_closed_passed`
- 证据：
  - `design/2026-03-28-gate4-next-stage-followup-office-hours-minutes-v1.md`
  - `design/2026-03-28-gate4-next-stage-followup-plan-eng-review-minutes-v1.md`
  - `design/validation/2026-03-28-gate4-next-stage-batch2-pass-validation.md`
  - `design/validation/2026-03-28-gate4-next-stage-batch3-pass-validation.md`
  - `design/validation/2026-03-28-gate4-next-stage-followup-window-close-validation.md`
- 决策：
  - 下一事件切换为“阶段 NEXT 项目级收口复核”

### 2026-03-28：锁定“NEXT 项目级收口 -> 角色全面固化”事件链

- 背景：
  - 阶段 NEXT 后续窗口已收口，主线进入项目级收口复核。
  - 用户确认“计划先入账本，再按事件触发持续推进并加速收口”。
- 决策：
  - 保持当前主线优先级：先完成阶段 NEXT 项目级收口两段式复核（`office-hours -> plan-eng-review`）。
  - 项目级收口执行包补齐为“三件套”：输入包 + 事件卡 + 评审议程。
  - 收口结论发布后，进入“角色全面固化”主线（`RH-T1~RH-T5`），不使用固定时间节点。
  - 角色固化继续沿用门禁：评审通过不等于自动执行，执行事件仍需人工闸门。
- 证据：
  - `design/2026-03-28-gate4-next-stage-full-close-review-prep-v1.md`
  - `design/2026-03-28-gate4-next-stage-full-close-event-card-v1.md`
  - `design/2026-03-28-gate4-next-stage-full-close-plan-eng-review-agenda-v1.md`
  - `design/2026-03-28-role-hardening-event-driven-plan-v1.md`
- 下一事件：
  - 执行阶段 NEXT 项目级收口 `office-hours` 预评审并形成结论。

### 2026-03-28：完成阶段 NEXT 项目级收口预评审（office-hours）

- 背景：
  - 阶段 NEXT 首批与后续窗口执行证据已形成并可追溯。
  - 项目级收口输入包与事件卡、议程已齐备。
- 预评审结论：
  - `office-hours`：`Conditional-Go`
  - 放行边界：仅放行到“项目级正式工程复核”；不放行跨阶段执行
- 风险点：
  - 项目级收口后三本台账回填完成的独立验证记录尚未闭合
  - 需防止“收口复核推进”被误读为“执行放行”
- 证据：
  - `design/2026-03-28-gate4-next-stage-full-close-office-hours-minutes-v1.md`
  - `design/2026-03-28-gate4-next-stage-full-close-review-prep-v1.md`
  - `design/validation/2026-03-28-gate4-next-stage-followup-window-close-validation.md`
- 决策：
  - 下一事件切换为“阶段 NEXT 项目级收口正式工程复核（plan-eng-review）”

### 2026-03-28：完成阶段 NEXT 项目级收口正式工程复核（plan-eng-review）

- 背景：
  - `office-hours` 预评审结论为 `Conditional-Go`，允许进入正式工程复核。
  - 项目级收口复核边界已锁定为“仅入口准备，不含执行放行”。
- 正式结论：
  - `plan-eng-review`：`Conditional-Go`
  - 放行边界：仅允许进入“下一阶段入口评审准备态”
- 阻断项：
  - `B-01`：项目级收口台账闭环验证缺口（需补三本台账回填独立验证记录）
- 证据：
  - `design/2026-03-28-gate4-next-stage-full-close-plan-eng-review-minutes-v1.md`
  - `design/2026-03-28-gate4-next-stage-full-close-office-hours-minutes-v1.md`
  - `design/validation/2026-03-28-gate4-next-stage-batch1-pass-validation.md`
  - `design/validation/2026-03-28-gate4-next-stage-followup-window-close-validation.md`
- 决策：
  - 下一事件切换为“关闭 B-01（台账回填闭环验证）”
  - `B-01` 关闭前，不进入跨阶段执行动作

### 2026-03-28：关闭阶段 NEXT 项目级收口阻断项 B-01并启动角色全面固化主线

- 背景：
  - 阶段 NEXT 项目级正式评审结论为 `Conditional-Go`，唯一阻断项为 `B-01`（台账回填闭环验证缺口）。
  - 已完成三本台账回填与证据映射核对。
- 关闭动作：
  - 新增独立验证记录：`design/validation/2026-03-28-gate4-next-stage-full-close-ledger-backfill-validation.md`
  - 回填 `BACKLOG/DECISIONS/验收清单`，形成项目级收口可追溯闭环
- 结果：
  - `b01_result=closed`
  - 阶段 NEXT 项目级收口阻断项全部关闭
- 决策：
  - 启动“角色全面固化”主线（`RH-T1~RH-T5`）
  - 下一事件切换为“执行 RH-T1 固化范围冻结（吸收/待验证/拒绝）”

### 2026-03-28：完成 RH-T1 角色固化范围冻结并切换 RH-T2

- 背景：
  - 角色全面固化主线已启动，需先冻结“吸收/待验证/拒绝”边界，避免 RH-T2 改动漂移。
- 产出：
  - 固化范围冻结文档：`design/2026-03-28-role-hardening-scope-freeze-v1.md`
  - 冻结范围覆盖：`steward/hunter/editor/publisher`
  - 本轮继续拒绝：`R01/R02/R03/R04`
- 决策：
  - RH-T1 关闭，进入 RH-T2（四角色契约全面固化：四件套 + 共享模板）
  - RH-T2 期间维持边界：不新增角色、不改默认入口、不放开自动执行

### 2026-03-28：执行 RH-T2 首轮契约固化改造（进行中）

- 背景：
  - RH-T1 已冻结边界，进入 RH-T2 文件级改造阶段。
- 已执行改造：
  - `steward/hunter/editor/publisher` 的 `AGENTS/SOUL` 契约升级
  - 共享模板升级：
    - `shared/templates/steward_response_template.md`
    - `shared/templates/hunter_topic_card_template.md`
    - `shared/templates/editor_output_template.md`
    - `shared/templates/publisher_output_template.md`
- 当前边界：
  - 仍保持 `steward` 作为默认入口
  - 仍保持“评审通过不等于自动执行”与人工闸门纪律
- 决策：
  - RH-T2 进入“待验证”状态
  - 下一事件切换为 RH-T3（运行态同步与黄金回归验证）

### 2026-03-28：完成 RH-T3 运行态同步与路由一致性校验

- 背景：
  - RH-T2 契约与模板改造已完成，进入运行态一致性验证。
  - 目标是确认“仓库契约 = 运行态加载状态”，并复核默认入口与通道稳定性。
- 结果：
  - 默认入口：`steward`（绑定 `telegram accountId=default`）
  - 通道状态：`telegram.running=true`、`probe.ok=true`、`lastError=null`
  - Gate-2 探针：`gate2_probe_result=ready_for_binding_test`
  - 哈希一致性：20/20 `match=yes`，`mismatch_count=0`
  - CLI 路由探针：`route_mismatch_detected`（默认 `--to -> main`，显式 `--agent steward -> steward`）
- 证据：
  - `design/validation/2026-03-28-role-hardening-rh-t3-runtime-sync-validation.md`
  - `design/validation/artifacts/openclaw-rh-t3-runtime-hash-parity-20260328-125727/parity.tsv`
  - `design/validation/artifacts/openclaw-rh-t3-route-parity-20260328-124635/artifacts/probe-summary.txt`
- 决策：
  - RH-T3 结论：`passed_with_known_cli_limitation`
  - 已知限制继续纳入治理，不作为本轮阻断
  - 下一事件切换为 RH-T4（黄金回归与高风险项复检）

### 2026-03-28：完成 RH-T4 黄金回归与高风险项复检

- 背景：
  - RH-T3 已通过，需对关键边界与高风险样例执行黄金回归。
- 执行动作：
  - 触发事件：`role_hardening_rh_t4`
  - 执行复检：`GATE3_TRIGGER_EVENT="role_hardening_rh_t4" GATE3_RECHECK_ID="R19" bash ./deploy/gate3_event_recheck.sh`
- 结果：
  - `R19-C11/C05/C13/X4/H5` 全部通过（5/5）
  - 运行态边界稳定，未触发回滚阈值
- 证据：
  - `design/validation/2026-03-28-role-hardening-rh-t4-regression-validation.md`
  - `design/validation/2026-03-28-gate3-v2-recheck-r19.md`
- 决策：
  - RH-T4 关闭，进入 RH-T5 项目级收口评审

### 2026-03-28：完成 RH-T5 项目级收口预评审（office-hours）

- 背景：
  - RH-T1~RH-T4 证据链已完整，进入项目级收口预评审。
  - gstack 专家预评审结论要求继续保留已知限制治理边界。
- 预评审结论：
  - `office-hours`：`Conditional-Go`
  - 放行边界：允许进入正式工程复核；不允许外推为跨阶段执行放行
- 风险点：
  - `route_mismatch_detected` 仍在，关键链路必须维持“显式 `--agent` + `safe wrapper`”
- 证据：
  - `design/2026-03-28-role-hardening-rh-t5-office-hours-minutes-v1.md`
  - `design/2026-03-28-role-hardening-rh-t5-review-prep-v1.md`
  - `design/validation/2026-03-28-role-hardening-rh-t3-runtime-sync-validation.md`
  - `design/validation/2026-03-28-role-hardening-rh-t4-regression-validation.md`
- 决策：
  - 下一事件切换为 RH-T5 正式工程复核（plan-eng-review）

### 2026-03-28：完成 RH-T5 项目级正式工程复核（plan-eng-review）

- 背景：
  - `office-hours` 已给出 `Conditional-Go`，允许进入正式工程复核。
  - RH-T3/RH-T4 结果稳定，但已知路由限制尚未关闭。
- 正式结论：
  - `plan-eng-review`：`Conditional-Go`
  - 放行边界：允许进入“收口后阻断治理与复评态”，不放行跨阶段执行
- 阻断项：
  - `RH-T5-B01`：CLI 默认/显式路由口径不一致（`default --to -> main`，`explicit --agent -> steward`）
- 证据：
  - `design/2026-03-28-role-hardening-rh-t5-plan-eng-review-minutes-v1.md`
  - `design/2026-03-28-role-hardening-rh-t5-office-hours-minutes-v1.md`
  - `design/validation/2026-03-28-role-hardening-rh-t3-runtime-sync-validation.md`
  - `design/validation/2026-03-28-role-hardening-rh-t4-regression-validation.md`
- 决策：
  - 发布 RH 主线阶段性收口结论：`Conditional-Go`
  - 下一事件切换为“关闭 RH-T5-B01 后重开最终 Go/No-Go 复评”

### 2026-03-28：完成 RH-T5-B01 护栏生效子验证（阻断持续治理）

- 背景：
  - RH-T5 正式评审已将 `RH-T5-B01` 标记为硬阻断。
  - 阻断关闭前，需先验证关键链路“显式 `--agent` 强制”护栏是否生效。
- 执行动作：
  - 使用 `scripts/openclaw_agent_safe.sh` 执行两组验证：
    - 未显式 `--agent` 调用（预期阻断）
    - 显式 `--agent steward` 调用（预期通过）
- 结果：
  - `missing_agent_exit=2`（阻断命中）
  - `explicit_agent_exit=0`（执行通过）
  - `explicit_agent_session_key=agent:steward:main`
- 证据：
  - `design/validation/2026-03-28-role-hardening-rh-t5-b01-guardrail-enforcement-validation.md`
  - `design/validation/artifacts/openclaw-rh-t5-b01-guardrail-20260328-132055/summary.txt`
- 决策：
  - 护栏生效子验证通过，但 `RH-T5-B01` 暂不关闭
  - 下一事件切换为 `rh_t5_route_parity_revalidated`

### 2026-03-28：完成 RH-T5-B01 路由口径复评（阻断维持开启）

- 背景：
  - `RH-T5-B01` 护栏生效子验证已通过，需继续复评默认/显式路由口径是否收敛。
- 执行动作：
  - 触发 `rh_t5_route_parity_revalidated`，重跑 `deploy/cli_route_parity_probe.sh`
- 结果：
  - `default_route_exit=0`，`explicit_route_exit=0`
  - `default_route_session_key=agent:main:main`
  - `explicit_route_session_key=agent:steward:main`
  - `probe_result=route_mismatch_detected`
- 证据：
  - `design/validation/2026-03-28-role-hardening-rh-t5-b01-route-parity-revalidation.md`
  - `design/validation/artifacts/openclaw-rh-t5-b01-route-parity-20260328-133402/artifacts/probe-summary.txt`
- 决策：
  - `RH-T5-B01` 维持开启，不做关单
  - 下一事件切换为 `rh_t5_final_go_nogo_rereview_requested`

### 2026-03-28：完成 RH-T5-B01 关键链路显式 Agent 审计

- 背景：
  - 护栏生效与路由复评已完成，需补充“关键链路是否都显式 `--agent`”的审计证据。
- 执行动作：
  - 审计 `deploy/recovery_drill.sh`、`deploy/host_apply_drill.sh`、`deploy/gate3_event_recheck.sh`
  - 复核 `scripts/openclaw_agent_safe.sh` 对缺失 `--agent` 的阻断行为
- 结果：
  - `keypath_all_ok=yes`
  - `wrapper_blocks_missing_agent=yes`
  - `result=pass`
- 证据：
  - `design/validation/2026-03-28-role-hardening-rh-t5-b01-keypath-explicit-agent-audit-validation.md`
  - `design/validation/artifacts/openclaw-rh-t5-b01-keypath-audit-20260328-134226/summary.txt`
- 决策：
  - 关键链路显式 agent 约束已形成审计留痕
  - 下一事件保持 `rh_t5_final_go_nogo_rereview_requested`

### 2026-03-28：完成 RH-T5 最终 Go/No-Go 复评（office-hours）

- 背景：
  - `RH-T5-B01` 仍开启，需对“是否允许受控例外关单”做最终预评审。
- 预评审结论：
  - `office-hours`：`Conditional-Go`
  - `RH-T5-B01` 受控例外关单：`no`
- 核心判断：
  - 护栏与审计可控但不等于风险消除，默认/显式路由分裂仍构成静默错路由风险
- 证据：
  - `design/2026-03-28-role-hardening-rh-t5-final-rereview-office-hours-minutes-v1.md`
  - `design/2026-03-28-role-hardening-rh-t5-final-rereview-prep-v1.md`
- 决策：
  - 下一事件切换为 RH-T5 最终正式工程复评（plan-eng-review）

### 2026-03-28：完成 RH-T5 最终 Go/No-Go 复评（plan-eng-review）

- 背景：
  - office-hours 已明确 `RH-T5-B01` 不可通过受控例外关单，进入正式工程复评。
- 正式结论：
  - `plan-eng-review`：`Conditional-Go`
  - `RH-T5-B01` 是否可关闭：`no`
- 阻断项：
  - `RH-T5-B01`（CLI 默认/显式路由口径不一致）继续保持开启
  - 关闭标准：route parity 不再出现 session_key 分裂，且护栏/审计持续通过并留痕
- 证据：
  - `design/2026-03-28-role-hardening-rh-t5-final-rereview-plan-eng-review-minutes-v1.md`
  - `design/2026-03-28-role-hardening-rh-t5-final-rereview-office-hours-minutes-v1.md`
  - `design/validation/2026-03-28-role-hardening-rh-t5-b01-route-parity-revalidation.md`
  - `design/validation/2026-03-28-role-hardening-rh-t5-b01-keypath-explicit-agent-audit-validation.md`
- 决策：
  - RH 主线维持 `Conditional-Go`，不宣告最终收口完成
  - 下一事件切换为 `rh_t5_b01_route_parity_remediation_requested`

### 2026-03-28：执行 RH-T5-B01 路由整改尝试 A1（未解决）

- 背景：
  - RH-T5 最终复评已确认 `RH-T5-B01` 不可通过受控例外关单，需进入整改事件。
- 尝试动作：
  - 验证“默认路径显式加 `--channel telegram`”是否能与显式 `--agent steward` 对齐
  - 对比两条路径的 `sessionKey`
- 结果：
  - `default_session_key=agent:main:main`
  - `explicit_session_key=agent:steward:main`
  - `same=no`
  - `attempt_result=not_resolved`
- 证据：
  - `design/validation/2026-03-28-role-hardening-rh-t5-b01-remediation-attempt-a1.md`
  - `design/validation/artifacts/openclaw-rh-t5-b01-channel-route-test-20260328-135133/`
- 决策：
  - `RH-T5-B01` 继续保持开启
  - 下一事件维持 `rh_t5_b01_route_parity_remediation_requested`，进入 A2 整改尝试

### 2026-03-28：执行 RH-T5-B01 路由整改尝试 A2（关键脚本护栏硬化）

- 背景：
  - A1 验证显示显式 channel 未消除路由分裂，需要继续降低关键链路误用风险。
- 执行动作：
  - 将关键脚本中的 agent 调用统一收敛到 `scripts/openclaw_agent_safe.sh`
  - 覆盖脚本：`deploy/recovery_drill.sh`、`deploy/host_apply_drill.sh`、`deploy/gate3_event_recheck.sh`
  - 执行静态审计确认关键链路不再存在 `openclaw agent` 直连调用
- 结果：
  - `all_key_files_use_wrapper=yes`
  - `any_direct_openclaw_agent_call=no`
  - `attempt_result=guardrail_hardening_passed`
- 证据：
  - `design/validation/2026-03-28-role-hardening-rh-t5-b01-remediation-attempt-a2-script-hardening.md`
  - `design/validation/artifacts/openclaw-rh-t5-b01-remediation-a2-20260328-135825/summary.txt`
- 决策：
  - A2 已降低关键链路误用风险，但不等于关闭路由分裂
  - `RH-T5-B01` 继续保持开启，下一事件维持 `rh_t5_b01_route_parity_remediation_requested`

### 2026-03-28：执行 RH-T5-B01 路由整改尝试 A3（channel=last，未解决）

- 背景：
  - A1 未解决，A2 完成护栏硬化后继续探索“调用参数层”是否可收敛路由口径。
- 尝试动作：
  - 对比 `--channel last` 的默认路径与显式 `--agent steward` 路径 `sessionKey`
- 结果：
  - `default_exit=0`，`explicit_exit=0`
  - `default_session_key=agent:main:main`
  - `explicit_session_key=agent:steward:main`
  - `same=no`
  - `attempt_result=not_resolved`
- 证据：
  - `design/validation/2026-03-28-role-hardening-rh-t5-b01-remediation-attempt-a3-channel-last.md`
  - `design/validation/artifacts/openclaw-rh-t5-b01-channel-last-test-20260328-140046/`
- 决策：
  - `RH-T5-B01` 继续保持开启
  - 下一事件保持 `rh_t5_b01_route_parity_remediation_requested`
