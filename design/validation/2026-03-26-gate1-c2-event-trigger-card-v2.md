# 2026-03-26 Gate-1 条件 C2 事件触发卡（v2）

更新时间：2026-03-26  
适用范围：`gstack Gate-1` 条件 C2（月度回归演练记录）  
目标：不依赖固定时间点，按事件完成触发执行与复核

## 1) 触发事件（全部满足即执行）

- `#4` 处于待执行状态（主线执行单）
- 最近一次预检结论为 `ready_for_monthly_window`
- 当前主线未存在阻断异常（仓库/运行态可执行）

说明：满足触发事件后，直接执行，不再等待日期窗口。

## 2) 主线执行命令

推荐（事件守卫 + 预检校验 + 演练串联）：

```bash
C2_TRIGGER_EVENT="mainline_ready" bash ./deploy/c2_event_guard.sh
```

兼容入口（已转发到事件守卫）：

```bash
C2_TRIGGER_EVENT="mainline_ready" bash ./deploy/c2_window_guard.sh
```

## 3) C2 关闭判定（全部满足）

- 产生新的月度回归验证记录（非历史复用）
- 记录包含：耗时、失败原因（若有）、修复动作、回切结论
- `BACKLOG.md` / `DECISIONS.md` / `验收清单.md` 已同步回填
- `#4` 已关闭，并立即触发 `#3`

## 4) gstack 专家介入时机（事件触发）

- 触发条件：`#4` 完成关闭 + 新记录落盘 + 台账回填完成
- 触发动作：立即推进 `#3` 复核（不等待固定时间）
- 复核产物：`design/validation/<date>-gstack-gate1-c2-close-review.md`

## 5) 失败与延期处理（事件口径）

- 执行失败：记录失败分类，修复后“事件重触发”立即补跑
- 不再用“窗口错过”概念；仅允许“事件未满足/执行失败”两类状态

## 6) GitHub 跟踪项

- 里程碑：`Gate-1 C2 closeout (event-driven)`
- C2 执行：`https://github.com/Oscarling/openclaw-multi-agent/issues/4`
- C2 关闭复核：`https://github.com/Oscarling/openclaw-multi-agent/issues/3`
