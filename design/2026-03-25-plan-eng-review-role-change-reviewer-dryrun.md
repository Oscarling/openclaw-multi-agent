# 2026-03-25 Plan-Eng-Review：角色变更干跑收口（reviewer）

更新时间：2026-03-25  
类型：工程收口（流程演练，不改运行态）

## 1) 评审目标

- 验证“新增角色门禁”流程是否可执行
- 明确 reviewer 未来上线的工程边界
- 给出可回归、可回滚、可落盘的最小口径

## 2) 工程边界

- 本次允许：
  - 新增 `roles/reviewer/*` 四件套草案
  - 新增流程文档与验证证据
- 本次禁止：
  - `openclaw agents add reviewer`
  - 修改默认入口
  - 修改现有四角色运行态路由

## 3) DoR（进入实现前）

- 角色变更申请单完整
- `office-hours` 纪要完整
- reviewer 四件套草案完整
- 影响范围、风险与回滚条件明确

## 4) DoD（本次 dry-run）

- 已产出申请单、两段式评审纪要
- 已产出 reviewer 四件套草案
- 已完成一次回归验证：
  - 运行态角色列表无漂移（不应出现 reviewer）
  - 默认入口仍为 `steward`
  - `steward` 冒烟响应正常

## 5) 最小验收 Case（Gate Dry-Run）

### Case G1：流程完整性

- 输入：角色变更申请（新增 reviewer）
- 期望：
  - 有 `office-hours` + `plan-eng-review` 两段记录
  - 有角色草案和风险说明

### Case G2：运行态稳定性

- 输入：完成流程演练后执行回归命令
- 期望：
  - `agents list` 仍是五角色
  - `assistantAgentId=steward`
  - `steward` 职责边界回答正常

## 6) 评审结论

- 通过（Dry-Run Pass）
- 结论口径：
  - 门禁流程可执行
  - reviewer 角色草案可用
  - 运行态保持不变，风险可控

