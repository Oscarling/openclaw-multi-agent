#!/usr/bin/env bash
set -euo pipefail
umask 077

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

TASK_ID="${TASK_ID:-GOAL-XHS-ASSET-001}"
POST_ID="${POST_ID:-P01}"
NOTE_ID="${NOTE_ID:-69ce60270000000021005d6c}"
OPERATOR="${OPERATOR:-lingguozhong}"
OUT_DIR="${OUT_DIR:-}"

usage() {
  cat >&2 <<'EOF'
Usage:
  bash ./scripts/xhs_review24h_capture.sh [options]

Options:
  --task-id <id>       Task id (default: GOAL-XHS-ASSET-001)
  --post-id <id>       Post id (default: P01)
  --note-id <id>       Note id
  --operator <name>    Operator name
  --out-dir <dir>      Output directory (default: runtime/publish_evidence/review_24h_<ts>)
  -h, --help           Show help

Description:
  Interactive capture for 24h review metrics.
  Outputs a valid JSON file:
    <out-dir>/p01_24h_metrics.json
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --task-id)
      TASK_ID="${2:-}"
      shift 2
      ;;
    --post-id)
      POST_ID="${2:-}"
      shift 2
      ;;
    --note-id)
      NOTE_ID="${2:-}"
      shift 2
      ;;
    --operator)
      OPERATOR="${2:-}"
      shift 2
      ;;
    --out-dir)
      OUT_DIR="${2:-}"
      shift 2
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

if [[ -z "$OUT_DIR" ]]; then
  TS="$(date -u +%Y%m%dT%H%M%SZ)"
  OUT_DIR="runtime/publish_evidence/review_24h_$TS"
fi

local_ts_default="$(date '+%Y-%m-%dT%H:%M:%S%z' | sed -E 's/([+-][0-9]{2})([0-9]{2})$/\1:\2/')"

prompt_non_empty() {
  local var_name="$1"
  local prompt_text="$2"
  local default_val="${3:-}"
  local value=""
  while true; do
    if [[ -n "$default_val" ]]; then
      read -r -p "$prompt_text [$default_val]: " value
      value="${value:-$default_val}"
    else
      read -r -p "$prompt_text: " value
    fi
    value="$(printf '%s' "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    if [[ -n "$value" ]]; then
      printf -v "$var_name" '%s' "$value"
      return 0
    fi
    echo "输入不能为空，请重试。"
  done
}

prompt_uint() {
  local var_name="$1"
  local prompt_text="$2"
  local value=""
  while true; do
    read -r -p "$prompt_text (非负整数): " value
    value="$(printf '%s' "$value" | tr -d '[:space:]')"
    if [[ "$value" =~ ^[0-9]+$ ]]; then
      printf -v "$var_name" '%s' "$value"
      return 0
    fi
    echo "请输入非负整数。"
  done
}

echo "[xhs-review24h-capture] 请按小红书后台数据填写。"
prompt_non_empty SNAPSHOT_TIME "snapshot_time (示例: 2026-04-04T21:05:00+08:00)" "$local_ts_default"

while true; do
  prompt_non_empty NOTE_STATUS "note_status (normal/limited/down/unknown)" "normal"
  if [[ "$NOTE_STATUS" == "normal" || "$NOTE_STATUS" == "limited" || "$NOTE_STATUS" == "down" || "$NOTE_STATUS" == "unknown" ]]; then
    break
  fi
  echo "note_status 只能是 normal/limited/down/unknown。"
done

prompt_uint VIEWS "views"
prompt_uint LIKES "likes"
prompt_uint SAVES "saves"
prompt_uint COMMENTS "comments"
prompt_uint SHARES "shares"
prompt_uint FOLLOWS "follows"
prompt_uint PROFILE_VISITS "profile_visits"
prompt_uint PRIVATE_INQUIRIES "private_inquiries"

prompt_non_empty COMMENT_TOPICS_CSV "comment_topics (逗号分隔，例如 求模板,问步骤)"
prompt_non_empty NEGATIVE_SIGNALS_CSV "negative_signals (逗号分隔；无则输入 none)" "none"

OUT_FILE="$OUT_DIR/p01_24h_metrics.json"
mkdir -p "$OUT_DIR"

node - <<'NODE' \
  "$OUT_FILE" \
  "$TASK_ID" \
  "$POST_ID" \
  "$NOTE_ID" \
  "$SNAPSHOT_TIME" \
  "$NOTE_STATUS" \
  "$VIEWS" \
  "$LIKES" \
  "$SAVES" \
  "$COMMENTS" \
  "$SHARES" \
  "$FOLLOWS" \
  "$PROFILE_VISITS" \
  "$PRIVATE_INQUIRIES" \
  "$COMMENT_TOPICS_CSV" \
  "$NEGATIVE_SIGNALS_CSV" \
  "$OPERATOR"
const fs = require("fs");

const [
  ,
  ,
  outFile,
  taskId,
  postId,
  noteId,
  snapshotTime,
  noteStatus,
  views,
  likes,
  saves,
  comments,
  shares,
  follows,
  profileVisits,
  privateInquiries,
  commentTopicsCsv,
  negativeSignalsCsv,
  operator,
] = process.argv;

function csvToArray(text) {
  return text
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean);
}

const payload = {
  task_id: taskId,
  post_id: postId,
  note_id: noteId,
  snapshot_time: snapshotTime,
  snapshot_mode: "delayed_backfill",
  note_status: noteStatus,
  views: Number.parseInt(views, 10),
  likes: Number.parseInt(likes, 10),
  saves: Number.parseInt(saves, 10),
  comments: Number.parseInt(comments, 10),
  shares: Number.parseInt(shares, 10),
  follows: Number.parseInt(follows, 10),
  profile_visits: Number.parseInt(profileVisits, 10),
  private_inquiries: Number.parseInt(privateInquiries, 10),
  comment_topics: csvToArray(commentTopicsCsv),
  negative_signals: csvToArray(negativeSignalsCsv),
  operator,
};

fs.writeFileSync(outFile, `${JSON.stringify(payload, null, 2)}\n`, "utf8");
NODE

chmod 600 "$OUT_FILE"
echo "[xhs-review24h-capture] done: $OUT_FILE"
