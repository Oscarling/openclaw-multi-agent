#!/usr/bin/env bash
set -euo pipefail
umask 077

TS="$(date +%Y%m%d-%H%M%S)"
UPSTREAM_REPO="${UPSTREAM_REPO:-openclaw/openclaw}"
UPSTREAM_ISSUE_NUMBER="${UPSTREAM_ISSUE_NUMBER:-56267}"
LOCAL_REPO="${LOCAL_REPO:-Oscarling/openclaw-multi-agent}"
LOCAL_ISSUE_NUMBER="${LOCAL_ISSUE_NUMBER:-37}"
ISSUE_OWNER_LOGIN="${ISSUE_OWNER_LOGIN:-Oscarling}"
STATE_FILE="${STATE_FILE:-runtime/argus/config/rh_t5_b01/upstream_feedback_state.env}"
PROBE_ROOT="${PROBE_ROOT:-design/validation/artifacts/openclaw-rh-t5-b01-upstream-feedback-probe-$TS}"
ARTIFACT_DIR="$PROBE_ROOT/artifacts"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

log() {
  printf '[rh-t5-b01-upstream-feedback-probe] %s\n' "$*"
}

need_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "missing command: $cmd" >&2
    exit 1
  fi
}

need_cmd gh
need_cmd jq

mkdir -p "$ARTIFACT_DIR"

read_state_key() {
  local file="$1"
  local key="$2"
  awk -F= -v k="$key" '$1==k{print substr($0, index($0,"=")+1)}' "$file" | tail -n 1
}

to_nonneg_int() {
  local raw="${1:-}"
  if [[ "$raw" =~ ^[0-9]+$ ]]; then
    printf '%s' "$raw"
  else
    printf '0'
  fi
}

UPSTREAM_JSON="$ARTIFACT_DIR/upstream-issue.json"
LOCAL_JSON="$ARTIFACT_DIR/local-issue.json"

log "fetching upstream issue"
gh issue view "$UPSTREAM_ISSUE_NUMBER" -R "$UPSTREAM_REPO" \
  --json number,title,state,author,url,createdAt,updatedAt,comments >"$UPSTREAM_JSON"

log "fetching local tracking issue"
gh issue view "$LOCAL_ISSUE_NUMBER" -R "$LOCAL_REPO" \
  --json number,title,state,author,url,createdAt,updatedAt,comments >"$LOCAL_JSON"

UPSTREAM_STATE="$(jq -r '.state // ""' "$UPSTREAM_JSON")"
UPSTREAM_UPDATED_AT="$(jq -r '.updatedAt // ""' "$UPSTREAM_JSON")"
UPSTREAM_COMMENT_COUNT="$(jq -r '.comments | length' "$UPSTREAM_JSON")"
UPSTREAM_EXTERNAL_COMMENT_COUNT="$(jq -r --arg owner "$ISSUE_OWNER_LOGIN" '[.comments[] | select((.author.login // "") != $owner)] | length' "$UPSTREAM_JSON")"
UPSTREAM_LAST_COMMENT_AUTHOR="$(jq -r '.comments[-1].author.login // ""' "$UPSTREAM_JSON")"
UPSTREAM_LAST_COMMENT_CREATED_AT="$(jq -r '.comments[-1].createdAt // ""' "$UPSTREAM_JSON")"
UPSTREAM_LAST_COMMENT_URL="$(jq -r '.comments[-1].url // ""' "$UPSTREAM_JSON")"
UPSTREAM_LAST_EXTERNAL_COMMENT_AUTHOR="$(jq -r --arg owner "$ISSUE_OWNER_LOGIN" '[.comments[] | select((.author.login // "") != $owner)][-1].author.login // ""' "$UPSTREAM_JSON")"
UPSTREAM_LAST_EXTERNAL_COMMENT_CREATED_AT="$(jq -r --arg owner "$ISSUE_OWNER_LOGIN" '[.comments[] | select((.author.login // "") != $owner)][-1].createdAt // ""' "$UPSTREAM_JSON")"
UPSTREAM_LAST_EXTERNAL_COMMENT_URL="$(jq -r --arg owner "$ISSUE_OWNER_LOGIN" '[.comments[] | select((.author.login // "") != $owner)][-1].url // ""' "$UPSTREAM_JSON")"

LOCAL_STATE="$(jq -r '.state // ""' "$LOCAL_JSON")"
LOCAL_UPDATED_AT="$(jq -r '.updatedAt // ""' "$LOCAL_JSON")"
LOCAL_COMMENT_COUNT="$(jq -r '.comments | length' "$LOCAL_JSON")"
LOCAL_TRACKING_ISSUE_OPEN="no"
if [[ "$LOCAL_STATE" == "OPEN" ]]; then
  LOCAL_TRACKING_ISSUE_OPEN="yes"
fi

STATE_PRESENT="no"
PROCESSED_EXTERNAL_COMMENT_COUNT=""
PROCESSED_LAST_EXTERNAL_COMMENT_AUTHOR=""
PROCESSED_LAST_EXTERNAL_COMMENT_CREATED_AT=""
PROCESSED_LAST_EXTERNAL_COMMENT_URL=""
if [[ -f "$STATE_FILE" ]]; then
  STATE_PRESENT="yes"
  PROCESSED_EXTERNAL_COMMENT_COUNT="$(read_state_key "$STATE_FILE" "last_processed_external_comment_count")"
  PROCESSED_LAST_EXTERNAL_COMMENT_AUTHOR="$(read_state_key "$STATE_FILE" "last_processed_external_comment_author")"
  PROCESSED_LAST_EXTERNAL_COMMENT_CREATED_AT="$(read_state_key "$STATE_FILE" "last_processed_external_comment_created_at")"
  PROCESSED_LAST_EXTERNAL_COMMENT_URL="$(read_state_key "$STATE_FILE" "last_processed_external_comment_url")"
fi

UPSTREAM_EXTERNAL_COMMENT_COUNT_NUM="$(to_nonneg_int "$UPSTREAM_EXTERNAL_COMMENT_COUNT")"
PROCESSED_EXTERNAL_COMMENT_COUNT_NUM="$(to_nonneg_int "$PROCESSED_EXTERNAL_COMMENT_COUNT")"

UPSTREAM_FEEDBACK_DETECTED="no"
UPSTREAM_NEW_FEEDBACK_DETECTED="no"
NEXT_EVENT="waiting_upstream_feedback"

if [[ "$UPSTREAM_EXTERNAL_COMMENT_COUNT_NUM" -gt 0 ]]; then
  UPSTREAM_FEEDBACK_DETECTED="yes"
fi

if [[ "$UPSTREAM_EXTERNAL_COMMENT_COUNT_NUM" -gt "$PROCESSED_EXTERNAL_COMMENT_COUNT_NUM" ]]; then
  UPSTREAM_NEW_FEEDBACK_DETECTED="yes"
elif [[ -n "$UPSTREAM_LAST_EXTERNAL_COMMENT_URL" && "$UPSTREAM_LAST_EXTERNAL_COMMENT_URL" != "$PROCESSED_LAST_EXTERNAL_COMMENT_URL" ]]; then
  UPSTREAM_NEW_FEEDBACK_DETECTED="yes"
fi

if [[ "$LOCAL_TRACKING_ISSUE_OPEN" != "yes" ]]; then
  NEXT_EVENT="reopen_local_tracking_issue"
elif [[ "$UPSTREAM_NEW_FEEDBACK_DETECTED" == "yes" ]]; then
  NEXT_EVENT="upstream_feedback_received"
fi

SUMMARY="$ARTIFACT_DIR/summary.txt"
cat >"$SUMMARY" <<EOF
timestamp=$(date +%Y-%m-%dT%H:%M:%S%z)
probe_root=$PROBE_ROOT
upstream_repo=$UPSTREAM_REPO
upstream_issue_number=$UPSTREAM_ISSUE_NUMBER
upstream_issue_state=$UPSTREAM_STATE
upstream_issue_updated_at=$UPSTREAM_UPDATED_AT
upstream_comment_count=$UPSTREAM_COMMENT_COUNT
upstream_external_comment_count=$UPSTREAM_EXTERNAL_COMMENT_COUNT
upstream_last_comment_author=$UPSTREAM_LAST_COMMENT_AUTHOR
upstream_last_comment_created_at=$UPSTREAM_LAST_COMMENT_CREATED_AT
upstream_last_comment_url=$UPSTREAM_LAST_COMMENT_URL
upstream_last_external_comment_author=$UPSTREAM_LAST_EXTERNAL_COMMENT_AUTHOR
upstream_last_external_comment_created_at=$UPSTREAM_LAST_EXTERNAL_COMMENT_CREATED_AT
upstream_last_external_comment_url=$UPSTREAM_LAST_EXTERNAL_COMMENT_URL
local_repo=$LOCAL_REPO
local_issue_number=$LOCAL_ISSUE_NUMBER
local_issue_state=$LOCAL_STATE
local_issue_updated_at=$LOCAL_UPDATED_AT
local_comment_count=$LOCAL_COMMENT_COUNT
local_tracking_issue_open=$LOCAL_TRACKING_ISSUE_OPEN
issue_owner_login=$ISSUE_OWNER_LOGIN
state_file=$STATE_FILE
state_present=$STATE_PRESENT
processed_external_comment_count=$PROCESSED_EXTERNAL_COMMENT_COUNT
processed_last_external_comment_author=$PROCESSED_LAST_EXTERNAL_COMMENT_AUTHOR
processed_last_external_comment_created_at=$PROCESSED_LAST_EXTERNAL_COMMENT_CREATED_AT
processed_last_external_comment_url=$PROCESSED_LAST_EXTERNAL_COMMENT_URL
upstream_feedback_detected=$UPSTREAM_FEEDBACK_DETECTED
upstream_new_feedback_detected=$UPSTREAM_NEW_FEEDBACK_DETECTED
next_event=$NEXT_EVENT
note=upstream_new_feedback_detected=yes means unprocessed upstream external feedback is present and should trigger upstream recheck bundle. upstream_feedback_detected=yes means external feedback exists, but may already have been processed.
EOF

log "done"
log "probe root: $PROBE_ROOT"
log "summary: $SUMMARY"
cat "$SUMMARY"
