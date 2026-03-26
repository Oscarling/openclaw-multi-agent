# 2026-03-26 Gate-3 prompts.chat 正式评审纪要（plan-eng-review，v1）

日期：2026-03-26  
会议类型：Gate-3 正式工程评审（plan-eng-review）  
会议方式：异步文档会（主持收敛）  
时间记录：2026-03-26 10:20-10:55（Asia/Shanghai）  
范围：仅收口“角色能力吸收 + 验证与回滚机制”；不直接改运行态

## 1) 输入材料

- `design/2026-03-26-gate-3-prompts-chat-role-optimization-pre-assessment-minutes-v1.md`
- `design/2026-03-26-gate-3-prompts-chat-plan-eng-observer-notes-v1.md`
- `design/2026-03-26-gate3-24h-execution-card-v1.md`
- `design/2026-03-26-prompts-chat-role-diff-mapping-v1.md`
- `design/2026-03-26-prompts-chat-golden-regression-checklist-v1.md`
- `design/validation/gate3-c11-min-cases-v1.md`
- `design/validation/gate3-c05-min-cases-v1.md`
- `design/validation/gate3-c13-min-cases-v1.md`
- `design/validation/gate3-regression-run-record-template-v1.md`
- `design/2026-03-26-gate3-v2-routing-and-killswitch-v1.md`

## 2) 评审结论

结论：**Conditional-Go（进入 v2 试运行准备，不进入默认自动命中）**

一句话理由：
低风险项与回滚机制已具备工程可落地基础，但 `C11/C05/C13` 仍需先完成最小验证，不能直接放行到运行态。

专家观察补充（gstack）：

- 工程专家初判：`No-Go`（原因：`T4-T8` 缺失时不具备可放行决策基础）。
- 本轮复核：`T4-T8` 已补齐并落盘后，复判为 `Conditional-Go`。

## 3) 放行项与阻断项

放行到“v2 准备池”的能力：

- `C01/C02/C03/C04/C07/C08/C09/C10/C12/C14`
- `C06`（仅在“禁止虚构事实”硬约束 + `E3/X4` 绑定前提下）

阻断项（不放行到 v2 试运行）：

- `C11/C05/C13`
- 阻断原因：验证样例尚未执行，尚无运行证据。

## 4) 关键工程决定

1. 默认入口不变：`steward` 保持唯一对外入口。  
2. v2 默认不自动命中：仅允许显式命中或受控测试绑定。  
3. 关键项一票否决：`S2/H5/E3/P4/X4` 任一失败即阻断并回滚。  
4. `C11/C05/C13` 的会议讨论仅限“边界与验证方案”，不讨论默认上线。  
5. Kill-Switch 采用三级：路由回切（K1）-> 能力冻结（K2）-> 运行态回退（K3）。

## 5) C11/C05/C13 最小验证门槛（确认版）

### C11（深度调查与证据链）

- 必须输出“证据等级 + 可信度 + 待核实项”三件套。
- 禁止无来源确定性结论。
- 调查类意图路由建议达到 Top-1 >= 95% 或 Top-3 >= 99%。
- 绑定 `H4/H5/X4` 回归。

### C05（重复度/同质化风险提示）

- 定位为“风险提示”，不做法律结论。
- 必带免责声明：“此检查不等同于抄袭检测，不构成法律判断。”
- 必须包含“段落定位 + 风险类型 + 改写建议”。
- 绑定 `E4/E5/X4` 回归。

### C13（人性化改写）

- 必须遵守事实锁定：实体/数字/引用/不确定表达不可漂移。
- 必须输出 `fact_lock_notes`。
- 采用新旧链路对照回归，建议通过率 >= 98%。
- 绑定 `E3/X4` 回归。

## 6) 风险与回滚口径（确认版）

- 安全一票否决：出现高危越权或敏感泄露立即回滚。
- 稳定性阈值：错误率 >= 0.5%（连续 5 分钟）回滚。
- 性能阈值：p95 延迟较基线升高 >= 30%（连续 10 分钟）回滚。
- 成本阈值：单位请求成本升高 >= 50%（连续 30 分钟且无收益证明）回滚。
- 执行入口：`design/2026-03-26-gate3-v2-routing-and-killswitch-v1.md`。

## 7) 会后动作（触发式）

1. 触发条件：正式评审纪要落盘（已满足）  
执行窗口：24-48 小时  
最晚窗口：5 个自然日  
动作：按模板执行一次完整黄金回归并留痕。  
产物：`design/validation/gate3-regression-run-record-template-v1.md`（回填记录）

2. 触发条件：黄金回归关键项全通过（待满足）  
执行窗口：同日或次日  
最晚窗口：3 个自然日  
动作：执行 `C11/C05/C13` 最小样例验证。  
产物：`design/validation/gate3-c11-min-cases-v1.md`、`design/validation/gate3-c05-min-cases-v1.md`、`design/validation/gate3-c13-min-cases-v1.md`（回填记录）

3. 触发条件：关键项与待验证项全部通过（待满足）  
执行窗口：24 小时内  
最晚窗口：2 个自然日  
动作：启动受控 v2 试运行（默认入口不变、默认不自动命中）。  
产物：v2 试运行记录（待创建）

## 8) 结论状态码

- `STATUS=DONE`
- 说明：正式评审与会后验证闭环已完成，待验证池项已完成放行口径收敛。
- 口径区分：
  - 可进入正式评审下一阶段：是
  - 可进入 v2 受控试运行：是（默认入口仍不变，默认不自动命中）

## 9) 会后进展（同日回填）

- 2026-03-26 已执行待验证池最小样例回归：
  - `C05`：通过
  - `C13`：通过
  - `C11`：首轮不通过，修复后复测通过
- 当前阶段结论更新为：
  - `C11/C05/C13` 均可进入 v2 受控试运行候选池
  - 继续维持“默认入口不变、默认不自动命中”
- 证据：
  - `design/validation/2026-03-26-gate3-min-cases-validation.md`
  - `design/validation/2026-03-26-gate3-c11-retest-validation.md`
