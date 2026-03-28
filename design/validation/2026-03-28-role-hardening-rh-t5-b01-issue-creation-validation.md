# 2026-03-28 RH-T5-B01 GitHub 追踪单创建记录

日期：2026-03-28  
事件：`rh_t5_b01_route_parity_remediation_requested`  
目标：将 RH-T5-B01 从本地治理提升为仓库级公开追踪项，便于持续协作与验收。

## 1) 创建结果

- 仓库：`Oscarling/openclaw-multi-agent`
- Issue：`#37`
- 标题：`RH-T5-B01: CLI default route mismatch vs explicit --agent (role-hardening blocker)`
- 链接：[https://github.com/Oscarling/openclaw-multi-agent/issues/37](https://github.com/Oscarling/openclaw-multi-agent/issues/37)

## 2) 提交内容摘要

- 问题定义：默认 `--to` 与显式 `--agent steward` 路由分裂
- 风险定性：静默错路由风险（角色固化阻断）
- 证据链：A1~A5 全部验证记录
- 验收标准：route parity 需达到 `route_parity_ok`，并保持护栏兼容

## 3) 结论

- `issue_created=yes`
- `issue_number=37`
- `blocker_external_tracking=enabled`
