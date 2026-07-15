# Bonsai Evaluations

The local Bonsai runtime is accepted on measured evidence, not subjective demo
impressions. The suite plan is [interactive-v1.json](bonsai-evals/interactive-v1.json).
It covers text fidelity, bounded reasoning, vision, cancellation, and
policy-mediated tool safety.

## Run and record

Use a private test corpus on a supported device. Each case must use a
deterministic evaluator that emits only pass/fail. Collect model and runtime
hashes, backend, aggregate latency, peak RSS, battery drain, thermal state,
low-memory-kill status, and listener status in a report matching
`schemas/bonsai-eval-report.schema.json`.

```bash
scripts/validate-bonsai-eval-report.sh report.json \
  --plan docs/bonsai-evals/interactive-v1.json

scripts/validate-bonsai-eval-report.sh candidate.json \
  --plan docs/bonsai-evals/interactive-v1.json \
  --baseline accepted.json
```

The validator rejects incomplete reports, failures, cloud runtimes,
non-loopback listeners, severe thermal throttling, low-memory kills, and
quality or latency regressions against the accepted baseline.

Reports contain only aggregate metrics and case identifiers. Do not commit the
private corpus, prompts, generations, images, logs, device serials, tokens, or
model files. An 8B profile can become default only after a passing report. A
27B profile requires a separate passing report and cannot replace the default
on quality, latency, thermal, memory, or network-isolation regression.
