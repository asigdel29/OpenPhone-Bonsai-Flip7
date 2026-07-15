# Local Bonsai Runtime

`BonsaiRuntime` is a planned privileged, on-device inference component. It is
not an external model broker and it is not the demo's LAN-facing server.

## Deployment contract

- The assistant talks to a stable Binder interface; it never executes a binary
  from writable storage.
- The native runtime runs in a dedicated system/native process under a distinct
  SELinux domain. It is started and restarted only by init/system service.
- If a llama.cpp compatibility HTTP endpoint is needed during development, it
  binds to `127.0.0.1` only. Production clients use Binder.
- The runtime has no `INTERNET` permission and the deployed image includes no
  MCP server, web search, Hugging Face downloader, provider key, or token.
- Models are read-only files under `/product/etc/bonsai/models` so llama.cpp can
  mmap them. They are supplied locally at build time and never committed.

## Release 1 API boundary

The Binder contract must cover model lifecycle and health, token streaming and
cancellation, image requests, reasoning budget, image-token cap, and
non-sensitive runtime telemetry. The UI must impose a 1024-token image cap by
default; a full-detail OCR mode must be an explicit slower user choice.

Release 1 permits only user-selected file/photo input and explicitly approved
device actions. Release 2 may connect to OpenPhone's existing framework action
executor, but every state-changing action remains subject to the framework
policy, confirmation, and audit path.

## Model staging

Use `scripts/stage-bonsai-model.sh` on a private build host. It verifies
user-supplied GGUF/mmproj files, creates a checked manifest, makes a read-only
staging directory, and rejects an image that exceeds the supplied dynamic
partition budget. The staging directory is ignored by Git.

Start hardware bring-up with `Ternary-Bonsai-8B-Q2_0`. Record CPU NEON/KleidiAI
and Vulkan results, using Q1_0 Vulkan as the control. The 27B Q2_0 model is
conditional: it may be staged only after measured memory, thermal, and image
budget evidence supports it.
