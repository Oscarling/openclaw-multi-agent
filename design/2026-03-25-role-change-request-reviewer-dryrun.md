# 2026-03-25 角色变更申请单（Dry Run：reviewer）

更新时间：2026-03-25  
类型：流程演练，不改运行态

## 1) 变更类型

- [x] 新增角色（草案）
- [ ] 删减角色
- [ ] 合并角色
- [ ] 拆分角色
- [ ] 默认入口调整

## 2) 变更背景

- 业务目标：在 `editor -> publisher` 之间增加可复核质量闸门
- 当前痛点：高风险表达与信息缺失目前靠人工临场发现，稳定性依赖执行人经验
- 若不变更的代价：真实运营阶段可能出现“质量复核不一致”

## 3) 目标与边界

- 目标角色：`reviewer`（复核角色草案）
- 不做事项：
  - 不改默认入口
  - 不进入运行态 Agent 注册
  - 不新增自动发布动作
- 成功标准（本次 dry-run）：
  - 申请单完整
  - 两段式评审纪要完整
  - 角色四件套草案完整
  - 回归验证通过且运行态无漂移

## 4) 方案候选

- 方案 A（推荐）：新增 `reviewer` 草案并完成门禁干跑，运行态暂不上线
- 方案 B（备选）：保持当前四角色，继续仅靠 `publisher` 末端守护
- 放弃方案及原因：直接上线上线 `reviewer`（当前尚无强触发需求，避免过早复杂化）

## 5) 影响范围

- 受影响角色四件套：`roles/reviewer/*`（新增草案）
- 受影响模板：无（本次仅流程演练）
- 受影响路由规则：无（本次不改运行态）
- 受影响验收 case：新增“门禁 dry-run 回归 case”

## 6) 风险与回滚

- 主要风险：
  - 流程演练与真实上线混淆
  - 草案角色与现网角色口径不一致
- 监控信号：
  - `agents list --bindings` 中不应出现 `reviewer`
  - `assistantAgentId` 不应漂移
- 回滚触发条件：若发现运行态漂移
- 回滚命令：按 `deploy/agent_argus-runbook.md` 执行原 override 重建

## 7) 评审记录

- `office-hours`：见 `design/2026-03-25-office-hours-role-change-reviewer-dryrun.md`
- `plan-eng-review`：见 `design/2026-03-25-plan-eng-review-role-change-reviewer-dryrun.md`
- 是否允许进入实现：否（仅允许进入“需求触发后再上线”状态）

