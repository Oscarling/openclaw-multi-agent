#!/usr/bin/env bash
set -euo pipefail
umask 077

TS="$(date +%Y%m%d-%H%M%S)"
EXEC_ROOT="${EXEC_ROOT:-/tmp/openclaw-gate4-stagea-exec-$TS}"
ARTIFACT_DIR="$EXEC_ROOT/artifacts"

ALLOWLIST_PATH="${GATE4_ALLOWLIST_PATH:-runtime/argus/config/gate4/account_allowlist.json}"
ACCOUNT_ID="${GATE4_ACCOUNT_ID:-}"
OPERATOR="${GATE4_OPERATOR:-unknown_operator}"
TICKET_ID="${GATE4_TICKET_ID:-}"
MANUAL_RECEIPT_FILE="${GATE4_MANUAL_RECEIPT_FILE:-}"
STRICT_MODE="${GATE4_STAGE_A_STRICT:-no}"

log() {
  printf '[gate4-stagea-exec] %s\n' "$*"
}

need_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "missing command: $cmd" >&2
    exit 1
  fi
}

need_cmd python3
need_cmd grep

mkdir -p "$ARTIFACT_DIR"

if [[ -z "$ACCOUNT_ID" ]]; then
  log "missing GATE4_ACCOUNT_ID"
  log "example: GATE4_ACCOUNT_ID='xhs_demo_001' bash ./deploy/gate4_stage_a_execute.sh"
  exit 2
fi

log "running stage-a preflight"
PREFLIGHT_ROOT="$EXEC_ROOT/preflight" bash ./deploy/gate4_stage_a_preflight.sh >"$ARTIFACT_DIR/preflight.out.log" 2>"$ARTIFACT_DIR/preflight.err.log" || true
PREFLIGHT_SUMMARY="$EXEC_ROOT/preflight/artifacts/preflight-summary.txt"
if [[ -f "$PREFLIGHT_SUMMARY" ]]; then
  cp "$PREFLIGHT_SUMMARY" "$ARTIFACT_DIR/preflight-summary.txt"
fi

PREFLIGHT_RESULT="unknown"
if [[ -f "$ARTIFACT_DIR/preflight-summary.txt" ]]; then
  PREFLIGHT_RESULT="$(grep -E '^preflight_result=' "$ARTIFACT_DIR/preflight-summary.txt" | head -n1 | cut -d= -f2- || true)"
fi

ACCOUNT_FOUND="no"
ACCOUNT_OWNER=""
ACCOUNT_PLATFORM=""
ACCOUNT_RISK=""
ACCOUNT_AUTOMATION=""

if python3 - "$ALLOWLIST_PATH" "$ACCOUNT_ID" >"$ARTIFACT_DIR/account-meta.env" 2>"$ARTIFACT_DIR/account-meta.err.log" <<'PY'
import json
import sys
from pathlib import Path

allowlist_path = Path(sys.argv[1])
account_id = sys.argv[2]

if not allowlist_path.exists():
    raise SystemExit("allowlist file not found")

obj = json.loads(allowlist_path.read_text(encoding="utf-8"))
accounts = obj.get("accounts")
if not isinstance(accounts, list):
    raise SystemExit("accounts must be list")

target = None
for item in accounts:
    if isinstance(item, dict) and item.get("account_id") == account_id:
        target = item
        break

if target is None:
    raise SystemExit("account not in allowlist")

print("account_found=yes")
print(f"account_owner={target.get('owner', '')}")
print(f"account_platform={target.get('platform', '')}")
print(f"account_risk={target.get('risk_level', '')}")
print(f"account_automation={target.get('automation_level', '')}")
PY
then
  # shellcheck disable=SC1091
  source "$ARTIFACT_DIR/account-meta.env"
  ACCOUNT_FOUND="${account_found:-no}"
  ACCOUNT_OWNER="${account_owner:-}"
  ACCOUNT_PLATFORM="${account_platform:-}"
  ACCOUNT_RISK="${account_risk:-}"
  ACCOUNT_AUTOMATION="${account_automation:-}"
fi

NEEDS_TICKET="no"
if [[ "$ACCOUNT_RISK" == "high" || "$ACCOUNT_AUTOMATION" == "gated_auto" ]]; then
  NEEDS_TICKET="yes"
fi

RECEIPT_PRESENT="no"
RECEIPT_VALID="no"
RECEIPT_LOGIN_OK=""
RECEIPT_EVIDENCE_REF=""

if [[ -n "$MANUAL_RECEIPT_FILE" && -f "$MANUAL_RECEIPT_FILE" ]]; then
  RECEIPT_PRESENT="yes"
  if python3 - "$MANUAL_RECEIPT_FILE" "$ACCOUNT_ID" >"$ARTIFACT_DIR/manual-receipt.env" 2>"$ARTIFACT_DIR/manual-receipt.err.log" <<'PY'
import json
import sys
from pathlib import Path

receipt_path = Path(sys.argv[1])
expect_account_id = sys.argv[2]

obj = json.loads(receipt_path.read_text(encoding="utf-8"))
required = {"account_id", "login_ok", "occurred_at", "evidence_ref"}
missing = sorted(required - set(obj.keys()))
if missing:
    raise SystemExit(f"missing fields: {', '.join(missing)}")
if obj["account_id"] != expect_account_id:
    raise SystemExit("receipt account_id mismatch")
if not isinstance(obj["login_ok"], bool):
    raise SystemExit("login_ok must be bool")

print("receipt_valid=yes")
print(f"receipt_login_ok={'yes' if obj['login_ok'] else 'no'}")
print(f"receipt_evidence_ref={obj.get('evidence_ref', '')}")
PY
  then
    # shellcheck disable=SC1091
    source "$ARTIFACT_DIR/manual-receipt.env"
    RECEIPT_VALID="${receipt_valid:-no}"
    RECEIPT_LOGIN_OK="${receipt_login_ok:-}"
    RECEIPT_EVIDENCE_REF="${receipt_evidence_ref:-}"
  fi
fi

STAGE_A_RESULT="blocked"
if [[ "$PREFLIGHT_RESULT" != "ready_for_stage_a_execution" ]]; then
  STAGE_A_RESULT="blocked_preflight"
elif [[ "$ACCOUNT_FOUND" != "yes" ]]; then
  STAGE_A_RESULT="blocked_account_not_allowlisted"
elif [[ "$NEEDS_TICKET" == "yes" && -z "$TICKET_ID" ]]; then
  STAGE_A_RESULT="blocked_need_ticket"
elif [[ "$RECEIPT_PRESENT" != "yes" ]]; then
  STAGE_A_RESULT="waiting_manual_login"
elif [[ "$RECEIPT_VALID" != "yes" ]]; then
  STAGE_A_RESULT="waiting_manual_receipt_fix"
elif [[ "$RECEIPT_LOGIN_OK" == "yes" ]]; then
  STAGE_A_RESULT="stage_a_passed"
else
  STAGE_A_RESULT="stage_a_failed"
fi

SUMMARY_FILE="$ARTIFACT_DIR/stage-a-summary.txt"
cat >"$SUMMARY_FILE" <<EOF
timestamp=$(date +%Y-%m-%dT%H:%M:%S%z)
exec_root=$EXEC_ROOT
allowlist_path=$ALLOWLIST_PATH
account_id=$ACCOUNT_ID
operator=$OPERATOR
ticket_id=$TICKET_ID
preflight_result=$PREFLIGHT_RESULT
account_found=$ACCOUNT_FOUND
account_owner=$ACCOUNT_OWNER
account_platform=$ACCOUNT_PLATFORM
account_risk=$ACCOUNT_RISK
account_automation=$ACCOUNT_AUTOMATION
needs_ticket=$NEEDS_TICKET
manual_receipt_file=$MANUAL_RECEIPT_FILE
manual_receipt_present=$RECEIPT_PRESENT
manual_receipt_valid=$RECEIPT_VALID
manual_receipt_login_ok=$RECEIPT_LOGIN_OK
manual_receipt_evidence_ref=$RECEIPT_EVIDENCE_REF
stage_a_result=$STAGE_A_RESULT
note=stage_a_passed requires preflight ready, allowlisted account, required ticket (if any), and manual receipt login_ok=true.
EOF

log "done"
log "exec root: $EXEC_ROOT"
log "summary: $SUMMARY_FILE"
cat "$SUMMARY_FILE"

if [[ "$STRICT_MODE" == "yes" && "$STAGE_A_RESULT" != "stage_a_passed" ]]; then
  exit 4
fi
