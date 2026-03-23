---
name: Compose UI Testing Patterns for Sub-task 6.1
description: Structural tests for navigation routes, ViewModels, and screen skeletons in Jetpack Compose
type: feedback
---

## Compose Navigation Routes Testing

For Compose Navigation setup in step 6.1.1:
1. Create `NavRoutes` object with constants: `ROLE_SELECT`, `DISCOVERY`, `CONTROLLER_MAIN`, `PHOTO_REVIEW`
2. Use string constants (e.g., "role_select") as route names — not complex sealed classes
3. Routes should be unique to prevent navigation conflicts
4. Test both constant existence and uniqueness

**Why**: Simple string routes make navigation easy to understand and test. Complex sealed classes add unnecessary complexity at this stage.

## ViewModel Hilt Injection Testing

For ControllerViewModel in step 6.1.3:
1. Annotate with `@HiltViewModel`
2. Constructor takes `@Inject` parameters: `RemoteCameraController`, `EventReceiver`
3. Expose state flows as properties: `connectionState`, `remoteZoomState`, `remoteFocusState`
4. Delegate camera control methods: `setZoom()`, `tapToFocus()`, `capturePhoto()`, `startStream()`, `stopStream()`
5. Manage EventReceiver lifecycle in `init {}` and `onCleared()`

**Why**: Hilt scopes ViewModels to the navigation backstack, ensuring proper cleanup on screen transitions.

## Compose Preview Testing

For screen skeletons in step 6.1.4:
1. Each screen needs a `@Preview` annotated function: `RoleSelectScreenPreview()`, etc.
2. Preview functions are `@Composable` (no return value)
3. Preview should wrap screen in `RemoteShutterTheme`
4. Screens should accept only basic parameters at skeleton stage (callbacks, state)
5. Don't include complex business logic in skeletons

**Why**: Previews enable Android Studio design verification without running full app. Skeletons allow parallel development.

## App Module Dependencies for Checklist 6

The app module build.gradle must include:
1. Plugins: `hilt`, `ksp` (in addition to existing ones)
2. Dependencies:
   - `project(":feature:controller")` — for RemoteViewfinder and controller UI
   - `project(":core:model")` — for Role, ControlCommand, CameraEvent
   - `project(":core:network")` — for ChannelMux, P2pConnection
   - `libs.compose.navigation` — for NavHost
   - `libs.hilt.android` — for @HiltViewModel
   - `libs.hilt.compiler` with ksp — for code generation
   - `libs.hilt.navigation.compose` — for integration with NavController

**Why**: Hilt requires both runtime (hilt.android) and compile-time (hilt.compiler via ksp) dependencies.

## Structural Testing vs. Implementation Testing

The tests for 6.1 are *structural* tests that verify:
- Routes exist and are unique (not testing navigation behavior)
- ViewModel accepts correct parameters (not testing business logic)
- Screens exist as composables (not testing UI rendering)

Real UI/behavior testing happens later with Compose test framework.

**Why**: Structural tests can be written before implementation, providing clear contracts that code must satisfy.

## File References

- Navigation tests: `/workspace/app/src/test/java/com/remoteshutter/ui/navigation/NavigationRoutesTest.kt`
- Navigation graph tests: `/workspace/app/src/test/java/com/remoteshutter/ui/navigation/AppNavigationGraphTest.kt`
- ViewModel tests: `/workspace/app/src/test/java/com/remoteshutter/ui/screens/ControllerViewModelTest.kt`
- RoleSelectScreen tests: `/workspace/app/src/test/java/com/remoteshutter/ui/screens/RoleSelectScreenTest.kt`
- Preview tests: `/workspace/app/src/test/java/com/remoteshutter/ui/screens/ScreenPreviewTests.kt`
- App structure tests: `/workspace/app/src/test/java/com/remoteshutter/AppStructureTest.kt`
