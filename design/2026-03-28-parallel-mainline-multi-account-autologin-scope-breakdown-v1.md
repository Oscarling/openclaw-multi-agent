# 2026-03-28 并行主链多账号自动登录能力范围拆解（A36，v1）

scope: `parallel_mainline_multi_account_autologin_scope_v1`  
日期：2026-03-28  
触发事件：`parallel_mainline_dual_account_closeout_passed`

## 1) 目标

在双账号收口完成后，把“多账号自动登录能力”从验证态推进到可执行实现态，且保持事件驱动、不跨界到自动发布链路。

## 2) 范围清单（in-scope）

1. 账号接入治理：白名单字段、风险等级、自动化等级与 owner 责任口径统一。
2. 登录态管理：登录前置检查、回执更新、失败回滚、重试上限。
3. 审计证据：每个账号必须具备可追溯 `evidence_ref`，禁止占位字符串。
4. 运行门禁：维持 `safe wrapper` 与阶段 A/B/C 受控门禁，不放开默认路由口径限制。
5. 运维流程：新增/变更账号必须有 ticket、operator 与回执链路。

## 3) 非范围（out-of-scope）

1. 自动发布执行链路扩展（仍归 M2-E4 范畴）。
2. 自动发小红书放量策略变更（仍归 M2-E5 范畴）。
3. 关闭 RH-T5-B01 路由阻断（仍走侧线 issue #37 事件触发治理）。

## 4) 验收口径（A36 输出标准）

1. 形成两段式评审结论：`office-hours -> plan-eng-review`。
2. 明确可执行拆解项（A37+）与每项完成标准。
3. 三本账同步回填，下一步触发点唯一。

## 5) 执行拆解（A37 候选）

1. A37-T1：产出“多账号登录实现准备包 v2”（字段契约、目录规范、示例回执模板）。
2. A37-T2：产出“多账号登录事件执行卡 v1”（事件、动作、产物、阻断、回滚）。
3. A37-T3：完成 `xhs_demo_001/xhs_demo_002` 配置一致性复检脚本化。
4. A37-T4：完成异常注入演练（token 缺失/账号不在 allowlist/回执不合法）。
5. A37-T5：形成 DoD 验证模板并指定“通过/阻断”判定字段。

## 6) 风险边界

1. 必须继续使用显式 `--agent`，不得绕过 `scripts/openclaw_agent_safe.sh`。
2. 不因 A36 推进降低任何 Gate-4 门禁阈值。
3. 涉及 secrets 的文件仍仅保留在 `runtime/argus/config/secrets`，权限保持 `600`。

## 7) 下一事件建议

`parallel_mainline_multi_account_autologin_scope_review_passed` -> 启动 A37（实现准备包 + 事件执行卡）。
