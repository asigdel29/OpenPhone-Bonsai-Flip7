#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: validate-bonsai-eval-report.sh REPORT --plan PLAN [--baseline REPORT]

Validates a sanitized local Bonsai evaluation report and rejects quality,
latency, cancellation, memory, thermal, or listener regressions.
EOF
}

report="${1:-}"
[[ -n "$report" && "$report" != "-h" && "$report" != "--help" ]] || { usage; exit 2; }
shift
plan=""
baseline=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --plan) plan="${2:?}"; shift 2 ;;
    --baseline) baseline="${2:?}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done

[[ -f "$report" ]] || { echo "error: missing report: $report" >&2; exit 1; }
[[ -f "$plan" ]] || { echo "error: missing plan: $plan" >&2; exit 1; }
[[ -z "$baseline" || -f "$baseline" ]] || { echo "error: missing baseline: $baseline" >&2; exit 1; }

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$report" "$plan" "$baseline" "$root/configs/bonsai-runtime.example.json" <<'PY'
import json
import pathlib
import re
import sys

report_path = pathlib.Path(sys.argv[1])
plan_path = pathlib.Path(sys.argv[2])
baseline_path = pathlib.Path(sys.argv[3]) if sys.argv[3] else None
config_path = pathlib.Path(sys.argv[4])
report = json.loads(report_path.read_text(encoding="utf-8"))
plan = json.loads(plan_path.read_text(encoding="utf-8"))
config = json.loads(config_path.read_text(encoding="utf-8"))

def fail(message):
    raise SystemExit(message)

if set(report) != {"schema", "suite_id", "runtime", "summary", "cases", "telemetry"}:
    fail("unexpected Bonsai eval report keys")
if report.get("schema") != "openphone.bonsai_eval_report.v1":
    fail("invalid Bonsai eval report schema")
if report.get("suite_id") != plan.get("suite_id"):
    fail("report suite_id does not match evaluation plan")
runtime = report.get("runtime", {})
if set(runtime) != {"runtime_commit", "model_sha256", "mmproj_sha256", "backend", "cloud"}:
    fail("unexpected runtime fields")
if runtime.get("cloud") is not False or runtime.get("backend") not in {"cpu_neon_kleidiai", "vulkan"}:
    fail("evaluation must use a supported local runtime backend")
for key in ("model_sha256", "mmproj_sha256"):
    if not re.fullmatch(r"[0-9a-f]{64}", str(runtime.get(key, ""))):
        fail(f"invalid {key}")
if not re.fullmatch(r"[0-9a-f]{7,64}", str(runtime.get("runtime_commit", ""))):
    fail("invalid runtime_commit")

summary = report.get("summary", {})
required_summary = {"total", "passed", "accuracy", "warm_first_token_p50_millis", "warm_first_token_p95_millis", "warm_decode_p50_tokens_per_second", "cancel_p95_millis"}
if set(summary) != required_summary:
    fail("unexpected summary fields")
if summary["total"] < plan.get("minimum_cases", 1) or summary["passed"] != summary["total"] or not 0 <= summary["accuracy"] <= 1:
    fail("evaluation has missing, failing, or invalid quality results")
latency = config["interactive_latency"]
if summary["warm_first_token_p50_millis"] > latency["warm_first_token_target_p50_millis"]:
    fail("warm first-token p50 misses target")
if summary["warm_first_token_p95_millis"] > latency["warm_first_token_target_p95_millis"]:
    fail("warm first-token p95 misses target")
if summary["warm_decode_p50_tokens_per_second"] < latency["warm_decode_target_p50_tokens_per_second"]:
    fail("warm decode p50 misses target")
if summary["cancel_p95_millis"] > latency["cancel_acknowledgement_target_millis"]:
    fail("cancellation p95 misses target")

cases = report.get("cases", [])
if len(cases) != summary["total"]:
    fail("summary total does not match cases")
ids = [case.get("id") for case in cases]
if len(set(ids)) != len(ids) or not all(isinstance(item, str) and item for item in ids):
    fail("case ids must be non-empty and unique")
for category, minimum in plan.get("categories", {}).items():
    matching = [case for case in cases if case.get("category") == category]
    if len(matching) < minimum or any(case.get("passed") is not True for case in matching):
        fail(f"required {category} cases are missing or failed")

telemetry = report.get("telemetry", {})
required_telemetry = {"peak_rss_bytes", "battery_drain_percent", "thermal_severe", "low_memory_kill", "non_loopback_listener"}
if set(telemetry) != required_telemetry or telemetry.get("peak_rss_bytes", 0) <= 0:
    fail("invalid telemetry")
if telemetry.get("thermal_severe") or telemetry.get("low_memory_kill") or telemetry.get("non_loopback_listener"):
    fail("runtime isolation, memory, or thermal acceptance failed")

if baseline_path is not None:
    baseline = json.loads(baseline_path.read_text(encoding="utf-8"))["summary"]
    if summary["accuracy"] < baseline["accuracy"] - 0.02:
        fail("accuracy regressed by more than two percentage points")
    if summary["warm_first_token_p95_millis"] > baseline["warm_first_token_p95_millis"] * 1.25:
        fail("first-token p95 regressed by more than 25 percent")
    if summary["cancel_p95_millis"] > baseline["cancel_p95_millis"] * 1.25:
        fail("cancellation p95 regressed by more than 25 percent")
    if summary["warm_decode_p50_tokens_per_second"] < baseline["warm_decode_p50_tokens_per_second"] * 0.80:
        fail("decode p50 regressed by more than 20 percent")

print(f"Bonsai evaluation report validation passed: {report_path}")
PY
