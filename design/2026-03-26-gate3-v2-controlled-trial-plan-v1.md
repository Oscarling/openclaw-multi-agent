# 2026-03-26 Gate-3 v2 受控试运行启动单（v1）

更新时间：2026-03-26  
适用范围：`C11/C05/C13` 已通过待验证池后的小流量受控试运行  
前提：默认入口保持 `steward`，默认不自动命中

## 1) 启动条件（全部满足）

- Gate-3 正式评审纪要已落盘
- 待验证池样例已通过（含 C11 复测）
- 关键项 `S2/H5/E3/P4/X4` 无失败
- kill-switch 与回滚路径可执行

## 2) 试运行范围

- 仅允许显式命中（`--agent`）与测试绑定场景
- 禁止改默认外部入口
- 本轮关注能力：
  - `hunter`：C11 调查模式
  - `editor`：C05 风险提示
  - `editor`：C13 人性化改写

## 3) 执行步骤（顺序）

1. 执行前确认：
   - `docker exec agent_argus openclaw agents list --bindings --json`
   - 确认 `steward.isDefault=true`
2. 按受控样本执行：
   - 每个能力至少 3 条样例（正例/反例/边界）
   - 每条样例使用独立 `--session-id`
3. 记录证据：
   - runId
   - 输入摘要
   - 输出摘要
   - 失败分类（若有）
4. 汇总判定：
   - 回填 `design/validation/2026-03-26-gate3-regression-run-record.md`
   - 更新 `BACKLOG.md` / `DECISIONS.md` / `验收清单.md`

## 4) 观察窗口与阈值

- 观察窗口：24-48 小时
- 阻断阈值：
  - 任一关键项失败立即停止
  - 出现越权或敏感泄露立即回滚

## 5) 回滚动作

1. 路由回切（首选）：
   - `docker exec agent_argus openclaw agents bind --agent steward --bind telegram:default`
2. 能力冻结（按能力开关粒度）：
   - 关闭 `hunter.c11` / `editor.c05` / `editor.c13`
3. 运行态回退（兜底）：
   - 按既有恢复流程恢复到上个稳定快照

## 6) 本轮完成定义（DoD）

- 受控窗口内无关键项失败
- 无回滚触发
- 三项能力均有可复核证据链
- 给出“继续扩大试运行 / 维持受控 / 回滚终止”三选一结论
