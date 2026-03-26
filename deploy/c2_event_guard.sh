#!/usr/bin/env bash
set -euo pipefail
umask 077

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

C2_TRIGGER_EVENT="${C2_TRIGGER_EVENT:-}"
PASSPHRASE_FILE="${OPENCLAW_BACKUP_PASSPHRASE_FILE:-$HOME/.openclaw/secrets/backup_passphrase.txt}"

log() {
  printf '[c2-event-guard] %s\n' "$*"
}

if [[ -z "$C2_TRIGGER_EVENT" ]]; then
  log "missing C2_TRIGGER_EVENT; refuse to run."
  log "example: C2_TRIGGER_EVENT='mainline_ready' bash ./deploy/c2_event_guard.sh"
  exit 2
fi

log "trigger_event=$C2_TRIGGER_EVENT"
log "running preflight"

PREFLIGHT_LOG="$(mktemp /tmp/c2-event-preflight-XXXXXX)"
bash ./deploy/monthly_recovery_preflight.sh | tee "$PREFLIGHT_LOG"

if ! grep -q 'preflight_result=ready_for_monthly_window' "$PREFLIGHT_LOG"; then
  log "preflight result is not ready_for_monthly_window, stop."
  exit 3
fi

log "preflight ready, running monthly recovery drill"
OPENCLAW_BACKUP_PASSPHRASE_FILE="$PASSPHRASE_FILE" bash ./deploy/monthly_recovery_drill.sh

log "completed"
