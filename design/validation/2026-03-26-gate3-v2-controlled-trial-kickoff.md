# 2026-03-26 Gate-3 v2 受控试运行启动记录（Day0）

更新时间：2026-03-26  
来源：按 `design/2026-03-26-gate3-v2-controlled-trial-plan-v1.md` 执行启动检查  
状态：已启动（观察窗口进行中）

## 1) 启动前检查

- 默认入口检查：`steward`（通过）
- 待验证池状态：`C11/C05/C13` 已通过（含 C11 复测）
- 关键项状态：`S2/H5/E3/P4/X4` 无失败
- 通道快照：Telegram `running=true`、`probe_ok=true`、`lastError=null`（ts=`1774494523756`）
- 结论：满足 Day0 启动条件

## 2) Day0 受控样例（显式命中）

- `C11-POS-01-RETEST`：`a45cf518-c882-42f4-8173-5f3406ba13d3`
- `C11-POS-02-RETEST`：`1105edb9-edcb-4b83-ac57-514546be70d4`
- `C11-NEG-01-RETEST`：`70588ec9-9964-4c0d-85df-2771bb03ac2b`
- `C05-POS-01`：`e11dc83f-6452-4ee6-ad73-38a0b9fd9962`
- `C05-POS-02`：`47f94661-0007-4f7a-b2e9-23020509bd5b`
- `C05-NEG-01`：`980555cb-05b9-47e4-98c0-c2220a2ee609`
- `C13-POS-01`：`2b7be5db-45ff-4bd5-85fb-0f7c6b895498`
- `C13-POS-02`：`8216bf08-df64-427e-84eb-fc878dbb03ab`
- `C13-NEG-01`：`68c37b15-b1fc-4f4a-b55f-faebc09800ef`

## 3) Day0 观察结论

- 暂未出现关键项失败
- 暂未触发回滚阈值
- 继续观察窗口：24-48h

## 4) 下一步

- Day1 回填一次窗口内复测与稳定性观察结果
- 观察期结束后给出三选一结论：
  - 继续扩大试运行
  - 维持受控范围
  - 回滚终止
- 中窗记录：`design/validation/2026-03-26-gate3-v2-controlled-trial-midwindow-check.md`
