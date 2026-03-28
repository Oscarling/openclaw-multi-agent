#!/usr/bin/env bash
set -euo pipefail
umask 077

TS="$(date +%Y%m%d-%H%M%S)"
CONTAINER_NAME="${OPENCLAW_AGENT_CONTAINER:-agent_argus}"
RECHECK_REASON="${RECHECK_REASON:-upstream_feedback}"
RECHECK_STRICT="${RECHECK_STRICT:-yes}"
UPSTREAM_ISSUE="${UPSTREAM_ISSUE:-https://github.com/openclaw/openclaw/issues/56267}"
LOCAL_TRACK_ISSUE="${LOCAL_TRACK_ISSUE:-https://github.com/Oscarling/openclaw-multi-agent/issues/37}"
EXEC_ROOT="${EXEC_ROOT:-design/validation/artifacts/openclaw-rh-t5-b01-upstream-recheck-$TS}"
ARTIFACT_DIR="$EXEC_ROOT/artifacts"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

log() {
  printf '[rh-t5-b01-upstream-recheck] %s\n' "$*"
}

need_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "missing command: $cmd" >&2
    exit 1
  fi
}

read_kv() {
  local file="$1"
  local key="$2"
  awk -F= -v k="$key" '$1==k{print substr($0, index($0,"=")+1)}' "$file" | tail -n 1
}

need_cmd awk
need_cmd sed
need_cmd bash

mkdir -p "$ARTIFACT_DIR"

A6_ROOT="$ARTIFACT_DIR/a6-min-repro"
A7_ROOT="$ARTIFACT_DIR/a7-controlled-comparison"
A8_ROOT="$ARTIFACT_DIR/a8-to-path-probe"

log "running A6 minimal repro"
OPENCLAW_AGENT_CONTAINER="$CONTAINER_NAME" PROBE_ROOT="$A6_ROOT" bash scripts/rh_t5_b01_min_repro.sh >"$ARTIFACT_DIR/a6.log" 2>&1

log "running A7 controlled comparison"
OPENCLAW_AGENT_CONTAINER="$CONTAINER_NAME" PROBE_ROOT="$A7_ROOT" bash scripts/rh_t5_b01_controlled_comparison.sh >"$ARTIFACT_DIR/a7.log" 2>&1

log "running A8 to-path probe"
OPENCLAW_AGENT_CONTAINER="$CONTAINER_NAME" PROBE_ROOT="$A8_ROOT" bash scripts/rh_t5_b01_to_path_probe.sh >"$ARTIFACT_DIR/a8.log" 2>&1

A6_SUMMARY="$A6_ROOT/artifacts/summary.txt"
A7_SUMMARY="$A7_ROOT/artifacts/summary.txt"
A8_SUMMARY="$A8_ROOT/artifacts/summary.txt"

A6_RESULT="$(read_kv "$A6_SUMMARY" "result")"
A7_RESULT="$(read_kv "$A7_SUMMARY" "result")"
A8_RESULT="$(read_kv "$A8_SUMMARY" "result")"

A6_DEFAULT_SESSION_KEY="$(read_kv "$A6_SUMMARY" "default_session_key")"
A6_EXPLICIT_SESSION_KEY="$(read_kv "$A6_SUMMARY" "explicit_session_key")"
A7_PMP_CONSISTENT="$(read_kv "$A7_SUMMARY" "pmp_consistent")"
A8_TO_PATH_SPLIT="$(read_kv "$A8_SUMMARY" "to_path_split_confirmed")"

BLOCKER_CLOSE_READY="no"
if [[ "$A6_RESULT" == "route_parity_ok" && "$A7_RESULT" == "route_split_not_detected_under_controlled_pmp" && "$A8_RESULT" == "to_path_specific_split_not_detected" ]]; then
  BLOCKER_CLOSE_READY="yes"
fi

FINAL_RESULT="blocker_still_open"
if [[ "$BLOCKER_CLOSE_READY" == "yes" ]]; then
  FINAL_RESULT="ready_for_blocker_close_rereview"
fi

SUMMARY="$ARTIFACT_DIR/summary.txt"
cat >"$SUMMARY" <<EOF
timestamp=$(date +%Y-%m-%dT%H:%M:%S%z)
exec_root=$EXEC_ROOT
container_name=$CONTAINER_NAME
recheck_reason=$RECHECK_REASON
recheck_strict=$RECHECK_STRICT
upstream_issue=$UPSTREAM_ISSUE
local_track_issue=$LOCAL_TRACK_ISSUE
a6_root=$A6_ROOT
a7_root=$A7_ROOT
a8_root=$A8_ROOT
a6_summary=$A6_SUMMARY
a7_summary=$A7_SUMMARY
a8_summary=$A8_SUMMARY
a6_result=$A6_RESULT
a7_result=$A7_RESULT
a8_result=$A8_RESULT
a6_default_session_key=$A6_DEFAULT_SESSION_KEY
a6_explicit_session_key=$A6_EXPLICIT_SESSION_KEY
a7_pmp_consistent=$A7_PMP_CONSISTENT
a8_to_path_split_confirmed=$A8_TO_PATH_SPLIT
blocker_close_ready=$BLOCKER_CLOSE_READY
final_result=$FINAL_RESULT
note=ready_for_blocker_close_rereview means A6/A7/A8 all report no route split and RH-T5-B01 can enter final close re-review.
EOF

log "done"
log "exec root: $EXEC_ROOT"
log "summary: $SUMMARY"
cat "$SUMMARY"

if [[ "$RECHECK_STRICT" == "yes" && "$BLOCKER_CLOSE_READY" != "yes" ]]; then
  exit 4
fi
