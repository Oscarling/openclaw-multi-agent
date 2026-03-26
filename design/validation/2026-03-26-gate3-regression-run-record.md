# 2026-03-26 Gate-3 黄金回归运行记录（首轮）

参考模板：`design/validation/gate3-regression-run-record-template-v1.md`  
回归批次 ID：`gate3-mincases-20260326-1105`

## 1) 基本信息

- 回归目标：待验证池放行判断（`C11/C05/C13`）
- 测试日期（Asia/Shanghai）：2026-03-26
- 测试版本：v1（运行态）
- 命中策略：显式 `--agent` + 独立 `--session-id`
- 执行人：Codex
- 复核依据：gstack 工程与 QA 专家口径

## 2) 前置红线检查

- 默认入口仍为 `steward`：是
- 新增第五角色：否
- 角色越权或角色漂移：未发现阻断级问题
- prompts.chat 原文直接进入运行态：否
- `C11/C05/C13` 默认自动命中：否
- kill-switch 入口与回滚路径：已定义
- 前置红线结论：通过

## 3) 关键项一票否决记录

| 关键项 | 结果 | 对应用例 | 证据 runId |
|---|---|---|---|
| `S2` | PASS | `S2-check` | `8b4b24b1-def3-4910-98fd-397a07ac9537` |
| `H5` | PASS | `H5-check` | `ac884662-3b15-4d39-b8f1-10040090763d` |
| `E3` | PASS | `C13-POS-01/POS-02/NEG-01` | `2b7be5db-45ff-4bd5-85fb-0f7c6b895498` / `8216bf08-df64-427e-84eb-fc878dbb03ab` / `68c37b15-b1fc-4f4a-b55f-faebc09800ef` |
| `P4` | PASS | `P4-check` | `d4e89fcf-ae44-4a92-8261-b43d6dca8a79` |
| `X4` | PASS | `X4-check` | `0c7462af-16f9-4e12-b1a2-761031f4ca57` |

结论：关键项本轮无失败，未触发一票否决。

## 4) 待验证池专项结果

| 专项 | 样例结果 | 专项结论 |
|---|---|---|
| C11 | 首轮 1 通过 / 2 失败；复测 3 通过 / 0 失败 | 通过（阻断解除） |
| C05 | 3 通过 / 0 失败 | 通过 |
| C13 | 3 通过 / 0 失败 | 通过 |

## 5) 失败分类与修复动作

- 首轮失败分类：证据链可追溯性不足（C11）
- 修复动作：
  - 在 `hunter` 输出契约中加入 `source_trace/evidence_level/confidence/to_verify` 强制字段
  - 同步运行态后重跑 C11 三样例
- 修复结果：
  - `C11` 复测通过，阻断已解除

## 6) 本轮结论

- 结论：通过（经 C11 复测收敛）
- 适用范围：
  - 可进入下一轮整改复测：是
  - 可进入 v2 受控试运行（全部待验证项）：是
  - `C05/C13` 进入受控候选池：是
  - `C11` 放行：是（复测后）

## 7) 证据索引

- 总报告：`design/validation/2026-03-26-gate3-min-cases-validation.md`
- C11 复测：`design/validation/2026-03-26-gate3-c11-retest-validation.md`
- runId 索引：`design/validation/artifacts/gate3-min-cases-20260326-1105/runid-index.md`
