#!/usr/bin/env bash
set -euo pipefail
umask 077

TS="$(date +%Y%m%d-%H%M%S)"
PREFLIGHT_ROOT="${PREFLIGHT_ROOT:-/tmp/openclaw-gate4-stagec-preflight-$TS}"
ARTIFACT_DIR="$PREFLIGHT_ROOT/artifacts"

STAGEB_DOD_FILE="${GATE4_STAGEB_DOD_FILE:-design/validation/2026-03-26-gate4-stage-b-dod-validation.md}"
ROLLOUT_STRATEGY_CARD="${GATE4_ROLLOUT_STRATEGY_CARD:-design/2026-03-26-m2-e5-rollout-strategy-card-v1.md}"
ROLLOUT_POLICY_TEMPLATE="${GATE4_ROLLOUT_POLICY_TEMPLATE:-shared/templates/gate4_rollout_policy_template.json}"
SECRETS_DIR="${GATE4_SECRETS_DIR:-runtime/argus/config/secrets}"
TOKEN_FILE="${GATE4_TELEGRAM_TOKEN_FILE:-runtime/argus/config/secrets/telegram_bot_token.txt}"

log() {
  printf '[gate4-stagec-preflight] %s\n' "$*"
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

STAGEB_DOD_PRESENT="no"
STAGEB_DOD_APPROVED="no"
ROLLOUT_CARD_PRESENT="no"
ROLLOUT_CARD_VALID="no"
ROLLOUT_TEMPLATE_PRESENT="no"
ROLLOUT_TEMPLATE_VALID="no"
SECRETS_DIR_PRESENT="no"
TOKEN_FILE_PRESENT="no"
TOKEN_PERM_OK="no"
SAFE_WRAPPER_OK="no"
ROUTE_PROBE_OK="no"

if [[ -f "$STAGEB_DOD_FILE" ]]; then
  STAGEB_DOD_PRESENT="yes"
  if grep -q '结论：`Conditional-Go`' "$STAGEB_DOD_FILE" || grep -q '结论：`Go`' "$STAGEB_DOD_FILE"; then
    STAGEB_DOD_APPROVED="yes"
  fi
fi

if [[ -f "$ROLLOUT_STRATEGY_CARD" ]]; then
  ROLLOUT_CARD_PRESENT="yes"
  if grep -q '流量梯度' "$ROLLOUT_STRATEGY_CARD" && grep -q '停机' "$ROLLOUT_STRATEGY_CARD" && grep -q '回滚' "$ROLLOUT_STRATEGY_CARD"; then
    ROLLOUT_CARD_VALID="yes"
  fi
fi

if [[ -f "$ROLLOUT_POLICY_TEMPLATE" ]]; then
  ROLLOUT_TEMPLATE_PRESENT="yes"
  if python3 - "$ROLLOUT_POLICY_TEMPLATE" >"$ARTIFACT_DIR/rollout-template-check.log" 2>&1 <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
obj = json.loads(path.read_text(encoding="utf-8"))

if not isinstance(obj.get("version"), str):
    raise SystemExit("version must be string")
if not isinstance(obj.get("platform"), str):
    raise SystemExit("platform must be string")

phases = obj.get("phases")
if not isinstance(phases, list) or not phases:
    raise SystemExit("phases must be non-empty list")

required = {
    "phase_id",
    "max_batch_size",
    "success_rate_threshold",
    "halt_failure_count",
    "require_manual_gate",
}

for i, phase in enumerate(phases, start=1):
    if not isinstance(phase, dict):
        raise SystemExit(f"phases[{i}] must be object")
    missing = sorted(required - set(phase.keys()))
    if missing:
        raise SystemExit(f"phases[{i}] missing fields: {', '.join(missing)}")
    if not isinstance(phase["phase_id"], str):
        raise SystemExit(f"phases[{i}].phase_id must be string")
    if not isinstance(phase["max_batch_size"], int) or phase["max_batch_size"] <= 0:
        raise SystemExit(f"phases[{i}].max_batch_size must be positive int")
    if not isinstance(phase["success_rate_threshold"], (int, float)) or not (0 <= phase["success_rate_threshold"] <= 1):
        raise SystemExit(f"phases[{i}].success_rate_threshold must be in [0,1]")
    if not isinstance(phase["halt_failure_count"], int) or phase["halt_failure_count"] < 0:
        raise SystemExit(f"phases[{i}].halt_failure_count must be non-negative int")
    if not isinstance(phase["require_manual_gate"], bool):
        raise SystemExit(f"phases[{i}].require_manual_gate must be bool")

print("rollout_policy_template_ok")
PY
  then
    ROLLOUT_TEMPLATE_VALID="yes"
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
if [[ "$STAGEB_DOD_PRESENT" != "yes" ]]; then
  PREFLIGHT_RESULT="waiting_stage_b_dod"
elif [[ "$STAGEB_DOD_APPROVED" != "yes" ]]; then
  PREFLIGHT_RESULT="waiting_stage_b_approval"
elif [[ "$ROLLOUT_CARD_PRESENT" != "yes" ]]; then
  PREFLIGHT_RESULT="waiting_rollout_card"
elif [[ "$ROLLOUT_CARD_VALID" != "yes" ]]; then
  PREFLIGHT_RESULT="waiting_rollout_card_fix"
elif [[ "$ROLLOUT_TEMPLATE_PRESENT" != "yes" ]]; then
  PREFLIGHT_RESULT="waiting_rollout_template"
elif [[ "$ROLLOUT_TEMPLATE_VALID" != "yes" ]]; then
  PREFLIGHT_RESULT="waiting_rollout_template_fix"
elif [[ "$SECRETS_DIR_PRESENT" != "yes" || "$TOKEN_FILE_PRESENT" != "yes" || "$TOKEN_PERM_OK" != "yes" ]]; then
  PREFLIGHT_RESULT="waiting_secrets"
elif [[ "$SAFE_WRAPPER_OK" == "yes" && "$ROUTE_PROBE_OK" == "yes" ]]; then
  PREFLIGHT_RESULT="ready_for_stage_c_execution"
fi

SUMMARY_FILE="$ARTIFACT_DIR/preflight-summary.txt"
cat >"$SUMMARY_FILE" <<EOF
timestamp=$(date +%Y-%m-%dT%H:%M:%S%z)
preflight_root=$PREFLIGHT_ROOT
stageb_dod_file=$STAGEB_DOD_FILE
stageb_dod_present=$STAGEB_DOD_PRESENT
stageb_dod_approved=$STAGEB_DOD_APPROVED
rollout_strategy_card=$ROLLOUT_STRATEGY_CARD
rollout_card_present=$ROLLOUT_CARD_PRESENT
rollout_card_valid=$ROLLOUT_CARD_VALID
rollout_policy_template=$ROLLOUT_POLICY_TEMPLATE
rollout_template_present=$ROLLOUT_TEMPLATE_PRESENT
rollout_template_valid=$ROLLOUT_TEMPLATE_VALID
secrets_dir=$SECRETS_DIR
secrets_dir_present=$SECRETS_DIR_PRESENT
token_file=$TOKEN_FILE
token_file_present=$TOKEN_FILE_PRESENT
token_perm_ok=$TOKEN_PERM_OK
safe_wrapper_ok=$SAFE_WRAPPER_OK
route_probe_ok=$ROUTE_PROBE_OK
preflight_result=$PREFLIGHT_RESULT
note=ready_for_stage_c_execution means stage-b decision, rollout controls, and guardrails are all ready.
EOF

log "done"
log "preflight root: $PREFLIGHT_ROOT"
log "summary: $SUMMARY_FILE"
cat "$SUMMARY_FILE"
