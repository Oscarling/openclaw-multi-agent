#!/usr/bin/env bash
set -euo pipefail
umask 077

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKUP_DIR="$PROJECT_ROOT/artifacts/backups"
PASSPHRASE_FILE="${OPENCLAW_BACKUP_PASSPHRASE_FILE:-$HOME/.openclaw/secrets/backup_passphrase.txt}"

TS="$(date +%Y%m%d-%H%M%S)"
CHECK_ROOT="${CHECK_ROOT:-/tmp/openclaw-monthly-preflight-$TS}"
ARTIFACT_DIR="$CHECK_ROOT/artifacts"
SUMMARY_FILE="$ARTIFACT_DIR/preflight-summary.txt"

log() {
  printf '[monthly-preflight] %s\n' "$*"
}

need_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "missing command: $cmd" >&2
    exit 1
  fi
}

perm_octal() {
  local target="$1"
  local mode
  mode="$(stat -f '%Lp' "$target" 2>/dev/null || true)"
  if [[ -z "$mode" ]]; then
    mode="$(stat -c '%a' "$target" 2>/dev/null || true)"
  fi
  echo "${mode:-unknown}"
}

need_cmd ls
need_cmd shasum
need_cmd awk
need_cmd docker
need_cmd bash

mkdir -p "$ARTIFACT_DIR"

ARCHIVE="$(ls -1t "$BACKUP_DIR"/*.tgz.enc 2>/dev/null | head -n 1 || true)"
MANIFEST=""
ARCHIVE_OK="no"
MANIFEST_OK="no"
SHA256_OK="no"
PASSPHRASE_OK="no"
PASSPHRASE_PERM="missing"
AGENT_CONTAINER_OK="no"
MONTHLY_SCRIPT_OK="no"
RECOVERY_SCRIPT_OK="no"
HOST_APPLY_SCRIPT_OK="no"

if [[ -n "$ARCHIVE" && -f "$ARCHIVE" ]]; then
  ARCHIVE_OK="yes"
  MANIFEST="${ARCHIVE%.tgz.enc}.manifest.txt"
fi

if [[ -n "$MANIFEST" && -f "$MANIFEST" ]]; then
  MANIFEST_OK="yes"
  EXPECTED_SHA="$(awk -F= '/^sha256=/{print $2; exit}' "$MANIFEST")"
  ACTUAL_SHA="$(shasum -a 256 "$ARCHIVE" | awk '{print $1}')"
  if [[ -n "$EXPECTED_SHA" && "$EXPECTED_SHA" == "$ACTUAL_SHA" ]]; then
    SHA256_OK="yes"
  fi
fi

if [[ -f "$PASSPHRASE_FILE" ]]; then
  PASSPHRASE_OK="yes"
  PASSPHRASE_PERM="$(perm_octal "$PASSPHRASE_FILE")"
fi

if docker ps --format '{{.Names}}' | grep -qx 'agent_argus'; then
  AGENT_CONTAINER_OK="yes"
fi

if bash -n "$PROJECT_ROOT/deploy/monthly_recovery_drill.sh" >/dev/null 2>&1; then
  MONTHLY_SCRIPT_OK="yes"
fi

if bash -n "$PROJECT_ROOT/deploy/recovery_drill.sh" >/dev/null 2>&1; then
  RECOVERY_SCRIPT_OK="yes"
fi

if bash -n "$PROJECT_ROOT/deploy/host_apply_drill.sh" >/dev/null 2>&1; then
  HOST_APPLY_SCRIPT_OK="yes"
fi

PREFLIGHT_RESULT="blocked"
if [[ \
  "$ARCHIVE_OK" == "yes" && \
  "$MANIFEST_OK" == "yes" && \
  "$SHA256_OK" == "yes" && \
  "$PASSPHRASE_OK" == "yes" && \
  "$AGENT_CONTAINER_OK" == "yes" && \
  "$MONTHLY_SCRIPT_OK" == "yes" && \
  "$RECOVERY_SCRIPT_OK" == "yes" && \
  "$HOST_APPLY_SCRIPT_OK" == "yes" ]]; then
  PREFLIGHT_RESULT="ready_for_monthly_window"
fi

cat >"$SUMMARY_FILE" <<EOF
timestamp=$(date +%Y-%m-%dT%H:%M:%S%z)
check_root=$CHECK_ROOT
archive=$ARCHIVE
archive_ok=$ARCHIVE_OK
manifest=$MANIFEST
manifest_ok=$MANIFEST_OK
sha256_ok=$SHA256_OK
passphrase_file=$PASSPHRASE_FILE
passphrase_ok=$PASSPHRASE_OK
passphrase_perm=$PASSPHRASE_PERM
agent_container_ok=$AGENT_CONTAINER_OK
monthly_script_ok=$MONTHLY_SCRIPT_OK
recovery_script_ok=$RECOVERY_SCRIPT_OK
host_apply_script_ok=$HOST_APPLY_SCRIPT_OK
preflight_result=$PREFLIGHT_RESULT
trigger_mode=event_driven
trigger_rule=run_when_preflight_ready_and_mainline_unblocked
EOF

log "done"
log "check root: $CHECK_ROOT"
log "summary: $SUMMARY_FILE"
cat "$SUMMARY_FILE"
