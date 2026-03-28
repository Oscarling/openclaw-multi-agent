#!/usr/bin/env bash
set -euo pipefail
umask 077

TS="$(date +%Y%m%d-%H%M%S)"
CONTAINER_NAME="${OPENCLAW_AGENT_CONTAINER:-agent_argus}"
ROUTE_TO="${ROUTE_TO:-+15550001111}"
ROUTE_AGENT="${ROUTE_AGENT:-steward}"
MESSAGE="${MESSAGE:-rh-t5-b01 minimal repro}"
PROBE_ROOT="${PROBE_ROOT:-design/validation/artifacts/openclaw-rh-t5-b01-min-repro-$TS}"
ARTIFACT_DIR="$PROBE_ROOT/artifacts"

log() {
  printf '[rh-t5-b01-min-repro] %s\n' "$*"
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
need_cmd tr

mkdir -p "$ARTIFACT_DIR"

log "collecting runtime baseline"
run_capture "version" docker exec "$CONTAINER_NAME" openclaw --version
run_capture "agents_bindings" docker exec "$CONTAINER_NAME" openclaw agents list --bindings --json

log "running default route call (--to without --agent)"
run_capture "default_route" docker exec "$CONTAINER_NAME" openclaw agent \
  --to "$ROUTE_TO" \
  --session-id "rh5-minrepro-default-$TS" \
  --message "$MESSAGE" \
  --json

log "running explicit route call (--agent + --to)"
run_capture "explicit_route" docker exec "$CONTAINER_NAME" openclaw agent \
  --agent "$ROUTE_AGENT" \
  --to "$ROUTE_TO" \
  --session-id "rh5-minrepro-explicit-$TS" \
  --message "$MESSAGE" \
  --json

VERSION_EXIT="$(cat "$ARTIFACT_DIR/version.exitcode")"
BINDINGS_EXIT="$(cat "$ARTIFACT_DIR/agents_bindings.exitcode")"
DEFAULT_EXIT="$(cat "$ARTIFACT_DIR/default_route.exitcode")"
EXPLICIT_EXIT="$(cat "$ARTIFACT_DIR/explicit_route.exitcode")"

DEFAULT_STATUS=""
DEFAULT_RUN_ID=""
DEFAULT_SESSION_KEY=""
DEFAULT_AGENT=""

EXPLICIT_STATUS=""
EXPLICIT_RUN_ID=""
EXPLICIT_SESSION_KEY=""
EXPLICIT_AGENT=""

if [[ "$DEFAULT_EXIT" -eq 0 ]]; then
  DEFAULT_STATUS="$(extract_json "$ARTIFACT_DIR/default_route.out" '.status // ""')"
  DEFAULT_RUN_ID="$(extract_json "$ARTIFACT_DIR/default_route.out" '.runId // ""')"
  DEFAULT_SESSION_KEY="$(extract_json "$ARTIFACT_DIR/default_route.out" '.result.meta.systemPromptReport.sessionKey // ""')"
  DEFAULT_AGENT="$(extract_agent_from_session_key "$DEFAULT_SESSION_KEY")"
fi

if [[ "$EXPLICIT_EXIT" -eq 0 ]]; then
  EXPLICIT_STATUS="$(extract_json "$ARTIFACT_DIR/explicit_route.out" '.status // ""')"
  EXPLICIT_RUN_ID="$(extract_json "$ARTIFACT_DIR/explicit_route.out" '.runId // ""')"
  EXPLICIT_SESSION_KEY="$(extract_json "$ARTIFACT_DIR/explicit_route.out" '.result.meta.systemPromptReport.sessionKey // ""')"
  EXPLICIT_AGENT="$(extract_agent_from_session_key "$EXPLICIT_SESSION_KEY")"
fi

RESULT="probe_error"
if [[ "$DEFAULT_EXIT" -eq 0 && "$EXPLICIT_EXIT" -eq 0 ]]; then
  if [[ -n "$DEFAULT_AGENT" && -n "$EXPLICIT_AGENT" && "$DEFAULT_AGENT" == "$EXPLICIT_AGENT" ]]; then
    RESULT="route_parity_ok"
  else
    RESULT="route_mismatch_detected"
  fi
fi

NOTE="probe_error means at least one probe command failed; check *.err for details."
if [[ "$RESULT" == "route_parity_ok" ]]; then
  NOTE="route_parity_ok means default --to and explicit --agent resolved to the same agent session key."
elif [[ "$RESULT" == "route_mismatch_detected" ]]; then
  NOTE="route_mismatch_detected means default --to and explicit --agent resolve to different agent session keys."
fi

SUMMARY="$ARTIFACT_DIR/summary.txt"
cat >"$SUMMARY" <<EOF
timestamp=$(date +%Y-%m-%dT%H:%M:%S%z)
probe_root=$PROBE_ROOT
container_name=$CONTAINER_NAME
route_to=$ROUTE_TO
route_agent=$ROUTE_AGENT
version_exit=$VERSION_EXIT
agents_bindings_exit=$BINDINGS_EXIT
default_exit=$DEFAULT_EXIT
explicit_exit=$EXPLICIT_EXIT
default_status=$DEFAULT_STATUS
explicit_status=$EXPLICIT_STATUS
default_runid=$DEFAULT_RUN_ID
explicit_runid=$EXPLICIT_RUN_ID
default_session_key=$DEFAULT_SESSION_KEY
explicit_session_key=$EXPLICIT_SESSION_KEY
default_agent=$DEFAULT_AGENT
explicit_agent=$EXPLICIT_AGENT
result=$RESULT
note=$NOTE
EOF

log "done"
log "probe root: $PROBE_ROOT"
log "summary: $SUMMARY"
cat "$SUMMARY"
