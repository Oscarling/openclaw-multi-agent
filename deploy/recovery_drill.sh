#!/usr/bin/env bash
set -euo pipefail
umask 077

# Recovery drill for agent_argus:
# 1) Prepare a clean drill workspace under /tmp
# 2) Restore runtime backup into drill workspace
# 3) Recreate agent_argus/sidecar_argus against drill workspace
# 4) Run smoke checks and collect evidence
# 5) Roll back to the original project override

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BASE_COMPOSE="${BASE_COMPOSE:-$HOME/.openclaw/olympus-deploy.yml}"
ORIGINAL_OVERRIDE="$PROJECT_ROOT/deploy/agent_argus.override.yml"
OVERRIDE_TEMPLATE="$PROJECT_ROOT/deploy/agent_argus.override.example.yml"

TS="$(date +%Y%m%d-%H%M%S)"
DRILL_ROOT_DEFAULT="/tmp/openclaw-recovery-drill-$TS"
DRILL_ROOT="${DRILL_ROOT:-$DRILL_ROOT_DEFAULT}"
ARTIFACT_DIR="$DRILL_ROOT/artifacts"

ROLLED_BACK=0

log() {
  printf '[recovery-drill] %s\n' "$*"
}

require_file() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    echo "missing required file: $file" >&2
    exit 1
  fi
}

rollback_original() {
  log "rolling back to original override"
  docker compose \
    -f "$BASE_COMPOSE" \
    -f "$ORIGINAL_OVERRIDE" \
    up -d --force-recreate agent_argus sidecar_argus >/dev/null
  ROLLED_BACK=1
  log "rollback completed"
}

on_exit() {
  local exit_code=$?
  if [[ "$ROLLED_BACK" -eq 0 ]]; then
    set +e
    rollback_original
    set -e
  fi
  exit "$exit_code"
}

trap on_exit EXIT

require_file "$BASE_COMPOSE"
require_file "$ORIGINAL_OVERRIDE"
require_file "$OVERRIDE_TEMPLATE"
require_file "$PROJECT_ROOT/runtime/argus/config/openclaw.json"

mkdir -p "$ARTIFACT_DIR"
mkdir -p "$DRILL_ROOT/runtime/argus/config" "$DRILL_ROOT/runtime/argus/agents"

log "copying project skeleton into drill workspace"
rsync -a \
  --exclude 'runtime/' \
  --exclude 'artifacts/' \
  --exclude '.git/' \
  --exclude '.DS_Store' \
  "$PROJECT_ROOT/" "$DRILL_ROOT/"

log "creating runtime backup archive from current project runtime"
BACKUP_TGZ="$ARTIFACT_DIR/runtime-backup-$TS.tgz"
tar -czf "$BACKUP_TGZ" \
  -C "$PROJECT_ROOT/runtime/argus" \
  agents config/openclaw.json

log "restoring runtime backup into drill workspace"
tar -xzf "$BACKUP_TGZ" -C "$DRILL_ROOT/runtime/argus"
rm -f "$BACKUP_TGZ"
log "removed plaintext runtime backup archive in drill workspace"

log "rendering compose config against drill workspace"
OPENCLAW_PROJECT_ROOT="$DRILL_ROOT" docker compose \
  -f "$BASE_COMPOSE" \
  -f "$DRILL_ROOT/deploy/agent_argus.override.example.yml" \
  config >"$ARTIFACT_DIR/drill-compose.rendered.yml"

log "recreating containers against drill workspace"
OPENCLAW_PROJECT_ROOT="$DRILL_ROOT" docker compose \
  -f "$BASE_COMPOSE" \
  -f "$DRILL_ROOT/deploy/agent_argus.override.example.yml" \
  up -d --force-recreate agent_argus sidecar_argus >"$ARTIFACT_DIR/drill-compose.up.log" 2>&1

log "collecting drill evidence"
docker exec agent_argus openclaw config file >"$ARTIFACT_DIR/drill-config-file.txt"
docker exec agent_argus openclaw agents list --bindings --json >"$ARTIFACT_DIR/drill-agents.json"
docker exec agent_argus sh -lc \
  'mount | grep -E "/root/.openclaw/config|/root/.openclaw/agents|/root/.openclaw/openclaw.json"' \
  >"$ARTIFACT_DIR/drill-mounts.txt"
curl -fsSL http://localhost:3001/__openclaw/control-ui-config.json >"$ARTIFACT_DIR/drill-control-ui-config.json"
docker logs --tail 60 agent_argus >"$ARTIFACT_DIR/drill-agent-log-tail.txt"

docker exec agent_argus openclaw agent \
  --agent steward \
  --message "恢复演练冒烟：请一句话说明你的职责边界。" \
  --json >"$ARTIFACT_DIR/drill-steward-smoke.json"

if command -v jq >/dev/null 2>&1; then
  jq -r '.runId // ""' "$ARTIFACT_DIR/drill-steward-smoke.json" >"$ARTIFACT_DIR/drill-steward-runid.txt"
else
  echo "jq not found" >"$ARTIFACT_DIR/drill-steward-runid.txt"
fi

rollback_original

log "collecting post-rollback evidence"
docker exec agent_argus openclaw config file >"$ARTIFACT_DIR/postrollback-config-file.txt"
docker exec agent_argus openclaw agents list --bindings --json >"$ARTIFACT_DIR/postrollback-agents.json"
curl -fsSL http://localhost:3001/__openclaw/control-ui-config.json >"$ARTIFACT_DIR/postrollback-control-ui-config.json"

log "done"
log "drill root: $DRILL_ROOT"
log "artifact dir: $ARTIFACT_DIR"
