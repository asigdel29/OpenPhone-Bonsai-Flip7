# Bonsai Runtime Acceptance

This checklist applies only after a supported device port has passed its own
hardware and recovery acceptance. It is not authorization to flash a candidate
device.

## Build-time checks

1. Stage user-supplied GGUF and mmproj assets with
   `scripts/stage-bonsai-model.sh`.
2. Run `scripts/verify-staged-bonsai-model.sh` on the staging directory before
   copying it into the read-only product image.
3. Record the runtime commit, model hashes, backend, partition budget, and
   minimum-free-memory threshold in the build record.
4. Confirm the source checkout, build logs, target-files archive, and OTA
   manifest contain no model files, tokens, or provider secrets.

## On-device Release 1 acceptance

| Check | Required evidence |
| --- | --- |
| Runtime isolation | Binder client works; no executable is read from writable storage; init owns restart. |
| Network isolation | No listening non-loopback socket and no network permission required by the runtime. |
| Text generation | Streaming, cancellation, and bounded reasoning budget work. |
| Vision | User-selected photo/file works with a 1024-token default cap; full detail is an explicit slower action. |
| Thermal and memory | `llama-bench` prefill/decode, peak RSS, battery drain, GPU-offload state, and thermal state are recorded. |
| Backend comparison | Ternary 8B Q2_0 CPU and Vulkan results are recorded; Q1_0 Vulkan is the control. |
| Device action safety | Every state-changing request uses OpenPhone policy, foreground confirmation, and durable audit evidence. Denied/cancelled actions leave no state change. |

## 27B promotion rule

`Ternary-Bonsai-27B-Q2_0` remains optional. Test it with vision at 2K context
and a capped reasoning budget. Do not make it default if it causes low-memory
kills, severe thermal throttling, or unstable generation. Keep the measured 8B
or Q1_0 fallback available instead.
