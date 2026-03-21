---
name: Serialization Testing Pattern
description: Best practices for testing Kotlinx Serialization with Protobuf round-trip encode/decode
type: reference
---

## Step 1.3.4 - Serialization Round-Trip Testing

Created comprehensive SerializationTest at `/workspace/core/model/src/test/java/com/remoteshutter/core/model/SerializationTest.kt`.

**Test Coverage Pattern:**
- For each serializable type, test basic round-trip: `encode -> decode -> equals original`
- For parameterized types (Float, ByteArray, String, Enum), test multiple values
- For sealed interfaces, test each subtype separately
- For data classes with primitive fields, test boundary values (0, max, min)
- For ByteArray fields, leverage existing contentEquals/contentHashCode overrides

**Import Requirements:**
```kotlin
import kotlinx.serialization.decodeFromByteArray
import kotlinx.serialization.encodeToByteArray
import kotlinx.serialization.protobuf.ProtoBuf
import org.junit.Assert.assertEquals  // NOT kotlin.test
```

**Key Test Patterns:**

1. **Basic Round-Trip**: `ProtoBuf.encodeToByteArray<Type>(original)` then `ProtoBuf.decodeFromByteArray<Type>(bytes)`
2. **Parametric Tests**: Loop through `listOf(values)` or `enum.entries` to test all variations
3. **Boundary Values**: Test empty strings/arrays, zero/max integers, all enum states
4. **Sanity Checks**: Verify encoded bytes are non-empty (catches missing Serializable annotations)

**ByteArray Handling:**
- CameraEvent.PhotoCaptured overrides equals/hashCode to use `contentEquals()` and `contentHashCode()`
- Test serialization preserves byte content exactly: assertEquals handles the overridden equals

**ControlCommand Types Tested:**
- SetZoom(Float) - with various ratios (0.5, 1.0, 2.5, 10.0)
- TapToFocus(Float, Float) - with coordinate pairs
- CapturePhoto (data object)
- RequestStreamStart (data object)
- RequestStreamStop (data object)

**CameraEvent Types Tested:**
- PhotoCaptured(ByteArray) - empty, small, large arrays
- FocusStateChanged(FocusState) - all enum states (FOCUSING, FOCUSED, FAILED)
- ZoomChanged(Float) - multiple ratios
- Error(String) - empty, normal, 1000-char strings

**FrameHeader Tested:**
- FrameType enum: VIDEO, CONTROL, EVENT
- Boundary values: zero payload, Int.MAX_VALUE, Long.MAX_VALUE timestamps
