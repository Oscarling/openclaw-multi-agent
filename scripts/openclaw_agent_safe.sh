#!/usr/bin/env bash
set -euo pipefail
umask 077

CONTAINER_NAME="${OPENCLAW_AGENT_CONTAINER:-agent_argus}"

log() {
  printf '[openclaw-agent-safe] %s\n' "$*" >&2
}

usage() {
  cat >&2 <<'EOF'
Usage:
  bash ./scripts/openclaw_agent_safe.sh --agent <agent_id> [openclaw agent args...]

Examples:
  bash ./scripts/openclaw_agent_safe.sh --agent steward --message "请做需求收敛"
  bash ./scripts/openclaw_agent_safe.sh --agent hunter --session-id test-001 --message "请给选题卡"

Notes:
  - This wrapper enforces explicit --agent to avoid CLI default routing ambiguity.
  - OPENCLAW_AGENT_CONTAINER can override the target container (default: agent_argus).
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ "$#" -eq 0 ]]; then
  usage
  exit 2
fi

need_value_after_agent="no"
has_agent="no"
has_to="no"

for arg in "$@"; do
  if [[ "$need_value_after_agent" == "yes" ]]; then
    if [[ -z "$arg" || "$arg" == --* ]]; then
      log "invalid --agent value"
      exit 2
    fi
    has_agent="yes"
    need_value_after_agent="no"
    continue
  fi

  case "$arg" in
    --agent)
      need_value_after_agent="yes"
      ;;
    --agent=*)
      if [[ "$arg" == "--agent=" ]]; then
        log "invalid --agent value"
        exit 2
      fi
      has_agent="yes"
      ;;
    --to|--to=*)
      has_to="yes"
      ;;
  esac
done

if [[ "$need_value_after_agent" == "yes" ]]; then
  log "missing value for --agent"
  exit 2
fi

if [[ "$has_agent" != "yes" ]]; then
  log "blocked: explicit --agent is required."
  if [[ "$has_to" == "yes" ]]; then
    log "reason: --to without --agent may route to main in current environment."
  fi
  usage
  exit 2
fi

if ! command -v docker >/dev/null 2>&1; then
  log "missing command: docker"
  exit 1
fi

exec docker exec "$CONTAINER_NAME" openclaw agent "$@"
