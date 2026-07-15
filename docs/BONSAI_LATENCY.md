# Bonsai Interactive Latency

This document defines what “fast” means for the local runtime. It does not
claim that a model can generate with zero latency. The goal is immediate UI
feedback, bounded cancellation, and a measured warm generation path that stays
within the device's thermal and memory envelope.

## Interactive profile

The checked runtime configuration is deliberately conservative:

| Control | Default | Reason |
| --- | ---: | --- |
| Active generations | 1 | Prevents competing decode loops and protects foreground responsiveness. |
| Context | 2,048 tokens | Bounds prompt prefill for ordinary turns. |
| Reasoning budget | 512 tokens | Avoids unbounded hidden computation in the default path. |
| Vision cap | 1,024 tokens | Keeps ordinary photo questions interactive. |
| Prompt cache | enabled | Reuses stable conversation prefixes. |
| Prewarm | after unlock, nominal thermal only | Avoids cold-start cost without background thermal debt. |
| Cancel acknowledgement | ≤250 ms target | Lets the user stop a mistaken or slow request promptly. |

Full-detail OCR, long context, high reasoning effort, and 27B inference are
explicit slower modes. They must never silently replace the interactive path.

## Acceptance targets

Measure each backend/model pair after a cold launch and after a prewarmed turn.
Use p50 and p95 across at least 20 representative prompts, with the device
unplugged and screen on. Record exact firmware, runtime commit, model and
mmproj hashes, context, image-token cap, backend/offload configuration, battery
level, thermal state, and ambient conditions.

| Metric | Interactive target | Failure handling |
| --- | ---: | --- |
| UI input acknowledgement | one display frame | Keep UI work independent of inference. |
| Cancel acknowledgement | ≤250 ms | Stop token emission, release request resources, and suppress completion. |
| Warm time to first token, p50 | ≤2,000 ms | Reduce context/reasoning, check prompt cache, or use the faster backend. |
| Warm time to first token, p95 | ≤4,000 ms | Do not promote the profile until tail latency is understood. |
| Warm decode, p50 | ≥8 tokens/s | Keep 8B or Q1_0 fallback as the default if Q2_0 misses it. |
| Thermal state | no severe throttling | Disable prewarm and fall back to the configured smaller/faster model. |
| Memory stability | no low-memory kill | Reduce context/offload or reject the model as default. |

These targets are acceptance gates, not guarantees for every prompt. Vision and
large OCR inputs must be reported separately because image encoding changes
prefill cost materially.

## Measurement protocol

1. Reboot the device, wait for nominal thermal state, and record the cold run.
2. Unlock once, allow the thermal-gated prewarm, then run the warm prompt set.
3. Run the same set on CPU NEON/KleidiAI, Vulkan Q2_0, and Vulkan Q1_0 control.
4. For every request, capture `llama-bench` prefill/decode, peak RSS,
   GPU-offload behavior, battery drain, and `dumpsys thermalservice` state.
5. Trigger cancellation during prefill and decode. Verify no further token,
   completion callback, audit action, or device side effect appears after the
   cancellation acknowledgement.
6. Repeat while folded and unfolded on a supported folding device.

Publish sanitized aggregate measurements only. Never publish prompts, image
inputs, tokens, model files, device identifiers, or audit contents.

## Rollout rule

Ship the interactive profile behind a runtime capability flag. A measured
regression in first-token p95, decode p50, severe thermal throttling, or a
low-memory kill disables the affected backend/model combination and returns to
the last accepted profile. The runtime must expose the selected backend and
degraded state to the user-facing status surface.
