#!/usr/bin/env bash

# Stage user-supplied Bonsai assets for a private Android image. Model assets
# and the resulting directory are intentionally ignored by Git.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: stage-bonsai-model.sh --model FILE --mmproj FILE --runtime-commit SHA \
  --dynamic-partition-budget-bytes BYTES [--backend NAME] [--minimum-free-memory-bytes BYTES] \
  [--stage-dir DIR]

Stages read-only copies as model.gguf and mmproj.gguf and writes manifest.json.
The budget must include all dynamic-partition content reserved for these assets.
EOF
}

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
model=""; mmproj=""; runtime_commit=""; budget=""; backend="cpu-neon-kleidiai"
minimum_free_memory="0"; stage_dir="$root/.local-bonsai/staged-model"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --model) model="${2:?}"; shift 2 ;;
    --mmproj) mmproj="${2:?}"; shift 2 ;;
    --runtime-commit) runtime_commit="${2:?}"; shift 2 ;;
    --dynamic-partition-budget-bytes) budget="${2:?}"; shift 2 ;;
    --backend) backend="${2:?}"; shift 2 ;;
    --minimum-free-memory-bytes) minimum_free_memory="${2:?}"; shift 2 ;;
    --stage-dir) stage_dir="${2:?}"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done

[[ -f "$model" && -s "$model" ]] || { echo "error: model must be a non-empty file" >&2; exit 2; }
[[ -f "$mmproj" && -s "$mmproj" ]] || { echo "error: mmproj must be a non-empty file" >&2; exit 2; }
[[ "$runtime_commit" =~ ^[[:xdigit:]]{7,64}$ ]] || { echo "error: runtime commit must be a git SHA" >&2; exit 2; }
[[ "$budget" =~ ^[0-9]+$ && "$budget" -gt 0 ]] || { echo "error: budget must be a positive byte count" >&2; exit 2; }
[[ "$minimum_free_memory" =~ ^[0-9]+$ ]] || { echo "error: minimum free memory must be a byte count" >&2; exit 2; }

model_bytes="$(wc -c < "$model" | tr -d '[:space:]')"
mmproj_bytes="$(wc -c < "$mmproj" | tr -d '[:space:]')"
total_bytes=$((model_bytes + mmproj_bytes))
(( total_bytes <= budget )) || {
  echo "error: model assets need $total_bytes bytes but budget is $budget bytes" >&2
  exit 1
}

mkdir -p "$stage_dir"
install -m 0444 "$model" "$stage_dir/model.gguf"
install -m 0444 "$mmproj" "$stage_dir/mmproj.gguf"

python3 - "$stage_dir/manifest.json" "$runtime_commit" "$backend" "$minimum_free_memory" \
  "$model_bytes" "$mmproj_bytes" <<'PY'
import hashlib
import json
import pathlib
import sys

manifest, commit, backend, free_memory, model_bytes, mmproj_bytes = sys.argv[1:]
directory = pathlib.Path(manifest).parent
assets = []
for name, byte_count in (("model.gguf", model_bytes), ("mmproj.gguf", mmproj_bytes)):
    path = directory / name
    assets.append({"filename": name, "sha256": hashlib.sha256(path.read_bytes()).hexdigest(), "bytes": int(byte_count)})
pathlib.Path(manifest).write_text(json.dumps({
    "schema_version": 1,
    "required_runtime_commit": commit,
    "backend_recommendation": backend,
    "minimum_free_memory_bytes": int(free_memory),
    "install_path": "/product/etc/bonsai/models",
    "assets": assets,
}, indent=2) + "\n", encoding="utf-8")
PY
chmod 0444 "$stage_dir/manifest.json"
printf 'Staged local-only model assets in %s (%s bytes; budget %s bytes)\n' "$stage_dir" "$total_bytes" "$budget"
