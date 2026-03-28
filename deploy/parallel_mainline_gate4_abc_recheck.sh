#!/usr/bin/env bash
set -euo pipefail
umask 077

TS="$(date +%Y%m%d-%H%M%S)"
EXEC_ROOT="${EXEC_ROOT:-design/validation/artifacts/openclaw-parallel-mainline-gate4-abc-recheck-runner-$TS}"
ARTIFACT_DIR="$EXEC_ROOT/artifacts"

ACCOUNT_ID="${GATE4_ACCOUNT_ID:-xhs_demo_001}"
OPERATOR="${GATE4_OPERATOR:-unknown_operator}"

STAGE_A_TICKET_ID="${GATE4_STAGE_A_TICKET_ID:-GATE4-A-001}"
STAGE_B_TICKET_ID="${GATE4_STAGE_B_TICKET_ID:-GATE4-B-001}"
STAGE_C_TICKET_ID="${GATE4_STAGE_C_TICKET_ID:-GATE4-C-REAL-001}"

STAGE_A_RECEIPT_FILE="${GATE4_MANUAL_RECEIPT_FILE:-runtime/argus/config/gate4/manual_receipt.json}"
STAGE_B_RELEASE_ID="${GATE4_STAGE_B_RELEASE_ID:-XHS-REL-001}"
STAGE_B_RECEIPT_FILE="${GATE4_RELEASE_RECEIPT_FILE:-runtime/argus/config/gate4/release_receipt.json}"

STAGE_C_PHASE_ID="${GATE4_PHASE_ID:-C1}"
STAGE_C_BATCH_ID="${GATE4_STAGE_C_BATCH_ID:-XHS-REAL-C1-BATCH-001}"
STAGE_C_RELEASE_ID="${GATE4_STAGE_C_RELEASE_ID:-XHS-REAL-C1-REL-001}"
STAGE_C_RECEIPT_FILE="${GATE4_STAGE_C_RECEIPT_FILE:-runtime/argus/config/gate4/stage_c_real_c1_receipt.json}"
STAGE_C_REQUIRE_REAL_EVIDENCE="${GATE4_STAGE_C_REQUIRE_REAL_EVIDENCE:-yes}"

log() {
  printf '[parallel-gate4-abc-recheck] %s\n' "$*"
}

read_kv() {
  local file="$1"
  local key="$2"
  awk -F= -v k="$key" '$1==k{print substr($0, index($0,"=")+1)}' "$file" | tail -n 1
}

need_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "missing command: $cmd" >&2
    exit 1
  fi
}

need_cmd bash
need_cmd awk

mkdir -p "$ARTIFACT_DIR"

STAGE_A_ROOT="$EXEC_ROOT/stage-a"
STAGE_B_ROOT="$EXEC_ROOT/stage-b"
STAGE_C_ROOT="$EXEC_ROOT/stage-c"

log "running stage-a strict recheck"
EXEC_ROOT="$STAGE_A_ROOT" \
GATE4_ACCOUNT_ID="$ACCOUNT_ID" \
GATE4_OPERATOR="$OPERATOR" \
GATE4_TICKET_ID="$STAGE_A_TICKET_ID" \
GATE4_MANUAL_RECEIPT_FILE="$STAGE_A_RECEIPT_FILE" \
GATE4_STAGE_A_STRICT='yes' \
bash ./deploy/gate4_stage_a_execute.sh >"$ARTIFACT_DIR/stage-a.log" 2>&1

log "running stage-b strict recheck"
EXEC_ROOT="$STAGE_B_ROOT" \
GATE4_ACCOUNT_ID="$ACCOUNT_ID" \
GATE4_RELEASE_ID="$STAGE_B_RELEASE_ID" \
GATE4_OPERATOR="$OPERATOR" \
GATE4_TICKET_ID="$STAGE_B_TICKET_ID" \
GATE4_RELEASE_RECEIPT_FILE="$STAGE_B_RECEIPT_FILE" \
GATE4_STAGE_B_STRICT='yes' \
bash ./deploy/gate4_stage_b_execute.sh >"$ARTIFACT_DIR/stage-b.log" 2>&1

log "running stage-c strict recheck"
EXEC_ROOT="$STAGE_C_ROOT" \
GATE4_ACCOUNT_ID="$ACCOUNT_ID" \
GATE4_PHASE_ID="$STAGE_C_PHASE_ID" \
GATE4_BATCH_ID="$STAGE_C_BATCH_ID" \
GATE4_RELEASE_ID="$STAGE_C_RELEASE_ID" \
GATE4_OPERATOR="$OPERATOR" \
GATE4_TICKET_ID="$STAGE_C_TICKET_ID" \
GATE4_STAGE_C_RECEIPT_FILE="$STAGE_C_RECEIPT_FILE" \
GATE4_STAGE_C_REQUIRE_REAL_EVIDENCE="$STAGE_C_REQUIRE_REAL_EVIDENCE" \
GATE4_STAGE_C_STRICT='yes' \
bash ./deploy/gate4_stage_c_execute.sh >"$ARTIFACT_DIR/stage-c.log" 2>&1

STAGE_A_SUMMARY="$STAGE_A_ROOT/artifacts/stage-a-summary.txt"
STAGE_B_SUMMARY="$STAGE_B_ROOT/artifacts/stage-b-summary.txt"
STAGE_C_SUMMARY="$STAGE_C_ROOT/artifacts/stage-c-summary.txt"

STAGE_A_RESULT="$(read_kv "$STAGE_A_SUMMARY" "stage_a_result")"
STAGE_B_RESULT="$(read_kv "$STAGE_B_SUMMARY" "stage_b_result")"
STAGE_C_RESULT="$(read_kv "$STAGE_C_SUMMARY" "stage_c_result")"

OVERALL_RESULT="blocked"
if [[ "$STAGE_A_RESULT" == "stage_a_passed" && "$STAGE_B_RESULT" == "stage_b_passed" && "$STAGE_C_RESULT" == "stage_c_passed" ]]; then
  OVERALL_RESULT="parallel_gate4_abc_recheck_passed"
fi

SUMMARY_FILE="$ARTIFACT_DIR/summary.txt"
cat >"$SUMMARY_FILE" <<EOF
timestamp=$(date +%Y-%m-%dT%H:%M:%S%z)
exec_root=$EXEC_ROOT
account_id=$ACCOUNT_ID
operator=$OPERATOR
stage_a_summary=$STAGE_A_SUMMARY
stage_a_result=$STAGE_A_RESULT
stage_b_summary=$STAGE_B_SUMMARY
stage_b_result=$STAGE_B_RESULT
stage_c_summary=$STAGE_C_SUMMARY
stage_c_result=$STAGE_C_RESULT
overall_result=$OVERALL_RESULT
note=parallel_gate4_abc_recheck_passed means stage-a/stage-b/stage-c strict checks all passed.
EOF

log "done"
log "exec root: $EXEC_ROOT"
log "summary: $SUMMARY_FILE"
cat "$SUMMARY_FILE"

if [[ "$OVERALL_RESULT" != "parallel_gate4_abc_recheck_passed" ]]; then
  exit 4
fi

