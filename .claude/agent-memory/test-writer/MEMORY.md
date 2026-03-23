# Test-Writer Memory

## WiFi Direct P2P Connection Testing (Project Camera)

### Socket Server Eager-Binding Pattern
When testing socket servers that bind to port 0 (OS-assigned ephemeral ports):
1. Bind ServerSocket in constructor, NOT in accept()
2. Expose `val boundPort: Int` property immediately after binding
3. This allows tests to launch accept() in background, then connect to the known port
4. Use `kotlinx.coroutines.delay()` for test thread synchronization (not perfect but works)

**Why**: Without eager binding, tests cannot introspect which port was assigned, making real socket integration tests impossible.

### Length-Prefix Frame Testing
For P2pConnection implementations using 4-byte big-endian length-prefix framing:
- Test sends frames from raw Socket using DataOutputStream.writeInt(length) + write(payload)
- Server side uses SocketP2pConnection which auto-handles framing via receive().collect()
- Test verifies by comparing received ByteArray payload against sent payload
- Use runTest { } for async frame verification, collect() with timeout/delay for synchronization

### P2pSocketServer Test Structure
8 comprehensive tests needed:
1. DEFAULT_PORT constant verification
2. boundPort exposed with port=0
3. boundPort exposed with explicit port
4. accept() returns P2pConnection with real Socket connection
5. Accepted connection can receive length-prefix frames
6. close() is idempotent
7. close() doesn't throw
8. Explicit port binding verification

All tests use real loopback sockets, no mocks.

### File References
- Tests: `/workspace/core/network/src/test/java/com/remoteshutter/core/network/P2pSocketServerTest.kt`
- Tests: `/workspace/core/network/src/test/java/com/remoteshutter/core/network/P2pSocketClientTest.kt`

## ConnectionHealthMonitor Testing (Step 2.4.4)

### TestScope Scoping Rules
When writing tests with `runTest { }`, the `currentTime` property is only accessible as a property of the test block's receiver (TestScope). Regular lambdas created inside `runTest` don't automatically have access to `currentTime`. If you need to access it from a lambda (e.g., `reconnectFactory = { ... }`):
1. Capture the TestScope reference: `val testScope = this` before the lambda
2. Use `testScope.currentTime` inside the lambda
**Why**: Lambda contexts don't inherit the TestScope receiver scope — explicit capture is required.

### Fake Connection Testing Patterns
When testing heartbeat/health monitoring, FakeP2pConnection implementations need:
1. **Simulating heartbeat responses**: Add a `simulateHeartbeatResponses` boolean flag that auto-echoes heartbeat frames
2. **Distinguishable heartbeat frames**: Use the constant `ConnectionHealthMonitor.HEARTBEAT_PAYLOAD`, not empty arrays
3. **Connection state manipulation**: Allow setting `isConnected` directly to simulate connection drops
4. **Frame recording**: Keep a mutable list of sent frames for assertion checking
**Why**: Without response simulation, tests can't distinguish between missed-heartbeat timeouts and keep-alive conditions.

### Test Assertion Quality
Replace trivial assertions like `assertTrue(true)` with meaningful assertions:
- Verify initial state is what's expected (e.g., `connectionState == HEALTHY`)
- Verify behavior occurred (e.g., `reconnectCount > 0`)
- Verify state transitions happened (e.g., state became UNHEALTHY)
**Why**: Trivial assertions add no value and mask test failures.

### File References
- Tests: `/workspace/core/network/src/test/java/com/remoteshutter/core/network/ConnectionHealthMonitorTest.kt`
- Implementation: `/workspace/core/network/src/main/java/com/remoteshutter/core/network/ConnectionHealthMonitor.kt`

## CameraX Testing (Step 3.1.1-3.1.5, 3.2.1-3.2.4)

### Android Framework Dependencies in Unit Tests
CameraX and other Android framework classes (Context, Activity, etc.) **cannot run in JVM unit tests**:
- ProcessCameraProvider, Preview, ImageCapture, etc. require Android native code
- Unit tests run on JVM without Android runtime
- Solution: Create testable abstraction (interface/impl pair)
  - Write test fixture that implements the contract (e.g., TestCameraManager)
  - Real implementation extends same contract with actual CameraX calls
  - Unit tests verify contract; instrumented tests verify CameraX integration

### StateFlow Observable Pattern for CameraX
Expose reactive state as StateFlow<T> for:
- Observable state changes (needed by Compose recomposition)
- Testable without mocking (can read .value synchronously)
- Matches CameraX's own patterns (e.g., cameraInfo.zoomState, focusState)

### Instrumented Test Placeholders
When tests require device/emulator (e.g., camera hardware):
1. Write placeholder test in unit test directory marked @Ignore
2. Include clear TODOs showing expected implementation
3. Document migration path to androidTest source set
4. Prevents breaking the test suite while enabling future implementation
**Why**: Allows tests to be versioned in git and discovered early, reducing surprises during implementation

### Zoom Control Testing Pattern (Step 3.2)
For range-bounded state like zoom ratios:
- Test must verify clamping logic: `ratio.coerceIn(min, max)`
- Test at boundaries: exactly min, exactly max, below min, above max
- Test rapid consecutive changes don't corrupt state
- Test idempotency: setting same ratio multiple times = stable state
- Use simple test fixtures with MutableStateFlow for synchronous .value access
- Include @Ignore-marked instrumented test placeholder for gesture-based testing

### File References
- Zoom tests: `/workspace/feature/camera/src/test/java/com/remoteshutter/feature/camera/ZoomControlTest.kt`
- Updated CameraManagerTest: `/workspace/feature/camera/src/test/java/com/remoteshutter/feature/camera/CameraManagerTest.kt`
- Updated interface: `/workspace/feature/camera/src/main/java/com/remoteshutter/feature/camera/CameraController.kt`
- Implementation: `/workspace/feature/camera/src/main/java/com/remoteshutter/feature/camera/CameraXManager.kt`

## Tap-to-Focus Testing (Step 3.3.1-3.3.5)

### Focus State Machine Pattern
Expose focus state as enum (IDLE, FOCUSING, FOCUSED, FAILED):
1. IDLE: Default state, no active focus operation
2. FOCUSING: User tapped; operation in progress
3. FOCUSED: Focus successful
4. FAILED: Focus failed
5. Auto-transition FOCUSED/FAILED → IDLE after timeout (5s)

### Coordinate Normalization in Focus Tests
When testing tapToFocus(x, y):
- Clamp both x and y to [0.0, 1.0] range using `coerceIn(0.0f, 1.0f)`
- Record last clamped coordinates in test fixture for assertion
- Test should verify clamping at boundaries (-0.5, 1.5) and valid range (0.3, 0.7)
**Why**: PreviewView coordinates must be normalized before converting to MeteringPoint

### Test Fixture Methods for Focus State Transitions
TestFocusController needs simulation methods:
1. `tapToFocus(x, y)` - clamps coords, transitions to FOCUSING
2. `simulateFocusSuccess()` - transitions FOCUSING → FOCUSED
3. `simulateFocusFailure()` - transitions FOCUSING → FAILED
4. `simulateTimeout()` - transitions FOCUSED/FAILED → IDLE
**Why**: Allows tests to drive state machine without mocking CameraX internals

### File References
- Tests: `/workspace/feature/camera/src/test/java/com/remoteshutter/feature/camera/TapToFocusTest.kt`

## Photo Capture Testing (Step 3.4.1-3.4.5)

### CaptureResult Sealed Class Pattern
Use sealed class with Success/Error variants:
- Success(jpegBytes: ByteArray, rotation: Int) - includes JPEG data and rotation metadata
- Error(message: String) - includes error description

**Why**: Allows type-safe handling of both success and failure paths without nullable returns

### JPEG Byte Array Testing
For testing JPEG validity:
1. Verify SOI marker (0xFF 0xD8) at bytes [0-1]
2. Verify EOI marker (0xFF 0xD9) at end of file
3. Generate mock JPEGs with both markers for realistic testing
4. Use ByteArray.contentEquals() for comparison in tests (data class equality)

**Why**: Without markers, you can't verify JPEG file structure correctness

### Photo Capture Test Coverage
Comprehensive tests should cover:
1. Success case with valid JPEG bytes
2. Error case with descriptive message
3. JPEG magic bytes (SOI/EOI markers)
4. Rotation metadata preservation (0, 90, 180, 270)
5. Failure when not initialized
6. Event emission (CameraEvent.PhotoCaptured)
7. Multiple consecutive captures
8. Error recovery (failures followed by success)
9. Result equality and serialization

### TestPhotoCaptureController Pattern
Mock implementation needs:
1. `isInitializedForTest` boolean flag
2. `forceFailureOnNextCapture` for failure simulation
3. `simulatedRotation` for rotation testing
4. `emittedEvents` list for event verification
5. `generateMockJpegBytes()` helper with proper SOI/EOI markers

**Why**: Allows fine-grained control over capture behavior without mocking CameraX internals

### Instrumented Test Placeholders
For device-dependent tests:
1. Mark with @Ignore("TODO: Migrate to androidTest source set")
2. Include detailed TODO comments with implementation steps
3. Document migration path clearly
4. Use placeholder methods in unit test directory

**Why**: Tests can be versioned and discovered early, but don't block JVM test suite

### File References
- CaptureResult class: `/workspace/feature/camera/src/main/java/com/remoteshutter/feature/camera/CaptureResult.kt`
- Tests: `/workspace/feature/camera/src/test/java/com/remoteshutter/feature/camera/PhotoCaptureTest.kt`
- Interface update: `/workspace/feature/camera/src/main/java/com/remoteshutter/feature/camera/CameraController.kt`
- CameraEvent: `/workspace/core/model/src/main/java/com/remoteshutter/core/model/CameraEvent.kt`

## RemoteViewfinder Testing (Step 4.4.1-4.4.4)

### Compose Surface Lifecycle Testing Pattern
RemoteViewfinder uses AndroidView(factory = { SurfaceView }) with surface lifecycle callbacks:
1. Create RemoteViewfinderCallback interface with onSurfaceCreated/onSurfaceDestroyed
2. Test fixture simulates surface creation/destruction separately
3. Decoder lifecycle follows: start() on surface creation, stop() on destruction
4. Allow multiple creation-destruction cycles (orientation changes)
**Why**: Unit tests avoid actual SurfaceView/Compose dependency; integration handled in instrumented tests

### 16:9 Aspect Ratio Calculation Logic
For maintaining 16:9 regardless of container dimensions:
1. Calculate container aspect ratio = width / height
2. If container aspect > 16/9: constrain by height, calculate width = height * (16/9)
3. If container aspect < 16/9: constrain by width, calculate height = width / (16/9)
4. Test extreme dimensions (small and large containers)
5. Test both portrait (height > width) and landscape (width > height)
**Why**: Video surfaces must never distort; incorrect ratio appears skewed

### Surface Provider and Callback Integration
TestRemoteViewfinderController pattern:
1. Track provided surface (reference for decoder)
2. Track surface validity (non-null, not destroyed)
3. Track decoder lifecycle (isRunning, decoderStartCount, decoderStopCount)
4. Maintain callback list for creation/destruction events
5. Expose surface width/height for dimension compatibility checks
**Why**: Decouples surface management from decoder and Compose runtime

### File References
- Tests: `/workspace/feature/controller/src/test/java/com/remoteshutter/feature/controller/RemoteViewfinderTest.kt`
- RemoteViewfinderCallback interface: In same test file
- TestRemoteViewfinderController: In same test file

## Frame Access Testing (Step 3.5.1-3.5.4)

### FrameData Pattern for Streaming
Create a simple data class with ByteArray equality support:
```kotlin
data class FrameData(
    val bytes: ByteArray, val width: Int, val height: Int,
    val format: Int,  // ImageFormat.YUV_420_888
    val timestamp: Long
)
```
Override equals() and hashCode() to properly handle ByteArray.contentEquals().
**Why**: Tests need to compare frames for correctness; default equals fails on ByteArray

### STRATEGY_KEEP_ONLY_LATEST Testing
When ImageAnalysis uses STRATEGY_KEEP_ONLY_LATEST:
- Frames are NOT buffered — only the latest is available
- Slow consumer gets most recent frame, older frames are dropped
- Test verifies: last emitted frame always arrives, intermediate frames may be skipped
- Use MutableStateFlow in test fixture to simulate frame emission
**Why**: This strategy prevents memory buildup during encoding; matches production behavior

### Frame Throughput Benchmark Pattern
For performance tests (Step 3.5.4) requiring device hardware:
1. Mark with @Ignore("Requires device/emulator...")
2. Include clear TODO with expected measurements (fps, latency)
3. Document migration path to androidTest source set
4. Include pseudo-code showing expected implementation
**Why**: Allows test versioning without breaking unit test suite

### Frame Flow Test Fixture
TestFrameProvider simulates ImageAnalysis:
- `emitFrame()` adds frames to internal list
- `frameFlow()` exposes them as Flow<FrameData>
- `shutdown()` clears state and stops emission
**Why**: Decouples tests from real camera hardware; allows deterministic testing

### File References
- Tests: `/workspace/feature/camera/src/test/java/com/remoteshutter/feature/camera/FrameAccessTest.kt`
- Data class: `/workspace/feature/camera/src/main/java/com/remoteshutter/feature/camera/FrameData.kt`
- Updated interface: `/workspace/feature/camera/src/main/java/com/remoteshutter/feature/camera/CameraController.kt`

## H.264 Video Encoder Testing (Step 4.1.1-4.1.6)

### EncodedFrame Data Class Pattern
Similar to FrameData and CaptureResult:
- Use sealed class or data class with ByteArray
- Override equals()/hashCode() using contentEquals() for ByteArray comparison
- Fields: data, presentationTimeUs, isKeyFrame
**Why**: Tests need to compare frame data; ByteArray default equals fails

### NAL Unit Start Code Validation
Valid H.264 start codes:
1. 4-byte: 0x00 0x00 0x00 0x01 (preferred for Annex B)
2. 3-byte: 0x00 0x00 0x01 (also valid)
Test should verify: frameData[0:3 or 4] matches one of these patterns
**Why**: NAL unit framing is critical for H.264 stream validity

### SPS/PPS Prefixing Pattern for H.264
H.264 decoders need Sequence Parameter Set (SPS) and Picture Parameter Set (PPS) NAL units before decoding:
1. Send SPS (0x67 NAL type) before first frame
2. Send PPS (0x68 NAL type) before first frame
3. Re-send SPS/PPS before each IDR (Instantaneous Decoder Refresh) frame
4. This allows mid-stream decoder join — decoder waits for IDR before starting
**Why**: Allows decoder to initialize and enables mid-stream connection recovery

### Test Fixture for VideoEncoder (TestVideoEncoder)
Mock implementation needs:
1. `simulateEncodedFrame(data, presentationTimeUs, isKeyFrame)` - inject frame
2. `emittedFrames` list to track all emitted frames
3. `firstFrameContainsSpsPps` boolean flag
4. `spsNalData`, `ppsNalData` byte arrays (realistic SPS/PPS)
5. `spsPpsResendCount` to verify resend behavior
6. State tracking: `isRunning`, `frameCount`, `lastWasKeyFrame`
**Why**: Allows tests to control frame emission without real MediaCodec

### VideoEncoder Test Coverage (9 tests needed)
1. testDefaultEncoderConfig() - verify defaults (1280x720, 24fps, 2Mbps, 1s iframe)
2. testCustomEncoderConfig() - verify custom params accepted
3. testEncodedFrameFlowEmitsFrames() - verify Flow emission works
4. testFirstFrameIsPrefixedWithSpsPps() - SPS/PPS before first frame
5. testKeyFramesFlaggedCorrectly() - IDR frames have isKeyFrame=true
6. testSpsPpsResendOnIdrFrame() - SPS/PPS re-sent before each IDR
7. testStopStopsEmitting() - stop() prevents further emission
8. testPresentationTimestampsIncreasing() - PTS monotonically increases
9. testEncodedFrameContainsValidNalUnits() - verify start code presence

### Instrumented Test Placeholders (3 tests)
For device-dependent MediaCodec testing:
1. testEncoderOutputNalUnits() - verify NAL structure from real encoder
2. testEncoderProducesValidBitstream() - bitrate/fps/IDR interval verification
3. testEncoderSpsppsPrefixing() - verify SPS/PPS parsing and resend
All marked @Ignore("TODO: Migrate to androidTest source set...")

### File References
- EncodedFrame class: `/workspace/feature/camera/src/main/java/com/remoteshutter/feature/camera/EncodedFrame.kt`
- Tests: `/workspace/feature/camera/src/test/java/com/remoteshutter/feature/camera/VideoEncoderTest.kt`

## Frame Transport Testing (Step 4.2.1-4.2.5)

### Frame Header Serialization for Video Frames
When testing video frame transport with FrameHeader:
1. Use ProtoBuf serialization (FrameHeader.serializer())
2. Wire format: [4-byte big-endian length][serialized header bytes][payload bytes]
3. To decode: read length, then use extractProtoField2Varint() to find payloadLength boundary
4. This avoids ProtoBuf's limitation where it can't safely decode when arbitrary bytes follow

**Why**: FrameHeader includes dynamic-length payload, requiring manual header/payload split

### Frame Drop Logic Implementation
Drop strategy for buffer-constrained video transport:
1. Track buffered frame count (increment on send, decrement on send-complete)
2. When buffer full (>= maxBuffered):
   - Drop non-keyframes (store flag "dropped_non_keyframe" for stats)
   - Allow keyframes through (buffer may grow temporarily)
3. Keyframes needed for decoder initialization; non-keyframes are expendable

**Why**: Non-keyframes don't reset decoder state, so losing them only degrades quality; keyframes are critical

### Slow Consumer Simulation in Frame Transport Tests
ChannelMux.videoFrames() uses DROP_OLDEST buffer strategy:
- Send frames quickly while receiver processes slowly
- Oldest non-critical frames get dropped automatically
- Keyframes survive longer naturally due to their importance in H.264
- Test should verify: received frames are in order (no reordering), no crashes under load

**Why**: Matches real scenario where encoder is fast (camera at 24fps), decoder may lag

### FrameTransportStats Data Class Pattern
For latency tracking across frame transport:
- Store: framesReceived, framesDropped, latencies list
- Compute: averageLatency, maxLatency, minLatency
- Immutable builder pattern: `withReceivedFrame(latency)` returns new stats with updated values
- Allows clean accumulation without mutation

**Why**: Immutable stats prevent accidental state corruption; easy to test

### TestVideoFrameSender Pattern
Mock sender for testing frame drop logic:
1. Track internal bufferedFrameCount (0 to maxBufferedFrames)
2. sendFrame() checks buffer; drops non-keyframes if full
3. recordFrameSent() decrements counter (simulates drain)
4. statsBuilder list records drop events for assertion

**Why**: Decouples drop logic from real I/O; tests can control buffer state directly

### Frame Reconstruction from Raw Payload
When receiving VIDEO frames and reconstructing EncodedFrame:
1. ChannelMux.videoFrames() returns payload (header already stripped)
2. Create EncodedFrame with: data=payload, presentationTimeUs=from metadata, isKeyFrame=inferred
3. In unit tests: can mock isKeyFrame by checking first byte (0x80 bit for quick flag)

**Why**: In real implementation, would need to parse H.264 NAL headers; unit tests can use simpler heuristics

### File References
- Tests: `/workspace/core/network/src/test/java/com/remoteshutter/core/network/FrameTransportTest.kt`
- ChannelMux: `/workspace/core/network/src/main/java/com/remoteshutter/core/network/ChannelMux.kt`
- EncodedFrame: `/workspace/feature/camera/src/main/java/com/remoteshutter/feature/camera/EncodedFrame.kt`

## CommandDispatcher Testing (Step 5.1.1-5.1.6)

### CommandDispatcher Pattern and Architecture
CommandDispatcher routes ControlCommand messages to CameraController methods:
1. **SetZoom** command -> CameraController.setZoomRatio(ratio)
2. **TapToFocus** command -> CameraController.tapToFocus(x, y)
3. **CapturePhoto** command -> CameraController.capturePhoto(), then emit CameraEvent.PhotoCaptured
4. **RequestStreamStart** -> activate encoding pipeline (call cameraController.frameFlow())
5. **RequestStreamStop** -> deactivate encoding pipeline (cancel Job)

### Test Fixture (TestCameraController)
Mock CameraController implementation with instrumentation:
1. Track method calls: `lastSetZoomRatio`, `lastTapToFocusX`, `lastTapToFocusY`, `capturePhotoCallCount`
2. Allow configurable results: `capturePhotoResult` (Success/Error)
3. Emit events via `cameraEvents: SharedFlow<CameraEvent>`
4. Control frame flow access: `frameFlowCount` tracks how many times frameFlow() called

### Comprehensive Test Coverage (26 tests)
1. **Deserialization** - CommandDispatcher deserializes CONTROL frames to ControlCommand
2. **SetZoom routing** - values passed through to controller (minimum, maximum, consecutive)
3. **TapToFocus routing** - coordinates passed through (boundaries, various values)
4. **CapturePhoto routing** - controller.capturePhoto() called, handles Success/Error results
5. **Stream lifecycle** - RequestStreamStart/Stop control frame flow access
6. **Event emission** - PhotoCaptured events sent with correct JPEG bytes
7. **Error handling** - graceful handling of capture errors
8. **Rapid commands** - no deadlocks under rapid successive commands
9. **Initialization state** - isInitialized flag exposed

### File References
- Tests: `/workspace/feature/controller/src/test/java/com/remoteshutter/feature/controller/CommandDispatcherTest.kt`
- Implementation: `/workspace/feature/controller/src/main/java/com/remoteshutter/feature/controller/CommandDispatcher.kt`
- Dependency update: `/workspace/feature/controller/build.gradle.kts` (added feature:camera, kotlin.test, coroutines-test)

## CommandDispatcher Testing (Step 5.1.1-5.1.6) - REVISED

### QA Defects Fixed
1. **CommandDispatcher now accepts ChannelMux parameter** in constructor
2. **PhotoCaptured events sent via ChannelMux.sendEvent()** (serialized bytes), not locally
3. **RequestStreamStart launches a job that collects from frameFlow()** (not just calls it)
4. **RequestStreamStop cancels the encoding pipeline job**
5. **Integration tests verify full ChannelMux deserialization path**
6. **testDispatcherPhotoCapturedEventHasCorrectBytes** now decodes sent frame and verifies bytes (FIXED 2026-03-23)

### Test Fixture Patterns
**TestCameraController**:
- Added `frameFlowCollectionStarted` flag to verify collection actually occurs
- Added `emittedFrames` list to inject test frames
- `frameFlow()` returns a real Flow that emits injected frames

**TestP2pConnection**:
- Implements P2pConnection with Channel-based frame injection
- Tracks sent frames via `getOutgoingSentFrames()`
- Allows tests to inject raw bytes and capture outgoing frames

### PhotoCaptured Event Payload Verification (Step 5.1.4 QA Fix)
Test `testDispatcherPhotoCapturedEventHasCorrectBytes` was only asserting `sentFrames.isNotEmpty()`. Fixed by:
1. **Parse wire frame**: Read 4-byte big-endian length, then read totalContent
2. **Extract payload**: Use `extractProtoField2Varint(totalContent)` to find header/payload boundary
3. **Decode event**: `ProtoBuf.decodeFromByteArray(CameraEvent.serializer(), payload)`
4. **Assert PhotoCaptured**: Verify it's a PhotoCaptured event
5. **Compare bytes**: Assert `photoCaptured.bytes.contentEquals(jpegBytes)`

Helper methods needed:
- `extractProtoField2Varint(bytes): Int` - scans ProtoBuf for field 2 varint (payloadLength)
- `readVarint(bytes, offset): Pair<Long, Int>` - reads ProtoBuf varint encoding

### Comprehensive Test Coverage (26+ tests)
- 5.1.1: CommandDispatcher deserialization from ChannelMux frames
- 5.1.2-5.1.3: SetZoom and TapToFocus routing (multiple variants)
- 5.1.4: CapturePhoto -> ChannelMux.sendEvent() with correct JPEG bytes in payload
- 5.1.5: RequestStreamStart/Stop with job lifecycle
- 5.1.6: Integration tests, rapid commands, error handling

### File References
- Tests: `/workspace/feature/controller/src/test/java/com/remoteshutter/feature/controller/CommandDispatcherTest.kt`
- Implementation: `/workspace/feature/controller/src/main/java/com/remoteshutter/feature/controller/CommandDispatcher.kt`

## EventPublisher Testing (Step 5.2.1-5.2.4)

### EventPublisher Architecture Pattern
EventPublisher observes CameraController state flows and publishes events via ChannelMux:
1. **ZoomChanged events**: Throttled to max 10/s (1 event per 100ms minimum)
2. **FocusStateChanged events**: NOT throttled, sent immediately on state change
3. **PhotoChunked transfer**: Large photos split into 64KB chunks with sequence numbers

### PhotoChunk Event Design
New CameraEvent.PhotoChunk variant for chunked photo transfers:
- `transferId: Int` - unique ID for grouping chunks from same photo
- `chunkIndex: Int` - sequence number (0-based) within this transfer
- `totalChunks: Int` - total number of chunks in this transfer
- `data: ByteArray` - chunk payload (max 64KB)

**Why**: Photos may be several MB; single large frame would exceed buffer limits. Chunking with sequence numbers allows reassembly on receiver side.

### Test Fixture Patterns
**TestCameraControllerForEventPublisher**:
- Exposes mutable StateFlow for zoomState and focusState
- Allows tests to trigger changes via direct assignment to MutableStateFlow.value
- Empty implementation of other CameraController methods

**TestP2pConnectionForEventPublisher**:
- Tracks all sent frames in `sentFrames` list
- No-op receive() (not needed for sender-side tests)

### EventPublisher Test Coverage (14 tests)
1. testEventPublisherSendsZoomChangedEvent - zoom state → ZoomChanged event
2. testEventPublisherSendsFocusStateChangedEvent - focus state → FocusStateChanged event
3. testEventPublisherSendsMultipleEvents - sequential zoom + focus events
4. testEventPublisherThrottlesZoomEvents - rapid zoom changes → max 5 per 500ms
5. testEventPublisherDoesNotThrottleFocusEvents - all focus changes sent
6. testEventPublisherChunksLargePhoto - 200KB photo → 4+ chunks
7. testEventPublisherSendsSmallPhotoAsingleChunk - 32KB photo → 1 chunk
8. testEventPublisherPhotoChunkSequenceNumbers - chunks have correct indices
9. testEventPublisherPhotoChunksHaveSameTransferId - all chunks in transfer share ID
10. testEventPublisherSerializesZoomChangedCorrectly - ZoomChanged round-trip
11. testEventPublisherSerializesFocusStateChangedCorrectly - FocusStateChanged round-trip
12. testEventPublisherSerializesPhotoChunkCorrectly - PhotoChunk round-trip
13. testEventPublisherLifecycle - start()/stop() execute without error
14. testEventPublisherDifferentPhotoTransfersHaveDifferentIds - different photos ≠ same ID

### Wire Frame Decoding Helper
For unit tests that need to verify serialized events:
- Use `decodeEventFrame(frameBytes)` helper to parse wire format
- Returns (FrameHeader, payload) where payload is raw CameraEvent bytes
- Mirrors ChannelMux.decodeFrame() logic using `extractProtoField2Varint()`

### Throttling Implementation Pattern
For zoom throttling (max 10/s):
- Track last emission time
- On zoom state change, check if 100ms elapsed since last emission
- If yes: emit immediately and update timestamp
- If no: buffer the latest value, emit on next allowed time window

**Why**: Simple time-based throttling prevents flooding; `advanceTimeBy()` in tests simulates passage of time

### File References
- Tests: `/workspace/feature/controller/src/test/java/com/remoteshutter/feature/controller/EventPublisherTest.kt`
- Implementation stub: `/workspace/feature/controller/src/main/java/com/remoteshutter/feature/controller/EventPublisher.kt`
- Updated CameraEvent: `/workspace/core/model/src/main/java/com/remoteshutter/core/model/CameraEvent.kt` (added PhotoChunk)

## RemoteCameraController Testing (Step 5.3.1-5.3.4)

### RemoteCameraController Interface and Implementation Pattern
RemoteCameraController is a command sender on Device B that sends control commands via ChannelMux:
1. **Interface methods** (all suspend): setZoom(ratio), tapToFocus(x, y), capturePhoto(), startStream(), stopStream()
2. **Implementation** (RemoteCameraControllerImpl):
   - Serializes each call as ControlCommand via ProtoBuf
   - Sends via `channelMux.sendControl(bytes)`
   - For capturePhoto(): sends CapturePhoto command, then awaits PhotoCaptured event from eventFrames()
3. **Request-response correlation** for photo capture:
   - Since ControlCommand.CapturePhoto has no request ID field, use single-in-flight correlation
   - Await the NEXT PhotoCaptured event (or reassemble from PhotoChunk frames) with 5s timeout
   - If timeout: throw TimeoutCancellationException

### Test Fixture for RemoteCameraController (TestP2pConnectionForRemote)
Mock P2pConnection with instrumentation:
1. Implements send() by appending to `outgoingFrames` list
2. Implements receive() via Channel that tests can inject into via `injectIncomingFrame()`
3. Tracks sent frames for assertion: `getOutgoingSentFrames()`

**Why**: Decouples RemoteCameraController tests from real sockets; allows deterministic event injection

### RemoteCameraController Test Coverage (13 tests)
1. **setZoom** - sends SetZoom command via ChannelMux
2. **tapToFocus** - sends TapToFocus command with x,y coordinates
3. **startStream** - sends RequestStreamStart command
4. **stopStream** - sends RequestStreamStop command
5. **capturePhoto sends command** - sends CapturePhoto command
6. **capturePhoto receives bytes** - awaits PhotoCaptured event and returns JPEG bytes
7. **capturePhoto timeout** - throws when no PhotoCaptured arrives within timeout
8. **serialization correctness** - verify all sent frames deserialize to valid ControlCommand
9. **chunked photo** - handle PhotoChunk frames, reassemble and await final PhotoCaptured
10. **interface completeness** - verify all methods exist and are callable
11. **rapid commands** - handle consecutive commands without deadlock
12. **await PhotoCaptured correctly** - proper async waiting for response
13. **serialization round-trips** - ControlCommand and CameraEvent serialize/deserialize correctly

### Frame Encoding/Decoding in RemoteCameraController Tests
When verifying sent command frames:
1. Read 4-byte big-endian length from DataInputStream
2. Read totalLength bytes of content
3. Use `extractProtoField2Varint(totalContent)` to find FrameHeader/payload boundary
4. Extract payload: `totalContent.copyOfRange(headerSize, totalLength)`
5. Deserialize payload as ControlCommand or CameraEvent
**Why**: FrameHeader includes dynamic-length field 2 (payloadLength); must manually split

When injecting event responses:
1. Serialize CameraEvent (PhotoCaptured or PhotoChunk) to ProtoBuf bytes
2. Wrap in FrameHeader(FrameType.EVENT, payloadSize, timestamp)
3. Use `createEventFrame(payload)` helper to encode wire format
4. Inject via `connection.injectIncomingFrame(frameBytes)`

### PhotoChunk and Reassembly Pattern
For testing chunked photo reassembly:
1. Create multiple PhotoChunk events with: transferId (same for all), chunkIndex (0-based), totalChunks, data
2. Inject all chunks in sequence
3. Then inject final PhotoCaptured event with complete JPEG bytes
4. Controller should buffer PhotoChunk frames and match against final PhotoCaptured
**Why**: Photos may be several MB; ChannelMux buffers are limited to 64 entries

### File References
- Tests: `/workspace/feature/controller/src/test/java/com/remoteshutter/feature/controller/RemoteCameraControllerTest.kt`
- Interface (to be implemented): `/workspace/feature/controller/src/main/java/com/remoteshutter/feature/controller/RemoteCameraController.kt`
- Implementation (to be implemented): `/workspace/feature/controller/src/main/java/com/remoteshutter/feature/controller/RemoteCameraControllerImpl.kt`

## EventReceiver Testing (Step 5.4.1-5.4.4)

### EventReceiver Architecture Pattern
EventReceiver is an event listener on Device B that collects EVENT frames from ChannelMux:
1. **Collect eventFrames()** in a coroutine started by start(scope)
2. **Deserialize frames** to CameraEvent via ProtoBuf
3. **Route events**:
   - ZoomChanged → update remoteZoomState StateFlow
   - FocusStateChanged → update remoteFocusState StateFlow
   - PhotoChunk → accumulate chunks, emit onPhotoReceived when complete
   - PhotoCaptured → invoke onPhotoReceived directly
   - Error/others → ignore
4. **Initial values**:
   - remoteZoomState: 1.0f
   - remoteFocusState: FocusState.FOCUSED
5. **Photo reassembly**: Store partial photos by transferId, emit only when all chunks arrived

### Test Fixture (TestEventP2pConnection)
Mock P2pConnection for event receiver tests:
1. Implements receive() with Channel<ByteArray>
2. `injectIncomingFrame(frameBytes)` method for tests to queue frames
3. Tracks `isConnected` flag (set to false on close())
4. No-op send() (not used by EventReceiver)

**Why**: Decouples EventReceiver tests from real network; allows deterministic event injection

### EventReceiver Test Coverage (16 tests)
1. testEventReceiverAcceptsChannelMuxParameter - constructor and properties exist
2. testEventReceiverRemoteZoomStateInitialValue - initial zoom = 1.0f
3. testEventReceiverRemoteFocusStateInitialValue - initial focus = FOCUSED
4. testEventReceiverUpdatesZoomState - ZoomChanged event updates remoteZoomState
5. testEventReceiverUpdatesFocusState - FocusStateChanged event updates remoteFocusState
6. testEventReceiverIgnoresUnrelatedEvents - Error events don't change state
7. testEventReceiverReassemblesChunkedPhoto - 3 PhotoChunk frames → reassembled bytes
8. testEventReceiverSingleChunkPhoto - 1 PhotoChunk with totalChunks=1 → callback invoked
9. testEventReceiverHandlesDirectPhotoCaptured - PhotoCaptured event → callback with bytes
10. testEventReceiverIgnoresChunksFromDifferentTransfers - 2 transfers reassembled independently
11. testEventReceiverDeserializesZoomChangedEvent - ZoomChanged round-trip
12. testEventReceiverDeserializesFocusStateChangedEvent - FocusStateChanged round-trip
13. testEventReceiverDeserializesPhotoChunkEvent - PhotoChunk round-trip with metadata
14. testEventReceiverDeserializesPhotoCapturedEvent - PhotoCaptured round-trip
15. testEventReceiverStartStop - start(scope) subscribes, stop() cancels
16. testEventReceiverHandlesMultipleZoomUpdates - rapid zoom changes tracked
17. testEventReceiverHandlesMultipleFocusUpdates - rapid focus changes tracked
18. testEventReceiverHandlesOutOfOrderChunks - chunks reassembled in correct order
19. testEventReceiverReassemblesLargePhoto - 10 chunks × 1000 bytes each
20. testEventReceiverPhotoCallbackIsOptional - onPhotoReceived can be null

### Wire Frame Helper
`createEventFrame(payload: ByteArray)` helper wraps payload in ChannelMux format:
- Encode FrameHeader(FrameType.EVENT, payload.size, 0L) with ProtoBuf
- Prepend 4-byte big-endian length to (header + payload)
- Return complete wire bytes
**Why**: Tests need to inject frames that match ChannelMux wire format exactly

### Chunk Reassembly Pattern
Track per-transferId state:
1. Map<Int, MutableList<PhotoChunk>> storing chunks by transferId
2. Keep sorted by chunkIndex for correct ordering
3. When chunkIndex==0 arrives: allocate new list
4. When chunkIndex==N arrives: insert in sorted position
5. When count == totalChunks: reassemble and invoke callback

**Why**: Out-of-order chunk injection requires buffering; sorted map prevents ordering errors

### File References
- Tests: `/workspace/feature/controller/src/test/java/com/remoteshutter/feature/controller/EventReceiverTest.kt`
- Implementation (to be implemented): `/workspace/feature/controller/src/main/java/com/remoteshutter/feature/controller/EventReceiver.kt`

## H.264 Video Decoder Testing (Step 4.3.1-4.3.6)

### DecoderState Enum Pattern
Create enum for decoder state machine (in same module as VideoDecoder):
- WAITING_FOR_SPS_PPS: Initial state, buffers all frames
- INITIALIZED: SPS/PPS received, waiting for first IDR
- DECODING: SPS/PPS + IDR received, actively decoding
- ERROR: Error occurred during decoding

**Why**: Testable state machine without mocking MediaCodec

### VideoDecoder Buffering and Initialization
1. Decoder starts in WAITING_FOR_SPS_PPS state
2. All incoming frames buffered until SPS/PPS received
3. On SPS/PPS: transition to INITIALIZED (don't decode yet)
4. On first IDR after SPS/PPS: transition to DECODING, flush buffered frames
5. Subsequent SPS/PPS resends handled gracefully (before IDR)
**Why**: Ensures decoder has initialization data before MediaCodec start

### Frame Feeding with Presentation Timestamps
- Track all fed frame timestamps in mutable list for assertion
- Feed to MediaCodec input buffer with PTS intact
- Maintain monotonic PTS ordering for frame sequencing
- Support idempotent multiple feed() calls on same buffer

### ReleaseOutputBuffer Testing Pattern
- Verify releaseOutputBuffer(render=true) called for each decoded frame
- Track rendered frame count separately from fed count
- Match counts accounting for buffering lag
**Why**: Proves frames actually rendered to Surface, not just fed

### Format Change Recovery (INFO_OUTPUT_FORMAT_CHANGED)
- Simulate format change event mid-stream
- Decoder does NOT transition to ERROR
- Decoder continues accepting frames after change
- Re-extract output format without crashing (e.g., resolution change)
**Why**: H.264 streams may have dynamic format changes

### TestVideoDecoder Fixture Implementation
Mock implementation needs:
1. `state: DecoderState` - track state machine
2. `feedFrame(nalData, pts, isSpsPps=false)` - accepts NAL units
3. `inputBuffer` list - all fed frames
4. `fedFrameCount` and `fedFrameTimestamps` - for assertion
5. `renderedFrameCount` - incremented by simulateDecodedFrame()
6. `simulateDecodedFrame()` - represents releaseOutputBuffer(render=true)
7. `simulateFormatChange()` - test format change handling
8. Lifecycle: `start()`, `stop()`, `release()` (release idempotent)
9. `isRunning` flag - prevents frame acceptance after stop

**Why**: Full control over decoder state without real MediaCodec

### VideoDecoder Test Coverage (14 unit tests)
1. testDefaultDecoderConfig() - video/avc, 1280x720
2. testDecoderInitialState() - WAITING_FOR_SPS_PPS
3. testFramesBufferedBeforeSpsPps() - pre-SPS/PPS frames buffered
4. testDecoderInitializesOnSpsPps() - transition to INITIALIZED
5. testDecodingStartsAfterSpsPpsAndIdr() - transition to DECODING
6. testNonIdrFramesBufferedUntilIdr() - buffering until init
7. testNalUnitsLoveCorrectPresentationTimestamps() - PTS tracking
8. testReleaseOutputBufferRenderCalled() - rendered frame count
9. testMultipleConsecutiveFrames() - batch frame handling
10. testErrorRecoveryOnFormatChange() - format change handling
11. testSpsPpsRetransmissionHandling() - resent SPS/PPS before IDR
12. testDecoderStopsCleanly() - stop() prevents acceptance
13. testDecoderReleaseIsIdempotent() - multiple release() safe
14. testDecoderLifecycleCycles() - start/stop/release cycles

### Instrumented Test Placeholders (4 tests)
For device-dependent MediaCodec testing:
1. testEndToEndEncodeDecodeLatency() - < 200ms requirement
2. testDecoderFrameRenderingOnSurface() - frames render
3. testDecoderHandlesMidStreamJoinWithSpsPpsResend() - recovery
4. testDecoderHandlesFormatChange() - dynamic resolution
All marked @Ignore("TODO: Migrate to androidTest source set...")

### File References
- DecoderState enum: `/workspace/feature/controller/src/main/java/com/remoteshutter/feature/controller/DecoderState.kt`
- Tests: `/workspace/feature/controller/src/test/java/com/remoteshutter/feature/controller/VideoDecoderTest.kt`
