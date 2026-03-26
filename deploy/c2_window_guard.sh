#!/usr/bin/env bash
set -euo pipefail
umask 077

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

TZ_REGION="${TZ_REGION:-Asia/Shanghai}"
WINDOW_START="${WINDOW_START:-2026-04-22}"
WINDOW_END="${WINDOW_END:-2026-04-28}"
TODAY="${TODAY_OVERRIDE:-$(TZ="$TZ_REGION" date +%F)}"
PASSPHRASE_FILE="${OPENCLAW_BACKUP_PASSPHRASE_FILE:-$HOME/.openclaw/secrets/backup_passphrase.txt}"

log() {
  printf '[c2-window-guard] %s\n' "$*"
}

log "timezone=$TZ_REGION today=$TODAY window=$WINDOW_START..$WINDOW_END"

if [[ "$TODAY" < "$WINDOW_START" || "$TODAY" > "$WINDOW_END" ]]; then
  log "outside execution window, skip monthly drill."
  log "this is expected before 2026-04-22 or after 2026-04-28."
  exit 2
fi

log "inside execution window, running preflight."
bash ./deploy/monthly_recovery_preflight.sh

log "running monthly recovery drill."
OPENCLAW_BACKUP_PASSPHRASE_FILE="$PASSPHRASE_FILE" bash ./deploy/monthly_recovery_drill.sh

log "completed."
