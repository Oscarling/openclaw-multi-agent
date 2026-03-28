#!/usr/bin/env bash
set -euo pipefail
umask 077

TS="$(date +%Y%m%d-%H%M%S)"
PREFLIGHT_ROOT="${PREFLIGHT_ROOT:-/tmp/openclaw-gate4-stageb-preflight-$TS}"
ARTIFACT_DIR="$PREFLIGHT_ROOT/artifacts"

STAGEA_DOD_FILE="${GATE4_STAGEA_DOD_FILE:-design/validation/2026-03-26-gate4-stage-a-dod-validation.md}"
RELEASE_RECEIPT_TEMPLATE="${GATE4_RELEASE_RECEIPT_TEMPLATE:-shared/templates/gate4_release_receipt_template.json}"
SECRETS_DIR="${GATE4_SECRETS_DIR:-runtime/argus/config/secrets}"
TOKEN_FILE="${GATE4_TELEGRAM_TOKEN_FILE:-runtime/argus/config/secrets/telegram_bot_token.txt}"

log() {
  printf '[gate4-stageb-preflight] %s\n' "$*"
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
need_cmd grep

mkdir -p "$ARTIFACT_DIR"

STAGEA_DOD_PRESENT="no"
STAGEA_DOD_GO="no"
RELEASE_TEMPLATE_PRESENT="no"
RELEASE_TEMPLATE_VALID="no"
SECRETS_DIR_PRESENT="no"
TOKEN_FILE_PRESENT="no"
TOKEN_PERM_OK="no"
SAFE_WRAPPER_OK="no"
ROUTE_PROBE_OK="no"

if [[ -f "$STAGEA_DOD_FILE" ]]; then
  STAGEA_DOD_PRESENT="yes"
  if grep -q '结论：`Go`' "$STAGEA_DOD_FILE"; then
    STAGEA_DOD_GO="yes"
  fi
fi

if [[ -f "$RELEASE_RECEIPT_TEMPLATE" ]]; then
  RELEASE_TEMPLATE_PRESENT="yes"
  if python3 - "$RELEASE_RECEIPT_TEMPLATE" >"$ARTIFACT_DIR/release-template-check.log" 2>&1 <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
obj = json.loads(path.read_text(encoding="utf-8"))

required = {
    "release_id",
    "account_id",
    "publish_ok",
    "occurred_at",
    "evidence_ref",
    "operator",
    "ticket_id",
}
missing = sorted(required - set(obj.keys()))
if missing:
    raise SystemExit(f"missing fields: {', '.join(missing)}")
if not isinstance(obj.get("publish_ok"), bool):
    raise SystemExit("publish_ok must be bool")

print("release_receipt_template_ok")
PY
  then
    RELEASE_TEMPLATE_VALID="yes"
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

if [[ -x "scripts/openclaw_agent_safe.sh" ]]; then
  SAFE_WRAPPER_OK="yes"
fi

if [[ -x "deploy/cli_route_parity_probe.sh" ]]; then
  ROUTE_PROBE_OK="yes"
fi

PREFLIGHT_RESULT="blocked"
if [[ "$STAGEA_DOD_PRESENT" != "yes" ]]; then
  PREFLIGHT_RESULT="waiting_stage_a_dod"
elif [[ "$STAGEA_DOD_GO" != "yes" ]]; then
  PREFLIGHT_RESULT="waiting_stage_a_go"
elif [[ "$RELEASE_TEMPLATE_PRESENT" != "yes" ]]; then
  PREFLIGHT_RESULT="waiting_release_template"
elif [[ "$RELEASE_TEMPLATE_VALID" != "yes" ]]; then
  PREFLIGHT_RESULT="waiting_release_template_fix"
elif [[ "$SECRETS_DIR_PRESENT" != "yes" || "$TOKEN_FILE_PRESENT" != "yes" || "$TOKEN_PERM_OK" != "yes" ]]; then
  PREFLIGHT_RESULT="waiting_secrets"
elif [[ "$SAFE_WRAPPER_OK" == "yes" && "$ROUTE_PROBE_OK" == "yes" ]]; then
  PREFLIGHT_RESULT="ready_for_stage_b_execution"
fi

SUMMARY_FILE="$ARTIFACT_DIR/preflight-summary.txt"
cat >"$SUMMARY_FILE" <<EOF
timestamp=$(date +%Y-%m-%dT%H:%M:%S%z)
preflight_root=$PREFLIGHT_ROOT
stagea_dod_file=$STAGEA_DOD_FILE
stagea_dod_present=$STAGEA_DOD_PRESENT
stagea_dod_go=$STAGEA_DOD_GO
release_receipt_template=$RELEASE_RECEIPT_TEMPLATE
release_template_present=$RELEASE_TEMPLATE_PRESENT
release_template_valid=$RELEASE_TEMPLATE_VALID
secrets_dir=$SECRETS_DIR
secrets_dir_present=$SECRETS_DIR_PRESENT
token_file=$TOKEN_FILE
token_file_present=$TOKEN_FILE_PRESENT
token_perm_ok=$TOKEN_PERM_OK
safe_wrapper_ok=$SAFE_WRAPPER_OK
route_probe_ok=$ROUTE_PROBE_OK
preflight_result=$PREFLIGHT_RESULT
note=ready_for_stage_b_execution means stage-a DoD is Go, release receipt template is valid, and baseline guardrails remain available.
EOF

log "done"
log "preflight root: $PREFLIGHT_ROOT"
log "summary: $SUMMARY_FILE"
cat "$SUMMARY_FILE"
