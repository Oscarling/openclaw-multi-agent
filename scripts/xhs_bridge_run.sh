#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

ENTRY_URL="${XHS_BRIDGE_ENTRY_URL:-https://creator.xiaohongshu.com/publish/publish?source=official}"
BROWSER="${XHS_BRIDGE_BROWSER:-webkit}"
KEEP_OPEN="${XHS_BRIDGE_KEEP_OPEN:-yes}"
PULL_JOB="no"
FORCE_INSTALL_WEBKIT="no"

usage() {
  cat <<'EOF'
用法：
  bash ./scripts/xhs_bridge_run.sh [选项]

选项：
  --pull-job               先执行 scripts/xhs_pull_publish_job.sh 拉取最新 job
  --browser <name>         指定浏览器：chromium | webkit | safari(=webkit)
  --entry-url <url>        指定入口地址（默认创作发布页）
  --no-keep-open           不加 --keep-open（脚本结束后关闭浏览器）
  --force-install-webkit   每次都执行 npx playwright install webkit
  -h, --help               显示帮助

环境变量（可选）：
  XHS_BRIDGE_ENTRY_URL
  XHS_BRIDGE_BROWSER
  XHS_BRIDGE_KEEP_OPEN

示例：
  bash ./scripts/xhs_bridge_run.sh
  bash ./scripts/xhs_bridge_run.sh --pull-job
  bash ./scripts/xhs_bridge_run.sh --browser chromium --no-keep-open
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pull-job)
      PULL_JOB="yes"
      shift
      ;;
    --browser)
      BROWSER="${2:-}"
      if [[ -z "$BROWSER" ]]; then
        echo "[xhs-bridge-run] 缺少 --browser 参数值"
        exit 1
      fi
      shift 2
      ;;
    --entry-url)
      ENTRY_URL="${2:-}"
      if [[ -z "$ENTRY_URL" ]]; then
        echo "[xhs-bridge-run] 缺少 --entry-url 参数值"
        exit 1
      fi
      shift 2
      ;;
    --no-keep-open)
      KEEP_OPEN="no"
      shift
      ;;
    --force-install-webkit)
      FORCE_INSTALL_WEBKIT="yes"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "[xhs-bridge-run] 未知参数：$1"
      usage
      exit 1
      ;;
  esac
done

if [[ "$BROWSER" == "safari" ]]; then
  BROWSER="webkit"
fi

if [[ "$BROWSER" != "chromium" && "$BROWSER" != "webkit" ]]; then
  echo "[xhs-bridge-run] --browser 仅支持 chromium 或 webkit（safari 会映射为 webkit）"
  exit 1
fi

if [[ "$PULL_JOB" == "yes" ]]; then
  echo "[xhs-bridge-run] pull latest publish_job from container..."
  bash ./scripts/xhs_pull_publish_job.sh
fi

if [[ "$BROWSER" == "webkit" ]]; then
  if [[ "$FORCE_INSTALL_WEBKIT" == "yes" ]]; then
    echo "[xhs-bridge-run] force install playwright webkit..."
    npx playwright install webkit
  else
    WEBKIT_CHECK="$(npx playwright install --dry-run webkit 2>&1 || true)"
    if echo "$WEBKIT_CHECK" | rg -q "browser: webkit version .* already installed"; then
      echo "[xhs-bridge-run] playwright webkit already installed"
    else
      echo "[xhs-bridge-run] playwright webkit not found, installing..."
      npx playwright install webkit
    fi
  fi
fi

LATEST_JOB="$(ls -1dt ./runtime/host_bridge_jobs/*/publish_job.json 2>/dev/null | head -n 1 || true)"
if [[ -z "$LATEST_JOB" ]]; then
  echo "[xhs-bridge-run] 未找到 publish_job.json"
  echo "[xhs-bridge-run] 请先执行：bash ./scripts/xhs_pull_publish_job.sh"
  exit 1
fi

echo "[xhs-bridge-run] latest job: $LATEST_JOB"
echo "[xhs-bridge-run] browser: $BROWSER"
echo "[xhs-bridge-run] entry-url: $ENTRY_URL"

echo "[xhs-bridge-run] validating publish_job contract..."
if ! node ./scripts/xhs_publish_job_guard.js --job "$LATEST_JOB"; then
  echo "[xhs-bridge-run] blocked: publish_job 校验未通过，已停止自动填充。"
  echo "[xhs-bridge-run] 可执行：bash ./scripts/xhs_argus_prep_gate.sh --json"
  exit 2
fi

CMD=(node ./scripts/xhs_host_bridge_fill.js --job "$LATEST_JOB" --entry-url "$ENTRY_URL" --browser "$BROWSER")
if [[ "$KEEP_OPEN" == "yes" ]]; then
  CMD+=(--keep-open)
fi

echo "[xhs-bridge-run] running: ${CMD[*]}"
"${CMD[@]}"
