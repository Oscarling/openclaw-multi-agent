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
