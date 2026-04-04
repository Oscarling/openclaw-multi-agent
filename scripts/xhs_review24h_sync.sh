#!/usr/bin/env bash
set -euo pipefail
umask 077

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

CONTAINER_NAME="${CONTAINER_NAME:-agent_argus}"
TASK_ID="${TASK_ID:-GOAL-XHS-ASSET-001}"
POST_ID="${POST_ID:-P01}"
OUTPUT_TS="${OUTPUT_TS:-20260401T001853Z}"
HOST_EVIDENCE_DIR="${HOST_EVIDENCE_DIR:-runtime/publish_evidence/latest}"
REVIEW_JSON="${REVIEW_JSON:-}"
JSON_OUTPUT="${JSON_OUTPUT:-no}"

usage() {
  cat >&2 <<'EOF'
Usage:
  bash ./scripts/xhs_review24h_sync.sh [options]

Options:
  --container <name>         Container name (default: agent_argus)
  --task-id <id>             Task id (default: GOAL-XHS-ASSET-001)
  --post-id <id>             Post id (default: P01)
  --output-ts <timestamp>    Output ts under steward outputs (default: 20260401T001853Z)
  --review-json <path>       Local 24h review input json path
  --host-evidence-dir <dir>  Host evidence dir with bridge_report/source_map/screenshot
  --json                     Emit json summary
  -h, --help                 Show help

Notes:
  1) If --review-json is omitted, script auto-picks newest:
       runtime/publish_evidence/review_24h_*/p01_24h_metrics.json
  2) This script only syncs files for Argus to read; it does not trigger publish.
  3) review json is strictly validated; placeholder/template values are rejected.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --container)
      CONTAINER_NAME="${2:-}"
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
    --output-ts)
      OUTPUT_TS="${2:-}"
      shift 2
      ;;
    --review-json)
      REVIEW_JSON="${2:-}"
      shift 2
      ;;
    --host-evidence-dir)
      HOST_EVIDENCE_DIR="${2:-}"
      shift 2
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

if [[ -z "$REVIEW_JSON" ]]; then
  REVIEW_JSON="$(ls -1dt runtime/publish_evidence/review_24h_*/p01_24h_metrics.json 2>/dev/null | head -n 1 || true)"
fi

if [[ -z "$REVIEW_JSON" ]]; then
  echo "[xhs-review24h-sync] review json not found. Provide --review-json." >&2
  exit 1
fi

if [[ ! -f "$REVIEW_JSON" ]]; then
  echo "[xhs-review24h-sync] review json file not found: $REVIEW_JSON" >&2
  exit 1
fi

VALIDATION_RESULT="$(
  node - <<'NODE' "$REVIEW_JSON" "$TASK_ID" "$POST_ID"
const fs = require("fs");

const [,, filePath, taskId, postId] = process.argv;
let raw = "";
let parsed = null;
const errors = [];
const warnings = [];

function addError(msg) {
  errors.push(msg);
}

function hasPlaceholder(v) {
  return typeof v === "string" && /<[^>]*>/.test(v);
}

try {
  raw = fs.readFileSync(filePath, "utf8");
} catch (err) {
  addError(`read_failed:${err.message}`);
}

if (!errors.length) {
  try {
    parsed = JSON.parse(raw);
  } catch (err) {
    addError(`invalid_json:${err.message}`);
  }
}

if (!errors.length) {
  if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
    addError("root_not_object");
  }
}

if (!errors.length) {
  const requiredStrings = [
    "task_id",
    "post_id",
    "note_id",
    "snapshot_time",
    "snapshot_mode",
    "note_status",
    "operator",
  ];
  const requiredNumbers = [
    "views",
    "likes",
    "saves",
    "comments",
    "shares",
    "follows",
    "profile_visits",
    "private_inquiries",
  ];
  const requiredArrays = ["comment_topics", "negative_signals"];

  for (const key of requiredStrings) {
    const value = parsed[key];
    if (typeof value !== "string" || !value.trim()) {
      addError(`missing_or_empty_string:${key}`);
      continue;
    }
    if (hasPlaceholder(value)) {
      addError(`placeholder_string:${key}`);
    }
  }

  for (const key of requiredNumbers) {
    const value = parsed[key];
    if (typeof value !== "number" || !Number.isFinite(value)) {
      addError(`invalid_number:${key}`);
      continue;
    }
    if (value < 0) {
      addError(`negative_number:${key}`);
    }
  }

  for (const key of requiredArrays) {
    const value = parsed[key];
    if (!Array.isArray(value) || value.length === 0) {
      addError(`invalid_array:${key}`);
      continue;
    }
    for (let i = 0; i < value.length; i += 1) {
      const item = value[i];
      if (typeof item !== "string" || !item.trim()) {
        addError(`invalid_array_item:${key}[${i}]`);
        continue;
      }
      if (hasPlaceholder(item)) {
        addError(`placeholder_array_item:${key}[${i}]`);
      }
    }
  }

  if (parsed.task_id !== taskId) {
    addError(`task_id_mismatch:expected=${taskId},actual=${parsed.task_id}`);
  }
  if (parsed.post_id !== postId) {
    addError(`post_id_mismatch:expected=${postId},actual=${parsed.post_id}`);
  }

  const allowedStatus = new Set(["normal", "limited", "down", "unknown"]);
  if (!allowedStatus.has(parsed.note_status)) {
    addError(`invalid_note_status:${parsed.note_status}`);
  }

  if (Number.isNaN(Date.parse(parsed.snapshot_time))) {
    addError(`invalid_snapshot_time:${parsed.snapshot_time}`);
  }

  if (typeof parsed.snapshot_mode === "string" && parsed.snapshot_mode !== "delayed_backfill") {
    warnings.push(`snapshot_mode_nonstandard:${parsed.snapshot_mode}`);
  }
}

const output = {
  ok: errors.length === 0,
  errors,
  warnings,
};

process.stdout.write(JSON.stringify(output));
if (errors.length > 0) {
  process.exit(3);
}
NODE
)" || true

VALIDATION_OK="$(printf '%s' "$VALIDATION_RESULT" | node -e 'const fs=require("fs"); const data=JSON.parse(fs.readFileSync(0,"utf8")); process.stdout.write(data.ok ? "yes":"no");')"
if [[ "$VALIDATION_OK" != "yes" ]]; then
  echo "[xhs-review24h-sync] review json validation failed: $REVIEW_JSON" >&2
  printf '%s\n' "$VALIDATION_RESULT" >&2
  echo "[xhs-review24h-sync] 请先把占位符替换为真实值（尤其 snapshot_time/note_status/数值字段）。" >&2
  exit 1
fi

BRIDGE_REPORT="$HOST_EVIDENCE_DIR/bridge_report.json"
STOP_SCREENSHOT="$HOST_EVIDENCE_DIR/stop_before_publish.png"
SOURCE_MAP="$HOST_EVIDENCE_DIR/source_map.txt"

for f in "$BRIDGE_REPORT" "$STOP_SCREENSHOT" "$SOURCE_MAP"; do
  if [[ ! -f "$f" ]]; then
    echo "[xhs-review24h-sync] missing host evidence file: $f" >&2
    exit 1
  fi
done

TARGET_DIR="/root/.openclaw/workspace/steward/outputs/$TASK_ID/$POST_ID/$OUTPUT_TS"
RUN_TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG_DIR="runtime/publish_evidence/review_sync_logs"
LOG_FILE="$LOG_DIR/review_sync_$RUN_TS.txt"
mkdir -p "$LOG_DIR"

docker exec "$CONTAINER_NAME" sh -lc "mkdir -p '$TARGET_DIR'"

docker cp "$REVIEW_JSON" "$CONTAINER_NAME:$TARGET_DIR/review_24h_input.json"
docker cp "$BRIDGE_REPORT" "$CONTAINER_NAME:$TARGET_DIR/host_bridge_report.json"
docker cp "$STOP_SCREENSHOT" "$CONTAINER_NAME:$TARGET_DIR/host_stop_before_publish.png"
docker cp "$SOURCE_MAP" "$CONTAINER_NAME:$TARGET_DIR/host_source_map.txt"

EXISTS_CHECK="$(docker exec "$CONTAINER_NAME" sh -lc "for f in \
  '$TARGET_DIR/review_24h_input.json' \
  '$TARGET_DIR/host_bridge_report.json' \
  '$TARGET_DIR/host_stop_before_publish.png' \
  '$TARGET_DIR/host_source_map.txt'; do \
    if [ -f \"\$f\" ]; then echo \"\$f=ok\"; else echo \"\$f=missing\"; fi; \
  done")"

cat > "$LOG_FILE" <<EOF
timestamp_utc=$RUN_TS
container_name=$CONTAINER_NAME
task_id=$TASK_ID
post_id=$POST_ID
output_ts=$OUTPUT_TS
target_dir=$TARGET_DIR
review_json_source=$REVIEW_JSON
review_json_validation=$VALIDATION_RESULT
host_bridge_report_source=$BRIDGE_REPORT
host_stop_screenshot_source=$STOP_SCREENSHOT
host_source_map_source=$SOURCE_MAP
$EXISTS_CHECK
EOF

if [[ "$JSON_OUTPUT" == "yes" ]]; then
  node - <<'NODE' \
    "$CONTAINER_NAME" \
    "$TASK_ID" \
    "$POST_ID" \
    "$OUTPUT_TS" \
    "$TARGET_DIR" \
    "$REVIEW_JSON" \
    "$VALIDATION_RESULT" \
    "$BRIDGE_REPORT" \
    "$STOP_SCREENSHOT" \
    "$SOURCE_MAP" \
    "$LOG_FILE" \
    "$EXISTS_CHECK"
const [
  ,
  ,
  containerName,
  taskId,
  postId,
  outputTs,
  targetDir,
  reviewJson,
  validationResultRaw,
  bridgeReport,
  stopScreenshot,
  sourceMap,
  logFile,
  existsCheck,
] = process.argv;

const check = Object.fromEntries(
  existsCheck
    .split("\n")
    .filter(Boolean)
    .map((line) => {
      const [k, v] = line.split("=");
      return [k, v];
    })
);
const validationResult = JSON.parse(validationResultRaw);

console.log(
  JSON.stringify(
    {
      action: "xhs_review24h_sync",
      containerName,
      taskId,
      postId,
      outputTs,
      targetDir,
      sources: {
        reviewJson,
        bridgeReport,
        stopScreenshot,
        sourceMap,
      },
      validationResult,
      check,
      logFile,
    },
    null,
    2
  )
);
NODE
else
  echo "[xhs-review24h-sync] synced to: $TARGET_DIR"
  echo "$EXISTS_CHECK"
  echo "[xhs-review24h-sync] log: $LOG_FILE"
fi
