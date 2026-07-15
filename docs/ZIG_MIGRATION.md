# Zig Local-Agent Migration

The migration is a sequence of reviewable compatibility-preserving changes, not
a flag day. Android Java/Kotlin/Compose/Binder code remains only where the
platform requires it; application logic moves behind a versioned Zig ABI.
This change completes the PR-00 bootstrap; later rows remain intentionally pending.

## Ledger

| Stack | Exit condition | Depends on |
| --- | --- | --- |
| PR-00 | ABI anchor, toolchain pin, review/source-cap gates | — |
| PR-01 | owned buffers, cancellation, bounded parsing | PR-00 |
| PR-02 | additive persistence migrations with parity tests | PR-01 |
| PR-03 | Zig orchestration and protocol routing | PR-02 |
| PR-04–05 | confined local runtime and mediated computer use | PR-03 |
| PR-06–08 | opt-in OpenRouter and sandboxed Hermes | PR-05 |
| PR-09–11 | broker replacement, CI gates, documentation cleanup | PR-08 |

`native/zig` uses the exact version in `.zigversion`. Reproducible Android
artifacts use `zig build -Dtarget=aarch64-linux-android35 -Doptimize=ReleaseSafe`;
host ABI tests use `zig build test`. The Android shim must pass immutable values,
never call JNI while holding native state locks, and fail closed on ABI errors.

Every stack PR needs a focused test, compatibility/rollback evidence where
applicable, `./scripts/check.sh`, `git diff --check`, `/code-review` evidence,
and an explicit emulator/Pixel evaluation statement. Device actions remain
framework-mediated, confirmation-aware, and audited throughout the migration.
