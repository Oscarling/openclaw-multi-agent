#!/usr/bin/env bash
set -euo pipefail
umask 077

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TS="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR_DEFAULT="$PROJECT_ROOT/artifacts/backups"
BACKUP_DIR="${BACKUP_DIR:-$BACKUP_DIR_DEFAULT}"

PASSPHRASE="${OPENCLAW_BACKUP_PASSPHRASE:-}"
PASSPHRASE_FILE="${OPENCLAW_BACKUP_PASSPHRASE_FILE:-}"
ARCHIVE_TGZ=""

log() {
  printf '[backup-state] %s\n' "$*"
}

need_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "missing required command: $cmd" >&2
    exit 1
  fi
}

need_cmd tar
need_cmd openssl
need_cmd shasum

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

mkdir -p "$BACKUP_DIR"

ARCHIVE_TGZ="$BACKUP_DIR/openclaw-state-$TS.tgz"
ARCHIVE_ENC="$ARCHIVE_TGZ.enc"
MANIFEST="$BACKUP_DIR/openclaw-state-$TS.manifest.txt"

TMP_DIR="$(mktemp -d /tmp/openclaw-backup-stage-XXXXXX)"
cleanup() {
  rm -rf "$TMP_DIR"
  if [[ -n "${ARCHIVE_TGZ:-}" && -f "$ARCHIVE_TGZ" ]]; then
    rm -f "$ARCHIVE_TGZ"
    log "removed plaintext temporary archive"
  fi
}
trap cleanup EXIT

log "staging backup payload"
mkdir -p "$TMP_DIR/project-runtime"

if [[ -d "$PROJECT_ROOT/runtime/argus/agents" ]]; then
  mkdir -p "$TMP_DIR/project-runtime/argus"
  cp -R "$PROJECT_ROOT/runtime/argus/agents" "$TMP_DIR/project-runtime/argus/agents"
fi

if [[ -f "$PROJECT_ROOT/runtime/argus/config/openclaw.json" ]]; then
  mkdir -p "$TMP_DIR/project-runtime/argus/config"
  cp "$PROJECT_ROOT/runtime/argus/config/openclaw.json" "$TMP_DIR/project-runtime/argus/config/openclaw.json"
fi

if [[ -d "$HOME/.openclaw/state/argus" ]]; then
  mkdir -p "$TMP_DIR/host-openclaw/state"
  cp -R "$HOME/.openclaw/state/argus" "$TMP_DIR/host-openclaw/state/argus"
else
  log "skip missing: $HOME/.openclaw/state/argus"
fi

if [[ -d "$HOME/.openclaw/workspaces/argus" ]]; then
  mkdir -p "$TMP_DIR/host-openclaw/workspaces"
  cp -R "$HOME/.openclaw/workspaces/argus" "$TMP_DIR/host-openclaw/workspaces/argus"
else
  log "skip missing: $HOME/.openclaw/workspaces/argus"
fi

log "creating tar archive"
tar -czf "$ARCHIVE_TGZ" -C "$TMP_DIR" .

log "encrypting archive with openssl (AES-256-CBC + PBKDF2)"
printf '%s' "$PASSPHRASE" | openssl enc \
  -aes-256-cbc \
  -pbkdf2 \
  -iter 200000 \
  -salt \
  -pass stdin \
  -in "$ARCHIVE_TGZ" \
  -out "$ARCHIVE_ENC"

rm -f "$ARCHIVE_TGZ"

SHA256="$(shasum -a 256 "$ARCHIVE_ENC" | awk '{print $1}')"
SIZE_BYTES="$(stat -f%z "$ARCHIVE_ENC" 2>/dev/null || stat -c%s "$ARCHIVE_ENC")"

cat >"$MANIFEST" <<EOF
timestamp=$TS
archive=$ARCHIVE_ENC
sha256=$SHA256
size_bytes=$SIZE_BYTES
includes=project-runtime/argus/agents
includes=project-runtime/argus/config/openclaw.json
includes=host-openclaw/state/argus (if present)
includes=host-openclaw/workspaces/argus (if present)
encryption=openssl-aes-256-cbc-pbkdf2-iter200000
EOF

log "backup complete"
log "archive: $ARCHIVE_ENC"
log "manifest: $MANIFEST"
