#!/usr/bin/env bash
set -euo pipefail
umask 077

TS="$(date +%Y%m%d-%H%M%S)"
EXEC_ROOT="${EXEC_ROOT:-/tmp/openclaw-gate4-stageb-exec-$TS}"
ARTIFACT_DIR="$EXEC_ROOT/artifacts"

ALLOWLIST_PATH="${GATE4_ALLOWLIST_PATH:-runtime/argus/config/gate4/account_allowlist.json}"
ACCOUNT_ID="${GATE4_ACCOUNT_ID:-}"
RELEASE_ID="${GATE4_RELEASE_ID:-}"
OPERATOR="${GATE4_OPERATOR:-unknown_operator}"
TICKET_ID="${GATE4_TICKET_ID:-}"
RELEASE_RECEIPT_FILE="${GATE4_RELEASE_RECEIPT_FILE:-}"
STRICT_MODE="${GATE4_STAGE_B_STRICT:-no}"

log() {
  printf '[gate4-stageb-exec] %s\n' "$*"
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
  log "example: GATE4_ACCOUNT_ID='xhs_demo_001' GATE4_RELEASE_ID='XHS-REL-001' bash ./deploy/gate4_stage_b_execute.sh"
  exit 2
fi

log "running stage-b preflight"
PREFLIGHT_ROOT="$EXEC_ROOT/preflight" bash ./deploy/gate4_stage_b_preflight.sh >"$ARTIFACT_DIR/preflight.out.log" 2>"$ARTIFACT_DIR/preflight.err.log" || true
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
RECEIPT_PUBLISH_OK=""
RECEIPT_EVIDENCE_REF=""
RECEIPT_RELEASE_ID=""

if [[ -n "$RELEASE_RECEIPT_FILE" && -f "$RELEASE_RECEIPT_FILE" ]]; then
  RECEIPT_PRESENT="yes"
  if python3 - "$RELEASE_RECEIPT_FILE" "$ACCOUNT_ID" "$RELEASE_ID" >"$ARTIFACT_DIR/release-receipt.env" 2>"$ARTIFACT_DIR/release-receipt.err.log" <<'PY'
import json
import sys
from pathlib import Path

receipt_path = Path(sys.argv[1])
expect_account_id = sys.argv[2]
expect_release_id = sys.argv[3]

obj = json.loads(receipt_path.read_text(encoding="utf-8"))
required = {"release_id", "account_id", "publish_ok", "occurred_at", "evidence_ref"}
missing = sorted(required - set(obj.keys()))
if missing:
    raise SystemExit(f"missing fields: {', '.join(missing)}")
if obj["account_id"] != expect_account_id:
    raise SystemExit("receipt account_id mismatch")
if expect_release_id and obj["release_id"] != expect_release_id:
    raise SystemExit("receipt release_id mismatch")
if not isinstance(obj["publish_ok"], bool):
    raise SystemExit("publish_ok must be bool")

print("receipt_valid=yes")
print(f"receipt_publish_ok={'yes' if obj['publish_ok'] else 'no'}")
print(f"receipt_evidence_ref={obj.get('evidence_ref', '')}")
print(f"receipt_release_id={obj.get('release_id', '')}")
PY
  then
    # shellcheck disable=SC1091
    source "$ARTIFACT_DIR/release-receipt.env"
    RECEIPT_VALID="${receipt_valid:-no}"
    RECEIPT_PUBLISH_OK="${receipt_publish_ok:-}"
    RECEIPT_EVIDENCE_REF="${receipt_evidence_ref:-}"
    RECEIPT_RELEASE_ID="${receipt_release_id:-}"
  fi
fi

STAGE_B_RESULT="blocked"
if [[ "$PREFLIGHT_RESULT" != "ready_for_stage_b_execution" ]]; then
  STAGE_B_RESULT="blocked_preflight"
elif [[ "$ACCOUNT_FOUND" != "yes" ]]; then
  STAGE_B_RESULT="blocked_account_not_allowlisted"
elif [[ "$NEEDS_TICKET" == "yes" && -z "$TICKET_ID" ]]; then
  STAGE_B_RESULT="blocked_need_ticket"
elif [[ "$RECEIPT_PRESENT" != "yes" ]]; then
  STAGE_B_RESULT="waiting_release_receipt"
elif [[ "$RECEIPT_VALID" != "yes" ]]; then
  STAGE_B_RESULT="waiting_release_receipt_fix"
elif [[ "$RECEIPT_PUBLISH_OK" == "yes" ]]; then
  STAGE_B_RESULT="stage_b_passed"
else
  STAGE_B_RESULT="stage_b_failed"
fi

SUMMARY_FILE="$ARTIFACT_DIR/stage-b-summary.txt"
cat >"$SUMMARY_FILE" <<EOF
timestamp=$(date +%Y-%m-%dT%H:%M:%S%z)
exec_root=$EXEC_ROOT
allowlist_path=$ALLOWLIST_PATH
account_id=$ACCOUNT_ID
release_id=$RELEASE_ID
operator=$OPERATOR
ticket_id=$TICKET_ID
preflight_result=$PREFLIGHT_RESULT
account_found=$ACCOUNT_FOUND
account_owner=$ACCOUNT_OWNER
account_platform=$ACCOUNT_PLATFORM
account_risk=$ACCOUNT_RISK
account_automation=$ACCOUNT_AUTOMATION
needs_ticket=$NEEDS_TICKET
release_receipt_file=$RELEASE_RECEIPT_FILE
release_receipt_present=$RECEIPT_PRESENT
release_receipt_valid=$RECEIPT_VALID
release_receipt_publish_ok=$RECEIPT_PUBLISH_OK
release_receipt_release_id=$RECEIPT_RELEASE_ID
release_receipt_evidence_ref=$RECEIPT_EVIDENCE_REF
stage_b_result=$STAGE_B_RESULT
note=stage_b_passed requires preflight ready, allowlisted account, required ticket (if any), and release receipt publish_ok=true.
EOF

log "done"
log "exec root: $EXEC_ROOT"
log "summary: $SUMMARY_FILE"
cat "$SUMMARY_FILE"

if [[ "$STRICT_MODE" == "yes" && "$STAGE_B_RESULT" != "stage_b_passed" ]]; then
  exit 4
fi
