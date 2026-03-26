#!/usr/bin/env bash
set -euo pipefail
umask 077

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VALIDATION_DIR="$PROJECT_ROOT/design/validation"
VALIDATION_ARTIFACTS_DIR="$VALIDATION_DIR/artifacts"
BACKUP_DIR="$PROJECT_ROOT/artifacts/backups"

TS="$(date +%Y%m%d-%H%M%S)"
DATE_STR="$(date +%Y-%m-%d)"
TZ_NAME="$(date +%Z)"

RUN_ROOT="${RUN_ROOT:-/tmp/openclaw-monthly-recovery-$TS}"
MONTHLY_ARTIFACT_DIR="$VALIDATION_ARTIFACTS_DIR/openclaw-monthly-recovery-$TS"
RECOVERY_DRILL_ROOT="/tmp/openclaw-recovery-drill-$TS"
HOST_APPLY_DRILL_ROOT="/tmp/openclaw-host-apply-drill-$TS"

ARCHIVE="${ARCHIVE:-}"
MANIFEST="${MANIFEST:-}"
PASSPHRASE_FILE="${OPENCLAW_BACKUP_PASSPHRASE_FILE:-$HOME/.openclaw/secrets/backup_passphrase.txt}"
PASSPHRASE="${OPENCLAW_BACKUP_PASSPHRASE:-}"
REPORT_PATH="${REPORT_PATH:-}"

START_EPOCH="$(date +%s)"
START_HUMAN="$(date '+%Y-%m-%d %H:%M:%S %z')"

log() {
  printf '[monthly-recovery-drill] %s\n' "$*"
}

need_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "missing command: $cmd" >&2
    exit 1
  fi
}

extract_run_id() {
  local json_file="$1"
  if [[ ! -f "$json_file" ]]; then
    echo ""
    return 0
  fi
  if command -v jq >/dev/null 2>&1; then
    jq -r '.runId // ""' "$json_file"
    return 0
  fi
  sed -n 's/^[[:space:]]*"runId":[[:space:]]*"\([^"]*\)".*$/\1/p' "$json_file" | head -n 1
}

need_cmd bash
need_cmd docker
need_cmd curl
need_cmd cp
need_cmd ls

mkdir -p "$RUN_ROOT" "$VALIDATION_ARTIFACTS_DIR" "$MONTHLY_ARTIFACT_DIR"

if [[ -z "$ARCHIVE" ]]; then
  ARCHIVE="$(ls -1t "$BACKUP_DIR"/*.tgz.enc 2>/dev/null | head -n 1 || true)"
fi

if [[ -z "$ARCHIVE" ]]; then
  echo "no backup archive found under $BACKUP_DIR (*.tgz.enc)" >&2
  exit 1
fi

if [[ ! -f "$ARCHIVE" ]]; then
  echo "archive not found: $ARCHIVE" >&2
  exit 1
fi

if [[ -z "$MANIFEST" ]]; then
  MANIFEST="${ARCHIVE%.tgz.enc}.manifest.txt"
fi

if [[ ! -f "$MANIFEST" ]]; then
  echo "manifest not found: $MANIFEST" >&2
  exit 1
fi

if [[ -z "$PASSPHRASE" ]]; then
  if [[ ! -f "$PASSPHRASE_FILE" ]]; then
    echo "passphrase file not found: $PASSPHRASE_FILE" >&2
    echo "set OPENCLAW_BACKUP_PASSPHRASE_FILE or OPENCLAW_BACKUP_PASSPHRASE before running." >&2
    exit 1
  fi
fi

log "running recovery drill"
DRILL_ROOT="$RECOVERY_DRILL_ROOT" \
  bash "$PROJECT_ROOT/deploy/recovery_drill.sh" \
  >"$RUN_ROOT/recovery-drill.log" 2>&1

log "running host apply drill"
if [[ -n "$PASSPHRASE" ]]; then
  ARCHIVE="$ARCHIVE" MANIFEST="$MANIFEST" OPENCLAW_BACKUP_PASSPHRASE="$PASSPHRASE" DRILL_ROOT="$HOST_APPLY_DRILL_ROOT" \
    bash "$PROJECT_ROOT/deploy/host_apply_drill.sh" \
    >"$RUN_ROOT/host-apply-drill.log" 2>&1
else
  ARCHIVE="$ARCHIVE" MANIFEST="$MANIFEST" OPENCLAW_BACKUP_PASSPHRASE_FILE="$PASSPHRASE_FILE" DRILL_ROOT="$HOST_APPLY_DRILL_ROOT" \
    bash "$PROJECT_ROOT/deploy/host_apply_drill.sh" \
    >"$RUN_ROOT/host-apply-drill.log" 2>&1
fi

log "collecting artifacts"
cp -R "$RECOVERY_DRILL_ROOT" "$VALIDATION_ARTIFACTS_DIR/"
cp -R "$HOST_APPLY_DRILL_ROOT" "$VALIDATION_ARTIFACTS_DIR/"
cp "$RUN_ROOT/recovery-drill.log" "$MONTHLY_ARTIFACT_DIR/"
cp "$RUN_ROOT/host-apply-drill.log" "$MONTHLY_ARTIFACT_DIR/"

docker exec agent_argus openclaw agents list --bindings --json >"$MONTHLY_ARTIFACT_DIR/postcheck-agents.json"
curl -fsSL http://localhost:3001/__openclaw/control-ui-config.json >"$MONTHLY_ARTIFACT_DIR/postcheck-control-ui-config.json"
docker exec agent_argus openclaw config file >"$MONTHLY_ARTIFACT_DIR/postcheck-config-file.txt"

RECOVERY_RUN_ID="$(extract_run_id "$RECOVERY_DRILL_ROOT/artifacts/drill-steward-smoke.json")"
HOST_APPLY_RUN_ID="$(extract_run_id "$HOST_APPLY_DRILL_ROOT/artifacts/applied-steward-smoke.json")"

END_EPOCH="$(date +%s)"
END_HUMAN="$(date '+%Y-%m-%d %H:%M:%S %z')"
DURATION_SEC=$((END_EPOCH - START_EPOCH))

if [[ -z "$REPORT_PATH" ]]; then
  REPORT_PATH="$VALIDATION_DIR/$DATE_STR-monthly-recovery-drill-validation.md"
  if [[ -f "$REPORT_PATH" ]]; then
    REPORT_PATH="$VALIDATION_DIR/$DATE_STR-monthly-recovery-drill-validation-$TS.md"
  fi
fi

cat >"$REPORT_PATH" <<EOF
# $DATE_STR Monthly Recovery Drill Validation

更新时间：$DATE_STR  
时区：$TZ_NAME  
类型：月度回归演练（\`recovery_drill + host_apply_drill\`）

## 1) 基本信息

- 演练日期（Asia/Shanghai）：$DATE_STR
- 执行时间：
  - 开始：$START_HUMAN
  - 结束：$END_HUMAN
  - 耗时：${DURATION_SEC} 秒
- 使用备份包：$ARCHIVE
- 使用 manifest：$MANIFEST

## 2) 执行口径

- Recovery Drill：\`deploy/recovery_drill.sh\`
- Host Apply Drill：\`deploy/host_apply_drill.sh\`
- host apply 含自动回滚：是
- 完整性校验：\`manifest sha256\`

## 3) 结果核验

- recovery drill 冒烟 runId：${RECOVERY_RUN_ID:-N/A}
- host apply 冒烟 runId：${HOST_APPLY_RUN_ID:-N/A}
- postcheck config file：见 \`design/validation/artifacts/openclaw-monthly-recovery-$TS/postcheck-config-file.txt\`
- postcheck agents：见 \`design/validation/artifacts/openclaw-monthly-recovery-$TS/postcheck-agents.json\`
- postcheck control ui：见 \`design/validation/artifacts/openclaw-monthly-recovery-$TS/postcheck-control-ui-config.json\`

## 4) 证据索引

- 月度聚合证据目录：
  - \`design/validation/artifacts/openclaw-monthly-recovery-$TS\`
- recovery drill 证据目录：
  - \`design/validation/artifacts/openclaw-recovery-drill-$TS/artifacts\`
- host apply drill 证据目录：
  - \`design/validation/artifacts/openclaw-host-apply-drill-$TS/artifacts\`

## 5) 结论

- 本次月度回归演练链路执行完成，证据已落盘。
- 满足 C2 事件触发条件后，本次记录可用于关闭 Gate-1 条件 C2。
EOF

log "done"
log "report: $REPORT_PATH"
log "monthly artifact dir: $MONTHLY_ARTIFACT_DIR"
