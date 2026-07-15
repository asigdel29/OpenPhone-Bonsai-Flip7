#!/usr/bin/env bash

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

python3 - "$tmp/accepted.json" "$tmp/candidate.json" <<'PY'
import json
import pathlib
import sys

accepted_path = pathlib.Path(sys.argv[1])
candidate_path = pathlib.Path(sys.argv[2])
categories = ["text"] * 4 + ["reasoning"] * 2 + ["vision"] * 2 + ["cancellation"] * 2 + ["tool_safety"] * 2
report = {
    "schema": "openphone.bonsai_eval_report.v1",
    "suite_id": "bonsai-interactive-v1",
    "runtime": {
        "runtime_commit": "0123456789abcdef",
        "model_sha256": "a" * 64,
        "mmproj_sha256": "b" * 64,
        "backend": "vulkan",
        "cloud": False,
    },
    "summary": {
        "total": len(categories),
        "passed": len(categories),
        "accuracy": 0.95,
        "warm_first_token_p50_millis": 1800,
        "warm_first_token_p95_millis": 3500,
        "warm_decode_p50_tokens_per_second": 10,
        "cancel_p95_millis": 200,
    },
    "cases": [{"id": f"case-{index}", "category": category, "passed": True} for index, category in enumerate(categories)],
    "telemetry": {
        "peak_rss_bytes": 1024,
        "battery_drain_percent": 1.0,
        "thermal_severe": False,
        "low_memory_kill": False,
        "non_loopback_listener": False,
    },
}
accepted_path.write_text(json.dumps(report), encoding="utf-8")
report["summary"]["accuracy"] = 0.90
candidate_path.write_text(json.dumps(report), encoding="utf-8")
PY

"$root/scripts/validate-bonsai-eval-report.sh" "$tmp/accepted.json" \
  --plan "$root/docs/bonsai-evals/interactive-v1.json" >/dev/null

if "$root/scripts/validate-bonsai-eval-report.sh" "$tmp/candidate.json" \
  --plan "$root/docs/bonsai-evals/interactive-v1.json" \
  --baseline "$tmp/accepted.json" >/dev/null 2>&1; then
  echo "expected quality regression to fail" >&2
  exit 1
fi

echo "Bonsai evaluation report tests passed."
