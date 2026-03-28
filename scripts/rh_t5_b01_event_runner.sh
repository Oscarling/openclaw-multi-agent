#!/usr/bin/env bash
set -euo pipefail
umask 077

TS="$(date +%Y%m%d-%H%M%S)"
EVENT_REASON="${EVENT_REASON:-routine_check}"
OPENCLAW_AGENT_CONTAINER="${OPENCLAW_AGENT_CONTAINER:-agent_argus}"
AUTO_REOPEN_LOCAL_ISSUE="${AUTO_REOPEN_LOCAL_ISSUE:-no}"
BUNDLE_STRICT="${BUNDLE_STRICT:-no}"
UPSTREAM_REPO="${UPSTREAM_REPO:-openclaw/openclaw}"
UPSTREAM_ISSUE_NUMBER="${UPSTREAM_ISSUE_NUMBER:-56267}"
LOCAL_REPO="${LOCAL_REPO:-Oscarling/openclaw-multi-agent}"
LOCAL_ISSUE_NUMBER="${LOCAL_ISSUE_NUMBER:-37}"
ISSUE_OWNER_LOGIN="${ISSUE_OWNER_LOGIN:-Oscarling}"
EXEC_ROOT="${EXEC_ROOT:-design/validation/artifacts/openclaw-rh-t5-b01-event-runner-$TS}"
ARTIFACT_DIR="$EXEC_ROOT/artifacts"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

log() {
  printf '[rh-t5-b01-event-runner] %s\n' "$*"
}

read_kv() {
  local file="$1"
  local key="$2"
  awk -F= -v k="$key" '$1==k{print substr($0, index($0,"=")+1)}' "$file" | tail -n 1
}

need_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "missing command: $cmd" >&2
    exit 1
  fi
}

need_cmd awk
need_cmd bash

mkdir -p "$ARTIFACT_DIR"

PROBE_ROOT="$ARTIFACT_DIR/upstream-feedback-probe"
BUNDLE_ROOT="$ARTIFACT_DIR/upstream-recheck-bundle"

log "running upstream feedback probe"
ISSUE_OWNER_LOGIN="$ISSUE_OWNER_LOGIN" \
UPSTREAM_REPO="$UPSTREAM_REPO" \
UPSTREAM_ISSUE_NUMBER="$UPSTREAM_ISSUE_NUMBER" \
LOCAL_REPO="$LOCAL_REPO" \
LOCAL_ISSUE_NUMBER="$LOCAL_ISSUE_NUMBER" \
PROBE_ROOT="$PROBE_ROOT" \
bash scripts/rh_t5_b01_upstream_feedback_probe.sh >"$ARTIFACT_DIR/probe.log" 2>&1

PROBE_SUMMARY="$PROBE_ROOT/artifacts/summary.txt"
NEXT_EVENT="$(read_kv "$PROBE_SUMMARY" "next_event")"
UPSTREAM_FEEDBACK_DETECTED="$(read_kv "$PROBE_SUMMARY" "upstream_feedback_detected")"
LOCAL_TRACKING_ISSUE_OPEN="$(read_kv "$PROBE_SUMMARY" "local_tracking_issue_open")"

ACTION_TAKEN="none"
ACTION_RESULT="not_run"
BUNDLE_SUMMARY=""
BUNDLE_FINAL_RESULT=""
BUNDLE_BLOCKER_CLOSE_READY=""
REOPEN_RESULT="not_needed"

if [[ "$NEXT_EVENT" == "reopen_local_tracking_issue" ]]; then
  ACTION_TAKEN="reopen_local_tracking_issue"
  if [[ "$AUTO_REOPEN_LOCAL_ISSUE" == "yes" ]]; then
    if gh issue reopen "$LOCAL_ISSUE_NUMBER" -R "$LOCAL_REPO" >"$ARTIFACT_DIR/reopen.log" 2>&1; then
      ACTION_RESULT="reopen_done"
      REOPEN_RESULT="done"
    else
      ACTION_RESULT="reopen_failed"
      REOPEN_RESULT="failed"
    fi
  else
    ACTION_RESULT="reopen_required_manual"
    REOPEN_RESULT="required_manual"
  fi
elif [[ "$NEXT_EVENT" == "upstream_feedback_received" ]]; then
  ACTION_TAKEN="run_upstream_recheck_bundle"
  set +e
  RECHECK_REASON="upstream_feedback" \
  RECHECK_STRICT="$BUNDLE_STRICT" \
  OPENCLAW_AGENT_CONTAINER="$OPENCLAW_AGENT_CONTAINER" \
  EXEC_ROOT="$BUNDLE_ROOT" \
  bash scripts/rh_t5_b01_upstream_recheck_bundle.sh >"$ARTIFACT_DIR/bundle.log" 2>&1
  BUNDLE_CODE=$?
  set -e
  ACTION_RESULT="bundle_exit_$BUNDLE_CODE"
  BUNDLE_SUMMARY="$BUNDLE_ROOT/artifacts/summary.txt"
  if [[ -f "$BUNDLE_SUMMARY" ]]; then
    BUNDLE_FINAL_RESULT="$(read_kv "$BUNDLE_SUMMARY" "final_result")"
    BUNDLE_BLOCKER_CLOSE_READY="$(read_kv "$BUNDLE_SUMMARY" "blocker_close_ready")"
  fi
else
  ACTION_TAKEN="wait"
  ACTION_RESULT="waiting_upstream_feedback"
fi

SUMMARY="$ARTIFACT_DIR/summary.txt"
cat >"$SUMMARY" <<EOF
timestamp=$(date +%Y-%m-%dT%H:%M:%S%z)
exec_root=$EXEC_ROOT
event_reason=$EVENT_REASON
upstream_repo=$UPSTREAM_REPO
upstream_issue_number=$UPSTREAM_ISSUE_NUMBER
local_repo=$LOCAL_REPO
local_issue_number=$LOCAL_ISSUE_NUMBER
issue_owner_login=$ISSUE_OWNER_LOGIN
openclaw_agent_container=$OPENCLAW_AGENT_CONTAINER
auto_reopen_local_issue=$AUTO_REOPEN_LOCAL_ISSUE
bundle_strict=$BUNDLE_STRICT
probe_root=$PROBE_ROOT
probe_summary=$PROBE_SUMMARY
next_event=$NEXT_EVENT
upstream_feedback_detected=$UPSTREAM_FEEDBACK_DETECTED
local_tracking_issue_open=$LOCAL_TRACKING_ISSUE_OPEN
action_taken=$ACTION_TAKEN
action_result=$ACTION_RESULT
reopen_result=$REOPEN_RESULT
bundle_root=$BUNDLE_ROOT
bundle_summary=$BUNDLE_SUMMARY
bundle_final_result=$BUNDLE_FINAL_RESULT
bundle_blocker_close_ready=$BUNDLE_BLOCKER_CLOSE_READY
note=run_upstream_recheck_bundle means upstream feedback is detected; wait means no upstream feedback yet.
EOF

log "done"
log "exec root: $EXEC_ROOT"
log "summary: $SUMMARY"
cat "$SUMMARY"
