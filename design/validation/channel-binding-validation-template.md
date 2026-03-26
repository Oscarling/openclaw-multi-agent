# Channel Binding Validation 模板

更新时间：2026-03-25  
用途：Gate-2 联调证据记录

## 1) 基本信息

- 联调日期（Asia/Shanghai）：
- channel：
- accountId（如有）：
- 执行人：

## 2) 执行命令

- 绑定命令：
- 查询命令：
- 冒烟命令：

## 3) 结果

- binding 是否生效：
- 默认入口是否漂移：
- 角色列表是否漂移：
- 冒烟 runId（如有）：

## 4) 证据路径

- `agents list --bindings --json`：
- `control-ui-config.json`：
- 冒烟输出：

## 5) 回滚（如触发）

- 触发原因：
- 回滚命令：
- 回滚后验证：

## 6) 结论

- 是否通过 Gate-2 联调前置：是/否
- 是否可进入 gstack Gate-2 评审：是/否

