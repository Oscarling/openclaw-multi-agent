#!/usr/bin/env bash
set -euo pipefail
umask 077

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

log() {
  printf '[premerge-check] %s\n' "$*"
}

need_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    log "missing command: $cmd"
    exit 1
  fi
}

need_cmd python3
need_cmd git

log "running backlog lint"
python3 scripts/backlog_lint.py

log "running backlog sync guard"
python3 scripts/backlog_sync.py

if [[ -f "scripts/openclaw_agent_safe.sh" ]]; then
  log "shell syntax check: scripts/openclaw_agent_safe.sh"
  bash -n scripts/openclaw_agent_safe.sh
fi

if compgen -G "scripts/rh_t5_b01_*.sh" >/dev/null; then
  for f in scripts/rh_t5_b01_*.sh; do
    log "shell syntax check: $f"
    bash -n "$f"
  done
fi

if [[ -f "scripts/agent_call_guard.sh" ]]; then
  log "running direct agent-call guard"
  bash scripts/agent_call_guard.sh
fi

log "working tree snapshot"
git status -sb

log "ok"
