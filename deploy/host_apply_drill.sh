#!/usr/bin/env bash
set -euo pipefail
umask 077

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BASE_COMPOSE="${BASE_COMPOSE:-$HOME/.openclaw/olympus-deploy.yml}"
OVERRIDE_COMPOSE="${OVERRIDE_COMPOSE:-$PROJECT_ROOT/deploy/agent_argus.override.yml}"

ARCHIVE="${ARCHIVE:-}"
MANIFEST="${MANIFEST:-}"
PASSPHRASE_FILE="${OPENCLAW_BACKUP_PASSPHRASE_FILE:-}"
PASSPHRASE="${OPENCLAW_BACKUP_PASSPHRASE:-}"

TS="$(date +%Y%m%d-%H%M%S)"
DRILL_ROOT="${DRILL_ROOT:-/tmp/openclaw-host-apply-drill-$TS}"
ARTIFACT_DIR="$DRILL_ROOT/artifacts"
STAGE_DIR="$DRILL_ROOT/restore-stage"
SNAPSHOT_DIR="$DRILL_ROOT/host-snapshot"

HOST_STATE_DIR="$HOME/.openclaw/state/argus"
HOST_WORKSPACES_DIR="$HOME/.openclaw/workspaces/argus"

HAD_STATE=0
HAD_WORKSPACES=0
APPLIED=0
ROLLED_BACK=0

log() {
  printf '[host-apply-drill] %s\n' "$*"
}

collect_host_metrics() {
  local out="$1"
  {
    echo "timestamp=$(date +%Y-%m-%dT%H:%M:%S%z)"
    if [[ -d "$HOST_STATE_DIR" ]]; then
      echo "state_dir=$HOST_STATE_DIR"
      du -sh "$HOST_STATE_DIR"
      printf 'state_files=%s\n' "$(find "$HOST_STATE_DIR" -type f | wc -l | awk '{print $1}')"
    else
      echo "state_dir=missing"
    fi

    if [[ -d "$HOST_WORKSPACES_DIR" ]]; then
      echo "workspaces_dir=$HOST_WORKSPACES_DIR"
      du -sh "$HOST_WORKSPACES_DIR"
      printf 'workspaces_files=%s\n' "$(find "$HOST_WORKSPACES_DIR" -type f | wc -l | awk '{print $1}')"
    else
      echo "workspaces_dir=missing"
    fi
  } >"$out"
}

need_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "missing command: $cmd" >&2
    exit 1
  fi
}

collect_postrollback_evidence() {
  docker exec agent_argus openclaw config file >"$ARTIFACT_DIR/postrollback-config-file.txt"
  docker exec agent_argus openclaw agents list --bindings --json >"$ARTIFACT_DIR/postrollback-agents.json"
  curl -fsSL http://localhost:3001/__openclaw/control-ui-config.json >"$ARTIFACT_DIR/postrollback-control-ui-config.json"
  collect_host_metrics "$ARTIFACT_DIR/postrollback-host-metrics.txt"
}

rollback_host_state() {
  if [[ "$ROLLED_BACK" -eq 1 ]]; then
    return 0
  fi
  log "rolling back host state/workspaces from snapshot"

  if [[ "$HAD_STATE" -eq 1 ]]; then
    mkdir -p "$HOST_STATE_DIR"
    rsync -a --delete "$SNAPSHOT_DIR/state_argus/" "$HOST_STATE_DIR/"
  fi

  if [[ "$HAD_WORKSPACES" -eq 1 ]]; then
    mkdir -p "$HOST_WORKSPACES_DIR"
    rsync -a --delete "$SNAPSHOT_DIR/workspaces_argus/" "$HOST_WORKSPACES_DIR/"
  fi

  log "recreating containers on original override after rollback"
  docker compose \
    -f "$BASE_COMPOSE" \
    -f "$OVERRIDE_COMPOSE" \
    up -d --force-recreate agent_argus sidecar_argus >"$ARTIFACT_DIR/postrollback-compose.up.log" 2>&1

  collect_postrollback_evidence
  ROLLED_BACK=1
  log "rollback completed"
}

on_exit() {
  local code=$?
  if [[ "$APPLIED" -eq 1 && "$ROLLED_BACK" -eq 0 ]]; then
    set +e
    rollback_host_state
    set -e
  fi
  exit "$code"
}

trap on_exit EXIT

need_cmd rsync
need_cmd docker
need_cmd curl

if [[ -z "$ARCHIVE" ]]; then
  echo "ARCHIVE is required" >&2
  exit 1
fi

if [[ ! -f "$ARCHIVE" ]]; then
  echo "archive not found: $ARCHIVE" >&2
  exit 1
fi

if [[ -z "$MANIFEST" ]]; then
  CANDIDATE_MANIFEST="${ARCHIVE%.tgz.enc}.manifest.txt"
  if [[ -f "$CANDIDATE_MANIFEST" ]]; then
    MANIFEST="$CANDIDATE_MANIFEST"
  fi
fi

if [[ -z "$PASSPHRASE" && -z "$PASSPHRASE_FILE" ]]; then
  echo "set OPENCLAW_BACKUP_PASSPHRASE_FILE or OPENCLAW_BACKUP_PASSPHRASE" >&2
  exit 1
fi

mkdir -p "$ARTIFACT_DIR" "$SNAPSHOT_DIR"
exec > >(tee -a "$ARTIFACT_DIR/host-apply-drill.log") 2>&1

if [[ -d "$HOST_STATE_DIR" ]]; then
  HAD_STATE=1
  mkdir -p "$SNAPSHOT_DIR/state_argus"
  rsync -a "$HOST_STATE_DIR/" "$SNAPSHOT_DIR/state_argus/"
fi

if [[ -d "$HOST_WORKSPACES_DIR" ]]; then
  HAD_WORKSPACES=1
  mkdir -p "$SNAPSHOT_DIR/workspaces_argus"
  rsync -a "$HOST_WORKSPACES_DIR/" "$SNAPSHOT_DIR/workspaces_argus/"
fi

log "snapshot completed: HAD_STATE=$HAD_STATE HAD_WORKSPACES=$HAD_WORKSPACES"
collect_host_metrics "$ARTIFACT_DIR/preapply-host-metrics.txt"

if [[ -n "$PASSPHRASE_FILE" ]]; then
  ARCHIVE="$ARCHIVE" MANIFEST="$MANIFEST" OPENCLAW_BACKUP_PASSPHRASE_FILE="$PASSPHRASE_FILE" STAGE_DIR="$STAGE_DIR" \
    bash "$PROJECT_ROOT/scripts/restore_state.sh" >"$ARTIFACT_DIR/stage-restore.log" 2>&1
else
  ARCHIVE="$ARCHIVE" MANIFEST="$MANIFEST" OPENCLAW_BACKUP_PASSPHRASE="$PASSPHRASE" STAGE_DIR="$STAGE_DIR" \
    bash "$PROJECT_ROOT/scripts/restore_state.sh" >"$ARTIFACT_DIR/stage-restore.log" 2>&1
fi

EXTRACTED="$STAGE_DIR/extracted/host-openclaw"

if [[ -d "$EXTRACTED/state/argus" ]]; then
  mkdir -p "$HOST_STATE_DIR"
  rsync -a --delete "$EXTRACTED/state/argus/" "$HOST_STATE_DIR/"
fi

if [[ -d "$EXTRACTED/workspaces/argus" ]]; then
  mkdir -p "$HOST_WORKSPACES_DIR"
  rsync -a --delete "$EXTRACTED/workspaces/argus/" "$HOST_WORKSPACES_DIR/"
fi

APPLIED=1
log "host apply completed"
collect_host_metrics "$ARTIFACT_DIR/applied-host-metrics.txt"

docker compose \
  -f "$BASE_COMPOSE" \
  -f "$OVERRIDE_COMPOSE" \
  up -d --force-recreate agent_argus sidecar_argus >"$ARTIFACT_DIR/applied-compose.up.log" 2>&1

docker exec agent_argus openclaw config file >"$ARTIFACT_DIR/applied-config-file.txt"
docker exec agent_argus openclaw agents list --bindings --json >"$ARTIFACT_DIR/applied-agents.json"
curl -fsSL http://localhost:3001/__openclaw/control-ui-config.json >"$ARTIFACT_DIR/applied-control-ui-config.json"
docker exec agent_argus openclaw agent \
  --agent steward \
  --message "host apply 演练冒烟：一句话说明职责边界。" \
  --json >"$ARTIFACT_DIR/applied-steward-smoke.json"

rollback_host_state

log "done"
log "drill root: $DRILL_ROOT"
log "artifact dir: $ARTIFACT_DIR"
