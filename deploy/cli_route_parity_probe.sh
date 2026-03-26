#!/usr/bin/env bash
set -euo pipefail
umask 077

TS="$(date +%Y%m%d-%H%M%S)"
PROBE_ROOT="${PROBE_ROOT:-/tmp/openclaw-cli-route-probe-$TS}"
ARTIFACT_DIR="$PROBE_ROOT/artifacts"
CONTAINER_NAME="${OPENCLAW_AGENT_CONTAINER:-agent_argus}"
ROUTE_PROBE_TO="${ROUTE_PROBE_TO:-+15550001111}"
ROUTE_PROBE_AGENT="${ROUTE_PROBE_AGENT:-steward}"
ROUTE_PROBE_MESSAGE="${ROUTE_PROBE_MESSAGE:-route parity probe}"
ROUTE_PROBE_STRICT="${ROUTE_PROBE_STRICT:-no}"

log() {
  printf '[cli-route-probe] %s\n' "$*"
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
  local out="$ARTIFACT_DIR/$name.out.json"
  local err="$ARTIFACT_DIR/$name.err.log"
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

log "running default path probe (--to without --agent)"
run_capture "default_route" docker exec "$CONTAINER_NAME" openclaw agent \
  --to "$ROUTE_PROBE_TO" \
  --session-id "routeprobe-default-$TS" \
  --message "$ROUTE_PROBE_MESSAGE" \
  --json

log "running explicit path probe (--agent + --to)"
run_capture "explicit_route" docker exec "$CONTAINER_NAME" openclaw agent \
  --agent "$ROUTE_PROBE_AGENT" \
  --to "$ROUTE_PROBE_TO" \
  --session-id "routeprobe-explicit-$TS" \
  --message "$ROUTE_PROBE_MESSAGE" \
  --json

DEFAULT_EXIT="$(cat "$ARTIFACT_DIR/default_route.exitcode")"
EXPLICIT_EXIT="$(cat "$ARTIFACT_DIR/explicit_route.exitcode")"

DEFAULT_RUN_ID=""
DEFAULT_SESSION_KEY=""
DEFAULT_AGENT=""
DEFAULT_STATUS=""

EXPLICIT_RUN_ID=""
EXPLICIT_SESSION_KEY=""
EXPLICIT_AGENT=""
EXPLICIT_STATUS=""

if [[ "$DEFAULT_EXIT" -eq 0 ]]; then
  DEFAULT_RUN_ID="$(extract_json "$ARTIFACT_DIR/default_route.out.json" '.runId // ""')"
  DEFAULT_SESSION_KEY="$(extract_json "$ARTIFACT_DIR/default_route.out.json" '.result.meta.systemPromptReport.sessionKey // ""')"
  DEFAULT_STATUS="$(extract_json "$ARTIFACT_DIR/default_route.out.json" '.status // ""')"
  DEFAULT_AGENT="$(extract_agent_from_session_key "$DEFAULT_SESSION_KEY")"
fi

if [[ "$EXPLICIT_EXIT" -eq 0 ]]; then
  EXPLICIT_RUN_ID="$(extract_json "$ARTIFACT_DIR/explicit_route.out.json" '.runId // ""')"
  EXPLICIT_SESSION_KEY="$(extract_json "$ARTIFACT_DIR/explicit_route.out.json" '.result.meta.systemPromptReport.sessionKey // ""')"
  EXPLICIT_STATUS="$(extract_json "$ARTIFACT_DIR/explicit_route.out.json" '.status // ""')"
  EXPLICIT_AGENT="$(extract_agent_from_session_key "$EXPLICIT_SESSION_KEY")"
fi

PROBE_RESULT="probe_error"
if [[ "$DEFAULT_EXIT" -eq 0 && "$EXPLICIT_EXIT" -eq 0 ]]; then
  if [[ -n "$DEFAULT_AGENT" && -n "$EXPLICIT_AGENT" && "$DEFAULT_AGENT" == "$EXPLICIT_AGENT" ]]; then
    PROBE_RESULT="route_parity_ok"
  else
    PROBE_RESULT="route_mismatch_detected"
  fi
fi

SUMMARY_FILE="$ARTIFACT_DIR/probe-summary.txt"
cat >"$SUMMARY_FILE" <<EOF
timestamp=$(date +%Y-%m-%dT%H:%M:%S%z)
probe_root=$PROBE_ROOT
container_name=$CONTAINER_NAME
route_probe_to=$ROUTE_PROBE_TO
route_probe_agent=$ROUTE_PROBE_AGENT
default_route_exit=$DEFAULT_EXIT
explicit_route_exit=$EXPLICIT_EXIT
default_route_status=$DEFAULT_STATUS
explicit_route_status=$EXPLICIT_STATUS
default_route_runid=$DEFAULT_RUN_ID
explicit_route_runid=$EXPLICIT_RUN_ID
default_route_session_key=$DEFAULT_SESSION_KEY
explicit_route_session_key=$EXPLICIT_SESSION_KEY
default_route_agent=$DEFAULT_AGENT
explicit_route_agent=$EXPLICIT_AGENT
probe_result=$PROBE_RESULT
note=route_parity_ok means default --to path hits same agent as explicit --agent path. route_mismatch_detected means default path likely still drifts from expected default entry.
EOF

log "done"
log "probe root: $PROBE_ROOT"
log "summary: $SUMMARY_FILE"
cat "$SUMMARY_FILE"

if [[ "$ROUTE_PROBE_STRICT" == "yes" && "$PROBE_RESULT" != "route_parity_ok" ]]; then
  exit 4
fi
