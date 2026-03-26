# 2026-03-26 CLI 安全封装脚本验证记录

更新时间：2026-03-26  
目标：通过脚本护栏避免 `openclaw agent --to ...` 在未显式 `--agent` 时误落 `main`。

## 1) 变更内容

- 新增脚本：`scripts/openclaw_agent_safe.sh`
- 策略：
  - 强制要求显式 `--agent`
  - 当检测到无 `--agent`（尤其含 `--to`）时直接阻断
  - 显式 `--agent` 时透传到容器内 `openclaw agent`

## 2) 验证命令与结果

### 用例 A：无 `--agent`（应阻断）

命令：

```bash
bash ./scripts/openclaw_agent_safe.sh --to telegram:default --message "test without agent"
```

结果：阻断成功（退出码 `2`），并提示显式 `--agent` 为必填。

### 用例 B：显式 `--agent`（应放行并透传）

命令：

```bash
bash ./scripts/openclaw_agent_safe.sh --agent steward --help
```

结果：透传成功，输出 `openclaw agent` 帮助信息，退出码 `0`。

## 3) 结论

- CLI 路由歧义已形成“工具层护栏”：无 `--agent` 的误用会被提前拦截。
- 当前“已知限制”仍存在于底层 CLI 默认行为（未在本仓直接修复），但联调风险已显著降低。
- 后续联调统一入口：优先使用 `scripts/openclaw_agent_safe.sh`。
