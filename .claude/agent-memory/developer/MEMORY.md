## Key Learnings

### Git Setup
- Main workspace: `/workspace` with git on `main` branch
- Worktree at `/workspace/.claude/worktrees/agent-a2fb033c/` on branch `worktree-agent-a2fb033c`
- Implementation files are in `/workspace/core/...` (main branch), NOT in the worktree
- Run `git` commands from `/workspace` to commit main branch changes

### ConnectionHealthMonitor Design (step 2.4.4)
- `heartbeatsWithoutResponse` counter increments on every heartbeat send, never resets automatically
- Only `onHeartbeatReceived()` resets it (and also resets the ReconnectStrategy)
- This ensures exponential backoff grows across reconnects until real heartbeat ACKs arrive
- Both `isConnected=false` AND `HealthState.UNHEALTHY` trigger the reconnect loop
- `ReconnectStrategy` is integrated (not HeartbeatMonitor); HeartbeatMonitor kept for its own tests

### Testing Patterns
- TestScope `runTest` + `advanceTimeBy` for virtual time control
- Use `val testScope = this` inside `runTest` to access `currentTime` in lambdas
- `FakeP2pConnection.receive()` returns `emptyFlow()` — heartbeat response mechanism is via `onHeartbeatReceived()` not receive flow

### StateFlow + sample(100L) with StandardTestDispatcher - IMPORTANT
- `StateFlow` is CONFLATED: if N values are set before a collection coroutine starts, the coroutine only sees the CURRENT (latest) value
- With `StandardTestDispatcher`, collection coroutines start only when `advanceTimeBy` or `runCurrent` is called
- If all state changes happen BEFORE `advanceTimeBy`, `sample(100L)` sees only ONE value → produces only 1 throttled event
- For throttle tests that expect N events after M rapid changes, use POLLING instead of `sample`:
  ```kotlin
  while (true) {
      val current = stateFlow.value
      // send event
      delay(throttleMs)
  }
  ```
- Polling every 100ms gives 500ms/100ms = 5-6 events in 500ms, satisfying `in 3..7` test ranges
- This works because the poll coroutine fires at each 100ms virtual tick during `advanceTimeBy(500)`

### Circular Dependency / Module Architecture
- `core:model` is the base data layer (no dependencies on other project modules)
- `core:network` depends on `core:model`
- `feature:camera` depends on `core:network` (and therefore `core:model`)
- If a data class (like `EncodedFrame`) is needed by both `core:network` AND `feature:camera`, move it to `core:model`
- Use `typealias` in `feature:camera` to preserve backward compatibility when moving types to `core:model`

### Kotlin Inner Class Visibility
- In Kotlin, `private` on a member of an inner class means it is private to THAT class
- The outer class CANNOT access `private` members of its inner class (unlike Java)
- To allow access from the outer test class, use default (package-private) visibility — just omit `private`
