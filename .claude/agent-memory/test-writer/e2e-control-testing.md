---
name: End-to-End Control Testing Pattern (Remote Control Protocol)
description: Patterns for testing bidirectional control message flows across Device A/B with ChannelMux
type: feedback
---

## Manual Frame Routing in E2E Tests

For testing end-to-end control flows without real socket connections:
1. Create two separate `TestP2pConnection` instances (one for Device A, one for Device B)
2. Each device has its own `ChannelMux` wrapping its connection
3. After Device B sends a CONTROL frame: manually call `connectionA.injectIncomingFrame()` with bytes from `connectionB.getOutgoingFrames()`
4. After Device A sends an EVENT frame: manually call `connectionB.injectIncomingFrame()` with bytes from `connectionA.getOutgoingFrames()`

**Why**: Avoids needing real sockets or loopback connections; tests can control frame delivery timing and order manually.

## CameraController Test Fixture for E2E

The test fixture must:
1. Immediately update internal `zoomState` MutableStateFlow when `setZoomRatio()` is called
2. Track call counts: `setZoomCallCount`, `capturePhotoCallCount`
3. Allow tests to set `capturePhotoResult` to control what photo bytes are returned

**Why**: EventPublisher polls `zoomState.value` every 100ms. If state isn't updated immediately in the fixture, the poll cycle will see old state and send stale events. Tests must be able to verify that all operations completed without race conditions.

## EventPublisher Continuous Polling in Tests

EventPublisher has a `while(true)` loop that polls zoom state every 100ms (ZOOM_THROTTLE_MS = 100L). In tests:
1. After CommandDispatcher processes a SetZoom command, call `advanceTimeBy(150)` to let polling cycle complete
2. Then route the EVENT frames from Device A→B
3. Use `advanceUntilIdle()` between state changes to let async operations settle

**Why**: Polling happens in background; tests must advance time to trigger emissions.

## File References
- Tests: `/workspace/feature/controller/src/test/java/com/remoteshutter/feature/controller/EndToEndControlTest.kt`
