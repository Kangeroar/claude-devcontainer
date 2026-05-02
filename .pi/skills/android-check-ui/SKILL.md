---
name: android-check-ui
description: >
  Best practices for using scrcpy and ADB to control Android phones, capture screenshots for multimodal review,
  stream/read logs, verify UI via XML layout dumps, and manage devcontainer vs. local build environments.
---

# Android UI Check & Control

Use ADB and (where available) scrcpy to inspect, interact with, and validate UI on connected Android devices.

## 1. Device Setup & Verification

Check connected devices:
```bash
adb devices
```

- Ensure **exactly one** device is connected.
- If multiple devices are present, specify the target device using the `-s <device_serial>` flag for all subsequent commands.

### Launching Apps

Get the package and main activity name:
```bash
adb shell dumpsys package com.example.app | grep -A 1 "android.intent.action.MAIN"
```

Start the app:
```bash
adb shell am start -n com.example.app/.MainActivity
```

## 2. Devcontainer vs. Local Environment

Check if you are in a devcontainer before building:
```bash
# Check for common devcontainer indicators
if [ -f /.dockerenv ] || [ -f /run/.containerenv ] || [ -n "$REMOTE_CONTAINERS" ]; then
  echo "Running in a devcontainer"
  GRADLE_CMD="gradle"
else
  echo "Running locally"
  GRADLE_CMD="./gradlew"
fi
```

- **Devcontainer**: Use `gradle` (pre-installed in the environment).
- **Local**: Use `./gradlew` from the project root.

**Example:**
```bash
# Local build
./gradlew assembleDebug

# Devcontainer build
gradle assembleDebug
```

## 3. Capturing Screenshots

Take a screenshot and pull it to your local machine:
```bash
adb shell screencap -p /sdcard/screen.png
adb pull /sdcard/screen.png /tmp/screen.png
```

### Multimodal Screenshot Review

When reviewing screenshots, use a **native multimodal model** (e.g., Claude with vision capabilities) to analyze the UI. The model can inspect:
- Layout correctness
- Element positioning
- Text content and alignment
- Visual anomalies

> **Note:** Ensure the screenshot file is accessible to the multimodal model for direct review.

## 4. UI Layout Verification via XML Dumps

For cases where multimodal review is unavailable or for automated validation, use `uiautomator` to dump the UI hierarchy:

```bash
adb shell uiautomator dump /sdcard/window_dump.xml
adb pull /sdcard/window_dump.xml /tmp/window_dump.xml
```

Inspect specific elements:
```bash
cat /tmp/window_dump.xml | grep "text=\"Expected Text\""
```

**Best Practices:**
- Combine XML dumps with screenshot review for comprehensive validation.
- Use XML dumps to verify element attributes (e.g., `bounds`, `resource-id`, `text`).
- When using multimodal models, provide the XML dump as context alongside the screenshot.

## 5. Logcat Streaming and Reading

### Stream Logs Continuously

Start a background log stream:
```bash
# Filter to a specific package (recommended)
adb logcat -v threadtime --pid=$(adb shell pidof com.example.app) > /tmp/app_logs.txt &
echo $! > /tmp/logcat_pid.txt
```

Read the latest logs:
```bash
tail -n 100 /tmp/app_logs.txt
```

### Reading Logs On-Demand

For immediate log inspection:
```bash
# Clear buffer and capture recent logs
adb logcat -c
adb logcat -v threadtime -d | grep "com.example.app"
```

**Log Level Filtering:**
```bash
adb logcat -v threadtime *:D  # Debug and above
adb logcat -v threadtime *:E   # Errors only
```

### App-Specific Log Filtering

```bash
# Get app PID first
APP_PID=$(adb shell pidof com.example.app)
adb logcat --pid=$APP_PID -v threadtime
```

## 6. Interacting with the Device

### Taps and Gestures
```bash
# Tap at coordinates (x, y)
adb shell input tap 540 1115

# Swipe
adb shell input swipe 300 1000 300 500 300   # x1 y1 x2 y2 duration(ms)
```

### Key Events
```bash
adb shell input keyevent 4    # Back
adb shell input keyevent 3    # Home
adb shell input keyevent 187  # Recent apps
```

### Text Input
```bash
adb shell input text "Hello World"
```

## 7. Cleanup Procedures

Always clean up after UI checks:

```bash
# Stop background logcat process
if [ -f /tmp/logcat_pid.txt ]; then
  kill $(cat /tmp/logcat_pid.txt) 2>/dev/null
  rm -f /tmp/logcat_pid.txt
fi

# Remove temporary files from device
adb shell rm -f /sdcard/screen.png
adb shell rm -f /sdcard/window_dump.xml
adb shell rm -f /sdcard/app_logs.txt

# Clean local temporary files
rm -f /tmp/screen.png
rm -f /tmp/window_dump.xml
rm -f /tmp/app_logs.txt
```

## 8. scrcpy Usage (if available)

If `scrcpy` is installed locally, use it to mirror and control the device screen:

```bash
# Basic mirroring
scrcpy

# Mirror with resolution control for better performance
scrcpy --max-size 1024 --bit-rate 2M
```

**Note:** In devcontainer or CI environments where GUI is unavailable, rely on ADB commands for UI interaction and verification.

## Complete Workflow Example

```bash
#!/bin/bash

# 1. Verify device
adb devices

# 2. Build and install (local environment)
./gradlew assembleDebug
./gradlew installDebug

# 3. Launch app
adb shell am start -n com.example.app/.MainActivity

# 4. Capture screenshot
adb shell screencap -p /sdcard/screen.png
adb pull /sdcard/screen.png /tmp/screen.png

# 5. Dump UI hierarchy
adb shell uiautomator dump /sdcard/window_dump.xml
adb pull /sdcard/window_dump.xml /tmp/window_dump.xml

# 6. Review screenshot with multimodal model (if available)
# Provide the screenshot file path to the model for analysis

# 7. Stream logs in background
adb logcat -v threadtime --pid=$(adb shell pidof com.example.app) > /tmp/app_logs.txt &
echo $! > /tmp/logcat_pid.txt

# 8. Interact with the app (e.g., tap)
adb shell input tap 540 1115

# 9. Read logs
sleep 2
tail -n 50 /tmp/app_logs.txt

# 10. Cleanup
kill $(cat /tmp/logcat_pid.txt) 2>/dev/null
adb shell rm -f /sdcard/screen.png /sdcard/window_dump.xml
rm -f /tmp/screen.png /tmp/window_dump.xml /tmp/app_logs.txt
```

## Key Considerations

- **Multimodal Review:** Always use native multimodal capabilities when available for screenshot analysis.
- **XML Fallback:** When multimodal tools are unavailable, XML layout dumps provide structural UI verification.
- **Environment Awareness:** Determine devcontainer vs. local environment to use the correct Gradle command (`gradle` vs. `./gradlew`).
- **Cleanup:** Always remove temporary files from the device and local machine after UI checks to maintain a clean state.
