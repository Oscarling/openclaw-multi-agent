#!/usr/bin/env bash
set -euo pipefail
umask 077

TS="$(date +%Y%m%d-%H%M%S)"
PREFLIGHT_ROOT="${PREFLIGHT_ROOT:-/tmp/openclaw-gate4-stagea-preflight-$TS}"
ARTIFACT_DIR="$PREFLIGHT_ROOT/artifacts"

ALLOWLIST_PATH="${GATE4_ALLOWLIST_PATH:-runtime/argus/config/gate4/account_allowlist.json}"
SECRETS_DIR="${GATE4_SECRETS_DIR:-runtime/argus/config/secrets}"
TOKEN_FILE="${GATE4_TELEGRAM_TOKEN_FILE:-runtime/argus/config/secrets/telegram_bot_token.txt}"

log() {
  printf '[gate4-stagea-preflight] %s\n' "$*"
}

need_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "missing command: $cmd" >&2
    exit 1
  fi
}

get_perm() {
  local path="$1"
  if [[ ! -e "$path" ]]; then
    printf ''
    return
  fi
  stat -f '%Lp' "$path" 2>/dev/null || true
}

need_cmd python3
need_cmd stat

mkdir -p "$ARTIFACT_DIR"

SAFE_WRAPPER_OK="no"
ROUTE_PROBE_OK="no"
ALLOWLIST_PRESENT="no"
ALLOWLIST_VALID="no"
SECRETS_DIR_PRESENT="no"
TOKEN_FILE_PRESENT="no"
TOKEN_PERM_OK="no"

if [[ -x "scripts/openclaw_agent_safe.sh" ]]; then
  SAFE_WRAPPER_OK="yes"
fi

if [[ -x "deploy/cli_route_parity_probe.sh" ]]; then
  ROUTE_PROBE_OK="yes"
fi

if [[ -f "$ALLOWLIST_PATH" ]]; then
  ALLOWLIST_PRESENT="yes"
  if python3 - "$ALLOWLIST_PATH" >"$ARTIFACT_DIR/allowlist-check.log" 2>&1 <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
obj = json.loads(path.read_text(encoding="utf-8"))
accounts = obj.get("accounts")
if not isinstance(accounts, list) or not accounts:
    raise SystemExit("accounts must be a non-empty list")

valid_risk = {"low", "medium", "high"}
valid_auto = {"observe_only", "assisted", "gated_auto"}
required = {"account_id", "platform", "owner", "risk_level", "automation_level"}

for i, item in enumerate(accounts, start=1):
    if not isinstance(item, dict):
        raise SystemExit(f"accounts[{i}] must be object")
    missing = sorted(required - set(item.keys()))
    if missing:
        raise SystemExit(f"accounts[{i}] missing fields: {', '.join(missing)}")
    if item["risk_level"] not in valid_risk:
        raise SystemExit(f"accounts[{i}] invalid risk_level")
    if item["automation_level"] not in valid_auto:
        raise SystemExit(f"accounts[{i}] invalid automation_level")

print("allowlist_schema_ok")
PY
  then
    ALLOWLIST_VALID="yes"
  fi
fi

if [[ -d "$SECRETS_DIR" ]]; then
  SECRETS_DIR_PRESENT="yes"
fi

if [[ -f "$TOKEN_FILE" ]]; then
  TOKEN_FILE_PRESENT="yes"
  TOKEN_PERM="$(get_perm "$TOKEN_FILE")"
  if [[ -n "$TOKEN_PERM" && "$TOKEN_PERM" -le 600 ]]; then
    TOKEN_PERM_OK="yes"
  fi
fi

PREFLIGHT_RESULT="blocked"
if [[ "$ALLOWLIST_PRESENT" == "no" ]]; then
  PREFLIGHT_RESULT="waiting_allowlist"
elif [[ "$ALLOWLIST_VALID" != "yes" ]]; then
  PREFLIGHT_RESULT="waiting_allowlist_fix"
elif [[ "$SECRETS_DIR_PRESENT" != "yes" || "$TOKEN_FILE_PRESENT" != "yes" || "$TOKEN_PERM_OK" != "yes" ]]; then
  PREFLIGHT_RESULT="waiting_secrets"
elif [[ "$SAFE_WRAPPER_OK" == "yes" && "$ROUTE_PROBE_OK" == "yes" ]]; then
  PREFLIGHT_RESULT="ready_for_stage_a_execution"
fi

SUMMARY_FILE="$ARTIFACT_DIR/preflight-summary.txt"
cat >"$SUMMARY_FILE" <<EOF
timestamp=$(date +%Y-%m-%dT%H:%M:%S%z)
preflight_root=$PREFLIGHT_ROOT
allowlist_path=$ALLOWLIST_PATH
allowlist_present=$ALLOWLIST_PRESENT
allowlist_valid=$ALLOWLIST_VALID
secrets_dir=$SECRETS_DIR
secrets_dir_present=$SECRETS_DIR_PRESENT
token_file=$TOKEN_FILE
token_file_present=$TOKEN_FILE_PRESENT
token_perm_ok=$TOKEN_PERM_OK
safe_wrapper_ok=$SAFE_WRAPPER_OK
route_probe_ok=$ROUTE_PROBE_OK
preflight_result=$PREFLIGHT_RESULT
note=ready_for_stage_a_execution means allowlist schema, secrets baseline, and route guardrails are all present.
EOF

log "done"
log "preflight root: $PREFLIGHT_ROOT"
log "summary: $SUMMARY_FILE"
cat "$SUMMARY_FILE"
