#!/usr/bin/env bash
set -euo pipefail
umask 077

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

TASK_ID="${TASK_ID:-GOAL-XHS-ASSET-001}"
POST_ID="${POST_ID:-P02}"
OPERATOR="${OPERATOR:-lingguozhong}"
CONTAINER_NAME="${CONTAINER_NAME:-agent_argus}"
PROFILE_URL="${XHS_PROFILE_URL:-https://www.xiaohongshu.com/user/profile/69cb5578000000003402cff4}"
BROWSER="${BROWSER:-webkit}"
HEADLESS="yes"
FORCE_REVIEW="no"
JSON_OUTPUT="no"

usage() {
  cat >&2 <<'EOF'
Usage:
  bash ./scripts/xhs_post_publish_oneclick.sh [options]

Options:
  --task-id <id>         Task id (default: GOAL-XHS-ASSET-001)
  --post-id <id>         Post id (default: P02)
  --operator <name>      Operator (default: lingguozhong)
  --container <name>     Container name (default: agent_argus)
  --profile-url <url>    XHS profile URL for latest note detection
  --browser <name>       chromium | webkit | safari(=webkit), default webkit
  --no-headless          Use headed browser
  --force-review         Run review autocollect immediately (skip 24h gate)
  --json                 Emit json summary
  -h, --help             Show help

Behavior:
  1) Auto register publish_receipt.json (note_id/post_url/publish_time/operator)
  2) If >=24h from publish_time (or --force-review), run review24h autocollect + sync automatically
  3) If <24h, exit with pending-review summary (no manual copy required)
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
    --operator)
      OPERATOR="${2:-}"
      shift 2
      ;;
    --container)
      CONTAINER_NAME="${2:-}"
      shift 2
      ;;
    --profile-url)
      PROFILE_URL="${2:-}"
      shift 2
      ;;
    --browser)
      BROWSER="${2:-}"
      shift 2
      ;;
    --no-headless)
      HEADLESS="no"
      shift
      ;;
    --force-review)
      FORCE_REVIEW="yes"
      shift
      ;;
    --json)
      JSON_OUTPUT="yes"
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

AUTOREG_CMD=(
  node ./scripts/xhs_publish_receipt_autoreg.js
  --task-id "$TASK_ID"
  --post-id "$POST_ID"
  --operator "$OPERATOR"
  --container "$CONTAINER_NAME"
  --profile-url "$PROFILE_URL"
  --browser "$BROWSER"
  --json
)

if [[ "$HEADLESS" == "yes" ]]; then
  AUTOREG_CMD+=(--headless)
fi

AUTOREG_JSON="$("${AUTOREG_CMD[@]}")"
AUTOREG_OK="$(printf '%s' "$AUTOREG_JSON" | node -e 'const fs=require("fs"); const d=JSON.parse(fs.readFileSync(0,"utf8")); process.stdout.write(d.ok ? "yes":"no");')"
if [[ "$AUTOREG_OK" != "yes" ]]; then
  if [[ "$JSON_OUTPUT" == "yes" ]]; then
    printf '%s\n' "$AUTOREG_JSON"
  else
    echo "[xhs-post-oneclick] publish receipt auto-register failed"
    echo "$AUTOREG_JSON"
  fi
  exit 2
fi

CONTAINER_TARGET_DIR="$(printf '%s' "$AUTOREG_JSON" | node -e 'const fs=require("fs"); const d=JSON.parse(fs.readFileSync(0,"utf8")); process.stdout.write(d.container_target_dir || "");')"
if [[ -z "$CONTAINER_TARGET_DIR" ]]; then
  echo "[xhs-post-oneclick] missing container_target_dir in autoreg output" >&2
  exit 2
fi

PUBLISH_RECEIPT_RAW="$(docker exec "$CONTAINER_NAME" sh -lc "cat '$CONTAINER_TARGET_DIR/publish_receipt.json'")"
NOTE_ID="$(printf '%s' "$PUBLISH_RECEIPT_RAW" | node -e 'const fs=require("fs"); const d=JSON.parse(fs.readFileSync(0,"utf8")); process.stdout.write(d.note_id || "");')"
PUBLISH_TIME_UTC="$(printf '%s' "$PUBLISH_RECEIPT_RAW" | node -e 'const fs=require("fs"); const d=JSON.parse(fs.readFileSync(0,"utf8")); process.stdout.write(d.publish_time_utc || "");')"

if [[ -z "$NOTE_ID" || -z "$PUBLISH_TIME_UTC" ]]; then
  echo "[xhs-post-oneclick] publish_receipt missing note_id/publish_time_utc" >&2
  exit 2
fi

GATE_JSON="$(node - <<'NODE' "$PUBLISH_TIME_UTC"
const [,, publishTimeUtc] = process.argv;
const publish = Date.parse(publishTimeUtc);
const now = Date.now();
if (Number.isNaN(publish)) {
  console.log(JSON.stringify({ ok:false, error:"invalid_publish_time_utc", publishTimeUtc }));
  process.exit(2);
}
const elapsedMs = now - publish;
const elapsedHours = elapsedMs / 3600000;
const reviewReady = elapsedHours >= 24;
const dueAtIso = new Date(publish + 24 * 3600000).toISOString();
console.log(JSON.stringify({
  ok: true,
  publishTimeUtc,
  elapsedHours: Number(elapsedHours.toFixed(2)),
  reviewReady,
  dueAtUtc: dueAtIso
}));
NODE
)"

GATE_OK="$(printf '%s' "$GATE_JSON" | node -e 'const fs=require("fs"); const d=JSON.parse(fs.readFileSync(0,"utf8")); process.stdout.write(d.ok ? "yes":"no");')"
if [[ "$GATE_OK" != "yes" ]]; then
  echo "$GATE_JSON" >&2
  exit 2
fi

REVIEW_READY="$(printf '%s' "$GATE_JSON" | node -e 'const fs=require("fs"); const d=JSON.parse(fs.readFileSync(0,"utf8")); process.stdout.write(d.reviewReady ? "yes":"no");')"

if [[ "$REVIEW_READY" != "yes" && "$FORCE_REVIEW" != "yes" ]]; then
  if [[ "$JSON_OUTPUT" == "yes" ]]; then
    node - <<'NODE' "$AUTOREG_JSON" "$GATE_JSON" "$NOTE_ID" "$TASK_ID" "$POST_ID"
const [,, autoregRaw, gateRaw, noteId, taskId, postId] = process.argv;
console.log(JSON.stringify({
  action: "xhs_post_publish_oneclick",
  ok: true,
  stage: "publish_receipt_registered_review_pending",
  taskId,
  postId,
  noteId,
  autoreg: JSON.parse(autoregRaw),
  reviewGate: JSON.parse(gateRaw),
  next: `node ./scripts/xhs_review24h_autocollect.js --task-id ${taskId} --post-id ${postId} --note-id ${noteId} --browser webkit --no-prompt --sync`
}, null, 2));
NODE
  else
    echo "[xhs-post-oneclick] publish receipt registered."
    echo "[xhs-post-oneclick] 24h gate not reached yet, review autocollect skipped."
    echo "$GATE_JSON"
  fi
  exit 0
fi

REVIEW_CMD=(
  node ./scripts/xhs_review24h_autocollect.js
  --task-id "$TASK_ID"
  --post-id "$POST_ID"
  --note-id "$NOTE_ID"
  --operator "$OPERATOR"
  --browser "$BROWSER"
  --no-prompt
  --sync
)

if [[ "$HEADLESS" == "yes" ]]; then
  REVIEW_CMD+=(--headless)
fi

set +e
REVIEW_OUTPUT="$("${REVIEW_CMD[@]}" 2>&1)"
REVIEW_EXIT=$?
set -e

if [[ "$JSON_OUTPUT" == "yes" ]]; then
  node - <<'NODE' "$AUTOREG_JSON" "$GATE_JSON" "$NOTE_ID" "$TASK_ID" "$POST_ID" "$REVIEW_EXIT" "$REVIEW_OUTPUT"
const [,, autoregRaw, gateRaw, noteId, taskId, postId, reviewExit, reviewOutput] = process.argv;
console.log(JSON.stringify({
  action: "xhs_post_publish_oneclick",
  ok: Number(reviewExit) === 0,
  stage: "publish_receipt_registered_review_attempted",
  taskId,
  postId,
  noteId,
  autoreg: JSON.parse(autoregRaw),
  reviewGate: JSON.parse(gateRaw),
  review: {
    exitCode: Number(reviewExit),
    output: reviewOutput
  }
}, null, 2));
NODE
else
  echo "[xhs-post-oneclick] publish receipt registered."
  echo "[xhs-post-oneclick] review24h auto-collect executed (exit=$REVIEW_EXIT)."
  echo "$REVIEW_OUTPUT"
fi

exit "$REVIEW_EXIT"
