# 2026-03-25 Monthly Recovery Drill Validation

更新时间：2026-03-25  
时区：CST  
类型：月度回归演练（`recovery_drill + host_apply_drill`）

## 1) 基本信息

- 演练日期（Asia/Shanghai）：2026-03-25
- 执行时间：
  - 开始：2026-03-25 22:31:34 +0800
  - 结束：2026-03-25 22:32:07 +0800
  - 耗时：33 秒
- 使用备份包：/Users/lingguozhong/Codex工作室/openclaw multi -agent/artifacts/backups/openclaw-state-20260325-220936.tgz.enc
- 使用 manifest：/Users/lingguozhong/Codex工作室/openclaw multi -agent/artifacts/backups/openclaw-state-20260325-220936.manifest.txt

## 2) 执行口径

- Recovery Drill：`deploy/recovery_drill.sh`
- Host Apply Drill：`deploy/host_apply_drill.sh`
- host apply 含自动回滚：是
- 完整性校验：`manifest sha256`

## 3) 结果核验

- recovery drill 冒烟 runId：8d5c2d30-3dc3-41c7-962f-1aa4ed3be2c3
- host apply 冒烟 runId：8a3ab6c2-32f7-4a81-9289-04c9518ad583
- postcheck config file：见 `design/validation/artifacts/openclaw-monthly-recovery-20260325-223134/postcheck-config-file.txt`
- postcheck agents：见 `design/validation/artifacts/openclaw-monthly-recovery-20260325-223134/postcheck-agents.json`
- postcheck control ui：见 `design/validation/artifacts/openclaw-monthly-recovery-20260325-223134/postcheck-control-ui-config.json`

## 4) 证据索引

- 月度聚合证据目录：
  - `design/validation/artifacts/openclaw-monthly-recovery-20260325-223134`
- recovery drill 证据目录：
  - `design/validation/artifacts/openclaw-recovery-drill-20260325-223134/artifacts`
- host apply drill 证据目录：
  - `design/validation/artifacts/openclaw-host-apply-drill-20260325-223134/artifacts`

## 5) 结论

- 本次月度回归演练链路执行完成，证据已落盘。
- 若本次日期满足“下一次月度回归”窗口，可用于关闭 Gate-1 条件 C2。
