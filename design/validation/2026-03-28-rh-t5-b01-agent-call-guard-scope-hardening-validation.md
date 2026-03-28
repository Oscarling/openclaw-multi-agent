# 2026-03-28 RH-T5-B01 agent-call-guard 覆盖面补强验证（A15）

## 1) 背景

- 阻断 `RH-T5-B01` 尚未关闭，当前处于等待上游反馈状态。
- 既有护栏可约束 `deploy/` 关键链路，但 `scripts/` 目录新增脚本的直连风险仍需统一门禁。

## 2) 变更内容

- 更新 `scripts/agent_call_guard.sh`：
  - 扫描范围由 `deploy/*.sh` 扩展为 `deploy/*.sh + scripts/*.sh`
  - 采用白名单豁免诊断脚本（仅 route-parity 诊断链路允许直连）
  - 常规执行路径继续要求通过 `scripts/openclaw_agent_safe.sh`
  - 命中规则调整为“非注释行”匹配，减少误报

## 3) 验证命令

```bash
bash scripts/agent_call_guard.sh
bash scripts/premerge_check.sh
```

## 4) 验证结果

- `agent-call-guard`：`ok`
- `premerge-check`：`ok`
- 结论：覆盖面补强后未引入回归，且门禁可继续拦截未来非白名单直连调用。

## 5) 结论

- A15 属于“等待上游反馈期间的本地风险收敛动作”。
- 不改变 `RH-T5-B01` 阻断结论，但提升后续脚本演进的一致性与安全性。
