#!/usr/bin/env bash
set -euo pipefail
umask 077

TS="$(date +%Y%m%d-%H%M%S)"
EXEC_ROOT="${EXEC_ROOT:-/tmp/openclaw-gate4-stagec-exec-$TS}"
ARTIFACT_DIR="$EXEC_ROOT/artifacts"

ALLOWLIST_PATH="${GATE4_ALLOWLIST_PATH:-runtime/argus/config/gate4/account_allowlist.json}"
ROLLOUT_POLICY_FILE="${GATE4_ROLLOUT_POLICY_FILE:-shared/templates/gate4_rollout_policy_template.json}"
ACCOUNT_ID="${GATE4_ACCOUNT_ID:-}"
PHASE_ID="${GATE4_PHASE_ID:-C1}"
BATCH_ID="${GATE4_BATCH_ID:-}"
RELEASE_ID="${GATE4_RELEASE_ID:-}"
OPERATOR="${GATE4_OPERATOR:-unknown_operator}"
TICKET_ID="${GATE4_TICKET_ID:-}"
STAGE_C_RECEIPT_FILE="${GATE4_STAGE_C_RECEIPT_FILE:-}"
STRICT_MODE="${GATE4_STAGE_C_STRICT:-no}"

log() {
  printf '[gate4-stagec-exec] %s\n' "$*"
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
  log "example: GATE4_ACCOUNT_ID='xhs_demo_001' GATE4_PHASE_ID='C1' bash ./deploy/gate4_stage_c_execute.sh"
  exit 2
fi

log "running stage-c preflight"
PREFLIGHT_ROOT="$EXEC_ROOT/preflight" bash ./deploy/gate4_stage_c_preflight.sh >"$ARTIFACT_DIR/preflight.out.log" 2>"$ARTIFACT_DIR/preflight.err.log" || true
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

PHASE_FOUND="no"
PHASE_MAX_BATCH=""
PHASE_SUCCESS_THRESHOLD=""
PHASE_HALT_FAILURE_COUNT=""
PHASE_REQUIRE_MANUAL_GATE=""

if python3 - "$ROLLOUT_POLICY_FILE" "$PHASE_ID" >"$ARTIFACT_DIR/phase-policy.env" 2>"$ARTIFACT_DIR/phase-policy.err.log" <<'PY'
import json
import sys
from pathlib import Path

policy_path = Path(sys.argv[1])
phase_id = sys.argv[2]

if not policy_path.exists():
    raise SystemExit("rollout policy file not found")

obj = json.loads(policy_path.read_text(encoding="utf-8"))
phases = obj.get("phases")
if not isinstance(phases, list):
    raise SystemExit("phases must be list")

target = None
for item in phases:
    if isinstance(item, dict) and item.get("phase_id") == phase_id:
        target = item
        break

if target is None:
    raise SystemExit("phase not found")

print("phase_found=yes")
print(f"phase_max_batch={target.get('max_batch_size', '')}")
print(f"phase_success_threshold={target.get('success_rate_threshold', '')}")
print(f"phase_halt_failure_count={target.get('halt_failure_count', '')}")
print(f"phase_require_manual_gate={'yes' if target.get('require_manual_gate') else 'no'}")
PY
then
  # shellcheck disable=SC1091
  source "$ARTIFACT_DIR/phase-policy.env"
  PHASE_FOUND="${phase_found:-no}"
  PHASE_MAX_BATCH="${phase_max_batch:-}"
  PHASE_SUCCESS_THRESHOLD="${phase_success_threshold:-}"
  PHASE_HALT_FAILURE_COUNT="${phase_halt_failure_count:-}"
  PHASE_REQUIRE_MANUAL_GATE="${phase_require_manual_gate:-no}"
fi

NEEDS_TICKET="no"
if [[ "$ACCOUNT_RISK" == "high" || "$ACCOUNT_AUTOMATION" == "gated_auto" || "$PHASE_REQUIRE_MANUAL_GATE" == "yes" ]]; then
  NEEDS_TICKET="yes"
fi

RECEIPT_PRESENT="no"
RECEIPT_VALID="no"
RECEIPT_PUBLISH_OK=""
RECEIPT_HALT_TRIGGERED=""
RECEIPT_SUCCESS_RATE=""
RECEIPT_FAILURE_COUNT=""
RECEIPT_BATCH_SIZE=""
RECEIPT_EVIDENCE_REF=""
RECEIPT_BATCH_ID=""
RECEIPT_RELEASE_ID=""

if [[ -n "$STAGE_C_RECEIPT_FILE" && -f "$STAGE_C_RECEIPT_FILE" ]]; then
  RECEIPT_PRESENT="yes"
  if python3 - "$STAGE_C_RECEIPT_FILE" "$ACCOUNT_ID" "$PHASE_ID" "$RELEASE_ID" "$BATCH_ID" >"$ARTIFACT_DIR/stagec-receipt.env" 2>"$ARTIFACT_DIR/stagec-receipt.err.log" <<'PY'
import json
import sys
from pathlib import Path

receipt_path = Path(sys.argv[1])
expect_account_id = sys.argv[2]
expect_phase_id = sys.argv[3]
expect_release_id = sys.argv[4]
expect_batch_id = sys.argv[5]

obj = json.loads(receipt_path.read_text(encoding="utf-8"))
required = {
    "phase_id",
    "batch_id",
    "release_id",
    "account_id",
    "batch_size",
    "success_count",
    "failure_count",
    "success_rate",
    "publish_ok",
    "halt_triggered",
    "occurred_at",
    "evidence_ref",
}
missing = sorted(required - set(obj.keys()))
if missing:
    raise SystemExit(f"missing fields: {', '.join(missing)}")

if obj["account_id"] != expect_account_id:
    raise SystemExit("receipt account_id mismatch")
if obj["phase_id"] != expect_phase_id:
    raise SystemExit("receipt phase_id mismatch")
if expect_release_id and obj["release_id"] != expect_release_id:
    raise SystemExit("receipt release_id mismatch")
if expect_batch_id and obj["batch_id"] != expect_batch_id:
    raise SystemExit("receipt batch_id mismatch")

if not isinstance(obj["batch_size"], int) or obj["batch_size"] <= 0:
    raise SystemExit("batch_size must be positive int")
if not isinstance(obj["success_count"], int) or obj["success_count"] < 0:
    raise SystemExit("success_count must be non-negative int")
if not isinstance(obj["failure_count"], int) or obj["failure_count"] < 0:
    raise SystemExit("failure_count must be non-negative int")
if not isinstance(obj["success_rate"], (int, float)) or not (0 <= obj["success_rate"] <= 1):
    raise SystemExit("success_rate must be in [0,1]")
if not isinstance(obj["publish_ok"], bool):
    raise SystemExit("publish_ok must be bool")
if not isinstance(obj["halt_triggered"], bool):
    raise SystemExit("halt_triggered must be bool")

print("receipt_valid=yes")
print(f"receipt_publish_ok={'yes' if obj['publish_ok'] else 'no'}")
print(f"receipt_halt_triggered={'yes' if obj['halt_triggered'] else 'no'}")
print(f"receipt_success_rate={obj.get('success_rate', '')}")
print(f"receipt_failure_count={obj.get('failure_count', '')}")
print(f"receipt_batch_size={obj.get('batch_size', '')}")
print(f"receipt_evidence_ref={obj.get('evidence_ref', '')}")
print(f"receipt_batch_id={obj.get('batch_id', '')}")
print(f"receipt_release_id={obj.get('release_id', '')}")
PY
  then
    # shellcheck disable=SC1091
    source "$ARTIFACT_DIR/stagec-receipt.env"
    RECEIPT_VALID="${receipt_valid:-no}"
    RECEIPT_PUBLISH_OK="${receipt_publish_ok:-}"
    RECEIPT_HALT_TRIGGERED="${receipt_halt_triggered:-}"
    RECEIPT_SUCCESS_RATE="${receipt_success_rate:-}"
    RECEIPT_FAILURE_COUNT="${receipt_failure_count:-}"
    RECEIPT_BATCH_SIZE="${receipt_batch_size:-}"
    RECEIPT_EVIDENCE_REF="${receipt_evidence_ref:-}"
    RECEIPT_BATCH_ID="${receipt_batch_id:-}"
    RECEIPT_RELEASE_ID="${receipt_release_id:-}"
  fi
fi

STAGE_C_RESULT="blocked"
if [[ "$PREFLIGHT_RESULT" != "ready_for_stage_c_execution" ]]; then
  STAGE_C_RESULT="blocked_preflight"
elif [[ "$ACCOUNT_FOUND" != "yes" ]]; then
  STAGE_C_RESULT="blocked_account_not_allowlisted"
elif [[ "$PHASE_FOUND" != "yes" ]]; then
  STAGE_C_RESULT="blocked_phase_not_found"
elif [[ "$NEEDS_TICKET" == "yes" && -z "$TICKET_ID" ]]; then
  STAGE_C_RESULT="blocked_need_ticket"
elif [[ "$RECEIPT_PRESENT" != "yes" ]]; then
  STAGE_C_RESULT="waiting_stage_c_receipt"
elif [[ "$RECEIPT_VALID" != "yes" ]]; then
  STAGE_C_RESULT="waiting_stage_c_receipt_fix"
elif [[ -n "$PHASE_MAX_BATCH" && -n "$RECEIPT_BATCH_SIZE" && "$RECEIPT_BATCH_SIZE" -gt "$PHASE_MAX_BATCH" ]]; then
  STAGE_C_RESULT="blocked_batch_exceeds_limit"
elif [[ -n "$PHASE_HALT_FAILURE_COUNT" && -n "$RECEIPT_FAILURE_COUNT" && "$RECEIPT_FAILURE_COUNT" -ge "$PHASE_HALT_FAILURE_COUNT" ]]; then
  STAGE_C_RESULT="stage_c_halted"
elif [[ "$RECEIPT_HALT_TRIGGERED" == "yes" ]]; then
  STAGE_C_RESULT="stage_c_halted"
elif [[ -n "$PHASE_SUCCESS_THRESHOLD" && -n "$RECEIPT_SUCCESS_RATE" ]] && ! python3 - "$RECEIPT_SUCCESS_RATE" "$PHASE_SUCCESS_THRESHOLD" <<'PY'
import sys
actual = float(sys.argv[1])
threshold = float(sys.argv[2])
sys.exit(0 if actual >= threshold else 1)
PY
then
  STAGE_C_RESULT="stage_c_failed_threshold"
elif [[ "$RECEIPT_PUBLISH_OK" == "yes" ]]; then
  STAGE_C_RESULT="stage_c_passed"
else
  STAGE_C_RESULT="stage_c_failed"
fi

SUMMARY_FILE="$ARTIFACT_DIR/stage-c-summary.txt"
cat >"$SUMMARY_FILE" <<EOF
timestamp=$(date +%Y-%m-%dT%H:%M:%S%z)
exec_root=$EXEC_ROOT
allowlist_path=$ALLOWLIST_PATH
rollout_policy_file=$ROLLOUT_POLICY_FILE
account_id=$ACCOUNT_ID
phase_id=$PHASE_ID
batch_id=$BATCH_ID
release_id=$RELEASE_ID
operator=$OPERATOR
ticket_id=$TICKET_ID
preflight_result=$PREFLIGHT_RESULT
account_found=$ACCOUNT_FOUND
account_owner=$ACCOUNT_OWNER
account_platform=$ACCOUNT_PLATFORM
account_risk=$ACCOUNT_RISK
account_automation=$ACCOUNT_AUTOMATION
phase_found=$PHASE_FOUND
phase_max_batch=$PHASE_MAX_BATCH
phase_success_threshold=$PHASE_SUCCESS_THRESHOLD
phase_halt_failure_count=$PHASE_HALT_FAILURE_COUNT
phase_require_manual_gate=$PHASE_REQUIRE_MANUAL_GATE
needs_ticket=$NEEDS_TICKET
stagec_receipt_file=$STAGE_C_RECEIPT_FILE
stagec_receipt_present=$RECEIPT_PRESENT
stagec_receipt_valid=$RECEIPT_VALID
stagec_receipt_publish_ok=$RECEIPT_PUBLISH_OK
stagec_receipt_halt_triggered=$RECEIPT_HALT_TRIGGERED
stagec_receipt_success_rate=$RECEIPT_SUCCESS_RATE
stagec_receipt_failure_count=$RECEIPT_FAILURE_COUNT
stagec_receipt_batch_size=$RECEIPT_BATCH_SIZE
stagec_receipt_batch_id=$RECEIPT_BATCH_ID
stagec_receipt_release_id=$RECEIPT_RELEASE_ID
stagec_receipt_evidence_ref=$RECEIPT_EVIDENCE_REF
stage_c_result=$STAGE_C_RESULT
note=stage_c_passed requires preflight ready, allowlisted account, valid phase policy, required ticket (if any), and receipt metrics within thresholds.
EOF

log "done"
log "exec root: $EXEC_ROOT"
log "summary: $SUMMARY_FILE"
cat "$SUMMARY_FILE"

if [[ "$STRICT_MODE" == "yes" && "$STAGE_C_RESULT" != "stage_c_passed" ]]; then
  exit 4
fi
