#!/usr/bin/env bash
set -euo pipefail
umask 077

TS="$(date +%Y%m%d-%H%M%S)"
CONTAINER_NAME="${OPENCLAW_AGENT_CONTAINER:-agent_argus}"
ROUTE_TO="${ROUTE_TO:-+15550001111}"
ROUTE_AGENT="${ROUTE_AGENT:-steward}"
MESSAGE="${MESSAGE:-rh-t5-b01 to-path probe}"
PROBE_ROOT="${PROBE_ROOT:-design/validation/artifacts/openclaw-rh-t5-b01-a8-to-path-probe-$TS}"
ARTIFACT_DIR="$PROBE_ROOT/artifacts"

log() {
  printf '[rh-t5-b01-a8] %s\n' "$*"
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

mkdir -p "$ARTIFACT_DIR"

SID_NO_TO="rh5-a8-noto-$TS"
SID_TO="rh5-a8-to-$TS"

log "running default route without --to"
run_capture "default_no_to" docker exec "$CONTAINER_NAME" openclaw agent \
  --session-id "$SID_NO_TO" \
  --message "$MESSAGE" \
  --json

log "running explicit route without --to"
run_capture "explicit_no_to" docker exec "$CONTAINER_NAME" openclaw agent \
  --agent "$ROUTE_AGENT" \
  --session-id "$SID_NO_TO" \
  --message "$MESSAGE" \
  --json

log "running default route with --to"
run_capture "default_with_to" docker exec "$CONTAINER_NAME" openclaw agent \
  --to "$ROUTE_TO" \
  --session-id "$SID_TO" \
  --message "$MESSAGE" \
  --json

log "running explicit route with --to"
run_capture "explicit_with_to" docker exec "$CONTAINER_NAME" openclaw agent \
  --agent "$ROUTE_AGENT" \
  --to "$ROUTE_TO" \
  --session-id "$SID_TO" \
  --message "$MESSAGE" \
  --json

DEFAULT_NO_TO_EXIT="$(cat "$ARTIFACT_DIR/default_no_to.exitcode")"
EXPLICIT_NO_TO_EXIT="$(cat "$ARTIFACT_DIR/explicit_no_to.exitcode")"
DEFAULT_WITH_TO_EXIT="$(cat "$ARTIFACT_DIR/default_with_to.exitcode")"
EXPLICIT_WITH_TO_EXIT="$(cat "$ARTIFACT_DIR/explicit_with_to.exitcode")"

DEFAULT_NO_TO_STATUS=""
EXPLICIT_NO_TO_STATUS=""
DEFAULT_WITH_TO_STATUS=""
EXPLICIT_WITH_TO_STATUS=""

DEFAULT_NO_TO_RUN_ID=""
EXPLICIT_NO_TO_RUN_ID=""
DEFAULT_WITH_TO_RUN_ID=""
EXPLICIT_WITH_TO_RUN_ID=""

DEFAULT_NO_TO_SESSION_KEY=""
EXPLICIT_NO_TO_SESSION_KEY=""
DEFAULT_WITH_TO_SESSION_KEY=""
EXPLICIT_WITH_TO_SESSION_KEY=""

DEFAULT_NO_TO_AGENT=""
EXPLICIT_NO_TO_AGENT=""
DEFAULT_WITH_TO_AGENT=""
EXPLICIT_WITH_TO_AGENT=""

DEFAULT_NO_TO_WORKSPACE=""
EXPLICIT_NO_TO_WORKSPACE=""
DEFAULT_WITH_TO_WORKSPACE=""
EXPLICIT_WITH_TO_WORKSPACE=""

DEFAULT_NO_TO_PROVIDER=""
EXPLICIT_NO_TO_PROVIDER=""
DEFAULT_WITH_TO_PROVIDER=""
EXPLICIT_WITH_TO_PROVIDER=""

DEFAULT_NO_TO_MODEL=""
EXPLICIT_NO_TO_MODEL=""
DEFAULT_WITH_TO_MODEL=""
EXPLICIT_WITH_TO_MODEL=""

DEFAULT_NO_TO_PROFILE=""
EXPLICIT_NO_TO_PROFILE=""
DEFAULT_WITH_TO_PROFILE=""
EXPLICIT_WITH_TO_PROFILE=""

if [[ "$DEFAULT_NO_TO_EXIT" -eq 0 ]]; then
  DEFAULT_NO_TO_STATUS="$(extract_json "$ARTIFACT_DIR/default_no_to.out" '.status // ""')"
  DEFAULT_NO_TO_RUN_ID="$(extract_json "$ARTIFACT_DIR/default_no_to.out" '.runId // ""')"
  DEFAULT_NO_TO_SESSION_KEY="$(extract_json "$ARTIFACT_DIR/default_no_to.out" '.result.meta.systemPromptReport.sessionKey // ""')"
  DEFAULT_NO_TO_AGENT="$(extract_agent_from_session_key "$DEFAULT_NO_TO_SESSION_KEY")"
  DEFAULT_NO_TO_WORKSPACE="$(extract_json "$ARTIFACT_DIR/default_no_to.out" '.result.meta.systemPromptReport.workspaceDir // ""')"
  DEFAULT_NO_TO_PROVIDER="$(extract_json "$ARTIFACT_DIR/default_no_to.out" '.result.meta.systemPromptReport.provider // ""')"
  DEFAULT_NO_TO_MODEL="$(extract_json "$ARTIFACT_DIR/default_no_to.out" '.result.meta.systemPromptReport.model // ""')"
  DEFAULT_NO_TO_PROFILE="$(extract_json "$ARTIFACT_DIR/default_no_to.out" '.result.meta.systemPromptReport.profile // ""')"
fi

if [[ "$EXPLICIT_NO_TO_EXIT" -eq 0 ]]; then
  EXPLICIT_NO_TO_STATUS="$(extract_json "$ARTIFACT_DIR/explicit_no_to.out" '.status // ""')"
  EXPLICIT_NO_TO_RUN_ID="$(extract_json "$ARTIFACT_DIR/explicit_no_to.out" '.runId // ""')"
  EXPLICIT_NO_TO_SESSION_KEY="$(extract_json "$ARTIFACT_DIR/explicit_no_to.out" '.result.meta.systemPromptReport.sessionKey // ""')"
  EXPLICIT_NO_TO_AGENT="$(extract_agent_from_session_key "$EXPLICIT_NO_TO_SESSION_KEY")"
  EXPLICIT_NO_TO_WORKSPACE="$(extract_json "$ARTIFACT_DIR/explicit_no_to.out" '.result.meta.systemPromptReport.workspaceDir // ""')"
  EXPLICIT_NO_TO_PROVIDER="$(extract_json "$ARTIFACT_DIR/explicit_no_to.out" '.result.meta.systemPromptReport.provider // ""')"
  EXPLICIT_NO_TO_MODEL="$(extract_json "$ARTIFACT_DIR/explicit_no_to.out" '.result.meta.systemPromptReport.model // ""')"
  EXPLICIT_NO_TO_PROFILE="$(extract_json "$ARTIFACT_DIR/explicit_no_to.out" '.result.meta.systemPromptReport.profile // ""')"
fi

if [[ "$DEFAULT_WITH_TO_EXIT" -eq 0 ]]; then
  DEFAULT_WITH_TO_STATUS="$(extract_json "$ARTIFACT_DIR/default_with_to.out" '.status // ""')"
  DEFAULT_WITH_TO_RUN_ID="$(extract_json "$ARTIFACT_DIR/default_with_to.out" '.runId // ""')"
  DEFAULT_WITH_TO_SESSION_KEY="$(extract_json "$ARTIFACT_DIR/default_with_to.out" '.result.meta.systemPromptReport.sessionKey // ""')"
  DEFAULT_WITH_TO_AGENT="$(extract_agent_from_session_key "$DEFAULT_WITH_TO_SESSION_KEY")"
  DEFAULT_WITH_TO_WORKSPACE="$(extract_json "$ARTIFACT_DIR/default_with_to.out" '.result.meta.systemPromptReport.workspaceDir // ""')"
  DEFAULT_WITH_TO_PROVIDER="$(extract_json "$ARTIFACT_DIR/default_with_to.out" '.result.meta.systemPromptReport.provider // ""')"
  DEFAULT_WITH_TO_MODEL="$(extract_json "$ARTIFACT_DIR/default_with_to.out" '.result.meta.systemPromptReport.model // ""')"
  DEFAULT_WITH_TO_PROFILE="$(extract_json "$ARTIFACT_DIR/default_with_to.out" '.result.meta.systemPromptReport.profile // ""')"
fi

if [[ "$EXPLICIT_WITH_TO_EXIT" -eq 0 ]]; then
  EXPLICIT_WITH_TO_STATUS="$(extract_json "$ARTIFACT_DIR/explicit_with_to.out" '.status // ""')"
  EXPLICIT_WITH_TO_RUN_ID="$(extract_json "$ARTIFACT_DIR/explicit_with_to.out" '.runId // ""')"
  EXPLICIT_WITH_TO_SESSION_KEY="$(extract_json "$ARTIFACT_DIR/explicit_with_to.out" '.result.meta.systemPromptReport.sessionKey // ""')"
  EXPLICIT_WITH_TO_AGENT="$(extract_agent_from_session_key "$EXPLICIT_WITH_TO_SESSION_KEY")"
  EXPLICIT_WITH_TO_WORKSPACE="$(extract_json "$ARTIFACT_DIR/explicit_with_to.out" '.result.meta.systemPromptReport.workspaceDir // ""')"
  EXPLICIT_WITH_TO_PROVIDER="$(extract_json "$ARTIFACT_DIR/explicit_with_to.out" '.result.meta.systemPromptReport.provider // ""')"
  EXPLICIT_WITH_TO_MODEL="$(extract_json "$ARTIFACT_DIR/explicit_with_to.out" '.result.meta.systemPromptReport.model // ""')"
  EXPLICIT_WITH_TO_PROFILE="$(extract_json "$ARTIFACT_DIR/explicit_with_to.out" '.result.meta.systemPromptReport.profile // ""')"
fi

PMP_CONSISTENT="unknown"
if [[ "$DEFAULT_NO_TO_EXIT" -eq 0 && "$EXPLICIT_NO_TO_EXIT" -eq 0 && "$DEFAULT_WITH_TO_EXIT" -eq 0 && "$EXPLICIT_WITH_TO_EXIT" -eq 0 ]]; then
  if [[ "$DEFAULT_NO_TO_PROVIDER" == "$EXPLICIT_NO_TO_PROVIDER" && "$EXPLICIT_NO_TO_PROVIDER" == "$DEFAULT_WITH_TO_PROVIDER" && "$DEFAULT_WITH_TO_PROVIDER" == "$EXPLICIT_WITH_TO_PROVIDER" && "$DEFAULT_NO_TO_MODEL" == "$EXPLICIT_NO_TO_MODEL" && "$EXPLICIT_NO_TO_MODEL" == "$DEFAULT_WITH_TO_MODEL" && "$DEFAULT_WITH_TO_MODEL" == "$EXPLICIT_WITH_TO_MODEL" && "$DEFAULT_NO_TO_PROFILE" == "$EXPLICIT_NO_TO_PROFILE" && "$EXPLICIT_NO_TO_PROFILE" == "$DEFAULT_WITH_TO_PROFILE" && "$DEFAULT_WITH_TO_PROFILE" == "$EXPLICIT_WITH_TO_PROFILE" ]]; then
    PMP_CONSISTENT="yes"
  else
    PMP_CONSISTENT="no"
  fi
fi

TO_PATH_SPLIT_CONFIRMED="unknown"
if [[ "$DEFAULT_NO_TO_EXIT" -eq 0 && "$DEFAULT_WITH_TO_EXIT" -eq 0 && "$EXPLICIT_WITH_TO_EXIT" -eq 0 ]]; then
  if [[ "$DEFAULT_NO_TO_WORKSPACE" == *"/workspace/steward" && "$DEFAULT_WITH_TO_AGENT" == "main" && "$EXPLICIT_WITH_TO_AGENT" == "$ROUTE_AGENT" ]]; then
    TO_PATH_SPLIT_CONFIRMED="yes"
  else
    TO_PATH_SPLIT_CONFIRMED="no"
  fi
fi

RESULT="probe_error"
if [[ "$TO_PATH_SPLIT_CONFIRMED" == "yes" && "$PMP_CONSISTENT" == "yes" ]]; then
  RESULT="to_path_specific_split_confirmed"
elif [[ "$TO_PATH_SPLIT_CONFIRMED" == "no" && "$PMP_CONSISTENT" == "yes" ]]; then
  RESULT="to_path_specific_split_not_detected"
fi

NOTE="probe_error means at least one probe command failed; check *.err for details."
if [[ "$RESULT" == "to_path_specific_split_confirmed" ]]; then
  NOTE="default no-to path stays on steward workspace, but default --to path resolves to main while explicit --agent --to resolves to steward."
elif [[ "$RESULT" == "to_path_specific_split_not_detected" ]]; then
  NOTE="to-path specific split was not reproduced under this probe."
fi

SUMMARY="$ARTIFACT_DIR/summary.txt"
cat >"$SUMMARY" <<EOF
timestamp=$(date +%Y-%m-%dT%H:%M:%S%z)
probe_root=$PROBE_ROOT
container_name=$CONTAINER_NAME
route_to=$ROUTE_TO
route_agent=$ROUTE_AGENT
session_id_no_to=$SID_NO_TO
session_id_to=$SID_TO
default_no_to_exit=$DEFAULT_NO_TO_EXIT
explicit_no_to_exit=$EXPLICIT_NO_TO_EXIT
default_with_to_exit=$DEFAULT_WITH_TO_EXIT
explicit_with_to_exit=$EXPLICIT_WITH_TO_EXIT
default_no_to_status=$DEFAULT_NO_TO_STATUS
explicit_no_to_status=$EXPLICIT_NO_TO_STATUS
default_with_to_status=$DEFAULT_WITH_TO_STATUS
explicit_with_to_status=$EXPLICIT_WITH_TO_STATUS
default_no_to_runid=$DEFAULT_NO_TO_RUN_ID
explicit_no_to_runid=$EXPLICIT_NO_TO_RUN_ID
default_with_to_runid=$DEFAULT_WITH_TO_RUN_ID
explicit_with_to_runid=$EXPLICIT_WITH_TO_RUN_ID
default_no_to_session_key=$DEFAULT_NO_TO_SESSION_KEY
explicit_no_to_session_key=$EXPLICIT_NO_TO_SESSION_KEY
default_with_to_session_key=$DEFAULT_WITH_TO_SESSION_KEY
explicit_with_to_session_key=$EXPLICIT_WITH_TO_SESSION_KEY
default_no_to_agent=$DEFAULT_NO_TO_AGENT
explicit_no_to_agent=$EXPLICIT_NO_TO_AGENT
default_with_to_agent=$DEFAULT_WITH_TO_AGENT
explicit_with_to_agent=$EXPLICIT_WITH_TO_AGENT
default_no_to_workspace=$DEFAULT_NO_TO_WORKSPACE
explicit_no_to_workspace=$EXPLICIT_NO_TO_WORKSPACE
default_with_to_workspace=$DEFAULT_WITH_TO_WORKSPACE
explicit_with_to_workspace=$EXPLICIT_WITH_TO_WORKSPACE
default_no_to_provider=$DEFAULT_NO_TO_PROVIDER
explicit_no_to_provider=$EXPLICIT_NO_TO_PROVIDER
default_with_to_provider=$DEFAULT_WITH_TO_PROVIDER
explicit_with_to_provider=$EXPLICIT_WITH_TO_PROVIDER
default_no_to_model=$DEFAULT_NO_TO_MODEL
explicit_no_to_model=$EXPLICIT_NO_TO_MODEL
default_with_to_model=$DEFAULT_WITH_TO_MODEL
explicit_with_to_model=$EXPLICIT_WITH_TO_MODEL
default_no_to_profile=$DEFAULT_NO_TO_PROFILE
explicit_no_to_profile=$EXPLICIT_NO_TO_PROFILE
default_with_to_profile=$DEFAULT_WITH_TO_PROFILE
explicit_with_to_profile=$EXPLICIT_WITH_TO_PROFILE
pmp_consistent=$PMP_CONSISTENT
to_path_split_confirmed=$TO_PATH_SPLIT_CONFIRMED
result=$RESULT
note=$NOTE
EOF

log "done"
log "probe root: $PROBE_ROOT"
log "summary: $SUMMARY"
cat "$SUMMARY"
