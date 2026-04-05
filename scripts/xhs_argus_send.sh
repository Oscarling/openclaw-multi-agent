#!/usr/bin/env bash
set -euo pipefail
umask 077

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

MODE=""
TASK_ID="${TASK_ID:-GOAL-XHS-ASSET-001}"
POST_ID="${POST_ID:-P02}"
AGENT_ID="${AGENT_ID:-steward}"
THINKING="${THINKING:-medium}"
TIMEOUT="${TIMEOUT:-600}"
JSON_OUTPUT="no"
DRY_RUN="no"
EXTRA_HINT=""

usage() {
  cat >&2 <<'EOF'
Usage:
  bash ./scripts/xhs_argus_send.sh --mode <name> [options]

Modes:
  prep_strict      Ask Argus to generate strict publish package for Host Bridge
  review_retry     Ask Argus to run 24h review retry using container evidence

Options:
  --task-id <id>      default GOAL-XHS-ASSET-001
  --post-id <id>      default P02
  --agent <id>        default steward
  --thinking <level>  off|minimal|low|medium|high (default medium)
  --timeout <sec>     default 600
  --extra-hint <txt>  append one extra line to prompt
  --json              pass --json to openclaw agent
  --dry-run           print prompt only, do not send
  -h, --help          show help

Examples:
  bash ./scripts/xhs_argus_send.sh --mode prep_strict --post-id P02
  bash ./scripts/xhs_argus_send.sh --mode review_retry --post-id P02 --json
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      MODE="${2:-}"
      shift 2
      ;;
    --task-id)
      TASK_ID="${2:-}"
      shift 2
      ;;
    --post-id)
      POST_ID="${2:-}"
      shift 2
      ;;
    --agent)
      AGENT_ID="${2:-}"
      shift 2
      ;;
    --thinking)
      THINKING="${2:-}"
      shift 2
      ;;
    --timeout)
      TIMEOUT="${2:-}"
      shift 2
      ;;
    --extra-hint)
      EXTRA_HINT="${2:-}"
      shift 2
      ;;
    --json)
      JSON_OUTPUT="yes"
      shift
      ;;
    --dry-run)
      DRY_RUN="yes"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "unknown argument: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if [[ -z "$MODE" ]]; then
  echo "--mode is required" >&2
  usage
  exit 2
fi

build_prompt() {
  local mode="$1"
  case "$mode" in
    prep_strict)
      cat <<EOF
进入 ${TASK_ID}_${POST_ID}_PREP_STRICT 模式（强约束，不聊天）：

目标：
输出可执行发布包并生成 publish_job.json，结论只能是 READY_FOR_BRIDGE 或 BLOCKED。

强约束：
- 不要追问，不要多轮收集
- 不展示内部工具日志
- 缺字段时只允许一次性给缺失清单；可默认则直接默认
- 只输出最终结果

必须交付字段：
1) final_title（含 A/B 备选 + 推荐）
2) body_text
3) hashtags（6-8个）
4) first_comment
5) cover_file
6) image_files（最终顺序）
7) material_dir（绝对路径）
8) stop_before_publish=true
9) operator_checklist（到发布按钮前）
10) evidence_ref 占位字段
11) publish_job.json 绝对路径
12) 唯一结论 READY_FOR_BRIDGE/BLOCKED

边界：
- 不自动点击发布
- 不假设已发布成功
- 不扩容、不改阈值、不关闭 RH-T5-B01
EOF
      ;;
    review_retry)
      cat <<EOF
进入 ${TASK_ID}_${POST_ID}_24H_REVIEW_RETRY 模式（只读复盘）：

请仅基于容器内证据文件执行复盘，并输出唯一结论 Continue/Halt。
要求：
- 不改文件，不触发发布
- 逐项引用字段原值（发布事实、闸门事实、24h 字段）
- 明确 delayed_backfill 口径
- 输出风险边界：不扩容 / 不改阈值 / 不关闭 RH-T5-B01
- 若 Halt，必须给出触发字段名 + 原值
EOF
      ;;
    *)
      echo "unsupported mode: $mode" >&2
      exit 2
      ;;
  esac
}

PROMPT="$(build_prompt "$MODE")"
if [[ -n "$EXTRA_HINT" ]]; then
  PROMPT="${PROMPT}"$'\n'"${EXTRA_HINT}"
fi

if [[ "$DRY_RUN" == "yes" ]]; then
  echo "$PROMPT"
  exit 0
fi

CMD=(
  bash ./scripts/openclaw_agent_safe.sh
  --agent "$AGENT_ID"
  --thinking "$THINKING"
  --timeout "$TIMEOUT"
  --message "$PROMPT"
)

if [[ "$JSON_OUTPUT" == "yes" ]]; then
  CMD+=(--json)
fi

"${CMD[@]}"
