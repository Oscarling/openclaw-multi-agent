#!/usr/bin/env bash
set -euo pipefail
umask 077

TS="$(date +%Y%m%d-%H%M%S)"
PROBE_ROOT="${PROBE_ROOT:-/tmp/openclaw-gate2-probe-$TS}"
ARTIFACT_DIR="$PROBE_ROOT/artifacts"

log() {
  printf '[gate2-probe] %s\n' "$*"
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
  local out="$ARTIFACT_DIR/$name.out.log"
  local err="$ARTIFACT_DIR/$name.err.log"
  local code_file="$ARTIFACT_DIR/$name.exitcode"

  set +e
  "$@" >"$out" 2>"$err"
  local code=$?
  set -e

  echo "$code" >"$code_file"
}

need_cmd docker
need_cmd curl
need_cmd grep

mkdir -p "$ARTIFACT_DIR"

log "collecting baseline runtime state"
run_capture "agents_list" docker exec agent_argus openclaw agents list --bindings --json
run_capture "control_ui" curl -fsSL http://localhost:3001/__openclaw/control-ui-config.json
run_capture "channels_list" docker exec agent_argus openclaw channels list --json
run_capture "channels_status" docker exec agent_argus openclaw channels status --json

log "probing bind command availability"
run_capture "bind_help" docker exec agent_argus openclaw agents bind --help

BIND_HELP_CODE="$(cat "$ARTIFACT_DIR/bind_help.exitcode")"
CHANNELS_LIST_CODE="$(cat "$ARTIFACT_DIR/channels_list.exitcode")"
CHANNELS_STATUS_CODE="$(cat "$ARTIFACT_DIR/channels_status.exitcode")"
AGENTS_LIST_CODE="$(cat "$ARTIFACT_DIR/agents_list.exitcode")"
CONTROL_UI_CODE="$(cat "$ARTIFACT_DIR/control_ui.exitcode")"

BIND_COMMAND_AVAILABLE="no"
if [[ "$BIND_HELP_CODE" -eq 0 ]]; then
  BIND_COMMAND_AVAILABLE="yes"
fi

if grep -qiE 'unknown command|not found|no such command' \
  "$ARTIFACT_DIR/bind_help.out.log" \
  "$ARTIFACT_DIR/bind_help.err.log"; then
  BIND_COMMAND_AVAILABLE="no"
fi

GATE2_PROBE_RESULT="blocked"
CHANNEL_CONFIGURED="unknown"
CHANNEL_PRESENT="unknown"
if [[ "$CHANNELS_STATUS_CODE" -eq 0 ]]; then
  CHANNEL_PRESENT="yes"
  CHANNEL_CONFIGURED="no"
  if grep -q '"channelOrder":[[:space:]]*\[\]' "$ARTIFACT_DIR/channels_status.out.log"; then
    CHANNEL_PRESENT="no"
  fi
  if grep -q '"configured":[[:space:]]*true' "$ARTIFACT_DIR/channels_status.out.log"; then
    CHANNEL_CONFIGURED="yes"
  fi
fi

if [[ "$AGENTS_LIST_CODE" -eq 0 && "$CONTROL_UI_CODE" -eq 0 && "$BIND_COMMAND_AVAILABLE" == "yes" ]]; then
  if [[ "$CHANNEL_PRESENT" == "yes" && "$CHANNEL_CONFIGURED" == "yes" ]]; then
    GATE2_PROBE_RESULT="ready_for_binding_test"
  elif [[ "$CHANNEL_PRESENT" == "no" ]]; then
    GATE2_PROBE_RESULT="waiting_channel_configuration"
  elif [[ "$CHANNEL_PRESENT" == "yes" && "$CHANNEL_CONFIGURED" == "no" ]]; then
    GATE2_PROBE_RESULT="waiting_channel_credentials"
  fi
fi

SUMMARY_FILE="$ARTIFACT_DIR/probe-summary.txt"
cat >"$SUMMARY_FILE" <<EOF
timestamp=$(date +%Y-%m-%dT%H:%M:%S%z)
probe_root=$PROBE_ROOT
agents_list_exit=$AGENTS_LIST_CODE
control_ui_exit=$CONTROL_UI_CODE
bind_help_exit=$BIND_HELP_CODE
channels_list_exit=$CHANNELS_LIST_CODE
channels_status_exit=$CHANNELS_STATUS_CODE
bind_command_available=$BIND_COMMAND_AVAILABLE
channel_present=$CHANNEL_PRESENT
channel_configured=$CHANNEL_CONFIGURED
gate2_probe_result=$GATE2_PROBE_RESULT
note=ready_for_binding_test means prerequisites passed; actual channel bind still needs live execution and validation. waiting_channel_configuration means no channel/account exists. waiting_channel_credentials means channel/account exists but credentials are still missing.
EOF

log "done"
log "probe root: $PROBE_ROOT"
log "summary: $SUMMARY_FILE"
cat "$SUMMARY_FILE"
