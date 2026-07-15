#!/usr/bin/env bash

# Verify a directory produced by stage-bonsai-model.sh immediately before it is
# copied into a read-only product image. This never fetches or executes assets.
set -euo pipefail

usage() {
  printf 'Usage: %s STAGING_DIRECTORY\n' "${0##*/}"
}

[[ $# -eq 1 ]] || { usage >&2; exit 2; }
directory="$1"
manifest="$directory/manifest.json"

[[ -d "$directory" ]] || { echo "error: staging directory does not exist" >&2; exit 2; }
[[ -f "$manifest" ]] || { echo "error: missing manifest.json" >&2; exit 2; }

python3 - "$directory" <<'PY'
import hashlib
import json
import os
import pathlib
import stat
import sys

directory = pathlib.Path(sys.argv[1]).resolve()
manifest_path = directory / "manifest.json"
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))

if manifest.get("schema_version") != 1:
    raise SystemExit("unsupported manifest schema version")
if manifest.get("install_path") != "/product/etc/bonsai/models":
    raise SystemExit("manifest install path must be read-only product storage")
if not isinstance(manifest.get("required_runtime_commit"), str) or len(manifest["required_runtime_commit"]) < 7:
    raise SystemExit("manifest has no pinned runtime commit")
assets = manifest.get("assets")
if not isinstance(assets, list) or {asset.get("filename") for asset in assets} != {"model.gguf", "mmproj.gguf"}:
    raise SystemExit("manifest must describe exactly model.gguf and mmproj.gguf")

for asset in assets:
    name = asset["filename"]
    path = (directory / name).resolve()
    if path.parent != directory or not path.is_file():
        raise SystemExit(f"missing or unsafe asset path: {name}")
    mode = stat.S_IMODE(path.stat().st_mode)
    if mode & 0o222:
        raise SystemExit(f"asset is writable: {name}")
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    if digest != asset.get("sha256"):
        raise SystemExit(f"SHA-256 mismatch: {name}")
    if path.stat().st_size != asset.get("bytes"):
        raise SystemExit(f"size mismatch: {name}")

if stat.S_IMODE(manifest_path.stat().st_mode) & 0o222:
    raise SystemExit("manifest is writable")
print(f"Verified local-only Bonsai staging directory: {directory}")
PY
