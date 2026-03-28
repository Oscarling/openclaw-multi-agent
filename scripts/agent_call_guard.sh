#!/usr/bin/env bash
set -euo pipefail
umask 077

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

log() {
  printf '[agent-call-guard] %s\n' "$*"
}

need_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    log "missing command: $cmd"
    exit 1
  fi
}

need_cmd rg

# Guardrail:
# deploy scripts must not invoke "docker exec ... openclaw agent" directly.
# Use scripts/openclaw_agent_safe.sh instead.
PATTERN='docker exec[[:space:]].*openclaw agent(?!s)'
EXEMPT_FILES=(
  "deploy/cli_route_parity_probe.sh"
)

matches=()
for file in deploy/*.sh; do
  skip="no"
  for exempt in "${EXEMPT_FILES[@]}"; do
    if [[ "$file" == "$exempt" ]]; then
      skip="yes"
      break
    fi
  done
  if [[ "$skip" == "yes" ]]; then
    continue
  fi

  set +e
  file_matches="$(rg -n -P "$PATTERN" "$file" 2>/dev/null)"
  code=$?
  set -e

  if [[ "$code" -eq 0 && -n "$file_matches" ]]; then
    matches+=("$file_matches")
  elif [[ "$code" -ne 1 ]]; then
    log "unexpected rg exit code: $code (file=$file)"
    exit 1
  fi
done

if [[ "${#matches[@]}" -gt 0 ]]; then
  log "blocked direct openclaw agent calls in deploy scripts:"
  printf '%s\n' "${matches[@]}"
  log "please route calls via scripts/openclaw_agent_safe.sh"
  exit 2
fi

log "ok"
