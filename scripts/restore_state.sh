#!/usr/bin/env bash
set -euo pipefail
umask 077

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT_DEFAULT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="${PROJECT_ROOT:-$PROJECT_ROOT_DEFAULT}"

ARCHIVE="${ARCHIVE:-}"
MANIFEST="${MANIFEST:-}"
STAGE_DIR_DEFAULT="/tmp/openclaw-restore-stage-$(date +%Y%m%d-%H%M%S)"
STAGE_DIR="${STAGE_DIR:-$STAGE_DIR_DEFAULT}"
APPLY="${APPLY:-0}"
ALLOW_NO_MANIFEST="${ALLOW_NO_MANIFEST:-0}"
I_UNDERSTAND_NO_INTEGRITY_CHECK="${I_UNDERSTAND_NO_INTEGRITY_CHECK:-0}"

PASSPHRASE="${OPENCLAW_BACKUP_PASSPHRASE:-}"
PASSPHRASE_FILE="${OPENCLAW_BACKUP_PASSPHRASE_FILE:-}"

usage() {
  cat <<'EOF'
usage:
  ARCHIVE=/path/to/openclaw-state-xxxx.tgz.enc OPENCLAW_BACKUP_PASSPHRASE_FILE=/path/to/passphrase.txt bash ./scripts/restore_state.sh

optional env:
  PROJECT_ROOT=/path/to/project
  MANIFEST=/path/to/openclaw-state-xxxx.manifest.txt
  STAGE_DIR=/tmp/custom-stage
  APPLY=1            # default is 0 (stage-only, no overwrite)
  ALLOW_NO_MANIFEST=1 # only for emergency restore, skip manifest check
  I_UNDERSTAND_NO_INTEGRITY_CHECK=1 # required when ALLOW_NO_MANIFEST=1
  OPENCLAW_BACKUP_PASSPHRASE_FILE=/path/to/passphrase.txt
EOF
}

log() {
  printf '[restore-state] %s\n' "$*"
}

need_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "missing required command: $cmd" >&2
    exit 1
  fi
}

need_cmd openssl
need_cmd tar
need_cmd rsync
need_cmd shasum

if [[ -z "$ARCHIVE" ]]; then
  usage >&2
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

if [[ -z "$MANIFEST" ]]; then
  if [[ "$ALLOW_NO_MANIFEST" != "1" ]]; then
    echo "manifest is required by default. provide MANIFEST or set ALLOW_NO_MANIFEST=1 for emergency restore." >&2
    exit 1
  fi
  if [[ "$I_UNDERSTAND_NO_INTEGRITY_CHECK" != "1" ]]; then
    echo "missing explicit confirmation: set I_UNDERSTAND_NO_INTEGRITY_CHECK=1 when ALLOW_NO_MANIFEST=1" >&2
    exit 1
  fi
  TS="$(date +%Y-%m-%dT%H:%M:%S%z)"
  ACTOR="$(whoami 2>/dev/null || echo unknown)"
  HOSTNAME="$(hostname 2>/dev/null || echo unknown)"
  log "AUDIT emergency restore without manifest ts=$TS actor=$ACTOR host=$HOSTNAME archive=$ARCHIVE stage_dir=$STAGE_DIR"
  log "ALLOW_NO_MANIFEST=1, skip sha256 verification"
else
  if [[ ! -f "$MANIFEST" ]]; then
    echo "manifest not found: $MANIFEST" >&2
    exit 1
  fi
  EXPECTED_SHA="$(awk -F= '/^sha256=/{print $2; exit}' "$MANIFEST")"
  if [[ -z "$EXPECTED_SHA" ]]; then
    echo "manifest missing sha256 entry: $MANIFEST" >&2
    exit 1
  fi
  ACTUAL_SHA="$(shasum -a 256 "$ARCHIVE" | awk '{print $1}')"
  if [[ "$ACTUAL_SHA" != "$EXPECTED_SHA" ]]; then
    echo "sha256 mismatch: expected=$EXPECTED_SHA actual=$ACTUAL_SHA" >&2
    exit 1
  fi
  log "manifest sha256 verified"
fi

if [[ -z "$PASSPHRASE" && -n "$PASSPHRASE_FILE" ]]; then
  if [[ ! -f "$PASSPHRASE_FILE" ]]; then
    echo "passphrase file not found: $PASSPHRASE_FILE" >&2
    exit 1
  fi
  PASSPHRASE="$(cat "$PASSPHRASE_FILE")"
fi

if [[ -z "$PASSPHRASE" ]]; then
  cat >&2 <<'EOF'
missing passphrase.
set one of:
  OPENCLAW_BACKUP_PASSPHRASE='...'
  OPENCLAW_BACKUP_PASSPHRASE_FILE='/path/to/passphrase.txt'
EOF
  exit 1
fi

mkdir -p "$STAGE_DIR"
TMP_TGZ="$STAGE_DIR/restored.tgz"
EXTRACT_DIR="$STAGE_DIR/extracted"
mkdir -p "$EXTRACT_DIR"

log "decrypting archive"
printf '%s' "$PASSPHRASE" | openssl enc \
  -d \
  -aes-256-cbc \
  -pbkdf2 \
  -iter 200000 \
  -pass stdin \
  -in "$ARCHIVE" \
  -out "$TMP_TGZ"

log "extracting archive"
tar -xzf "$TMP_TGZ" -C "$EXTRACT_DIR"
rm -f "$TMP_TGZ"

log "stage-only preview"
find "$EXTRACT_DIR" -maxdepth 4 -type d | sed "s|$EXTRACT_DIR|.|" | sort

if [[ "$APPLY" != "1" ]]; then
  log "APPLY=0, no files overwritten"
  log "if you want to apply project runtime restore, rerun with APPLY=1"
  log "stage dir: $STAGE_DIR"
  exit 0
fi

log "applying project runtime restore"
mkdir -p "$PROJECT_ROOT/runtime/argus"

if [[ -d "$EXTRACT_DIR/project-runtime/argus/agents" ]]; then
  mkdir -p "$PROJECT_ROOT/runtime/argus/agents"
  rsync -a --delete "$EXTRACT_DIR/project-runtime/argus/agents/" "$PROJECT_ROOT/runtime/argus/agents/"
fi

if [[ -f "$EXTRACT_DIR/project-runtime/argus/config/openclaw.json" ]]; then
  mkdir -p "$PROJECT_ROOT/runtime/argus/config"
  cp "$EXTRACT_DIR/project-runtime/argus/config/openclaw.json" "$PROJECT_ROOT/runtime/argus/config/openclaw.json"
fi

log "apply completed"
log "project root: $PROJECT_ROOT"
log "stage dir: $STAGE_DIR"
log "note: host ~/.openclaw state/workspaces are not auto-applied in this script"
