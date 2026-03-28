# M2-E3 多账号登录受控接入实现准备包（v1）

日期：2026-03-26  
阶段：M2-E3（阶段 A）  
状态：已通过（Stage-A DoD 完成，已触发 M2-E4 准备）

## 1) 目标

在不破坏现有主线稳定性的前提下，为“受控多账号登录”建立最小可执行实现路径。

## 2) 输入前提（来自 Gate-4 评审）

- Gate-4 `office-hours`：`Conditional-Go`
- Gate-4 `plan-eng-review`：`Conditional-Go`，允许进入 M2-E3 准备态
- 路由护栏持续生效：`openclaw_agent_safe` + `cli_route_parity_probe`

参考文档：
- `design/2026-03-26-gate-4-automation-scope-office-hours-minutes-v1.md`
- `design/2026-03-26-gate-4-automation-plan-eng-review-minutes-v1.md`
- `design/validation/gate4-dod-checklist-template-v1.md`

## 3) 实现边界（本阶段）

允许：
- 仅实现“受控账号登录准备与验证链路”
- 仅处理白名单账号，不做全量账号扩展
- 仅落地可审计流程，不做自动发布

禁止：
- 跳过白名单直接登录
- 跳过人工确认执行高危动作
- 绑定自动发布链路（属于 M2-E4）

## 4) 最小交付物（事件触发）

1. 账号白名单样例与字段说明（不含真实敏感值）
   - 模板：`shared/templates/gate4_account_allowlist_template.json`
2. 登录链路操作步骤（含失败处理）
3. 阶段 A DoD 验证记录（基于统一模板）
4. 回滚步骤（登录态撤销与链路回切）

## 5) 验收标准（阶段 A）

- 至少 1 个受控账号完成登录流程验证
- 登录失败路径可复现并可定位
- secrets 不入库，权限符合现有安全口径
- 形成一份可复核的 DoD 验证记录

## 6) 回滚口径

- 触发条件：
  - 登录链路连续失败或出现权限越界
  - 无法保证审计留痕完整
- 回滚动作：
  - 立即停用自动化登录入口
  - 恢复人工登录流程
  - 回填异常记录与处置结论

## 7) 下一事件动作

1. 事件：准备包落盘（已满足）  
动作：复制白名单模板并复跑阶段 A 预检  
命令：`bash ./deploy/gate4_stage_a_preflight.sh`  
产物：`design/validation/<date>-gate4-stage-a-dod-validation.md`（待创建）

当前进展：`design/validation/2026-03-26-gate4-stagea-preflight-rerun-validation.md` 已达到 `ready_for_stage_a_execution`。

2. 事件：阶段 A 预检就绪（已满足）  
动作：执行 Stage-A 脚本并等待手工回执  
命令：`GATE4_ACCOUNT_ID='<id>' GATE4_OPERATOR='<op>' GATE4_TICKET_ID='<ticket>' bash ./deploy/gate4_stage_a_execute.sh`  
回执模板：`shared/templates/gate4_stage_a_manual_receipt_template.json`

当前进展：`design/validation/2026-03-26-gate4-stage-a-pass-validation.md` 已达到 `stage_a_passed`，DoD 结论为 `Go`。

3. 事件：阶段 A DoD 通过（已满足）  
动作：进入 M2-E4 准备态（自动发布链路）  
产物：`design/2026-03-26-m2-e4-release-chain-prep-v1.md`
