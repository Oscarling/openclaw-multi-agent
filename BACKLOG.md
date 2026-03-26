# OpenClaw Multi-Agent Backlog

更新时间：2026-03-26

## Now

- [x] 只修改 `agent_argus` 的部署层，让它支持可写运行配置
  验收标准：`openclaw config file` 指向可写路径；`openclaw agents add steward ...` 不再报 `EBUSY rename ... openclaw.json`

- [x] 为 `agent_argus` 增加 `/root/.openclaw/agents` 持久化
  验收标准：新增 Agent 后，宿主机对应目录能看到 agent 状态；容器重建后 Agent 仍存在

- [x] 把四个角色收敛成轻量草图，但暂不细化全部角色
  验收标准：`steward`、`hunter`、`editor`、`publisher` 都有一句话职责定义；详细角色文件只先做前两个

- [x] 跑通两角色 MVP：`steward` + `hunter`
  当前状态：Agent 创建成功，角色文件与身份验证完成；默认入口已切换到 `steward`
  验收标准：两个 Agent 都能创建成功；各自回答身份和职责时不串角色

- [x] 固化 `agent_argus` 专属的 rollout / rollback 命令
  验收标准：有一套可重复执行的修改、验证、回滚步骤，不依赖临场回忆

## Next

- [x] 用 `gstack` 讨论 `steward` 和 `hunter` 的角色定义
  推荐顺序：先 `office-hours`，再 `plan-eng-review`
  触发时机：`agent_argus` 的部署层解锁后、正式写角色文件之前

- [x] 为 `steward` 和 `hunter` 补齐角色文件
  范围：`IDENTITY.md`、`SOUL.md`、`AGENTS.md`、`TOOLS.md`

- [x] 对 `steward` 和 `hunter` 做 `plan-eng-review` 收口
  当前状态：角色路由规则、输入输出契约、共享模板已同步运行态，并通过 Case A/B/C 验收
  验收标准：路由规则、输入输出契约、验收口径都可执行且可测试

- [x] 明确 `steward` 作为唯一对外入口的路由策略
  验收标准：外部请求默认只进 `steward`，其他角色不直接对外

- [x] 跑完 `steward` + `hunter` 的第一轮真实样本压测
  当前状态：`steward` 5 组 + `hunter` 2 组，契约总体稳定；出现 1 次 `hunter` 超时，重试通过
  验收标准：完整输入下结构化输出稳定；缺字段场景返回缺失清单；压测证据可复核

- [x] 完成第二轮回归压测（防漂移）
  当前状态：`steward` 3 组 + `hunter` 3 组全部通过；无新增阻断问题
  验收标准：模板输出稳定、缺字段兜底稳定、越权守护稳定

- [x] 完成 channel 级显式绑定（首轮）
  当前状态：`steward -> telegram:default` 已绑定生效；Gate-2 探针为 `ready_for_binding_test`
  就绪文档：`design/2026-03-25-gate2-channel-binding-readiness-v1.md`
  onboarding 清单：`design/2026-03-26-channel-onboarding-checklist-v1.md`
  验证模板：`design/validation/channel-binding-validation-template.md`
  探针证据：`design/validation/2026-03-26-readiness-preflight-validation.md`
  补充证据：`design/validation/artifacts/openclaw-gate2-plugin-enable-20260326-081842/`
  联调报告：`design/validation/2026-03-26-channel-binding-validation.md`
  验收标准：可执行 `openclaw agents bind --agent steward --bind <channel[:accountId]>`，并能查看 bindings 生效

- [x] 修复 Telegram 通道探活 `404`
  当前状态：`channels status --probe` 已恢复 `probe.ok=true`；`running=true`、`lastError=null`
  证据：`design/validation/2026-03-26-channel-binding-validation.md`

- [x] 轮换 Telegram Bot Token（安全收口）
  当前状态：已完成轮换并重配；token 文件长度由异常 `11` 字节恢复到 `46` 字节
  证据：`design/validation/2026-03-26-channel-binding-validation.md`

- [x] 补 1 次真实入站/回包冒烟留痕（Gate-2 运营侧证据）
  当前状态：已完成日志留痕与主动回包（`telegram pairing request` + `message send ok=true`）；`lastInboundAt/lastOutboundAt` 未回填列入观测侧已知限制
  证据：`design/validation/2026-03-26-telegram-message-smoke-validation.md`
  验收标准：
  - 至少 1 条可复核入站证据 + 1 条可复核回包证据（优先时间戳字段；字段未回填时可用日志与发送回执替代）
  - 记录到 `design/validation/2026-03-26-channel-binding-validation.md`
  - 关闭后回填 Gate-2 评审条件项

- [x] 统一 CLI 与 UI 的默认入口路由口径
  当前观察：`openclaw agent --to ...` 仍落到 `main`，而 Control UI 默认入口已是 `steward`
  当前约定：CLI 联调必须显式 `--agent`；UI 入口验收以 `assistantAgentId` 为准
  验收标准：明确并固化“验收/联调时使用哪个入口判定为准”，避免测试结论歧义

- [x] 增加 CLI 安全封装护栏（强制显式 `--agent`）
  当前状态：`scripts/openclaw_agent_safe.sh` 已落地；无 `--agent` 会阻断，显式 `--agent` 可正常透传
  验证证据：`design/validation/2026-03-26-cli-safe-wrapper-validation.md`
  风险处置：作为 R-03（CLI/UI 口径差异）的缓解措施，降低联调误判风险

- [x] 增加 CLI 路由口径探针并完成首轮基线留痕
  当前状态：`deploy/cli_route_parity_probe.sh` 已落地并完成首轮执行
  首轮结果：`default_route_agent=main`、`explicit_route_agent=steward`，`probe_result=route_mismatch_detected`
  同日实验：尝试 `--bind last`，返回 `Unknown channel "last"`，当前版本下无法通过现有绑定机制直接修复
  验证证据：`design/validation/2026-03-26-cli-route-parity-probe-validation.md`
  使用口径：升级/恢复/路由相关变更后复跑探针，再判定是否可关闭已知限制

- [x] 跑一轮四角色端到端演练（steward -> hunter -> editor -> publisher）
  当前状态：同一业务 brief 已完成四阶段链路验证，均未越权
  验收证据：`design/validation/2026-03-25-fullchain-validation.md`
  验收标准：同一业务 brief 能串起四角色产出，且每步都遵守边界不越权

- [x] 完成重建后的五角色冒烟回归（含 `main`）
  当前状态：`agent_argus + sidecar_argus` `--force-recreate` 后，`main/steward/hunter/editor/publisher` 均可响应；默认入口仍为 `steward`
  验收证据：`design/validation/2026-03-25-recreate-smoke-validation.md`
  验收标准：可写配置、挂载读写、默认入口与五角色可用性均不漂移

- [x] 在两角色稳定后补 `editor`
  当前状态：`editor` agent 已创建并通过 E1-E4 验收；“选题卡 -> 草稿/标题/封面文案”链路已跑通
  验收标准：能把“选题卡 -> 草稿/标题/封面文案”这条链路跑通

- [x] 在三角色稳定后补 `publisher`
  当前状态：`publisher` agent 已创建并通过 P1-P4 验收；“成稿包 -> 发布策略包”链路已跑通
  验收标准：能输出发布时间建议、发布检查清单、复盘模板，但不自动发帖

- [x] 用 `gstack` 讨论 `editor` 的角色定义
  推荐顺序：先 `office-hours`，再 `plan-eng-review`
  当前状态：讨论文档与收口文档已落地，E1-E4 已通过

- [x] 用 `gstack` 讨论 `publisher` 的角色定义
  推荐顺序：先 `office-hours`，再 `plan-eng-review`
  当前状态：讨论文档与收口文档已落地，P1-P4 已通过

- [x] 启动 `editor` 角色讨论准备包
  当前状态：已补输入输出契约草案、`hunter -> editor` 交接模板、第一批验收 case
  产物：`design/2026-03-25-editor-discussion-prep.md` 与 `shared/templates/*editor*`
  触发时机：第二轮回归通过后立即可启动

## Later

- [x] 整理成可上 GitHub 的项目骨架
  当前状态：已补 `README.md`、`RECOVERY.md`、`.env.example`、`deploy/agent_argus.override.example.yml`
  验收标准：仓库里至少包含文档、部署模板、角色文件、恢复说明和示例环境变量

- [x] 设计“GitHub + secrets + state backup”的恢复方案
  当前状态：方案已定稿（openssl + manifest 校验 + 密钥文件托管），并完成脚本与演练验证
  产物：`design/2026-03-25-backup-recovery-plan-v1.md`
  脚本：`scripts/backup_state.sh`、`scripts/restore_state.sh`
  脚本验证：`design/validation/2026-03-25-backup-script-validation.md`
  演练证据：`design/validation/2026-03-25-recovery-drill-validation.md`
  验收标准：明确哪些内容可以进 GitHub，哪些必须走加密备份，恢复顺序如何执行

- [x] 完成项目上 GitHub（私有仓库）
  当前状态：已完成 `init -> commit -> create repo -> push`，默认分支 `main`
  仓库：`https://github.com/Oscarling/openclaw-multi-agent`
  验收标准：远端仓库可访问、`origin/main` 已建立、工作区干净

- [x] 启用 GitHub 可用协作门禁（当前套餐可执行）
  当前状态：已启用 `squash-only`、关闭 `merge/rebase`、合并后自动删分支，并补齐 PR 模板
  配置：
  - 合并策略：仅 `squash merge`
  - 自动清理：`delete_branch_on_merge=true`
  - PR 模板：`.github/PULL_REQUEST_TEMPLATE.md`
  验收标准：仓库级合并策略生效，PR 走模板化检查

- [x] 启用 `main` 分支保护（强制 PR review 等）
  当前状态：已启用（仓库改为公开后落地）
  保护规则：
  - 单人维护模式：`required_approving_review_count=0`
  - 会话必须 resolved
  - 线性历史开启
  - 禁止 force-push / 删除分支
  - 管理员同样受保护（`enforce_admins=true`）
  验收标准：`branches/main/protection` 可读且规则生效（当前已满足）

- [x] 为 `agent_argus` 设计状态备份方案
  当前状态：目录范围、频率与恢复顺序已定稿；脚本 v0 已落地并通过 stage/异常场景验证；明文残留已清理
  范围：`~/.openclaw/state/argus`、`~/.openclaw/workspaces/argus` 及后续新增持久化目录
  说明：后续进入运维节奏（按月回归演练）

- [x] 建立备份恢复月度回归节奏
  当前状态：已完成首次演练与异常场景验证；月度一键脚本已落地并完成预演（同日）；2026-03-26 已按事件触发完成一次主线执行并形成新记录
  跟踪 Issue：`#4` `Gate-1 C2｜事件触发执行月度回归`
  里程碑：`Gate-1 C2 closeout (event-driven)`
  脚本：`deploy/monthly_recovery_drill.sh`
  预演证据：`design/validation/2026-03-25-monthly-recovery-drill-validation-20260325-223134.md`
  本次执行证据：`design/validation/2026-03-26-monthly-recovery-drill-validation.md`
  预检证据：`design/validation/2026-03-26-readiness-preflight-validation.md`
  触发卡：`design/validation/2026-03-26-gate1-c2-event-trigger-card-v2.md`
  执行触发事件：`#4` 待执行 + 预检 `ready_for_monthly_window` + 主线无阻断异常
  记录模板：`design/validation/monthly-recovery-drill-template.md`
  验收标准：每月至少一次演练并记录耗时、失败原因、修复动作

- [x] 设定 gstack 专家介入节奏（里程碑触发三关口）
  当前状态：
  - 关口 1 已执行，结论 `Pass with conditions`
  - 关口 2 已进入可触发状态（绑定与探活已通过）
  - 关口 3 待后续触发
  当前规则：
  - 关口 1（阶段收口后）：任一子项目达到 DoD（文档/验证/回滚都齐）后，在进入下一子项目前发起一次 `plan-eng-review`
  - 关口 2（联调收口前）：channel plugin 可用且完成首轮联调后，发起一次路由/绑定专项评审
  - 关口 3（角色变更前）：任一新增/删减角色需求进入实现前，先走 `office-hours -> plan-eng-review`
  评审证据：`design/validation/2026-03-25-gstack-gate1-review.md`
  关口 2 触发证据：`design/validation/2026-03-26-channel-binding-validation.md`
  验收标准：每次关口都有纪要、结论和对应文档回填

- [x] 发起 gstack Gate-2 专项评审（路由/绑定）
  当前状态：已完成，结论 `Pass with conditions`（不阻塞进入下一阶段）
  触发证据：`design/validation/2026-03-26-channel-binding-validation.md`
  评审纪要：`design/validation/2026-03-26-gstack-gate2-review.md`
  验收标准：形成 Gate-2 评审纪要并回填 `DECISIONS.md` / `验收清单.md`

- [x] 发起“prompts.chat 角色优化”Gate-3 预评审（office-hours）
  触发条件：Gate-2 已收口，且 prompts.chat 评估文档已确认（当前已满足）
  执行动作：触发条件满足后立即推进
  当前目标：把外部角色库降噪为 10-20 条候选意图/能力点，不直接落运行态
  评估文档：`design/2026-03-26-prompts-chat-role-optimization-assessment-v1.md`
  输入包：`design/2026-03-26-prompts-chat-candidate-intents-v1.md`
  行动清单：`design/2026-03-26-gate3-pre-review-action-list-v1.md`
  会议纪要：`design/2026-03-26-gate-3-prompts-chat-role-optimization-pre-assessment-minutes-v1.md`
  结论：`Conditional-Go`（允许进入正式 plan-eng-review）
  验收标准：形成候选清单 v1 与会后 action list

- [x] 发起“prompts.chat 角色优化”Gate-3 正式评审（plan-eng-review）
  触发条件：预评审完成，且候选清单已标注“吸收/拒绝/待验证”
  当前状态：已完成，结论 `Conditional-Go`（进入 v2 准备，不进入默认自动命中）
  工程观察：`design/2026-03-26-gate-3-prompts-chat-plan-eng-observer-notes-v1.md`
  24h 执行卡：`design/2026-03-26-gate3-24h-execution-card-v1.md`
  会议议程：`design/2026-03-26-gate-3-prompts-chat-plan-eng-review-agenda-v1.md`
  会议纪要：`design/2026-03-26-gate-3-prompts-chat-plan-eng-review-minutes-v1.md`
  执行动作：触发条件满足后立即推进
  验收标准：形成 go/no-go 结论与 v2 试运行边界（不改默认入口）

- [x] 执行 Gate-3 待验证池最小样例回归（`C11/C05/C13`）
  触发条件：Gate-3 正式评审纪要已落盘（当前已满足）
  当前状态：已执行并回填；`C11/C05/C13` 均通过（C11 经修复复测通过）
  验证文档：
  - `design/validation/gate3-c11-min-cases-v1.md`
  - `design/validation/gate3-c05-min-cases-v1.md`
  - `design/validation/gate3-c13-min-cases-v1.md`
  总报告：`design/validation/2026-03-26-gate3-min-cases-validation.md`
  运行记录：`design/validation/2026-03-26-gate3-regression-run-record.md`
  回归模板：`design/validation/gate3-regression-run-record-template-v1.md`
  验收标准：
  - 三组最小样例全部执行并有证据链
  - `S2/H5/E3/P4/X4` 关键项补测无失败
  - 明确“可进 v2 受控试运行 / 不可进入”结论（当前为可进入受控试运行）

- [x] 关闭 C11 放行阻断项（证据链可追溯字段）
  触发条件：已完成待验证池首轮回归且仅 C11 阻断（当前已满足）
  当前状态：已完成契约补齐并复测通过，阻断解除
  修复文件：`roles/hunter/AGENTS.md`、`roles/hunter/SOUL.md`
  复测文档：`design/validation/gate3-c11-min-cases-v1.md`、`design/validation/2026-03-26-gate3-c11-retest-validation.md`
  结论：待验证池三项均可进入 v2 受控试运行候选

- [x] Gate-3 v2 受控试运行（阶段完成，默认入口不变）
  触发条件：待验证池样例全部通过（当前已满足）
  当前状态：已完成阶段性收口，且 R1/R2/R3/R4/R5/R6/R7/R8/R9/R10/R11/R12/R13/R14/R15/R16/R17/R18 复检连续通过，结论“维持受控范围”（不放量）
  执行口径：`design/2026-03-26-gate3-v2-routing-and-killswitch-v1.md`
  启动单：`design/2026-03-26-gate3-v2-controlled-trial-plan-v1.md`
  启动记录：`design/validation/2026-03-26-gate3-v2-controlled-trial-kickoff.md`
  中窗记录：`design/validation/2026-03-26-gate3-v2-controlled-trial-midwindow-check.md`
  结束清单：`design/validation/gate3-v2-window-close-checklist-v1.md`
  结束报告：`design/validation/2026-03-26-gate3-v2-controlled-trial-closeout.md`
  下一轮触发卡：`design/validation/gate3-v2-next-check-trigger-card-v1.md`
  放量准入：`design/2026-03-26-gate3-v2-scale-up-criteria-v1.md`
  复检记录：`design/validation/2026-03-26-gate3-v2-recheck-r1.md`、`design/validation/2026-03-26-gate3-v2-recheck-r2.md`、`design/validation/2026-03-26-gate3-v2-recheck-r3.md`、`design/validation/2026-03-26-gate3-v2-recheck-r4.md`、`design/validation/2026-03-26-gate3-v2-recheck-r5.md`、`design/validation/2026-03-26-gate3-v2-recheck-r6.md`、`design/validation/2026-03-26-gate3-v2-recheck-r7.md`、`design/validation/2026-03-26-gate3-v2-recheck-r8.md`、`design/validation/2026-03-26-gate3-v2-recheck-r9.md`、`design/validation/2026-03-26-gate3-v2-recheck-r10.md`、`design/validation/2026-03-26-gate3-v2-recheck-r11.md`、`design/validation/2026-03-26-gate3-v2-recheck-r12.md`、`design/validation/2026-03-26-gate3-v2-recheck-r13.md`、`design/validation/2026-03-26-gate3-v2-recheck-r14.md`、`design/validation/2026-03-26-gate3-v2-recheck-r15.md`、`design/validation/2026-03-26-gate3-v2-recheck-r16.md`、`design/validation/2026-03-26-gate3-v2-recheck-r17.md`、`design/validation/2026-03-26-gate3-v2-recheck-r18.md`
  复检索引：`design/validation/gate3-v2-recheck-index.md`
  运行记录：`design/validation/2026-03-26-gate3-regression-run-record.md`
  验收标准：受控窗口内关键项无失败，且未触发回滚阈值

- [x] 启动 Gate-3 v2 扩大试运行 Day0（仍不改默认入口）
  触发条件：放量准入判定通过（当前已满足）
  当前状态：Day0 首批扩大样本已执行，9/9 通过；脚本化事件复检已到 R18 且持续通过，保持受控观察
  准入判定：`design/validation/2026-03-26-gate3-v2-scale-up-readiness.md`
  准入标准：`design/2026-03-26-gate3-v2-scale-up-criteria-v1.md`
  执行记录：`design/validation/2026-03-26-gate3-v2-scaleup-day0.md`
  后续复检：`design/validation/2026-03-26-gate3-v2-recheck-r3.md`、`design/validation/2026-03-26-gate3-v2-recheck-r4.md`、`design/validation/2026-03-26-gate3-v2-recheck-r5.md`、`design/validation/2026-03-26-gate3-v2-recheck-r6.md`、`design/validation/2026-03-26-gate3-v2-recheck-r7.md`、`design/validation/2026-03-26-gate3-v2-recheck-r8.md`、`design/validation/2026-03-26-gate3-v2-recheck-r9.md`、`design/validation/2026-03-26-gate3-v2-recheck-r10.md`、`design/validation/2026-03-26-gate3-v2-recheck-r11.md`、`design/validation/2026-03-26-gate3-v2-recheck-r12.md`、`design/validation/2026-03-26-gate3-v2-recheck-r13.md`、`design/validation/2026-03-26-gate3-v2-recheck-r14.md`、`design/validation/2026-03-26-gate3-v2-recheck-r15.md`、`design/validation/2026-03-26-gate3-v2-recheck-r16.md`、`design/validation/2026-03-26-gate3-v2-recheck-r17.md`、`design/validation/2026-03-26-gate3-v2-recheck-r18.md`
  runId 索引：`design/validation/artifacts/gate3-min-cases-20260326-1105/runid-index.md`
  验收标准：扩大样本后关键项仍 100% 通过，且无回滚触发

- [x] 回填 Gate-3 v2 扩大试运行 Day12 观察记录（仍不改默认入口）
  触发条件：Day11 观察回填已完成，且触发式复检链路稳定（当前已满足）
  当前状态：Day12 观察回填已完成，R18 关键样例全部通过，仍保持受控观察
  Day12 记录：`design/validation/2026-03-26-gate3-v2-scaleup-day12.md`
  R18 记录：`design/validation/2026-03-26-gate3-v2-recheck-r18.md`
  复检索引：`design/validation/gate3-v2-recheck-index.md`
  跟踪 Issue：`#35` `Gate-3 v2｜Day11-Day12批处理（R17+R18）`
  验收标准：Day12 窗口内关键样例无失败，且无回滚触发

- [x] 回填 Gate-3 v2 扩大试运行 Day11 观察记录（仍不改默认入口）
  触发条件：Day10 观察回填已完成，且触发式复检链路稳定（当前已满足）
  当前状态：Day11 观察回填已完成，R17 关键样例全部通过，仍保持受控观察
  Day11 记录：`design/validation/2026-03-26-gate3-v2-scaleup-day11.md`
  R17 记录：`design/validation/2026-03-26-gate3-v2-recheck-r17.md`
  复检索引：`design/validation/gate3-v2-recheck-index.md`
  跟踪 Issue：`#35` `Gate-3 v2｜Day11-Day12批处理（R17+R18）`
  验收标准：Day11 窗口内关键样例无失败，且无回滚触发

- [x] 回填 Gate-3 v2 扩大试运行 Day10 观察记录（仍不改默认入口）
  触发条件：Day9 观察回填已完成，且触发式复检链路稳定（当前已满足）
  当前状态：Day10 观察回填已完成，R16 关键样例全部通过，仍保持受控观察
  Day10 记录：`design/validation/2026-03-26-gate3-v2-scaleup-day10.md`
  R16 记录：`design/validation/2026-03-26-gate3-v2-recheck-r16.md`
  复检索引：`design/validation/gate3-v2-recheck-index.md`
  跟踪 Issue：`#33` `Gate-3 v2｜Day9-Day10批处理（R15+R16）`
  验收标准：Day10 窗口内关键样例无失败，且无回滚触发

- [x] 回填 Gate-3 v2 扩大试运行 Day9 观察记录（仍不改默认入口）
  触发条件：Day8 观察回填已完成，且触发式复检链路稳定（当前已满足）
  当前状态：Day9 观察回填已完成，R15 关键样例全部通过，仍保持受控观察
  Day9 记录：`design/validation/2026-03-26-gate3-v2-scaleup-day9.md`
  R15 记录：`design/validation/2026-03-26-gate3-v2-recheck-r15.md`
  复检索引：`design/validation/gate3-v2-recheck-index.md`
  跟踪 Issue：`#33` `Gate-3 v2｜Day9-Day10批处理（R15+R16）`
  验收标准：Day9 窗口内关键样例无失败，且无回滚触发

- [x] 回填 Gate-3 v2 扩大试运行 Day8 观察记录（仍不改默认入口）
  触发条件：Day7 观察回填已完成，且触发式复检链路稳定（当前已满足）
  当前状态：Day8 观察回填已完成，R14 关键样例全部通过，仍保持受控观察
  Day8 记录：`design/validation/2026-03-26-gate3-v2-scaleup-day8.md`
  R14 记录：`design/validation/2026-03-26-gate3-v2-recheck-r14.md`
  复检索引：`design/validation/gate3-v2-recheck-index.md`
  跟踪 Issue：`#31` `Gate-3 v2｜Day7-Day8批处理（R13+R14）`
  验收标准：Day8 窗口内关键样例无失败，且无回滚触发

- [x] 回填 Gate-3 v2 扩大试运行 Day7 观察记录（仍不改默认入口）
  触发条件：Day6 观察回填已完成，且触发式复检链路稳定（当前已满足）
  当前状态：Day7 观察回填已完成，R13 关键样例全部通过，仍保持受控观察
  Day7 记录：`design/validation/2026-03-26-gate3-v2-scaleup-day7.md`
  R13 记录：`design/validation/2026-03-26-gate3-v2-recheck-r13.md`
  复检索引：`design/validation/gate3-v2-recheck-index.md`
  跟踪 Issue：`#31` `Gate-3 v2｜Day7-Day8批处理（R13+R14）`
  验收标准：Day7 窗口内关键样例无失败，且无回滚触发

- [x] 回填 Gate-3 v2 扩大试运行 Day6 观察记录（仍不改默认入口）
  触发条件：Day5 观察回填已完成，且触发式复检链路稳定（当前已满足）
  当前状态：Day6 观察回填已完成，R12 关键样例全部通过，仍保持受控观察
  Day6 记录：`design/validation/2026-03-26-gate3-v2-scaleup-day6.md`
  R12 记录：`design/validation/2026-03-26-gate3-v2-recheck-r12.md`
  复检索引：`design/validation/gate3-v2-recheck-index.md`
  跟踪 Issue：`#29` `Gate-3 v2｜Day6观察回填 + 事件复检 R12`
  验收标准：Day6 窗口内关键样例无失败，且无回滚触发

- [x] 回填 Gate-3 v2 扩大试运行 Day5 观察记录（仍不改默认入口）
  触发条件：Day4 观察回填已完成，且触发式复检链路稳定（当前已满足）
  当前状态：Day5 观察回填已完成，R11 关键样例全部通过，仍保持受控观察
  Day5 记录：`design/validation/2026-03-26-gate3-v2-scaleup-day5.md`
  R11 记录：`design/validation/2026-03-26-gate3-v2-recheck-r11.md`
  复检索引：`design/validation/gate3-v2-recheck-index.md`
  跟踪 Issue：`#27` `Gate-3 v2｜Day5观察回填 + 事件复检 R11`
  验收标准：Day5 窗口内关键样例无失败，且无回滚触发

- [x] 回填 Gate-3 v2 扩大试运行 Day4 观察记录（仍不改默认入口）
  触发条件：Day3 观察回填已完成，且触发式复检链路稳定（当前已满足）
  当前状态：Day4 观察回填已完成，R10 关键样例全部通过，仍保持受控观察
  Day4 记录：`design/validation/2026-03-26-gate3-v2-scaleup-day4.md`
  R10 记录：`design/validation/2026-03-26-gate3-v2-recheck-r10.md`
  复检索引：`design/validation/gate3-v2-recheck-index.md`
  跟踪 Issue：`#25` `Gate-3 v2｜Day4观察回填 + 事件复检 R10`
  验收标准：Day4 窗口内关键样例无失败，且无回滚触发

- [x] 回填 Gate-3 v2 扩大试运行 Day3 观察记录（仍不改默认入口）
  触发条件：Day2 观察回填已完成，且触发式复检链路稳定（当前已满足）
  当前状态：Day3 观察回填已完成，R9 关键样例全部通过，仍保持受控观察
  Day3 记录：`design/validation/2026-03-26-gate3-v2-scaleup-day3.md`
  R9 记录：`design/validation/2026-03-26-gate3-v2-recheck-r9.md`
  复检索引：`design/validation/gate3-v2-recheck-index.md`
  跟踪 Issue：`#23` `Gate-3 v2｜Day3观察回填 + 事件复检 R9`
  验收标准：Day3 窗口内关键样例无失败，且无回滚触发

- [x] 回填 Gate-3 v2 扩大试运行 Day2 观察记录（仍不改默认入口）
  触发条件：Day1 观察回填已完成，且触发式复检链路稳定（当前已满足）
  当前状态：Day2 观察回填已完成，R8 关键样例全部通过，仍保持受控观察
  Day2 记录：`design/validation/2026-03-26-gate3-v2-scaleup-day2.md`
  R8 记录：`design/validation/2026-03-26-gate3-v2-recheck-r8.md`
  复检索引：`design/validation/gate3-v2-recheck-index.md`
  跟踪 Issue：`#21` `Gate-3 v2｜Day2观察回填 + 事件复检 R8`
  验收标准：Day2 窗口内关键样例无失败，且无回滚触发

- [x] 回填 Gate-3 v2 扩大试运行 Day1 观察记录（仍不改默认入口）
  触发条件：Day0 扩大试运行已启动，且触发式复检链路稳定（当前已满足）
  当前状态：Day1 观察回填已完成，R7 关键样例全部通过，仍保持受控观察
  Day1 记录：`design/validation/2026-03-26-gate3-v2-scaleup-day1.md`
  R7 记录：`design/validation/2026-03-26-gate3-v2-recheck-r7.md`
  复检索引：`design/validation/gate3-v2-recheck-index.md`
  跟踪 Issue：`#19` `Gate-3 v2｜Day1观察回填 + 事件复检 R7`
  验收标准：Day1 窗口内关键样例无失败，且无回滚触发

- [x] 固化 Gate-3 复检一键事件执行脚本
  当前状态：已新增脚本并写入触发卡，且已完成 R4/R5/R6/R7/R8/R9/R10/R11/R12/R13/R14/R15/R16/R17/R18 连续实跑验证
  脚本：`deploy/gate3_event_recheck.sh`
  触发卡：`design/validation/gate3-v2-next-check-trigger-card-v1.md`
  复检索引：`design/validation/gate3-v2-recheck-index.md`
  R4 记录：`design/validation/2026-03-26-gate3-v2-recheck-r4.md`
  R5 记录：`design/validation/2026-03-26-gate3-v2-recheck-r5.md`
  R6 记录：`design/validation/2026-03-26-gate3-v2-recheck-r6.md`
  R7 记录：`design/validation/2026-03-26-gate3-v2-recheck-r7.md`
  R8 记录：`design/validation/2026-03-26-gate3-v2-recheck-r8.md`
  R9 记录：`design/validation/2026-03-26-gate3-v2-recheck-r9.md`
  R10 记录：`design/validation/2026-03-26-gate3-v2-recheck-r10.md`
  R11 记录：`design/validation/2026-03-26-gate3-v2-recheck-r11.md`
  R12 记录：`design/validation/2026-03-26-gate3-v2-recheck-r12.md`
  R13 记录：`design/validation/2026-03-26-gate3-v2-recheck-r13.md`
  R14 记录：`design/validation/2026-03-26-gate3-v2-recheck-r14.md`
  R15 记录：`design/validation/2026-03-26-gate3-v2-recheck-r15.md`
  R16 记录：`design/validation/2026-03-26-gate3-v2-recheck-r16.md`
  R17 记录：`design/validation/2026-03-26-gate3-v2-recheck-r17.md`
  R18 记录：`design/validation/2026-03-26-gate3-v2-recheck-r18.md`
  跟踪 Issue：`#16` `Gate-3 v2｜事件复检 R6（day1_scaleup_ready）`
  批处理 Issue：`#31` `Gate-3 v2｜Day7-Day8批处理（R13+R14）`
  批处理 Issue：`#33` `Gate-3 v2｜Day9-Day10批处理（R15+R16）`
  批处理 Issue：`#35` `Gate-3 v2｜Day11-Day12批处理（R17+R18）`
  执行口径：`GATE3_TRIGGER_EVENT=<event> GATE3_RECHECK_ID=<R#> bash ./deploy/gate3_event_recheck.sh`
  验收标准：可自动采集快照 + 执行关键样例 + 生成复检记录并写入复检索引

- [x] 产出角色优化执行包（RoleSpec + 差异清单 + 黄金回归清单）
  当前目标：将 prompts.chat 的可用能力映射到 `steward/hunter/editor/publisher` 四角色，不新增运行态默认入口
  当前进展：执行包三件套已落地（RoleSpec + 差异清单 + 黄金回归清单）
  模板：`shared/templates/role_spec_template.md`
  差异清单：`design/2026-03-26-prompts-chat-role-diff-mapping-v1.md`
  回归清单：`design/2026-03-26-prompts-chat-golden-regression-checklist-v1.md`
  验收标准：
  - `RoleSpec` 模板落地
  - 四角色差异清单完成（吸收/拒绝/待验证）
  - 回归清单可执行（逐角色 + 端到端）

- [x] 关闭 gstack Gate-1 条件项（C1/C2）
  当前状态：C1/C2 均已关闭；已完成 C2 事件触发执行、关闭复核与台账回填
  跟踪 Issue：`#3` `Gate-1 C2｜事件触发后进行 gstack 关闭复核`
  里程碑：`Gate-1 C2 closeout (event-driven)`
  条件 C1：完成 host `~/.openclaw/state/argus` 与 `~/.openclaw/workspaces/argus` apply 覆盖演练并落盘（已完成）
  C1 证据：`design/validation/2026-03-25-host-apply-drill-validation.md`
  条件 C2：按事件触发形成下一次月度回归演练记录
  C2 执行 Issue：`#4` `Gate-1 C2｜事件触发执行月度回归`
  C2 触发卡：`design/validation/2026-03-26-gate1-c2-event-trigger-card-v2.md`
  C2 预演证据：`design/validation/2026-03-25-monthly-recovery-drill-validation-20260325-223134.md`
  C2 本次记录：`design/validation/2026-03-26-monthly-recovery-drill-validation.md`
  C2 预检证据：`design/validation/2026-03-26-readiness-preflight-validation.md`
  C2 模板：`design/validation/monthly-recovery-drill-template.md`
  验收证据：`design/validation/2026-03-25-gstack-gate1-review.md`
  关闭复核：`design/validation/2026-03-26-gstack-gate1-c2-close-review.md`

- [x] 设立“新增/删减角色”的评审门禁（`gstack` 两段式）
  当前状态：已完成 dry-run 实战演练（申请单 + 两段评审 + 四件套草案 + 回归验证）
  流程文档：`design/2026-03-25-role-change-gate-v1.md`
  申请模板：`shared/templates/role_change_request_template.md`
  dry-run 证据：`design/validation/2026-03-25-role-change-gate-dryrun-validation.md`
  规则：新增或删减角色前，先走 `office-hours` 再走 `plan-eng-review`，再进入运行态变更
  触发时机：现有链路稳定后出现新角色需求，或现有角色边界需要合并/拆分
  执行口径：首次真实角色变更继续沿用本次 dry-run 链路

- [x] 评估是否需要更正式的项目管理方式
  结论：采用“轻量正规化管理（L1）”，暂不引入重型流程（L2）
  评估文档：`design/2026-03-25-project-management-assessment-v1.md`
  风险台账：`design/2026-03-25-risk-register-v1.md`

- [x] 建立周度治理复盘节奏（L1）
  当前状态：模板已落地，首轮周度治理记录（kickoff）已完成
  模板：`shared/templates/weekly_governance_review_template.md`
  首轮记录：`design/validation/2026-03-25-weekly-governance-review-kickoff.md`
  后续节奏：按事件触发（默认每完成一批关键事件后执行一次）

- [x] 启用“本地阶段收口 -> 分段上 GitHub”提速口径
  当前状态：已定稿并纳入主线执行规则
  执行文档：`design/2026-03-26-local-first-staged-github-sync-v1.md`
  规则：本地先连续推进，满足触发条件后再统一 `push + PR`，不改变现有门禁（PR + squash + 分支保护）
  触发条件：主线事件收口 / 风险项收口 / 可回滚检查点形成

- [x] 将“本地阶段上传 + 恢复对比策略”写入项目契约
  当前状态：`PROJECT_CONTRACT.md` 已落地并在 README 建立入口
  执行脚本：`scripts/backlog_lint.py`、`scripts/backlog_sync.py`、`scripts/premerge_check.sh`
  契约范围：Local-First 阶段上传口径 + `provider/model/profile` 受控对比恢复策略

- [x] 梳理下一里程碑 M2 的事件触发执行计划
  当前状态：M2 计划文档已落地（不按时间、按事件触发）
  计划文档：`design/2026-03-26-mainline-m2-event-driven-plan-v1.md`

- [x] 启动 Gate-4 自动化范围冻结预评审准备包
  当前状态：预评审输入包与 `office-hours` 纪要均已落地，进入 `plan-eng-review` 准备态
  输入文档：`design/2026-03-26-gate4-automation-scope-prep-v1.md`
  使用口径：先冻结自动化边界，再进入多账号登录/自动发布实现
  纪要：`design/2026-03-26-gate-4-automation-scope-office-hours-minutes-v1.md`

- [x] 产出 Gate-4 事件执行卡与正式评审议程
  当前状态：已完成 `office-hours -> plan-eng-review` 的会后衔接文档
  执行卡：`design/2026-03-26-gate4-event-execution-card-v1.md`
  议程：`design/2026-03-26-gate-4-automation-plan-eng-review-agenda-v1.md`
  DoD 模板：`design/validation/gate4-dod-checklist-template-v1.md`
  使用口径：按事件触发推进，不进入时间节点排程

- [x] 完成 Gate-4 正式评审（plan-eng-review）并放行到 M2-E3 准备态
  当前状态：结论 `Conditional-Go`，允许进入阶段 A（多账号登录）受控实现准备
  评审纪要：`design/2026-03-26-gate-4-automation-plan-eng-review-minutes-v1.md`
  放行边界：不跳阶段、不放行无回执动作、不放行无人工闸门高危操作

- [x] 启动 M2-E3 多账号登录实现准备包
  当前状态：准备文档已落地，进入阶段 A 执行前置准备
  准备文档：`design/2026-03-26-m2-e3-login-implementation-prep-v1.md`
  使用口径：先完成受控账号登录 DoD，再进入 M2-E4

- [x] 新增 Stage-A 预检脚本与白名单模板并完成首轮预检
  当前状态：`deploy/gate4_stage_a_preflight.sh` 与白名单模板已落地，首轮 `waiting_allowlist`，复跑已达 `ready_for_stage_a_execution`
  模板：`shared/templates/gate4_account_allowlist_template.json`
  预检记录：`design/validation/2026-03-26-gate4-stagea-preflight-validation.md`
  复跑记录：`design/validation/2026-03-26-gate4-stagea-preflight-rerun-validation.md`
  下一动作：按 DoD 模板启动阶段 A 验证留痕

- [x] 新增 Stage-A 执行脚本与手工回执模板并完成等待态验证
  当前状态：`deploy/gate4_stage_a_execute.sh` 与回执模板已落地；无回执时结果为 `waiting_manual_login`
  回执模板：`shared/templates/gate4_stage_a_manual_receipt_template.json`
  验证记录：`design/validation/2026-03-26-gate4-stage-a-execution-prep-validation.md`
  下一动作：提供手工登录回执后复跑，目标 `stage_a_passed`

- [x] 完成 Stage-A 手工回执复跑并通过 DoD（`stage_a_passed`）
  当前状态：已提供手工回执并复跑成功，`manual_receipt_valid=yes`、`manual_receipt_login_ok=yes`
  通过记录：`design/validation/2026-03-26-gate4-stage-a-pass-validation.md`
  DoD 记录：`design/validation/2026-03-26-gate4-stage-a-dod-validation.md`
  下一动作：触发进入 M2-E4（自动发布链路）准备态

- [x] 启动 M2-E4 自动发布执行链路准备包
  当前状态：准备包已落地，进入阶段 B 准备中
  准备文档：`design/2026-03-26-m2-e4-release-chain-prep-v1.md`
  下一动作：补齐阶段 B 预检脚手架与发布回执模板

- [x] 完成 M2-E4 阶段 B 预检脚手架与回执模板并通过预检
  当前状态：已新增 `deploy/gate4_stage_b_preflight.sh` 与发布回执模板，预检结果 `ready_for_stage_b_execution`
  模板：`shared/templates/gate4_release_receipt_template.json`
  验证记录：`design/validation/2026-03-26-gate4-stage-b-preflight-validation.md`
  下一动作：创建阶段 B DoD 记录并执行首轮 dry-run

- [x] 新增 Stage-B 执行脚本并完成首轮 dry-run（`stage_b_passed`）
  当前状态：`deploy/gate4_stage_b_execute.sh` 已落地，受控 dry-run 结果 `stage_b_passed`
  dry-run 记录：`design/validation/2026-03-26-gate4-stage-b-dryrun-validation.md`
  DoD 记录：`design/validation/2026-03-26-gate4-stage-b-dod-validation.md`
  下一动作：由阶段 B `Conditional-Go` 触发进入 M2-E5 准备态

- [x] 启动 M2-E5 平台受控放量准备包
  当前状态：准备包已落地，进入阶段 C 准备中
  准备文档：`design/2026-03-26-m2-e5-xhs-scaleup-prep-v1.md`
  下一动作：补齐阶段 C 放量策略卡与预检脚手架

- [x] 完成阶段 C 放量策略卡与预检脚手架并达到执行就绪
  当前状态：已新增放量策略卡、rollout 模板与 `deploy/gate4_stage_c_preflight.sh`，预检结果 `ready_for_stage_c_execution`
  策略卡：`design/2026-03-26-m2-e5-rollout-strategy-card-v1.md`
  模板：`shared/templates/gate4_rollout_policy_template.json`
  验证记录：`design/validation/2026-03-26-gate4-stage-c-preflight-validation.md`
  下一动作：执行阶段 C 首轮受控验证并形成 DoD

- [x] 新增 Stage-C 执行脚本并完成首轮受控验证（`stage_c_passed`）
  当前状态：`deploy/gate4_stage_c_execute.sh` 已落地，C1 受控批次验证通过
  回执模板：`shared/templates/gate4_stage_c_receipt_template.json`
  dry-run 记录：`design/validation/2026-03-26-gate4-stage-c-dryrun-validation.md`
  DoD 记录：`design/validation/2026-03-26-gate4-stage-c-dod-validation.md`
  下一动作：发起“真实小流量 C1 运行”专项评审准备

- [x] 完成“真实小流量 C1 运行”专项评审准备包
  当前状态：专项评审输入包、执行卡与议程均已落地，待执行 gstack 专项评审
  输入包：`design/2026-03-26-gate4-stage-c-real-c1-review-prep-v1.md`
  执行卡：`design/2026-03-26-gate4-stage-c-real-c1-event-execution-card-v1.md`
  议程：`design/2026-03-26-gate4-stage-c-real-c1-plan-eng-review-agenda-v1.md`
  下一动作：执行 gstack `office-hours` + `plan-eng-review` 并形成放行结论

- [x] 完成“真实小流量 C1 运行”专项评审（`office-hours -> plan-eng-review`）
  当前状态：两段式评审已收口，结论 `Conditional-Go`，允许进入真实 C1 单批次执行
  预评审纪要：`design/2026-03-26-gate4-stage-c-real-c1-office-hours-minutes-v1.md`
  正式评审纪要：`design/2026-03-26-gate4-stage-c-real-c1-plan-eng-review-minutes-v1.md`
  下一动作：按执行卡执行真实 C1 单批次并回填阶段结论

- [x] 完成真实 C1 单批次执行准备验证（等待真实回执）
  当前状态：真实 C1 执行链路已验证到 `waiting_stage_c_receipt`，未回执不误判通过
  验证记录：`design/validation/2026-03-26-gate4-stage-c-real-c1-execution-prep-validation.md`
  下一动作：提供真实 C1 回执后复跑，目标 `stage_c_passed`

- [x] 完成真实 C1 单批次回执复跑并通过（`stage_c_passed`）
  当前状态：真实 C1 执行结果 `stage_c_passed`，已形成真实 C1 DoD 记录
  通过记录：`design/validation/2026-03-26-gate4-stage-c-real-c1-pass-validation.md`
  DoD 记录：`design/validation/2026-03-26-gate4-stage-c-real-c1-dod-validation.md`
  下一动作：补齐真实证据引用并发起 C2 评审准备（不直接执行 C2）

- [x] 完成 C2 受控放量专项评审准备包
  当前状态：C2 输入包、执行卡与议程均已落地，并用于专项评审
  输入包：`design/2026-03-26-gate4-stage-c-c2-review-prep-v1.md`
  执行卡：`design/2026-03-26-gate4-stage-c-c2-event-execution-card-v1.md`
  议程：`design/2026-03-26-gate4-stage-c-c2-plan-eng-review-agenda-v1.md`
  下一动作：执行 C2 两段式评审并形成放行结论

- [x] 完成 C2 预评审（office-hours）
  当前状态：结论 `Conditional-Go`（仅允许进入正式评审，不允许直接执行 C2）
  纪要：`design/2026-03-26-gate4-stage-c-c2-office-hours-minutes-v1.md`
  下一动作：进入 C2 `plan-eng-review` 正式评审

- [x] 完成 C2 正式评审（plan-eng-review）并形成 `No-Go`
  当前状态：因“C1 连续两批成功未满足 + 审计 `evidence_ref` 未收口”，当前不放行 C2 执行
  纪要：`design/2026-03-26-gate4-stage-c-c2-plan-eng-review-minutes-v1.md`
  下一动作：先关闭阻断项，再触发 C2 复评

- [ ] 关闭 C2 阻断项 A：补齐真实 C1 第 2 批并达到阈值
  触发条件：第 2 批真实 C1 执行回执可用
  完成标准：形成“连续 2 批成功”证据（每批 `success_rate >= 0.95` 且未触发停机）
  产物：第 2 批真实 C1 通过记录（待创建）

- [ ] 关闭 C2 阻断项 B：完成 `evidence_ref` 审计收口
  触发条件：可提供真实证据引用（消息链接或证据 ID）
  完成标准：`stage_c_real_c1_receipt.json` 中 `evidence_ref` 非占位值，并完成复核留痕
  产物：审计收口记录（待创建）

- [x] 增加 Stage-C 真实审计证据硬门禁（防占位值误通过）
  当前状态：`deploy/gate4_stage_c_execute.sh` 已支持 `GATE4_STAGE_C_REQUIRE_REAL_EVIDENCE=yes`；占位 `evidence_ref` 会返回 `waiting_stage_c_receipt_fix`
  验证记录：`design/validation/2026-03-26-gate4-stage-c-real-c1-evidence-gate-validation.md`
  下一动作：替换真实 `evidence_ref` 后复跑，关闭 C2 阻断项 B

- [ ] 触发 C2 复评并决定是否放行 C2 单批次
  触发条件：阻断项 A/B 均已关闭
  完成标准：形成 C2 复评结论（`No-Go/Conditional-Go/Go`）并回填三本账
  产物：C2 复评纪要（待创建）
