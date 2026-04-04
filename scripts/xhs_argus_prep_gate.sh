#!/usr/bin/env bash
set -euo pipefail
umask 077

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

CONTAINER_NAME="${CONTAINER_NAME:-agent_argus}"
TASK_ID="${TASK_ID:-GOAL-XHS-ASSET-001}"
POST_ID="${POST_ID:-P01}"
JSON_OUTPUT="no"
OUT_DIR=""

usage() {
  cat >&2 <<'EOF'
Usage:
  bash ./scripts/xhs_argus_prep_gate.sh [options]

Options:
  --container <name>      Container name (default: agent_argus)
  --task-id <id>          Task id (default: GOAL-XHS-ASSET-001)
  --post-id <id>          Post id (default: P01)
  --out-dir <dir>         Local output dir (default: runtime/host_bridge_jobs/<ts>)
  --json                  Emit json summary
  -h, --help              Show help

What this does:
  1) Find latest publish_job.json from Argus container outputs
  2) Pull it locally with materials
  3) Run xhs_publish_job_guard.js strict validation
  4) If blocked, generate retry prompt file for Argus
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
    --out-dir)
      OUT_DIR="${2:-}"
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

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
if [[ -z "$OUT_DIR" ]]; then
  OUT_DIR="runtime/host_bridge_jobs/$STAMP"
fi
mkdir -p "$OUT_DIR"

CONTAINER_JOB_PATH="$(
  docker exec "$CONTAINER_NAME" sh -lc \
    "ls -1dt /root/.openclaw/workspace/steward/outputs/$TASK_ID/$POST_ID/*/publish_job.json 2>/dev/null | head -n 1" \
  | tr -d '\r'
)"

RETRY_PROMPT_FILE="$OUT_DIR/retry_prompt_for_argus.txt"

if [[ -z "${CONTAINER_JOB_PATH:-}" ]]; then
  cat > "$RETRY_PROMPT_FILE" <<EOF
进入 GOAL-XHS-ASSET-001_${POST_ID}_PREP_STRICT 模式（强约束，不聊天）：

当前阻断原因：
- 未发现 publish_job.json（task_id=${TASK_ID}, post_id=${POST_ID}）。

请你直接产出可执行发布包并生成 publish_job.json。
必须包含：
final_title/title_candidates/body_text/hashtags/first_comment/cover_file/image_files/material_dir/stop_before_publish/operator_checklist/evidence_ref
并给出 publish_job.json 绝对路径。

边界：
- 不自动点击发布
- 不假设已发布成功
- 不扩容、不改阈值、不关闭 RH-T5-B01
EOF

  if [[ "$JSON_OUTPUT" == "yes" ]]; then
    node - <<'NODE' "$CONTAINER_NAME" "$TASK_ID" "$POST_ID" "$RETRY_PROMPT_FILE"
const [,, containerName, taskId, postId, retryPromptFile] = process.argv;
console.log(JSON.stringify({
  action: "xhs_argus_prep_gate",
  ok: false,
  stage: "find_latest_publish_job",
  containerName,
  taskId,
  postId,
  error: "publish_job_not_found",
  retryPromptFile
}, null, 2));
NODE
  else
    echo "[xhs-argus-prep-gate] blocked: publish_job not found (task_id=$TASK_ID post_id=$POST_ID)"
    echo "[xhs-argus-prep-gate] retry prompt: $RETRY_PROMPT_FILE"
  fi
  exit 2
fi

bash ./scripts/xhs_pull_publish_job.sh "$CONTAINER_JOB_PATH" "$OUT_DIR" >/dev/null
LOCAL_JOB_PATH="$OUT_DIR/publish_job.json"

set +e
GUARD_JSON="$(node ./scripts/xhs_publish_job_guard.js --job "$LOCAL_JOB_PATH" --json)"
GUARD_EXIT=$?
set -e
if [[ -z "${GUARD_JSON:-}" ]]; then
  GUARD_JSON='{"action":"xhs_publish_job_guard","ok":false,"errors":[{"code":"guard_no_output","detail":"validator returned no output"}],"warnings":[]}'
fi
GUARD_OK="$(printf '%s' "$GUARD_JSON" | node -e 'const fs=require("fs"); const d=JSON.parse(fs.readFileSync(0,"utf8")); process.stdout.write(d.ok?"yes":"no");')"

if [[ "$GUARD_OK" != "yes" || "$GUARD_EXIT" -ne 0 ]]; then
  ERROR_LINES="$(printf '%s' "$GUARD_JSON" | node -e '
const fs=require("fs");
const d=JSON.parse(fs.readFileSync(0,"utf8"));
const lines=(d.errors||[]).map((e)=>`- ${e.code}: ${e.detail}`);
process.stdout.write(lines.join("\n"));
')"

  cat > "$RETRY_PROMPT_FILE" <<EOF
进入 GOAL-XHS-ASSET-001_${POST_ID}_PREP_STRICT 模式（强约束，不聊天）：

当前 publish_job.json 校验未通过，请按以下问题修复后重新产出：
$ERROR_LINES

要求：
1) 直接给修复后的 publish_job.json 绝对路径
2) 保持 stop_before_publish=true
3) 不要占位符（如 <...>）
4) image_files 与 cover_file 必须与 material_dir 下真实文件一致
5) operator_checklist 必须包含“发布按钮前停住/手动确认”

边界：
- 不自动点击发布
- 不假设已发布成功
- 不扩容、不改阈值、不关闭 RH-T5-B01
EOF

  if [[ "$JSON_OUTPUT" == "yes" ]]; then
    node - <<'NODE' "$CONTAINER_NAME" "$TASK_ID" "$POST_ID" "$CONTAINER_JOB_PATH" "$LOCAL_JOB_PATH" "$RETRY_PROMPT_FILE" "$GUARD_JSON"
const [,, containerName, taskId, postId, containerJobPath, localJobPath, retryPromptFile, guardRaw] = process.argv;
console.log(JSON.stringify({
  action: "xhs_argus_prep_gate",
  ok: false,
  stage: "validate_publish_job",
  containerName,
  taskId,
  postId,
  containerJobPath,
  localJobPath,
  guard: JSON.parse(guardRaw),
  retryPromptFile
}, null, 2));
NODE
  else
    echo "[xhs-argus-prep-gate] blocked: publish_job guard failed"
    echo "$GUARD_JSON"
    echo "[xhs-argus-prep-gate] retry prompt: $RETRY_PROMPT_FILE"
  fi
  exit 2
fi

if [[ "$JSON_OUTPUT" == "yes" ]]; then
  node - <<'NODE' "$CONTAINER_NAME" "$TASK_ID" "$POST_ID" "$CONTAINER_JOB_PATH" "$LOCAL_JOB_PATH" "$GUARD_JSON"
const [,, containerName, taskId, postId, containerJobPath, localJobPath, guardRaw] = process.argv;
console.log(JSON.stringify({
  action: "xhs_argus_prep_gate",
  ok: true,
  containerName,
  taskId,
  postId,
  containerJobPath,
  localJobPath,
  guard: JSON.parse(guardRaw),
  next: `node ./scripts/xhs_host_bridge_fill.js --job ${localJobPath} --browser webkit --keep-open`
}, null, 2));
NODE
else
  echo "[xhs-argus-prep-gate] ok"
  echo "container_job=$CONTAINER_JOB_PATH"
  echo "local_job=$LOCAL_JOB_PATH"
  echo "next=node ./scripts/xhs_host_bridge_fill.js --job \"$LOCAL_JOB_PATH\" --browser webkit --keep-open"
fi
