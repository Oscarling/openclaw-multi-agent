# OpenClaw Multi-Agent（agent_argus）

这是 OpenClaw A 版的多 Agent 运营中台实验项目，当前只在 `agent_argus` 容器内演进，核心目标是先验证角色分工、路由协作和人工闸门，再逐步扩展自动化能力。

## 当前状态（2026-03-26）

- 运行角色：`main`、`steward`、`hunter`、`editor`、`publisher`
- 默认入口：`steward`
- 链路状态：`steward -> hunter -> editor -> publisher` 已完成端到端验收
- 发布边界：MVP 保留人工闸门，不做自动发帖
- Gate-2 状态：已完成 `steward -> telegram:default` 首轮绑定，通道探活恢复为 `probe.ok=true`

## 目录说明

- `deploy/`：`agent_argus` 的 rollout/rollback 和 override 文件
- `roles/`：角色定义四件套（`IDENTITY.md`、`SOUL.md`、`AGENTS.md`、`TOOLS.md`）
- `shared/`：共享模板与交接契约
- `design/`：讨论纪要、工程收口文档、验证证据、治理文档（风险台账/管理评估）
- `runtime/`：本地运行态（默认不入库）
- `PROJECT_CONTRACT.md`：项目协作契约（Local-First 阶段上传 + 恢复策略）
- `BACKLOG.md` / `DECISIONS.md` / `验收清单.md`：项目推进主线

## 快速开始

1. 准备运行目录

```bash
mkdir -p './runtime/argus/config'
mkdir -p './runtime/argus/agents'
```

2. 准备可写配置文件

```bash
cp "$HOME/.openclaw/docker-openclaw.json" './runtime/argus/config/openclaw.json'
```

3. 使用 override 重建 `agent_argus`

```bash
docker compose \
  -f "$HOME/.openclaw/olympus-deploy.yml" \
  -f './deploy/agent_argus.override.yml' \
  up -d --force-recreate agent_argus sidecar_argus
```

4. 验证默认入口和角色列表

```bash
docker exec agent_argus openclaw agents list --bindings --json
curl -fsSL http://localhost:3001/__openclaw/control-ui-config.json
```

## 升级 `agent_midas`

说明：`agent_midas` 的运行镜像来自宿主机 `$HOME/.openclaw/olympus-deploy.yml`。如果基础 compose 里把镜像 tag 固定在旧版本，仅执行 `up -d --force-recreate` 不会升级。

先看当前版本：

```bash
docker exec agent_midas openclaw --version
```

使用仓库里的升级脚本拉取并重建 `agent_midas`：

```bash
bash ./scripts/upgrade_midas.sh
```

脚本默认会从当前 `agent_midas` 容器里查询 `npm` 上的 `openclaw latest`，然后叠加 `deploy/agent_midas.override.yml` 覆盖镜像并执行 `pull + recreate`。

如果要明确指定版本，可直接传 `MIDAS_TAG`：

```bash
MIDAS_TAG=2026.3.31 bash ./scripts/upgrade_midas.sh
```

也支持显式参数：

```bash
bash ./scripts/upgrade_midas.sh --tag 2026.3.31
bash ./scripts/upgrade_midas.sh --dry-run
bash ./scripts/upgrade_midas.sh --json
```

如果你在容器里直接执行：

```bash
docker exec agent_midas openclaw update status --json
```

偶尔看到：

```text
AbortError: This operation was aborted
```

这通常不是版本损坏，而是 `openclaw update status` 默认给 npm registry 检查的超时只有约 3.5 秒；在当前 `agent_midas` 容器环境里，`https://registry.npmjs.org/openclaw/latest` 的首包有时会超过这个阈值。

建议改用：

```bash
docker exec agent_midas openclaw update status --timeout 10 --json
```

当前环境下，`--timeout 10` 已验证可正常返回 `latestVersion`。

如果想把镜像、运行版本和 update status 一次看全，可直接运行：

```bash
bash ./scripts/midas_status.sh
bash ./scripts/midas_status.sh --json
```

如果想量化当前容器访问 npm registry 的时延波动，可运行：

```bash
bash ./scripts/midas_registry_probe.sh --samples 5
```

完整优化说明见：

- `design/2026-04-01-midas-upgrade-timeout-optimization-note.md`

## 修复 `agent_athena`

说明：`agent_athena` 在宿主机基础 compose 中当前仍指向 `openclaw-control-ui13:2026.3.12`。仓库里新增了 `deploy/agent_athena.override.yml`，用于用官方镜像覆盖基础 compose。

查看 `athena` 当前状态：

```bash
bash ./scripts/athena_status.sh
bash ./scripts/athena_status.sh --json
```

按标准路径启动或重建 `athena`：

```bash
bash ./scripts/start_athena.sh
bash ./scripts/start_athena.sh --dry-run
```

说明：该入口会默认套用 `deploy/agent_athena.override.yml`，并优先读取 `~/.openclaw/state/athena/desired-image.txt` 里的期望镜像，避免 `docker compose up -d --force-recreate` 又回到基础 compose 的旧镜像。

预览升级/拉起动作：

```bash
bash ./scripts/upgrade_athena.sh --dry-run
```

执行升级或首次拉起：

```bash
bash ./scripts/upgrade_athena.sh
bash ./scripts/upgrade_athena.sh --tag 2026.3.31
```

执行成功后，脚本会把当前目标镜像写入 `~/.openclaw/state/athena/desired-image.txt`，供后续 `start_athena.sh` 复用。

如果你想在 macOS 里直接点一下执行宿主机升级，可使用：

```bash
bash ./scripts/upgrade_athena.command
```

探测 `athena` 容器访问 registry 的时延波动：

```bash
bash ./scripts/athena_registry_probe.sh --samples 5
```

## 联调约定

- CLI 联调必须显式带 `--agent <id>`，不要用“只带 `--to`”的方式判断默认入口
- 推荐使用安全封装：`bash ./scripts/openclaw_agent_safe.sh --agent <id> ...`
- 路由复检探针：`bash ./deploy/cli_route_parity_probe.sh`
- UI 验收以 `control-ui-config.json` 的 `assistantAgentId` 为准
- 当前已启用 `telegram` channel 插件并完成显式绑定（`steward -> telegram:default`）
- Gate-2 探针当前状态：`ready_for_binding_test`
- 当前通道探活状态：`channels status --probe -> probe.ok=true`
- 下一步：补 1 次真实入站/回包冒烟后，触发 gstack Gate-2 专项评审
- 若 token 发生暴露，必须先在 `@BotFather` 轮换（`/revoke` + `/token`）再继续联调

## XHS Host Bridge（自动填充，发布前停住）

说明：该流程用于“本机网页自动填充”，并且强制停在发布按钮前，最终发布必须人工点击。

1. 安装依赖（首次一次）

```bash
cd "/Users/lingguozhong/Codex工作室/openclaw multi -agent"
npm install playwright
```

2. 从 `agent_argus` 拉取 `publish_job.json` 到本地

```bash
bash ./scripts/xhs_pull_publish_job.sh
```

说明：该脚本会同时拉取图片素材，并把 `publish_job.json` 里的 `material_dir` 自动改写为本机可访问路径。

3. 运行 host bridge 自动填充（不会自动发布）

```bash
node ./scripts/xhs_host_bridge_fill.js \
  --job ./runtime/host_bridge_jobs/<timestamp>/publish_job.json \
  --entry-url "https://www.xiaohongshu.com/user/profile/69cb5578000000003402cff4"
```

也可用环境变量固定入口地址（后续命令无需重复传参）：

```bash
export XHS_BRIDGE_ENTRY_URL="https://www.xiaohongshu.com/user/profile/69cb5578000000003402cff4"
```

若你希望走 Safari 引擎渲染（Playwright WebKit）：

```bash
npx playwright install webkit
node ./scripts/xhs_host_bridge_fill.js \
  --job ./runtime/host_bridge_jobs/<timestamp>/publish_job.json \
  --entry-url "https://creator.xiaohongshu.com/publish/publish?source=official" \
  --browser webkit \
  --keep-open
```

也可以直接用一键脚本（推荐，避免每次手敲长命令）：

```bash
bash ./scripts/xhs_bridge_run.sh
```

说明：`xhs_bridge_run.sh` 现在会先执行 `publish_job` 契约校验（`scripts/xhs_publish_job_guard.js`），
若发现占位符、缺字段、文件缺失、未停在发布闸门等问题，会自动阻断，不再继续填充发布页。

常用变体：

```bash
# 先从容器拉取最新 publish_job，再自动填充
bash ./scripts/xhs_bridge_run.sh --pull-job

# 指定 Chromium
bash ./scripts/xhs_bridge_run.sh --browser chromium

# 不保持浏览器常开（执行结束自动关闭）
bash ./scripts/xhs_bridge_run.sh --no-keep-open
```

如果入口是个人主页，脚本会在找不到上传控件时提示你手动切到“图文发布页”，按回车后自动继续重试。
若仍找不到，脚本会自动尝试 fallback 发布页：`https://creator.xiaohongshu.com/publish/publish`，再进行一轮重试。
如需避免自动关闭浏览器，可加 `--keep-open`，完成人工操作后输入 `CLOSE` 再关闭。

### XHS 防跑偏闸门（自动）

为减少人工监督，新增“Argus 发布包防呆闸门”：

```bash
bash ./scripts/xhs_argus_prep_gate.sh --task-id GOAL-XHS-ASSET-001 --post-id P02 --json
```

该脚本会自动执行：

1. 从 `agent_argus` 容器里找指定 `task_id/post_id` 的最新 `publish_job.json`
2. 拉到本机并同步素材图
3. 执行严格契约校验（字段/占位符/文件存在/闸门语义）
4. 通过则给出下一步 host bridge 命令
5. 不通过则自动生成 `retry_prompt_for_argus.txt`，用于一键回发 Argus 修复

常用配套命令：

```bash
# 只校验某个本地 publish_job
node ./scripts/xhs_publish_job_guard.js --job ./runtime/host_bridge_jobs/<ts>/publish_job.json --json

# 闸门通过后再跑 bridge
bash ./scripts/xhs_bridge_run.sh
```

执行结果会输出：

- 填充停住截图：`runtime/host_bridge_runs/<timestamp>/stop_before_publish.png`
- 首评缓存：`runtime/host_bridge_runs/<timestamp>/first_comment.txt`
- 运行回执：`runtime/host_bridge_runs/<timestamp>/bridge_report.json`

安全边界：

- 脚本不会点击发布按钮
- `stop_before_publish` 不是 `true` 时会直接阻断
- 只能在你人工确认后，手动完成最终发布

### 发布回执自动登记（减少人工）

发布成功后，可用下面一条命令自动完成 `publish_receipt.json` 登记（自动抓最新笔记链接与 note_id）：

```bash
node ./scripts/xhs_publish_receipt_autoreg.js \
  --task-id GOAL-XHS-ASSET-001 \
  --post-id P02 \
  --operator lingguozhong \
  --browser webkit \
  --json
```

默认行为：

1. 从 `agent_argus` 容器读取该任务/篇次最新 `publish_job.json`
2. 打开你的小红书个人主页，自动识别最新 `/explore/<note_id>` 链接
3. 生成 `publish_receipt.json` 并回写到容器目标目录
4. 输出登记回执报告，供后续 24h 复盘使用

可选环境变量（个人主页地址）：

```bash
export XHS_PROFILE_URL="https://www.xiaohongshu.com/user/profile/69cb5578000000003402cff4"
```

## XHS 24h 复盘防再发（证据同步）

问题背景：Argus 容器默认无法直接读取主机路径（如 `/Users/.../runtime/publish_evidence/...`），会导致“证据不可访问 -> 复盘 Halt”。

建议在每次 24h 复盘前，先执行“采集 -> 同步”两步：

```bash
# 第一步：交互式采集真实指标，生成合法 JSON（避免占位符）
bash ./scripts/xhs_review24h_capture.sh
```

```bash
# 第二步：同步到 Argus 容器可读路径
bash ./scripts/xhs_review24h_sync.sh
```

说明：`xhs_review24h_sync.sh` 对输入做严格校验，若存在占位符/模板值/非法 JSON 会直接阻断并报错。

如果你希望尽量减少人工输入，可使用自动采集脚本（推荐）：

```bash
node ./scripts/xhs_review24h_autocollect.js --sync
```

自动采集脚本会：

- 复用 Host Bridge 浏览器登录态
- 在你切到“目标笔记数据页”后自动提取：
  - `views / likes / saves / comments / shares / follows / profile_visits / private_inquiries / note_status`
- 自动生成合法 `p01_24h_metrics.json`
- 可直接触发 `xhs_review24h_sync.sh` 完成容器侧同步（`--sync`）

无交互模式（适合自动化流水线）：

```bash
node ./scripts/xhs_review24h_autocollect.js --note-id <NOTE_ID> --no-prompt --sync --headless
```

说明：`comment_topics` 与 `negative_signals` 的语义判断目前仍建议人工复核；自动采集默认写入保守占位语义值，不影响你列出的九个核心数值字段采集。

默认行为：

- 自动选择最新 `runtime/publish_evidence/review_24h_*/p01_24h_metrics.json`
- 同步 `runtime/publish_evidence/latest/` 下三项证据到 Argus 容器：
  - `bridge_report.json`
  - `stop_before_publish.png`
  - `source_map.txt`
- 写入容器路径：
  - `/root/.openclaw/workspace/steward/outputs/GOAL-XHS-ASSET-001/P01/20260401T001853Z/`
- 自动校验文件是否到位并落盘日志：
  - `runtime/publish_evidence/review_sync_logs/review_sync_<ts>.txt`

常用参数：

```bash
bash ./scripts/xhs_review24h_sync.sh --review-json /abs/path/p01_24h_metrics.json
bash ./scripts/xhs_review24h_sync.sh --task-id GOAL-XHS-ASSET-001 --post-id P01 --output-ts 20260401T001853Z
bash ./scripts/xhs_review24h_sync.sh --json
```

建议执行顺序（固定）：

1. 运行 `xhs_review24h_capture.sh` 采集真实指标（生成合法 `p01_24h_metrics.json`）
2. 运行 `xhs_review24h_sync.sh` 同步并校验
3. 再让 Argus 执行 24h 只读复盘

## 发布后“一键自动登记 + 24h自动采集”流水线

如果你希望尽量减少人工步骤（仅保留发布按钮人工确认），可使用：

```bash
bash ./scripts/xhs_post_publish_oneclick.sh \
  --task-id GOAL-XHS-ASSET-001 \
  --post-id P02 \
  --operator lingguozhong \
  --browser webkit \
  --json
```

该脚本自动做：

1. 自动登记 `publish_receipt.json`（自动识别最新 `note_id/post_url`）
2. 自动判断是否到达 24h 复盘窗口
3. 若已到 24h（或传 `--force-review`），自动执行 `xhs_review24h_autocollect --no-prompt --sync`
4. 若未到 24h，返回 `review_pending` 与下一次可执行提示，不需要你手工整理字段

常用参数：

```bash
# 未到24h也强制执行一次复盘采集（补录场景）
bash ./scripts/xhs_post_publish_oneclick.sh --post-id P02 --force-review --json

# 如果要观察浏览器界面（非 headless）
bash ./scripts/xhs_post_publish_oneclick.sh --post-id P02 --no-headless --json
```

## 恢复与备份

- GitHub 恢复说明见 `RECOVERY.md`
- `runtime/` 相关状态与 secrets 不直接入库，后续按 backlog 的备份方案补齐
- 可执行恢复演练脚本：`deploy/recovery_drill.sh`
- 月度回归一键脚本：`deploy/monthly_recovery_drill.sh`
- 月度演练预检脚本：`deploy/monthly_recovery_preflight.sh`
- Gate-2 可用性探针：`deploy/gate2_readiness_probe.sh`
- 周度治理模板：`shared/templates/weekly_governance_review_template.md`
- 备份/恢复脚本（v0）：`scripts/backup_state.sh`、`scripts/restore_state.sh`
- 当前加密口径：`openssl(AES-256-CBC + PBKDF2) + manifest sha256`

## 新机器恢复（5 步）

说明：下面是“从 GitHub 拉起可用环境”的最短路径。更完整的异常场景与覆盖恢复请看 `RECOVERY.md`。

1. 拉代码

```bash
git clone https://github.com/Oscarling/openclaw-multi-agent.git
cd "openclaw-multi-agent"
```

2. 准备运行目录与本地配置

```bash
mkdir -p './runtime/argus/config' './runtime/argus/agents' './runtime/argus/config/secrets'
cp "$HOME/.openclaw/docker-openclaw.json" './runtime/argus/config/openclaw.json'
```

3. 写入 Telegram token（仅本机，不入库）

```bash
read -rs NEW_TELEGRAM_BOT_TOKEN
echo
printf '%s' "$NEW_TELEGRAM_BOT_TOKEN" > './runtime/argus/config/secrets/telegram_bot_token.txt'
chmod 600 './runtime/argus/config/secrets/telegram_bot_token.txt'
unset NEW_TELEGRAM_BOT_TOKEN
```

4. 重建容器

```bash
docker compose \
  -f "$HOME/.openclaw/olympus-deploy.yml" \
  -f './deploy/agent_argus.override.yml' \
  up -d --force-recreate agent_argus sidecar_argus
```

5. 验证入口、绑定与通道健康

```bash
docker exec agent_argus openclaw agents list --bindings --json
docker exec agent_argus openclaw channels status --json --probe
curl -fsSL http://localhost:3001/__openclaw/control-ui-config.json
```

## GitHub 协作基线（当前仓库）

- 仓库：`PUBLIC`（`Oscarling/openclaw-multi-agent`）
- 合并策略：仅允许 `squash merge`
- 已关闭：`merge commit`、`rebase merge`
- 自动清理：PR 合并后自动删除分支
- `main` 分支保护（已启用）：
  - 单人维护模式：`required_approving_review_count=0`
  - 会话必须 resolved
  - 线性历史（`required_linear_history=true`）
  - 禁止 force-push / 删除分支
  - 管理员同样受保护（`enforce_admins=true`）
- 后续建议：当有第二位协作者加入时，把 `required_approving_review_count` 调回 `1`
- 公开仓库提醒：公开期间代码可能被检索与 fork；如后续改回私有，公开期传播内容不保证可逆收回

## 提速模式（本地优先，分段上云）

- 主线推进默认先在本地连续收口，不要求每个小步骤都立刻 push
- 上云触发采用事件制，不按时间点：
  - 一个主线事件收口（例如一次 R 批处理完成）
  - 一个风险项收口（例如安全/路由修复完成）
  - 一个可回滚检查点形成（代码+证据+台账已对齐）
- 触发后再统一执行 `push + PR`，继续保持 `PR + squash + 分支保护` 门禁
- 执行细则见：`design/2026-03-26-local-first-staged-github-sync-v1.md`
