# Rules

These are repository coding and testing conventions. Codex command permission rules belong in `.codex/rules/*.rules`; see `.agents/agent-config.md` before adding those.

## Dart and Flutter Style

`analysis_options.yaml` enforces these non-default rules:

- `prefer_single_quotes: true`: always use single quotes.
- `require_trailing_commas: true`: use trailing commas in multi-line argument lists.
- `sort_child_properties_last: true`: `child:` must be the last named parameter.
- `avoid_print: true`: do not use `print()` calls.
- `prefer_const_constructors: true` and `prefer_const_declarations: true`.
- `prefer_final_locals: true` and `prefer_final_in_for_each: true`.
- `always_declare_return_types: true`.

Generated directories are excluded from analysis:

- `build/**`
- `lib/l10n/intl/**`
- `lib/**/generated/**`
- `plugins/**`

## Comments

Comments are opt-in and reserved for the few places that genuinely need one. Density is the point: every comment that
restates the code devalues the comments that carry real information, until readers skim past all of them. A file with
three comments that matter is more readable than one with thirty.

### Writing Comments

- Never add a comment on your own initiative. This covers explanatory, narrative, TODO, section-divider, and
  documentation comments, in Dart, Kotlin, Swift, Go, Rust, YAML, Gradle, and any other file you touch.
- Never annotate line by line or statement by statement, and never restate in prose what the code already says. If a
  block needs a comment per step, the block needs better names or a smaller decomposition instead.
- When a change genuinely cannot be understood without a comment, do not write it silently. Explain what is unclear,
  propose the exact comment text, and wait for the user to approve it before adding it.
- Delete commented-out code, stale version notes, and comments that only restate the code, whenever you edit the file
  that contains them. This does not need approval.
- These are not comments and must be preserved: analyzer and linter directives (`// ignore:`, `// ignore_for_file:`,
  `// coverage:ignore`), license and copyright headers, code-generation markers, and comments inside vendored upstream
  code such as `lib/widgets/open_container.dart`.

### Where Knowledge Belongs

Pick the destination by where the constraint would be violated, not by how important it feels.

- **Assertable behavior goes in a test.** A test is the only form that cannot drift, because it fails when the behavior
  it describes is broken. Prefer it over both a comment and a document whenever the fact can be checked in code.
- **Repository-wide defaults, ownership, and invariants go in `.agents/*.md` or a `.agents/skills/*/SKILL.md`.** They
  are violated from many files, so they must reach every future agent at session start. A comment in one file cannot do
  that.
- **A fact that is true only at one call site, and is not visible from that call site, stays a comment there.** Its
  value is being in the reader's line of sight at the moment of the edit. `lib/common/constant.dart` is the model case:
  the delay-test concurrency cap is bound to `mBatch` in `core/common.go`, and whoever changes that number must see the
  constraint on the same screen.

Both failure directions are real. Moving a local constraint into `.agents/` hides it from the person editing the line;
leaving a repo-wide policy as a comment reaches only the reader of that one file.

Before any of the three, prefer encoding the intent in structure and naming — a named mixin, type, or method that makes
the invariant hard to break beats prose that asks the next reader not to break it.

## Core API Safety

- Do not expose direct filesystem deletion APIs through Core or helper IPC; use
  a scope-specific cleanup API instead.
- Keep the shared `CoreMethodCall`/`CoreMethodResponse` JSON envelope structurally identical across Dart, Go, JNI, and
  desktop IPC. Do not double-encode `arguments`, `result`, or event batches.
- `core/message.go` carries three event queues, and the split is load-bearing: state (loaded, geo-update), delay, and
  bulk (log, request). Delay and bulk evict their own oldest entry under backpressure; state uses `enqueueState`, which
  never evicts, because a dropped `geoUpdate{updating:false}` leaves `isUpdatingProvider` stuck at true in the UI until
  `UpdatingAction` sweeps it as stale minutes later. Do not merge the tiers or give state eviction semantics. `enqueueState` drops silently on a full
  queue and must stay that way: reaching it means the host stopped reading, which `logDeliveryError` already reports,
  and reporting it from the message layer feeds the same batcher.
- `jni_get_string` in `android/core/src/main/cpp/jni_helper.cpp` `malloc`s and hands ownership to Go, which frees through
  `free_string_func`. `quickSetup` relies on that: it reads its `*C.char` arguments inside a goroutine, after the JNI
  wrapper has already returned. Switching the wrapper to `GetStringUTFChars`/`ReleaseStringUTFChars`, or freeing on the
  C side, turns that read into a use-after-free.
- Go goroutines reach Java through `ATTACH_JNI()`, which attaches once with `AttachCurrentThreadAsDaemon` and detaches
  from a `pthread_key` destructor at thread death. Do not restore a detach-per-call: `protect` runs once per outbound
  socket and `onResult` once per event batch, and attach/detach takes ART's thread-list lock each time.
- Every JNI call into Kotlin must be followed by `jni_clear_exception`. A pending exception left in place aborts the
  process on the next JNI call on that thread, so a throw in `protect`/`resolveUid`/`resolvePackage`/`onResult` becomes a
  crash in unrelated code. For the same reason every one of those wrappers checks its `tun_interface`/`invoke_interface`
  for `nullptr` first: ART aborts on a call through a null object, and a callback released by `TunHandler.clear` while a
  connection is still resolving is exactly that.
- The Android bridge resolves an owner in two steps — `resolve_uid` then `resolve_package` — because mihomo fills
  `metadata.Uid` from a procfs lookup that Android Q closed off. Collapsing them back into one call that returns only a
  package name is what left every connection reporting uid 0, so `UID` rules matched nothing.
- The desktop delivery path in `core/server.go` must not report failures through `logError`. A log event is published to
  the log subscriber, batched, and handed back to `send`, so a send failure reported that way feeds itself; use
  `logDeliveryError`, which writes to stderr and latches until a frame gets through or the next connection is installed.
  A write that fails without putting a byte on the wire — host backpressure hitting `ipcWriteTimeout`, or a payload above
  `maxIPCFrameSize` — drops that one frame and keeps the connection: the stream is still framed correctly, and tearing it
  down here ends the read loop, and with it the Core process. A half-written frame whose write merely timed out is
  resumed for as long as the stall lasts: Windows Modern Standby suspends the app while the Helper's Core keeps running,
  so the host can stop draining for hours and still come back, and go-winio reports the expiry as its own `ErrTimeout`
  rather than `os.ErrDeadlineExceeded`, which is why `send` checks `Timeout()`. The wait has no cap on purpose, and
  `send` holds `writeMu` throughout, so every other frame — method responses and the single batcher goroutine behind
  the event queues — waits behind the stalled one. Memory is bounded by the queues; what gives is delivery: the state
  queue fills and `enqueueState` starts dropping, which is the case the `UpdatingAction` sweep above exists for. Nothing
  on the Dart side restarts the Core over a stall: `CoreRpcClient` times each pending request out on its own and hands
  the caller `null` (a `no_response` exception for message methods), and the sweep clears core-scope updating state
  minutes later. Only a half-written frame that fails outright desynchronizes the stream, and that is the one case
  `send` closes on.
- Core method handlers in `core/hub.go` are synchronous. Anything that must not block the dispatcher is spawned by
  `safeGo`/`safeGoDetached` in `core/method.go`, which recover; a bare `go` in a handler puts a panic outside every
  recovery and kills the process, which on Android is the whole application. The `//export` entry points in
  `core/lib.go` do not reach `handleMethodCall`, so each one carries its own recovery.
- `dialer.DefaultSocketHook` and `process.DefaultPackageNameResolver` are installed exactly once, by `installHooks` in
  `core/lib.go`, and never cleared. mihomo checks `DefaultSocketHook` for nil once and dereferences it again when the
  socket is created (`component/dialer/socket_hook.go`), so clearing it while a dial is in flight calls a nil func
  value. Stopping the TUN swaps `activeTunHandler` instead.
- `tunnel.AllProxies()` returns a shared, cached map — never modify it. The cache is invalidated by
  `invalidateAllProxies` on `tunnel.UpdateProxies` and validated against each provider's `Version()`, so a rebuild
  costs one read per provider rather than one per proxy. Anything else added to `tunnel/patch.go` that derives from the
  proxy set needs both signals: the external controller can reload the config through `hub/route/configs.go` without
  going through YuClash's `applyConfig`, so a hook on the YuClash side alone would miss a profile switch.
- Core state that mirrors mihomo state goes stale at the next `applyConfig`, which replaces every proxy, provider and
  rule. Read the tunnel instead of caching a snapshot of it: `lookupExternalProvider` kept one that was rebuilt only
  when the host asked for the provider list, and the host asks after a successful setup and not after a failed one, so
  an update ran against a provider the tunnel no longer held — downloading, writing to disk and reporting success
  against nothing.
- Selection writes take `selectMu`, not `configMu`. mihomo's `Selector.Set` has no lock of its own, so the writes need
  mutual exclusion against each other and against `patchSelectGroup` — but not against a whole config apply, which is
  what `configMu` made a proxy switch wait for, provider downloads included. `patchSelectGroup` takes `selectMu` under
  `configMu`, fixing the order as `configMu` → `selectMu`.
- The delay-test semaphore is acquired with a slice of the caller's budget (`budget/delayTestQueueShare`), not
  unconditionally and not with the whole deadline. Queueing and probing come out of one budget, so a test handed all of
  it can spend it waiting and reach `URLTest` with nothing left, reporting a proxy it never contacted as unreachable.
  The probe keeps the caller's original deadline, so whatever the queue did not use is still its own.
- A delay test that the Core does not answer is a fault of the Core or the channel, never a verdict on the proxy:
  `handleTestDelay` returns inside its own budget on every path. `asyncTestDelay` therefore returns null instead of a
  `-1` delay, and `ProxiesAction` leaves the last measurement in place and abandons the rest of the run. Writing a
  timeout there is what made a reachable node read as unreachable whenever the host deadline beat the Core's.
- Delay-test progress lives in `pendingDelayTestsProvider`, not as a sentinel value in `DelayDataSource`. A delay of 0
  used to mean "testing", which let a result and the state of a test overwrite each other and left cards spinning
  forever when the Core restarted. The run owns its keys and releases them in a `finally`, so nothing depends on a
  reply arriving; core status leaving `connected` cancels every run in flight.
- Anything on the mihomo side that is reached from both a user-triggered core method and mihomo's own background
  scheduler needs its in-flight guard on the YuClash side. `updater.UpdateMMDB` and its siblings have none — only the
  batch `UpdateGeoDatabases` does — and two concurrent runs close the mmap'd database twice, so `handleUpdateGeoData`
  claims per resource and `updater.GeoUpdateHook` releases.
- A failed `applyConfig` rolls the tunnel back to the default config, and that rollback is the whole recovery:
  `handleSetupConfig` returns the error and stops there. Do not add a teardown on top of it — stopping the listeners
  takes the app offline over a profile the user can still switch away from, and the error already reaches the host,
  which is what surfaces the failure (`MessageException` on the Flutter side, the config-error toast on Android). Keep
  an empty `config.yaml` out of the failure path — it is how the app says "no profile selected", and `loadConfig`
  resolves it to the defaults.
- Package `init` in the Android library runs while the `.so` is being loaded, so a panic there takes the application
  down before it can report anything. `platform/limit.go` arms an fd-pressure probe and degrades to never blocking when
  it cannot; keep that shape for anything else `init` sets up that correctness does not depend on.
- Every `android && cgo` file in `core/` is compiled only by the NDK-backed CI step in the `go` job. Keep the build
  constraints as `android && cgo` / `!(android && cgo)`: a bare `cgo` constraint makes `go build ./...` fail in `core/`
  on any developer machine, because the files it pulls in need the NDK.

## Lifecycle Rules

- Desktop process ownership belongs to `DesktopCoreLifecycle`; do not start/kill `YuClashCore` from providers, widgets,
  managers, or ad hoc exit callbacks. Acquire and release it through a `CoreProcessLease`.
- `CoreController.close()` and platform `close()` implementations are terminal and idempotent. Application shutdown must
  stay centralized in `SystemAction`/`SystemExitCoordinator`.
- Android start/stop MethodChannel calls are optimistic UI commands. Keep latest-wins arbitration in native
  `ServiceState`; do not add a Flutter completion callback that creates a second lifecycle owner.
- Android service callbacks are not automatically user intent. Route explicit Quick Settings, Always-on VPN, and revoke
  actions through `ServiceState` and keep `ServiceController` as the sole binding/run-time owner.
- Every `BroadcastReceiver.goAsync()` path must finish its `PendingResult` exactly once. A watchdog may release the
  broadcast lease, but must not cancel, reverse, or otherwise redefine the service operation.
- Presentation smoothing such as `CoreStatusButton`'s connecting hold must remain local display state. It must not delay or
  overwrite `coreStatusProvider`, and a real failure must bypass/cancel the hold immediately.

## Testing Rules

Unit and widget tests are allowed. Keep them focused on changed behavior and integration contracts, and run them with
`flutter test` rather than `dart test`.

The `core/` directory is excluded from automated coverage accounting. Do not add coverage instrumentation or coverage
collection for code under `core/`. CI still runs `CGO_ENABLED=0 go test .` and `go vet .` to compile/check the Go wrapper;
verify cross-language protocol behavior through shared Dart contract tests under `test/core/` and native platform build
checks.

Use `CoreController.test(mock)` to inject a mocked `CoreHandlerInterface`. Call `CoreController.resetInstance()` in `tearDown` to clean up the singleton between tests.

Register fallback values for freezed params used with `any()` matchers.

Use `ProviderContainer` directly for simple Riverpod provider tests. The generated Riverpod `update()` method takes a callback:

```dart
notifier.update((state) => newValue);
```

When testing freezed models with nested objects, always round-trip through `jsonEncode` and `jsonDecode`. Direct `fromJson(toJson())` fails for nested freezed types because `toJson()` stores child objects directly instead of maps.

For async widgets, put visual cleanup in `finally` when the action may throw. Focused widget tests should cover success,
failure, disposal, and any timer boundary that changes visible state.

## Generated Code

Do not manually edit generated files under:

- `lib/l10n/l10n.dart`
- `lib/models/generated/`
- `lib/providers/generated/`
- `lib/database/generated/`
- `lib/l10n/intl/`

After schema, model, or provider changes, run build generation and include focused tests when behavior changes.
