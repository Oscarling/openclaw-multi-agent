#!/usr/bin/env bash
set -euo pipefail
umask 077

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

CONTAINER_NAME="${CONTAINER_NAME:-agent_argus}"
CONTAINER_JOB_PATH="${1:-/root/.openclaw/workspace/steward/outputs/GOAL-XHS-ASSET-001/P01/20260401T001853Z/publish_job.json}"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUT_DIR="${2:-runtime/host_bridge_jobs/$STAMP}"
OUT_PATH="$OUT_DIR/publish_job.json"
CONTAINER_DIR="$(dirname "$CONTAINER_JOB_PATH")"
LOCAL_MATERIAL_DIR="$OUT_DIR/materials"
LOCAL_CONTAINER_COPY="$OUT_DIR/publish_job.container.json"
LOCAL_ABS_MATERIAL_DIR="$(cd "$PROJECT_ROOT" && mkdir -p "$LOCAL_MATERIAL_DIR" && cd "$LOCAL_MATERIAL_DIR" && pwd)"

mkdir -p "$OUT_DIR"

echo "[xhs-pull] container=$CONTAINER_NAME"
echo "[xhs-pull] source=$CONTAINER_JOB_PATH"
echo "[xhs-pull] target=$OUT_PATH"

docker cp "$CONTAINER_NAME:$CONTAINER_JOB_PATH" "$LOCAL_CONTAINER_COPY"
cp "$LOCAL_CONTAINER_COPY" "$OUT_PATH"
chmod 600 "$OUT_PATH"
chmod 600 "$LOCAL_CONTAINER_COPY"

echo "[xhs-pull] syncing images from $CONTAINER_DIR/export"
docker cp "$CONTAINER_NAME:$CONTAINER_DIR/export/." "$LOCAL_MATERIAL_DIR/"

echo "[xhs-pull] syncing optional metadata files"
docker cp "$CONTAINER_NAME:$CONTAINER_DIR/index.html" "$OUT_DIR/index.html" || true
docker cp "$CONTAINER_NAME:$CONTAINER_DIR/manifest.json" "$OUT_DIR/manifest.json" || true

python3 - "$OUT_PATH" "$LOCAL_ABS_MATERIAL_DIR" <<'PY'
import json
import pathlib
import sys

job_path = pathlib.Path(sys.argv[1])
material_dir = pathlib.Path(sys.argv[2]).resolve()

data = json.loads(job_path.read_text(encoding="utf-8"))
data["material_dir"] = str(material_dir)

def normalize_image_ref(value: str) -> str:
    if not isinstance(value, str):
        return value
    # If Argus outputs container absolute paths, keep only filename so host side
    # can resolve it under rewritten local material_dir.
    if value.startswith("/"):
        return pathlib.Path(value).name
    return value

if isinstance(data.get("cover_file"), str):
    data["cover_file"] = normalize_image_ref(data["cover_file"])

if isinstance(data.get("image_files"), list):
    data["image_files"] = [normalize_image_ref(v) for v in data["image_files"]]

job_path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY

SHA256="$(shasum -a 256 "$OUT_PATH" | awk '{print $1}')"
SHA256_CONTAINER="$(shasum -a 256 "$LOCAL_CONTAINER_COPY" | awk '{print $1}')"

echo "[xhs-pull] ok"
echo "local_path=$OUT_PATH"
echo "sha256=$SHA256"
echo "container_sha256=$SHA256_CONTAINER"
echo "material_dir=$LOCAL_ABS_MATERIAL_DIR"
