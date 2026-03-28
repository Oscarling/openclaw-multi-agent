# 2026-03-28 并行主链 Gate-4 A/B/C 一键复检脚本验证（A26）

## 1) 触发背景

- A25 已验证 Gate-4 A/B/C 严格复检可通过。
- 为提升并行主链执行效率，需要把 A/B/C 三段复检沉淀为“一键执行 + 汇总摘要”能力。

## 2) 变更内容

- 新增脚本：`deploy/parallel_mainline_gate4_abc_recheck.sh`
  - 串行执行 `gate4_stage_a_execute.sh`、`gate4_stage_b_execute.sh`、`gate4_stage_c_execute.sh`
  - 默认开启三段严格模式（`STRICT=yes`）
  - 输出聚合摘要 `artifacts/summary.txt`
  - 三段均通过才返回成功

## 3) 执行命令

```bash
EXEC_ROOT="design/validation/artifacts/openclaw-parallel-mainline-gate4-abc-recheck-runner-test-<ts>" \
GATE4_OPERATOR='lingguozhong' \
bash ./deploy/parallel_mainline_gate4_abc_recheck.sh
```

## 4) 结果摘要

- `stage_a_result=stage_a_passed`
- `stage_b_result=stage_b_passed`
- `stage_c_result=stage_c_passed`
- `overall_result=parallel_gate4_abc_recheck_passed`

## 5) 证据路径

- 聚合摘要：`design/validation/artifacts/openclaw-parallel-mainline-gate4-abc-recheck-runner-test-20260328-202651/artifacts/summary.txt`
- Stage A 摘要：`design/validation/artifacts/openclaw-parallel-mainline-gate4-abc-recheck-runner-test-20260328-202651/stage-a/artifacts/stage-a-summary.txt`
- Stage B 摘要：`design/validation/artifacts/openclaw-parallel-mainline-gate4-abc-recheck-runner-test-20260328-202651/stage-b/artifacts/stage-b-summary.txt`
- Stage C 摘要：`design/validation/artifacts/openclaw-parallel-mainline-gate4-abc-recheck-runner-test-20260328-202651/stage-c/artifacts/stage-c-summary.txt`

## 6) 结论

- 一键复检脚本验证通过，后续并行主链可复用该脚本降低重复操作成本。

