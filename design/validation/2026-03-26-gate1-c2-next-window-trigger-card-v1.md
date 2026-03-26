# 2026-03-26 Gate-1 条件 C2 下一窗口触发卡（v1）

更新时间：2026-03-26  
适用范围：`gstack Gate-1` 条件 C2（月度回归演练记录）  
目标：不依赖固定会议时间，按触发条件完成 C2 收口并触发专家复核

## 1) 触发窗口（绝对日期）

- 执行窗口（Asia/Shanghai）：2026-04-22 至 2026-04-28（即 2026-04-25 ± 3 天）
- 进入窗口后：优先在前 48 小时内执行，避免临近窗口末尾堆积风险

## 2) 触发前最小检查

1. 确认仓库 `main` 可用且运行态无阻断异常  
2. 执行月度预检：

```bash
bash ./deploy/monthly_recovery_preflight.sh
```

3. 预检结论需为可执行（历史口径：`ready_for_monthly_window`）

## 3) 窗口内执行动作

执行月度一键回归：

```bash
OPENCLAW_BACKUP_PASSPHRASE_FILE="$HOME/.openclaw/secrets/backup_passphrase.txt" bash ./deploy/monthly_recovery_drill.sh
```

执行后要求：

- 生成一份新的月度验证记录（`design/validation/`）
- 生成一份新的证据归档目录（`design/validation/artifacts/`，仓库忽略）

## 4) C2 关闭判定（全部满足）

- 新窗口内有新的月度回归记录（非同日预演复用）
- 记录包含：耗时、失败原因（若有）、修复动作、回切结论
- `BACKLOG.md` / `DECISIONS.md` / `验收清单.md` 同步回填

## 5) gstack 专家介入时机（事件触发）

- 触发条件：C2 新窗口记录落盘且台账回填完成
- 触发动作：在同日或 24 小时内发起一次 Gate-1 C2 关闭复核（`gstack`）
- 复核目标：
  - 确认 C2 关闭证据完整
  - 确认后续月度节奏可持续（不是一次性通过）
- 复核产物：`design/validation/<date>-gstack-gate1-c2-close-review.md`

## 6) 失败与延期处理

- 若窗口内执行失败：同窗口内优先补跑 1 次，并记录失败分类
- 若窗口错过：在 `DECISIONS.md` 明确延期原因和新的绝对日期窗口，不允许口头顺延

## 7) GitHub 跟踪项

- C2 窗口执行：`https://github.com/Oscarling/openclaw-multi-agent/issues/4`
- C2 关闭复核触发：`https://github.com/Oscarling/openclaw-multi-agent/issues/3`
