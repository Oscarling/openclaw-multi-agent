# 2026-03-25 风险台账（v1）

更新时间：2026-03-26  
状态说明：`Open`（进行中）/ `Mitigated`（已缓解）/ `Closed`（已关闭）

## R-01：Gate-1 C2 未关闭（月度记录待下窗口）

- 等级：P1
- 状态：Open
- 影响：Gate-1 无法完全关闭，备份恢复常态化能力无法标记完成
- 当前措施：
  - 已落地一键脚本 `deploy/monthly_recovery_drill.sh`
  - 已完成同日预演并留痕
  - 2026-03-26 预检通过（`ready_for_monthly_window`）
- 下一动作：2026-04-25 ± 3 天执行下一次月度窗口演练并落盘

## R-02：Telegram 通道健康回归后的运行侧留痕不足

- 等级：P2
- 状态：Mitigated
- 影响：技术链路已恢复，但若缺少真实入站/回包留痕，后续运营排障证据不足
- 当前措施：
  - 已将 Gate-2 设为触发式关口
  - 已启用 `telegram` 插件、完成 `steward -> telegram:default` 显式绑定
  - `assistantAgentId=steward` 与 `agents list --bindings` 一致，默认入口未漂移
  - token 轮换后 `channels status --probe` 已恢复 `probe.ok=true`，`running=true`
  - 已完成真实入站/回包留痕（`telegram pairing request` + `message send ok=true`）
- 下一动作：跟踪观测字段回填行为（`lastInboundAt/lastOutboundAt` 目前仍为 `null`）
  - onboarding 清单：`design/2026-03-26-channel-onboarding-checklist-v1.md`
  - 联调报告：`design/validation/2026-03-26-channel-binding-validation.md`
  - 冒烟证据：`design/validation/2026-03-26-telegram-message-smoke-validation.md`

## R-03：CLI `--to` 路径与 UI 默认入口口径差异

- 等级：P2
- 状态：Open
- 影响：联调口径可能误判默认入口
- 当前措施：
  - 已在 README/验收口径中明确：CLI 联调必须显式 `--agent`
- 下一动作：channel/plugin 联调阶段并行评估收敛方案

## R-04：角色变更流程执行一致性风险

- 等级：P2
- 状态：Mitigated
- 影响：后续新增/删减角色时可能出现漏评审或漏回填
- 当前措施：
  - 已落地门禁文档与申请模板
  - 强制顺序：`office-hours -> plan-eng-review -> 运行态变更`
- 下一动作：首次角色变更时按模板实战一次，完成闭环验证

## R-05：Secrets 单点保管风险

- 等级：P2
- 状态：Open
- 影响：本机故障且 secrets 未异地保管时，恢复速度受限
- 当前措施：
  - 本机 `~/.openclaw/secrets/backup_passphrase.txt` 已设为 `600`
  - 备份包已加密（openssl + pbkdf2）并配套 manifest
- 下一动作：按备份方案补异地 secrets 保管检查清单

## R-06：Bot Token 暴露风险（需轮换）

- 等级：P1
- 状态：Mitigated
- 影响：若 token 泄露，Telegram bot 可能被第三方滥用
- 当前措施：
  - 已完成 token 轮换并重配 channel
  - 已改为 token 文件方式（`/root/.openclaw/config/secrets/telegram_bot_token.txt`）
  - 文件权限已收敛为 `600`
  - token 文件长度已恢复到合理区间（`46` 字节）
- 下一动作：
  - 后续若再次出现敏感值外泄，按同口径立即轮换并复测
