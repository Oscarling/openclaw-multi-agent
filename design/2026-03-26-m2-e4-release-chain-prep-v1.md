# M2-E4 自动发布执行链路准备包（v1）

日期：2026-03-26  
阶段：M2-E4（阶段 B 准备）  
状态：预检就绪（可进入阶段 B 首轮 dry-run）

## 1) 目标

在不突破现有安全边界的前提下，定义“自动发布动作 + 发布回执”最小可执行准备路径，为后续受控实跑提供统一口径。

## 2) 触发前提

- M2-E3 Stage-A DoD 已通过：`design/validation/2026-03-26-gate4-stage-a-dod-validation.md`
- Stage-A 通过留痕：`design/validation/2026-03-26-gate4-stage-a-pass-validation.md`
- 路由护栏持续生效：`scripts/openclaw_agent_safe.sh` + `deploy/cli_route_parity_probe.sh`

## 3) 实现边界（本阶段）

允许：
- 定义发布动作输入/回执字段
- 定义执行前置检查与失败可定位字段
- 定义人工闸门位置与回滚触发条件

禁止：
- 跳过人工闸门直接执行高危发布
- 跳过回执记录直接判定发布成功
- 将真实敏感凭据入库

## 4) 最小交付物（事件触发）

1. 发布回执模板（含成功/失败统一字段）
2. 阶段 B 执行前置检查脚本（脚手架）
3. 阶段 B DoD 验证记录（基于统一模板）
4. 失败回滚动作清单（含人工接管入口）

## 5) 验收标准（阶段 B 准备态）

- 发布动作链路字段定义完整，可审计
- 异常路径能定位到具体阶段与原因
- 发布回执与 ticket/operator/account 可关联追溯
- 形成可复核的阶段 B DoD 草案

## 6) 回滚口径

- 触发条件：
  - 发布动作失败率异常或出现越权执行
  - 回执链路不完整导致不可审计
- 回滚动作：
  - 立即停用自动发布入口（回切人工发布）
  - 保留失败上下文与回执证据
  - 回填 `DECISIONS.md` 与阶段 DoD 结论

## 7) 下一事件动作

1. 事件：M2-E4 准备包落盘（已满足）  
动作：补齐发布回执模板与阶段 B 预检脚手架  
产物：`shared/templates/gate4_release_receipt_template.json`、`deploy/gate4_stage_b_preflight.sh`

2. 事件：阶段 B 预检就绪（已满足）  
动作：进入阶段 B 首轮验证（仅受控 dry-run）  
产物：`design/validation/2026-03-26-gate4-stage-b-preflight-validation.md`

下一步：创建阶段 B DoD 记录并执行首轮 dry-run 留痕。
