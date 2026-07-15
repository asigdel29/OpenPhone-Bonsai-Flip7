# Java and Concurrency Style

New Java and Binder/runtime code follows the practical portions of Doug Lea's
[Java coding standard](https://gee.cs.oswego.edu/dl/html/javaCodingStd.html),
adapted to current Android APIs and the Android source tree's established
formatting.

## Structure

- Put each substantive class in its own source file and use precise imports.
- Give public classes, Binder interfaces, and public methods documentation that
  states purpose, preconditions, effects, failure modes, and ownership.
- Keep a method focused on one operation. Separate observation from state
  change unless atomicity requires their combination.
- Use names that expose units and semantics: `timeoutMillis`,
  `maximumImageTokens`, and `isGenerationActive` instead of ambiguous names.
- Prefer interfaces at stable boundaries, particularly runtime adapters and
  privileged service clients.

## Shared state and cancellation

- State every shared-state invariant beside the state it protects.
- Make ownership explicit: every mutable field has one lock, serial executor,
  or single-thread confinement rule.
- Prefer immutable `final` value objects for cross-thread and Binder requests.
- Public methods that can block, wait, or perform asynchronous work must state
  cancellation and interruption behavior. Restore interruption when catching
  `InterruptedException` unless the method propagates it.
- Wait only in condition loops; use `notifyAll` when monitor coordination is
  required. Prefer modern structured Android concurrency primitives when they
  provide clearer ownership.
- Do not hold a lock while calling Binder clients, invoking callbacks, doing
  model inference, or waiting on I/O.
- Make lifecycle transitions idempotent and observable. A cancelled generation
  must not later emit completion or change device state.

## Runtime safety

- No mutable public fields. Avoid ambient static mutable state.
- Validate Binder inputs at the boundary, including size, file-descriptor, and
  caller-identity constraints.
- Fail closed: an unavailable model, invalid manifest, unknown capability, or
  expired approval denies the action without a side effect.
- Record state-changing actions only through the existing policy, confirmation,
  and audit boundary.

The original standard explicitly allows justified exceptions to rules of thumb.
When Android compatibility, performance, or safety requires one, document the
reason next to the exception and test the affected concurrency behavior.
