#!/usr/bin/env bash
set -euo pipefail
umask 077

TS="$(date +%Y%m%d-%H%M%S)"
CONTAINER_NAME="${OPENCLAW_AGENT_CONTAINER:-agent_argus}"
ROUTE_TO="${ROUTE_TO:-+15550001111}"
ROUTE_AGENT="${ROUTE_AGENT:-steward}"
MESSAGE="${MESSAGE:-rh-t5-b01 controlled comparison}"
SESSION_ID_BASE="${SESSION_ID_BASE:-rh5-a7-$TS}"
PROBE_ROOT="${PROBE_ROOT:-design/validation/artifacts/openclaw-rh-t5-b01-a7-controlled-comparison-$TS}"
ARTIFACT_DIR="$PROBE_ROOT/artifacts"

log() {
  printf '[rh-t5-b01-a7] %s\n' "$*"
}

need_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "missing command: $cmd" >&2
    exit 1
  fi
}

run_capture() {
  local name="$1"
  shift
  local out="$ARTIFACT_DIR/$name.out"
  local err="$ARTIFACT_DIR/$name.err"
  local code_file="$ARTIFACT_DIR/$name.exitcode"

  set +e
  "$@" >"$out" 2>"$err"
  local code=$?
  set -e

  echo "$code" >"$code_file"
}

extract_json() {
  local file="$1"
  local jq_filter="$2"
  jq -r "$jq_filter" "$file" 2>/dev/null || true
}

extract_agent_from_session_key() {
  local session_key="$1"
  if [[ -z "$session_key" ]]; then
    printf ''
    return
  fi
  printf '%s' "$session_key" | awk -F: '{print $2}'
}

need_cmd docker
need_cmd jq
need_cmd awk
need_cmd sed

mkdir -p "$ARTIFACT_DIR"

SID_FIXED="$SESSION_ID_BASE-fixed"
SID_NEW="$SESSION_ID_BASE-new"

log "collecting baseline default agent + bindings"
run_capture "agents_list" docker exec "$CONTAINER_NAME" openclaw agents list --bindings --json

log "running explicit route with fixed session-id"
run_capture "explicit_fixed" docker exec "$CONTAINER_NAME" openclaw agent \
  --agent "$ROUTE_AGENT" \
  --to "$ROUTE_TO" \
  --session-id "$SID_FIXED" \
  --message "$MESSAGE" \
  --json

log "running default route with same fixed session-id"
run_capture "default_fixed" docker exec "$CONTAINER_NAME" openclaw agent \
  --to "$ROUTE_TO" \
  --session-id "$SID_FIXED" \
  --message "$MESSAGE" \
  --json

log "running default route with new session-id"
run_capture "default_new" docker exec "$CONTAINER_NAME" openclaw agent \
  --to "$ROUTE_TO" \
  --session-id "$SID_NEW" \
  --message "$MESSAGE" \
  --json

log "running explicit route with same new session-id"
run_capture "explicit_new" docker exec "$CONTAINER_NAME" openclaw agent \
  --agent "$ROUTE_AGENT" \
  --to "$ROUTE_TO" \
  --session-id "$SID_NEW" \
  --message "$MESSAGE" \
  --json

AGENTS_LIST_EXIT="$(cat "$ARTIFACT_DIR/agents_list.exitcode")"
EXPLICIT_FIXED_EXIT="$(cat "$ARTIFACT_DIR/explicit_fixed.exitcode")"
DEFAULT_FIXED_EXIT="$(cat "$ARTIFACT_DIR/default_fixed.exitcode")"
DEFAULT_NEW_EXIT="$(cat "$ARTIFACT_DIR/default_new.exitcode")"
EXPLICIT_NEW_EXIT="$(cat "$ARTIFACT_DIR/explicit_new.exitcode")"

DEFAULT_AGENT_IDS=""
if [[ "$AGENTS_LIST_EXIT" -eq 0 ]]; then
  DEFAULT_AGENT_IDS="$(extract_json "$ARTIFACT_DIR/agents_list.out" 'map(select(.isDefault == true) | .id) | join(",")')"
fi

EXPLICIT_FIXED_SESSION_KEY=""
EXPLICIT_FIXED_AGENT=""
EXPLICIT_FIXED_STATUS=""
EXPLICIT_FIXED_RUN_ID=""
EXPLICIT_FIXED_PROVIDER=""
EXPLICIT_FIXED_MODEL=""
EXPLICIT_FIXED_PROFILE=""

DEFAULT_FIXED_SESSION_KEY=""
DEFAULT_FIXED_AGENT=""
DEFAULT_FIXED_STATUS=""
DEFAULT_FIXED_RUN_ID=""
DEFAULT_FIXED_PROVIDER=""
DEFAULT_FIXED_MODEL=""
DEFAULT_FIXED_PROFILE=""

DEFAULT_NEW_SESSION_KEY=""
DEFAULT_NEW_AGENT=""
DEFAULT_NEW_STATUS=""
DEFAULT_NEW_RUN_ID=""
DEFAULT_NEW_PROVIDER=""
DEFAULT_NEW_MODEL=""
DEFAULT_NEW_PROFILE=""

EXPLICIT_NEW_SESSION_KEY=""
EXPLICIT_NEW_AGENT=""
EXPLICIT_NEW_STATUS=""
EXPLICIT_NEW_RUN_ID=""
EXPLICIT_NEW_PROVIDER=""
EXPLICIT_NEW_MODEL=""
EXPLICIT_NEW_PROFILE=""

if [[ "$EXPLICIT_FIXED_EXIT" -eq 0 ]]; then
  EXPLICIT_FIXED_STATUS="$(extract_json "$ARTIFACT_DIR/explicit_fixed.out" '.status // ""')"
  EXPLICIT_FIXED_RUN_ID="$(extract_json "$ARTIFACT_DIR/explicit_fixed.out" '.runId // ""')"
  EXPLICIT_FIXED_SESSION_KEY="$(extract_json "$ARTIFACT_DIR/explicit_fixed.out" '.result.meta.systemPromptReport.sessionKey // ""')"
  EXPLICIT_FIXED_AGENT="$(extract_agent_from_session_key "$EXPLICIT_FIXED_SESSION_KEY")"
  EXPLICIT_FIXED_PROVIDER="$(extract_json "$ARTIFACT_DIR/explicit_fixed.out" '.result.meta.systemPromptReport.provider // ""')"
  EXPLICIT_FIXED_MODEL="$(extract_json "$ARTIFACT_DIR/explicit_fixed.out" '.result.meta.systemPromptReport.model // ""')"
  EXPLICIT_FIXED_PROFILE="$(extract_json "$ARTIFACT_DIR/explicit_fixed.out" '.result.meta.systemPromptReport.profile // ""')"
fi

if [[ "$DEFAULT_FIXED_EXIT" -eq 0 ]]; then
  DEFAULT_FIXED_STATUS="$(extract_json "$ARTIFACT_DIR/default_fixed.out" '.status // ""')"
  DEFAULT_FIXED_RUN_ID="$(extract_json "$ARTIFACT_DIR/default_fixed.out" '.runId // ""')"
  DEFAULT_FIXED_SESSION_KEY="$(extract_json "$ARTIFACT_DIR/default_fixed.out" '.result.meta.systemPromptReport.sessionKey // ""')"
  DEFAULT_FIXED_AGENT="$(extract_agent_from_session_key "$DEFAULT_FIXED_SESSION_KEY")"
  DEFAULT_FIXED_PROVIDER="$(extract_json "$ARTIFACT_DIR/default_fixed.out" '.result.meta.systemPromptReport.provider // ""')"
  DEFAULT_FIXED_MODEL="$(extract_json "$ARTIFACT_DIR/default_fixed.out" '.result.meta.systemPromptReport.model // ""')"
  DEFAULT_FIXED_PROFILE="$(extract_json "$ARTIFACT_DIR/default_fixed.out" '.result.meta.systemPromptReport.profile // ""')"
fi

if [[ "$DEFAULT_NEW_EXIT" -eq 0 ]]; then
  DEFAULT_NEW_STATUS="$(extract_json "$ARTIFACT_DIR/default_new.out" '.status // ""')"
  DEFAULT_NEW_RUN_ID="$(extract_json "$ARTIFACT_DIR/default_new.out" '.runId // ""')"
  DEFAULT_NEW_SESSION_KEY="$(extract_json "$ARTIFACT_DIR/default_new.out" '.result.meta.systemPromptReport.sessionKey // ""')"
  DEFAULT_NEW_AGENT="$(extract_agent_from_session_key "$DEFAULT_NEW_SESSION_KEY")"
  DEFAULT_NEW_PROVIDER="$(extract_json "$ARTIFACT_DIR/default_new.out" '.result.meta.systemPromptReport.provider // ""')"
  DEFAULT_NEW_MODEL="$(extract_json "$ARTIFACT_DIR/default_new.out" '.result.meta.systemPromptReport.model // ""')"
  DEFAULT_NEW_PROFILE="$(extract_json "$ARTIFACT_DIR/default_new.out" '.result.meta.systemPromptReport.profile // ""')"
fi

if [[ "$EXPLICIT_NEW_EXIT" -eq 0 ]]; then
  EXPLICIT_NEW_STATUS="$(extract_json "$ARTIFACT_DIR/explicit_new.out" '.status // ""')"
  EXPLICIT_NEW_RUN_ID="$(extract_json "$ARTIFACT_DIR/explicit_new.out" '.runId // ""')"
  EXPLICIT_NEW_SESSION_KEY="$(extract_json "$ARTIFACT_DIR/explicit_new.out" '.result.meta.systemPromptReport.sessionKey // ""')"
  EXPLICIT_NEW_AGENT="$(extract_agent_from_session_key "$EXPLICIT_NEW_SESSION_KEY")"
  EXPLICIT_NEW_PROVIDER="$(extract_json "$ARTIFACT_DIR/explicit_new.out" '.result.meta.systemPromptReport.provider // ""')"
  EXPLICIT_NEW_MODEL="$(extract_json "$ARTIFACT_DIR/explicit_new.out" '.result.meta.systemPromptReport.model // ""')"
  EXPLICIT_NEW_PROFILE="$(extract_json "$ARTIFACT_DIR/explicit_new.out" '.result.meta.systemPromptReport.profile // ""')"
fi

SAME_SID_ROUTE_SPLIT="unknown"
if [[ "$EXPLICIT_FIXED_EXIT" -eq 0 && "$DEFAULT_FIXED_EXIT" -eq 0 ]]; then
  if [[ -n "$EXPLICIT_FIXED_AGENT" && -n "$DEFAULT_FIXED_AGENT" && "$EXPLICIT_FIXED_AGENT" != "$DEFAULT_FIXED_AGENT" ]]; then
    SAME_SID_ROUTE_SPLIT="yes"
  else
    SAME_SID_ROUTE_SPLIT="no"
  fi
fi

DEFAULT_SESSION_STICKY="unknown"
if [[ "$DEFAULT_FIXED_EXIT" -eq 0 && "$DEFAULT_NEW_EXIT" -eq 0 ]]; then
  if [[ -n "$DEFAULT_FIXED_AGENT" && "$DEFAULT_FIXED_AGENT" == "$DEFAULT_NEW_AGENT" ]]; then
    DEFAULT_SESSION_STICKY="yes"
  else
    DEFAULT_SESSION_STICKY="no"
  fi
fi

PMP_CONSISTENT="unknown"
if [[ "$EXPLICIT_FIXED_EXIT" -eq 0 && "$DEFAULT_FIXED_EXIT" -eq 0 && "$DEFAULT_NEW_EXIT" -eq 0 && "$EXPLICIT_NEW_EXIT" -eq 0 ]]; then
  if [[ "$EXPLICIT_FIXED_PROVIDER" == "$DEFAULT_FIXED_PROVIDER" && "$DEFAULT_FIXED_PROVIDER" == "$DEFAULT_NEW_PROVIDER" && "$DEFAULT_NEW_PROVIDER" == "$EXPLICIT_NEW_PROVIDER" && "$EXPLICIT_FIXED_MODEL" == "$DEFAULT_FIXED_MODEL" && "$DEFAULT_FIXED_MODEL" == "$DEFAULT_NEW_MODEL" && "$DEFAULT_NEW_MODEL" == "$EXPLICIT_NEW_MODEL" && "$EXPLICIT_FIXED_PROFILE" == "$DEFAULT_FIXED_PROFILE" && "$DEFAULT_FIXED_PROFILE" == "$DEFAULT_NEW_PROFILE" && "$DEFAULT_NEW_PROFILE" == "$EXPLICIT_NEW_PROFILE" ]]; then
    PMP_CONSISTENT="yes"
  else
    PMP_CONSISTENT="no"
  fi
fi

RESULT="probe_error"
if [[ "$SAME_SID_ROUTE_SPLIT" == "yes" && "$PMP_CONSISTENT" == "yes" ]]; then
  RESULT="route_split_confirmed_under_controlled_pmp"
elif [[ "$SAME_SID_ROUTE_SPLIT" == "no" && "$PMP_CONSISTENT" == "yes" ]]; then
  RESULT="route_split_not_detected_under_controlled_pmp"
fi

NOTE="probe_error means at least one probe command failed; check *.err for details."
if [[ "$RESULT" == "route_split_confirmed_under_controlled_pmp" ]]; then
  NOTE="default/explicit split persists even with same session-id and same provider/model/profile."
elif [[ "$RESULT" == "route_split_not_detected_under_controlled_pmp" ]]; then
  NOTE="no default/explicit split was observed under controlled provider/model/profile."
fi

SUMMARY="$ARTIFACT_DIR/summary.txt"
cat >"$SUMMARY" <<EOF
timestamp=$(date +%Y-%m-%dT%H:%M:%S%z)
probe_root=$PROBE_ROOT
container_name=$CONTAINER_NAME
route_to=$ROUTE_TO
route_agent=$ROUTE_AGENT
session_id_fixed=$SID_FIXED
session_id_new=$SID_NEW
agents_list_exit=$AGENTS_LIST_EXIT
default_agent_ids=$DEFAULT_AGENT_IDS
explicit_fixed_exit=$EXPLICIT_FIXED_EXIT
default_fixed_exit=$DEFAULT_FIXED_EXIT
default_new_exit=$DEFAULT_NEW_EXIT
explicit_new_exit=$EXPLICIT_NEW_EXIT
explicit_fixed_status=$EXPLICIT_FIXED_STATUS
default_fixed_status=$DEFAULT_FIXED_STATUS
default_new_status=$DEFAULT_NEW_STATUS
explicit_new_status=$EXPLICIT_NEW_STATUS
explicit_fixed_runid=$EXPLICIT_FIXED_RUN_ID
default_fixed_runid=$DEFAULT_FIXED_RUN_ID
default_new_runid=$DEFAULT_NEW_RUN_ID
explicit_new_runid=$EXPLICIT_NEW_RUN_ID
explicit_fixed_session_key=$EXPLICIT_FIXED_SESSION_KEY
default_fixed_session_key=$DEFAULT_FIXED_SESSION_KEY
default_new_session_key=$DEFAULT_NEW_SESSION_KEY
explicit_new_session_key=$EXPLICIT_NEW_SESSION_KEY
explicit_fixed_agent=$EXPLICIT_FIXED_AGENT
default_fixed_agent=$DEFAULT_FIXED_AGENT
default_new_agent=$DEFAULT_NEW_AGENT
explicit_new_agent=$EXPLICIT_NEW_AGENT
explicit_fixed_provider=$EXPLICIT_FIXED_PROVIDER
default_fixed_provider=$DEFAULT_FIXED_PROVIDER
default_new_provider=$DEFAULT_NEW_PROVIDER
explicit_new_provider=$EXPLICIT_NEW_PROVIDER
explicit_fixed_model=$EXPLICIT_FIXED_MODEL
default_fixed_model=$DEFAULT_FIXED_MODEL
default_new_model=$DEFAULT_NEW_MODEL
explicit_new_model=$EXPLICIT_NEW_MODEL
explicit_fixed_profile=$EXPLICIT_FIXED_PROFILE
default_fixed_profile=$DEFAULT_FIXED_PROFILE
default_new_profile=$DEFAULT_NEW_PROFILE
explicit_new_profile=$EXPLICIT_NEW_PROFILE
same_sid_route_split=$SAME_SID_ROUTE_SPLIT
default_session_sticky=$DEFAULT_SESSION_STICKY
pmp_consistent=$PMP_CONSISTENT
result=$RESULT
note=$NOTE
EOF

log "done"
log "probe root: $PROBE_ROOT"
log "summary: $SUMMARY"
cat "$SUMMARY"
