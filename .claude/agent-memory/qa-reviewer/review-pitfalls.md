---
name: Android project test pitfalls
description: Common test anti-patterns found in the RemoteShutter project, especially around build config, SDK version, missing test dependencies, stream encoding bugs, CameraX stub implementations, and ChannelMux integration gaps
type: feedback
---

## Notes from Step 6.1 review (Compose Navigation + ControllerViewModel + screen skeletons)

**Trivially-passing Compose/ViewModel tests via hardcoded string literals:** When Compose UI tests cannot run in JVM unit tests (they require instrumented tests), the correct fallback is source-scanning tests — not tests that assert `assert("RoleSelectScreen".isNotEmpty())`. A test that only stores a string literal in a `val` and asserts non-emptiness provides zero regression value. The implementation can be deleted entirely and the test still passes.

**Source-scanning is the correct JVM fallback for Compose composables:** For `@Composable` functions and `@HiltViewModel` classes in the `:app` module (which cannot be instantiated in JVM unit tests without the full Android/Hilt runtime), the correct testing approach is:
  - Read the source file via `File(projectDir, "relative/path/to/File.kt").readText()`
  - Assert `.contains("@Composable")`, `.contains("fun FunctionName")`, `.contains("@Preview")`, etc.
  This directly verifies the implementation rather than asserting tautologies.

**ControllerViewModel CAN be constructed in JVM tests by bypassing Hilt:** Even though `ControllerViewModel` is `@HiltViewModel`, the class is a plain Kotlin class with a constructor. JVM unit tests can instantiate it directly using a fake `RemoteCameraController` (it's an interface) and a fake `ChannelMux` passed to a real `EventReceiver`. This gives real behavioural coverage without instrumented tests.

**`assert(navRoutes != null)` on a Kotlin `object` is always true:** Kotlin `object` singletons can never be null — this assertion is a no-op. Flag as trivially-passing but do not block if other meaningful tests exist in the same class.

**How to apply:** When reviewing any Compose UI or ViewModel test file, check that at least one test constructs or reads the actual class under test. If every test body starts with `val name = "SomeName"` and ends with `assert(name.isNotEmpty())`, the entire file must be failed on "Tests Written". Source-scanning or direct construction must replace the trivial assertions.

## Notes from Step 5.5 review (End-to-end integration tests)

**Unused imports in E2E test files are style-only, not blockers:** `EndToEndControlTest.kt` imports `FrameHeader`, `FrameType`, `DataInputStream`, `ByteArrayInputStream` that are not used in any test body. These are harmless but should be noted as minor style issues.

**Mixed-type stress test may only verify one command type:** `testRapidMixedCommands` sends 50 `SetZoom` + 50 `TapToFocus` (100 total) but only asserts `setZoomCallCount == 50`, leaving `tapToFocusCallCount` unverified. This is a half-verification — the test still catches dropped zoom commands but would not catch dropped focus commands. Flag as minor gap when reviewing mixed-type stress tests; do not block QA if a separate single-type stress test covers the full 100 count.

**`EventReceiver` and `capturePhoto()` compete on the same `eventChannel`:** `ChannelMux.eventFrames()` returns `receiveAsFlow()` from a single `Channel` instance. If both `EventReceiver.start()` and `RemoteCameraControllerImpl.capturePhoto()` are active simultaneously, they will compete for the same events — only one consumer receives each frame. Integration tests must not start `EventReceiver` in the same test that calls `capturePhoto()` (and vice versa), or both will see partial event streams. This is by design but must be respected in test setup.

**`advanceUntilIdle()` works correctly when infinite polling coroutines are suspended on channel receive:** An `EventPublisher` with a `while(true) { delay(100ms) }` loop or a `ChannelMux` collecting from an open channel will not block `advanceUntilIdle()` — suspended coroutines waiting on channels/delays are not "active work". Only coroutines with queued tasks prevent idle. This means `advanceUntilIdle()` is safe to use for stress tests that end with all frames injected and processing complete.

## Notes from Step 5.3 review (RemoteCameraController / command sender)

**`transferId` field on `PhotoChunk` exists for correlation but may be ignored:** `CameraEvent.PhotoChunk` has a `transferId: Int` field. When a checklist step says "assign a request ID, await matching event", verify the implementation uses `transferId` to filter incoming chunks. An implementation that collects any `PhotoChunk` without checking `transferId` fails the correlation requirement — concurrent capture calls would interleave incorrectly.

**`ControlCommand.CapturePhoto` as `data object` has no request ID:** If request-response correlation is required, `CapturePhoto` must carry a `requestId` field (change from `data object` to `data class CapturePhoto(val requestId: Int)`). Similarly, `CameraEvent.PhotoCaptured` needs a matching `requestId` field added. Verify the model is updated before accepting "request ID correlation" as implemented.

**Side-effectful `.first { ... }` predicates on `eventFrames()`:** Using `channelMux.eventFrames().first { ... }` with chunk accumulation as a side effect in the predicate is a valid single-caller pattern. Flag it when concurrent callers are possible — only the first caller holds the channel consumer and the other will deadlock waiting for a response that was consumed.

**`requestId == 0` fallback bypass in `capturePhoto()`:** When a `PhotoCaptured` event filter uses `event.requestId == requestId || event.requestId == 0`, the fallback accepts any zero-ID response from any call. This is a latent concurrency bug but does not break tests if the wrong-requestId tests use non-zero IDs (e.g. 999). Accept as a minor concern when: (1) the wrong-ID test uses a non-zero wrong ID; (2) no test sends a zero-ID event to a non-first caller. Flag for production review but do not block QA.

**How to apply:** When reviewing any request-response correlation feature, check: (1) the command carries a request ID; (2) the response event carries a matching ID; (3) the `first { }` predicate filters by that ID; (4) tests verify wrong-ID events are ignored; (5) the filter predicate has no `|| id == 0` bypass that weakens concurrent-call safety.

---

## Notes from Step 5.2 review (EventPublisher)

**Zoom throttle tests that count ALL frames (zoom + focus mixed) are fragile but pass:** The throttle test in `EventPublisherTest` counts `sentFrames.size` which includes focus events from the initial StateFlow emission. The range `3..7` is generous enough to absorb this. Acceptable as-is, but when reviewing similar throttle tests, flag if the range is tight enough to be broken by extra non-zoom frames.

**Zoom polling approach sends events even when unchanged:** `EventPublisher` uses a polling loop (every 100ms) rather than `distinctUntilChanged()`. This satisfies "max 10/s" but also fires when zoom is stable. Not a defect per spec wording ("throttle to max 10/s"), but flag if a requirement explicitly says "only send on change".

---

## Pitfalls found in Step 5.1 review, second pass (test quality — byte content verification)

**Test name claims to verify "correct bytes" but only asserts non-empty:** `testDispatcherPhotoCapturedEventHasCorrectBytes` checks `sentFrames.isNotEmpty()`, which only verifies `sendEvent` was called — not that the payload contains a correctly serialized `CameraEvent.PhotoCaptured` with the expected JPEG bytes. When a QA note says "assert that `sendEvent` was called with correctly serialized bytes", the test must decode the outgoing frame (using the known wire format: `[4-byte totalLen][headerBytes][payload]`) and assert the deserialized event matches the input.

**How to apply:** When a test name includes "HasCorrectBytes", "HasCorrectPayload", or similar, verify the test actually decodes and compares the byte content — not just checks for non-empty. A non-empty assertion only proves a method was called, not that the content is correct.

---

## Pitfalls found in Step 5.1 review (CommandDispatcher / ChannelMux integration)

**`CommandDispatcher` implemented as a pure router without ChannelMux integration:** The step required the dispatcher to collect raw `ByteArray` CONTROL frames from `ChannelMux.controlFrames()`, deserialize them to `ControlCommand`, and route them. The implementation instead accepted already-deserialized `ControlCommand` objects via `handleControlCommand()`. There was no `ChannelMux` constructor parameter and no collection coroutine. Tests passed only because the test double bypassed the entire collection + deserialization path.

**`PhotoCaptured` emitted locally instead of sent back over the wire:** After `capturePhoto()`, the requirement is to send the JPEG bytes back to Device B via `channelMux.sendEvent(serialized)`. The implementation instead called `cameraController.emitEvent()`, which emits to a local `SharedFlow` on Device A — it never reaches Device B. Tests subscribed to `cameraController.cameraEvents` verified local emission only, not wire transmission.

**`frameFlow()` called but result discarded — encoding pipeline never starts:** `handleStreamStart()` called `cameraController.frameFlow()` but discarded the returned `Flow`. `encodingPipelineJob` was never assigned, so `handleStreamStop()` always cancelled a `null` job (no-op). Tests verified only that `frameFlowCount` incremented — not that any frames were collected or the pipeline was running.

**How to apply:** When reviewing a class described as "collects X from ChannelMux", verify: (1) the constructor accepts a `ChannelMux`; (2) there is a `start(scope)` / `stop()` API that launches/cancels a collection coroutine; (3) tests feed serialized bytes through a fake `ChannelMux` rather than calling the routing method directly. When reviewing "send back" requirements, verify the implementation calls `channelMux.sendEvent()` / `sendControl()`, not a local flow emission. When reviewing pipeline start/stop, verify `encodingPipelineJob` is non-null after start and null after stop.

## Pitfalls found in Step 4.4 review (RemoteViewfinder / Compose video surface)

**`class FakeSurface : Surface` does not compile in JVM unit tests:** `android.graphics.Surface` has no public no-arg constructor and its `isValid()` / `release()` methods are `final`. Subclassing `Surface` in a unit test is a compile error even with `isReturnDefaultValues = true`. Fix: use `testImplementation(libs.mockito.core)` and `mock(Surface::class.java)`, OR avoid passing `Surface` instances through callbacks in unit tests entirely (use boolean flags or call counts instead).

**Test-double logic duplicated from production function prevents real coverage:** When `TestRemoteViewfinderController.calculateAspectRatioDimensions` contains a verbatim copy of the production `calculateAspectRatioDimensions` top-level function, all aspect ratio tests pass vacuously — the production function is never called. Always have unit tests call the production function under test directly. Remove the duplicate from the test double.

**How to apply:** When a test controller/fake class exposes a `calculateX` or `computeX` method, grep for the same method name in the production source. If an identical implementation exists, the test double copy must be removed and tests updated to call the production version.

---

## Pitfalls found in Steps 3.4–3.5 review (CameraX photo capture + frame access)

**CameraEvent created but never emitted (silent discard):** In `CameraXManager.capturePhoto()`, `CameraEvent.PhotoCaptured(jpegBytes)` was created as a local variable inside a `coroutineScope.launch` block and logged, but there was no `Channel`, `SharedFlow`, or callback to send it to. The test for event emission passes because the test double (`TestPhotoCaptureController`) has its own `emittedEvents` list — it never exercises the production event path. Always verify the production class has an actual delivery mechanism (a `SharedFlow` or `Channel` on the interface) and that the event is sent through it.

**EXIF rotation metadata not embedded:** `imageProxyToJpegBytes()` captured `rotationDegrees` from `ImageProxy.imageInfo` and returned it as a separate field on `CaptureResult.Success`, but did not write it into the JPEG EXIF `TAG_ORIENTATION`. The step requirement "correct rotation/EXIF" requires embedding via `ExifInterface`. Carrying rotation as out-of-band metadata is not equivalent to embedding it in the file.

**MediaStore "optional" step ticked as implemented when only a TODO comment exists:** The checklist step was marked "Code Implemented" despite the entire body being `// TODO(3.4.3): ...`. Any step described as "optionally configurable" still needs at least a feature-flagged stub before the box is ticked. A comment alone is not an implementation.

**How to apply:** For any CameraEvent-emitting step, verify: (1) the interface has a `SharedFlow<CameraEvent>` or equivalent; (2) the production class sends to it (not just creates the object); (3) the unit test for event emission is wired to the interface property, not only a test-double list. For JPEG rotation, always grep for `ExifInterface` or `TAG_ORIENTATION` before accepting "rotation/EXIF" as done.

## Pitfalls found in Steps 3.2–3.3 review (CameraX zoom + focus)

**CameraX stub implementations accepted as complete:** `CameraXManager.setZoomRatio()` and `tapToFocus()` both had `TODO` comments stating the real CameraX calls were not yet made. The in-memory state was updated but `CameraControl.setZoomRatio()` and `CameraControl.startFocusAndMetering()` were never invoked. This is a silent failure — unit tests (which use `TestZoomController`/`TestFocusController`) pass, but the real camera hardware is unaffected. Always verify that the production implementation class (not just the test double) actually calls the real API.

**Hardcoded min/max zoom [1.0, 1.0] renders clamping a no-op:** When `_minZoomRatio` and `_maxZoomRatio` are never populated from `CameraInfo.zoomState`, every `coerceIn` call returns `1.0f` regardless of input, silently defeating the clamping requirement. Verify real bounds are read from `camera.cameraInfo.zoomState.value.minRatioSupported` / `maxRatioSupported`.

**Focus state machine missing FOCUSED/FAILED states in real implementation:** `CameraXManager.tapToFocus()` only transitions FOCUSING → IDLE (via timeout), never FOCUSED or FAILED. The `FocusResult` enum has all four values, but only the test double (`TestFocusController`) exercises FOCUSED and FAILED. Verify the production class calls `startFocusAndMetering()` and reads `FocusMeteringResult.isFocusSuccessful` to drive the state machine.

**Missing instrumented test placeholder for focus lifecycle:** Unlike the zoom step which had an `@Ignore`d `PinchToZoomGestureTest` class documenting the future instrumented test, the focus step had no equivalent placeholder. When a checklist requires an instrumented test, always add at minimum an `@Ignore`d class in the test file with documented expected behaviour, so the requirement is not silently dropped.

**How to apply:** When reviewing CameraX feature implementations, verify: (1) the `Camera` object returned by `bindToLifecycle()` is stored; (2) `CameraControl` methods are actually called, not just stubbed with `TODO`; (3) `CameraInfo.zoomState` is observed to populate min/max bounds; (4) all enum states are reachable from the production class (not just test doubles); (5) a test placeholder exists for any required instrumented test.

## Pitfalls found in Steps 2.4.1–2.4.3 review

**`P2pSocketServer` binding inside `accept()` blocks testability:** If a `ServerSocket` is created inside a `suspend fun accept()` method rather than eagerly in the constructor, the caller cannot obtain the bound port (especially when `port = 0` is used for OS-assigned ephemeral ports). This makes it impossible to connect a test client, so tests are left with empty bodies. Always bind the `ServerSocket` eagerly (in constructor or a `start()`/`bind()` method) and expose `boundPort: Int` so tests can connect.

**Empty test bodies are a hard fail:** Methods that consist only of comments and a `server.close()` call (no `accept()` call, no assertions) do not test anything. This is an automatic QA fail regardless of whether the production code is correct — the spec requirement is untested.

**How to apply:** When reviewing a server/listener class test, verify that at minimum one test actually calls the `accept()` (or equivalent) method and asserts the returned value is non-null and usable. If the test file has empty method bodies, fail "Test Written" and "Code Implemented" and require the implementation to be made testable.

---

## Pitfalls found in Steps 2.3.1–2.3.3 review

**`String.substringBefore()` has no `Regex` overload in the Kotlin standard library.** Only `Char` and `String` overloads exist. Passing `Regex(...)` to `substringBefore` is a **compile-time type error** that prevents the entire test class from building. Tests attempting to bound a method-body scan with `substringBefore(Regex("\\n\\s*public\\s+fun|..."))` will not compile. The fix is to replace the `Regex` argument with a `String` delimiter such as `"\n    public fun "` that matches the actual indented method prefix in the source file.

**How to apply:** Whenever a structural source-scanning test uses `substringBefore(...)` to extract a method body, verify the argument type is `String` or `Char`. Any `Regex(...)` argument is a compile error.

---

## Pitfalls found in Steps 1.3.1–1.3.3 review

**Tautological `is`-instance-check tests:** Tests that assert `assertTrue(command is ControlCommand)` when `command` is statically typed as a subtype of `ControlCommand` provide no regression value — the Kotlin type system guarantees this at compile time. Similarly, `assertTrue(x is X)` after `val x = X(...)` is always true by construction. These tests should instead assert meaningful cross-subtype distinctness (e.g. `assertFalse(CapturePhoto == SetZoom(1.0f))`) or be removed. They were accepted in 1.3.1/1.3.2 because sufficient meaningful tests co-exist, but should not be introduced in future steps.

**Float equality in JUnit 4 without delta:** `assertEquals(Float, Float)` auto-boxes to `assertEquals(Object, Object)`, which works correctly when the Float values are stored and retrieved without arithmetic (bit-for-bit identical). This is acceptable for direct-assignment round-trip tests. If any floating-point arithmetic is involved, always use `assertEquals(expected, actual, delta)`.

**`Error` field name discrepancy:** The checklist abbreviated the field as `msg` but the implementation used `message`, which is more idiomatic. Abbreviations in checklist descriptions should be treated as shorthand, not strict API contracts — prefer the idiomatic full name in code.

**How to apply:** When reviewing sealed hierarchy model tests, check that at least the data-holding tests (field round-trips, ByteArray equality, enum membership counts) are present. Tautological is-instance checks may be flagged as low-quality but do not require failing the review if meaningful tests are alongside them.

---

## Pitfalls found in Step 1.2.6 review

**`module.replace(":", "/")` on a colon-prefixed module name (e.g. `:core:model`) produces a path starting with `/` (e.g. `/core/model`).** On Linux/macOS the JVM `File(base, child)` constructor treats a `child` starting with `/` as an absolute path, completely ignoring `base`. This means `File(projectRoot, "/core/model/build.gradle.kts")` resolves to the filesystem root, not the project root. The fix is to strip the leading colon first: `module.removePrefix(":").replace(":", "/")`.

**`extractProjectDependencies` silently returns `emptySet()` when the file doesn't exist**, so a wrong path causes all inter-module dependency assertions to pass vacuously (comparing `emptySet() == emptySet()`), hiding the bug.

**`settings.gradle.kts` `include(...)` syntax uses colon-prefixed module paths.** The test stripped the leading colon before checking and then looked for `include("app")` or a multi-arg form `include("core", "model")`, neither of which matches the actual `include(":app")` / `include(":core:model")` syntax. Always check against the actual file's `include` format before writing the assertion.

**How to apply:** When reviewing tests that read build files by constructing paths from module names, verify the leading `:` is stripped before using the string as a relative path. When reviewing `settings.gradle.kts` checks, confirm the expected `include(...)` string matches what is actually in the file.

---

## Pitfalls found in Step 1.4.1 review

**detekt YAML property names use camelCase, not kebab-case:** Tests asserting config file content must use the actual detekt YAML key name. For example, the maximum line length property in `detekt.yml` is `maxLineLength` (under `MaximumLineLength:`), NOT `max-line-length` (which is the EditorConfig/ktlint convention). Searching for `max-line-length` in `detekt.yml` will always fail.

**Duplicate YAML keys in detekt.yml are silently ignored:** YAML does not error on duplicate keys; the last one wins. Both `ParameterListWrapping` and `UnnecessaryFilter` appeared twice in `detekt.yml`. These should be deduped.

**Test method named "IsExecutable" that only checks `canRead()`:** A test named `verifyCheckScript_IsExecutable` that only asserts `isFile && canRead()` is misleading — it does not actually check file execute permissions. Either add `canExecute()` or rename to `verifyCheckScript_IsReadableFile`.

**How to apply:** When reviewing tests that assert string content in config files, grep the actual config file for the exact string before accepting the test. YAML camelCase vs kebab-case is a common source of test/implementation divergence.

---

## Pitfalls found in Steps 1.2.2–1.2.5 review

**`testBuildGradleUsesAndroidLibraryPlugin` searches for `"com.android.library"` in `build.gradle.kts`, but the Kotlin DSL uses `alias(libs.plugins.android.library)`.** The literal string `"com.android.library"` only appears in `gradle/libs.versions.toml`, not in the module build file. The correct search token is `"android.library"` (a substring of the alias accessor expression), not the plugin ID string. This test fails at runtime in all four modules.

**How to apply:** When a test does `content.contains("com.android.library")` on a `build.gradle.kts`, confirm the literal string appears in that file. If the file uses `alias(libs.plugins.android.library)`, the match will fail. Use `"android.library"` instead.

---

## Pitfalls found in Step 1.2.1 review

**`kotlin.test` imports require an explicit `kotlin-test-junit` dependency:** Using `import kotlin.test.assertEquals` or `import kotlin.test.assertNotNull` in a test that only declares `testImplementation(libs.junit)` will fail to compile. The `kotlin.test` API is NOT bundled with JUnit 4; it requires `org.jetbrains.kotlin:kotlin-test-junit` to be declared explicitly. Add it to `libs.versions.toml` and the module's `build.gradle.kts`. (Or replace with JUnit 4 `org.junit.Assert.*` calls instead.)

**`assertNotNull` on enum constants is a no-op:** Accessing a Kotlin enum constant by name (e.g. `Role.CAMERA`) can never return null — it is a compile-time constant. Wrapping it in `assertNotNull` adds no value and is misleading. Replace with `assertEquals("CAMERA", Role.CAMERA.name)` which is both meaningful and idiomatic.

**`substringAfterLast(".")` on `enum.toString()` is unnecessary:** Standard Kotlin enum `toString()` returns the constant name exactly (e.g. `"CAMERA"`) without any dot-separated prefix. Using `.substringAfterLast(".")` implies the format contains a dot, which is misleading. Use `.name` directly.

**Why:** These issues result in either tests that don't compile or tests that assert tautologies, giving false confidence in the test suite.

**How to apply:** When reviewing enum tests, check: (1) all `kotlin.test.*` imports have a matching `kotlin-test-junit` dependency in the build file; (2) no `assertNotNull` on enum constants; (3) toString assertions use `.name` rather than string manipulation.

---

## Pitfalls found in Step 1.1.3 review

**Tests matching trailing comments instead of real code tokens (false positive tests):** When a Gradle Kotlin DSL file uses `alias(libs.plugins.kotlin.serialization)`, tests that search for `"kotlin-serialization"` will only pass because a developer added a trailing comment `// kotlin-serialization plugin` to the same line. If the comment is removed, the test fails — yet the production code is correct. This gives false confidence.

**Why:** Implementers sometimes add comments to satisfy tests that check for a string that does not appear in the actual code syntax. The real token in Kotlin DSL uses dot notation (`libs.plugins.kotlin.serialization`), not kebab-case. The TOML catalog key (`kotlin-serialization = ...`) is legitimate to match, but the Kotlin DSL code is not.

**How to apply:** When reviewing tests that do `contains("some-string")` on build files, verify that the matched string is an actual code token (not a comment). Grep for the string in the file and check if it only appears inside a `//` comment. If so, the test must be updated to match the real token, and the comment removed.

**Explicit API mode scope confusion:** When a step requires "explicit API mode for library modules", this MUST NOT be configured on the `:app` module (application, not library). It belongs in each `:core:*` and `:feature:*` library module's own `build.gradle.kts` using `kotlin { explicitApiStrict() }`. When those modules don't exist yet, the requirement should be documented with an `@Ignore` test or a comment in the root build file.

---

## Pitfalls found in Step 1.1.2 review

**`user.dir` points to module directory, not project root:** When an Android unit test (JVM) calls `System.getProperty("user.dir")`, Gradle sets it to the **module** directory (e.g. `/workspace/app`), not the project root. Any test that constructs a path like `File(user.dir, "gradle/libs.versions.toml")` to read a root-level file will fail to find it. Fix: either walk up with `.parentFile`, or inject the root via a Gradle system property (`testOptions { unitTests.all { it.systemProperty("project.root", rootDir.absolutePath) } }`).

**Why:** The AGP test runner sets `user.dir` to the module working directory by default. This is a well-known gotcha when writing JVM unit tests that need to read project-root files.

**How to apply:** Any time a test reads a file using `user.dir` as a base, verify the expected path actually exists relative to the module directory — if it doesn't, the path resolution is wrong.

---

## Pitfalls found in Step 4.1 review (VideoEncoder / MediaCodec)

**`object : Surface(null)` in unit tests crashes at runtime:** Android stubs in JVM unit tests throw `RuntimeException("Stub!")` for any framework constructor including `Surface(SurfaceTexture)`. Tests that return `object : Surface(null)` from a fake method will crash before any assertion. Move real-Surface tests to the instrumented test class, or return a non-Android sentinel object from the fake.

**Fake `simulateX` methods must actually emit to their flow:** A test fake that appends to an `emittedFrames` list but has an empty try-catch where flow emission should happen is silently broken. Tests that collect from the fake's `Flow` will block/timeout. Always call `_flow.tryEmit(item)` in the simulate method.

**SPS/PPS resend condition `isKeyFrame && lastWasKeyFrame` is wrong:** The correct condition for prepending SPS/PPS to every IDR frame is simply `isKeyFrame`. Using `isKeyFrame && lastWasKeyFrame` means it only fires on back-to-back keyframes, which never happens in normal encoding. Tests relying on this condition (IDR → P → P → IDR pattern) will silently fail the assertion `secondCount > firstCount`.

**Asserting a flag immediately after `start()` without simulating any data:** If a boolean flag like `firstFrameContainsSpsPps` is reset in `start()` and only set during frame simulation, asserting it immediately after `start()` (without calling `simulateEncodedFrame`) will always assert `false`. Always simulate the relevant input before asserting state.

**How to apply:** When reviewing encoder or codec fake implementations, verify: (1) no `android.graphics.Surface(...)` constructor calls in non-instrumented tests; (2) simulate methods call `flow.tryEmit()`; (3) SPS/PPS prepend logic fires on every keyframe, not only consecutive keyframes; (4) state-flag assertions occur after the operation that sets the flag.

**MediaCodec async/sync API must not be mixed — `setCallback` + `dequeueInputBuffer` is broken:** Once `codec.setCallback(...)` is called, the `MediaCodec` instance enters async mode. In async mode, `codec.dequeueInputBuffer(timeoutUs)` always returns `-1` (or throws `IllegalStateException`). Input buffers must be filled inside the `onInputBufferAvailable` callback, not via a synchronous dequeue. Similarly, output buffers are delivered via `onOutputBufferAvailable` — `dequeueOutputBuffer` must not be called. Choose one mode and apply it consistently. A self-contradicting comment like "Handled in feedToCodec via synchronous path" alongside a `setCallback` call is a strong signal of this bug.

---

## Pitfalls found in Step 1.1.1 review

**Boilerplate test not removed:** `ExampleUnitTest.kt` with `assertEquals(4, 2+2)` was left in from project scaffolding. Always verify no boilerplate remains when marking "Tests Written".

**False Kotlin-version claim:** A test claimed to verify "Kotlin 2.x is configured" by using `data class .copy()`, which is a Kotlin 1.x feature. When a test claims to verify a language version, the feature used must be genuinely version-specific, or the claim must be removed.

**BuildConfig does not expose minSdk/targetSdk:** The `BuildConfig` class generated by AGP at build time includes `APPLICATION_ID`, `VERSION_NAME`, `VERSION_CODE`, `BUILD_TYPE`, `FLAVOR`, and `DEBUG` — but NOT `minSdk` or `targetSdk`. Tests cannot assert these values via `BuildConfig` at JVM unit-test runtime. SDK version correctness is best documented as "verified by code review of `app/build.gradle.kts`" or by checking that the build succeeds.

**Redundant assertions:** Having both `verifyPackageName()` and `verifyApplicationIdIsNotEmpty()` both asserting `APPLICATION_ID == "com.remoteshutter"` adds no value. Remove duplicates.

**Why:** These issues make the test suite appear to verify requirements that it does not actually validate, giving false confidence.

**How to apply:** When reviewing Android project skeleton tests, specifically check: (1) boilerplate removed, (2) language-version tests use genuinely version-specific features, (3) no false claims in KDoc about what is verified, (4) no redundant assertions.

---

## Pitfalls found in Steps 2.5.1–2.5.3 review

**`DataOutputStream` has no `.toByteArray()` method — compile error:** `DataOutputStream` extends `FilterOutputStream` and has no `.toByteArray()`. When using an `.apply { writeInt(...); write(...) }` block on `DataOutputStream(ByteArrayOutputStream())`, the block returns the `DataOutputStream` instance. Calling `.toByteArray()` on it is a compile error. The fix is to capture the inner `ByteArrayOutputStream` in a separate variable, then call `.toByteArray()` on it after writing:
```kotlin
val baos = ByteArrayOutputStream()
DataOutputStream(baos).apply {
    writeInt(totalContent.size)
    write(totalContent)
}
return baos.toByteArray()
```

**`payloadLength` in `FrameHeader` must exactly match actual payload byte count:** `ChannelMux.decodeFrame()` uses the `payloadLength` field extracted from the ProtoBuf-encoded `FrameHeader` to compute `headerSize = totalLength - payloadLength`. If `payloadLength` does not equal the actual payload byte count, the header/payload split is wrong, corrupting both. In tests using `FrameHeader(FrameType.VIDEO, hardcodedInt, timestamp)`, always use `payload.size` for `payloadLength`. Hardcoded mismatches (e.g., `payloadLength = 5` when payload is "v1" = 2 bytes) will cause `decodeFrame` to throw or produce corrupted frames.

**How to apply:** When reviewing tests that hand-construct `FrameHeader` objects in wire format tests, always verify `payloadLength == actualPayload.size`. Any hardcoded integer in the `payloadLength` field must be cross-checked against the actual payload bytes used in the same test frame.
