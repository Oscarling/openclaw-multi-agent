#!/usr/bin/env bash
set -euo pipefail
umask 077

# Backward-compat entrypoint. We have switched to event-driven trigger mode.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

printf '[c2-window-guard] deprecated: use event trigger mode via deploy/c2_event_guard.sh\n'
exec bash ./deploy/c2_event_guard.sh "$@"
