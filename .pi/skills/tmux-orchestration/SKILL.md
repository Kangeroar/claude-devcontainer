---
name: tmux-orchestration
description: "Commands and patterns for managing subagent tmux sessions"
---

# Tmux Orchestration Skill

Everything the Orchestrator needs to create, communicate with, and tear down subagent tmux sessions.

## Creating Sessions

```bash
# Create a session for each subagent role
tmux new-session -d -s test-writer "ollama launch pi --model kimi-k2.5:cloud"
tmux new-session -d -s developer   "ollama launch pi --model kimi-k2.5:cloud"
tmux new-session -d -s qa-reviewer "ollama launch pi --model glm-5.1:cloud"
tmux new-session -d -s work-planner "ollama launch pi --model opus"
```

## Verifying Sessions

```bash
# List all running sessions
tmux list-sessions
```

## Sending Instructions

```bash
# Send a complete message followed by Enter
tmux send-keys -t test-writer "Your instruction here"
tmux send-keys -t test-writer Enter

# Multi-line instruction (use literal newlines)
tmux send-keys -t developer "I'm the Orchestrator. Implement Sub-task 2.1 from docs/checklists/2026-04-10-1-carousel-autoscroll-progress-bar.md. Read tests first at output/frontend/__tests__/carousel-autoscroll-progress.test.ts. Run tests, tick Code Implemented boxes, commit, let me know when done."
tmux send-keys -t developer Enter
```

**Be specific** — always include:
- Checklist file path
- Exact sub-task number and description
- File paths to read/write
- Which checkboxes to tick
- "Let me know when done" (so they signal completion)

## Reading Responses

```bash
# Read the last 50 lines of output
tmux capture-pane -t test-writer -p -S -50

# Read more lines if the output was long
tmux capture-pane -t developer -p -S -200

# Read a specific session into a file for detailed inspection
tmux capture-pane -t qa-reviewer -p -S -500 > /tmp/qa-output.txt
```

## Resetting Agent Context

**Always reset context before re-assigning a task.** Agents accumulate stale conversation history that confuses subsequent assignments.

Send `/new` to start a fresh session (this fully clears context and resets the token counter):

```bash
# 1. Cancel any ongoing generation
tmux send-keys -t developer C-c
sleep 2

# 2. Start a fresh session (fully resets context)
tmux send-keys -t developer "/new"
tmux send-keys -t developer Enter
sleep 3

# 3. Now send the new task
tmux send-keys -t developer "Your new task..."
tmux send-keys -t developer Enter
```

> **`/new` vs `/compact`:** `/new` starts a completely fresh session, resetting the token counter (X%/203k). `/compact` only summarizes the existing context to save tokens — it does **not** fully clear it. Always use `/new` between tasks.

## Detecting Completion

After sending a task, wait then check for completion signals:

```bash
# Wait for the agent to finish (adjust sleep based on task complexity)
sleep 90

# Check for completion phrases
tmux capture-pane -t developer -p -S -30
```

Look for these signals in the output:
- "Ready for next task"
- "Awaiting your next instruction"
- "Task Complete"
- "✅" / "All done" / "Finished"
- Git commit messages (signalling they committed their work)

If the agent doesn't appear done, wait longer and check again:
```bash
sleep 60 && tmux capture-pane -t developer -p -S -30
```

## Suggested Sleep Times

| Task Type                              | Recommended Sleep |
|----------------------------------------|-------------------|
| Writing tests (medium complexity)      | 60-90 seconds     |
| Code implementation (complex)          | 90-120 seconds    |
| QA review (reading files + running tests)| 90-120 seconds   |
| Simple fixes (1-2 line changes)        | 30-60 seconds     |

## Verifying Work After Each Agent

```bash
# Check git commits
cd output/frontend && git log --oneline -5

# Run the relevant test suite
npx jest __tests__/carousel-autoscroll-progress.test.ts --verbose

# Check which checklist boxes are ticked
grep "\[x\]" docs/checklists/YYYY-MM-DD-N-title.md
grep "\[ \]" docs/checklists/YYYY-MM-DD-N-title.md
```

## Handling QA Feedback Loops

When QA-Reviewer flags an issue:

```bash
# 1. Read the QA note from the checklist or captured output
# Example: "⚠️ BUG: var(--color-buttonLight-border) doesn't work in Tailwind v3"

# 2. Clear Developer context and send the fix task, quoting QA's note verbatim
tmux send-keys -t developer C-c
sleep 2
tmux send-keys -t developer "/new"
tmux send-keys -t developer Enter
sleep 3
tmux send-keys -t developer "Quick fix from QA review: var(--color-buttonLight-border) doesn't work in Tailwind v3. Change to theme('colors.buttonLight.border'). Also update test regex if needed. Run tests, tick Code Implemented, commit, let me know when done."
tmux send-keys -t developer Enter

# 3. After Developer fixes, clear QA context and send re-review
tmux send-keys -t qa-reviewer C-c
sleep 2
tmux send-keys -t qa-reviewer "/new"
tmux send-keys -t qa-reviewer Enter
sleep 3
tmux send-keys -t qa-reviewer "Re-review: Developer fixed the var(--color-buttonLight-border) issue. Verify the fix at <file>. Run tests, tick QA Reviewed, let me know when done."
tmux send-keys -t qa-reviewer Enter
```

## Handling Stuck or Failed Agents

```bash
# 1. Cancel current output
tmux send-keys -t developer C-c
sleep 2

# 2. Start fresh session
tmux send-keys -t developer "/new"
tmux send-keys -t developer Enter
sleep 3

# 3. Re-send the instruction more specifically
tmux send-keys -t developer "More detailed instruction..."
tmux send-keys -t developer Enter

# If still failing, kill and recreate the session:
tmux kill-session -t developer
tmux new-session -d -s developer "ollama launch pi --model kimi-k2.5:cloud"
sleep 5
tmux send-keys -t developer "I'm the Orchestrator. Your task is..."
tmux send-keys -t developer Enter
```

## Tearing Down Sessions

```bash
# When a session is no longer needed
tmux kill-session -t test-writer

# Kill all agent sessions at once
tmux kill-session -t test-writer
tmux kill-session -t developer
tmux kill-session -t qa-reviewer
```

## Full Cycle Example

One complete sub-task (Test → Code → Review):

```bash
# ── TEST-WRITER ──
tmux send-keys -t test-writer C-c; sleep 2
tmux send-keys -t test-writer "/new"; tmux send-keys -t test-writer Enter; sleep 3
tmux send-keys -t test-writer "Write tests for Sub-task 2.1 from docs/checklists/2026-04-10-1-carousel-autoscroll-progress-bar.md. Add tests to output/frontend/__tests__/carousel-autoscroll-progress.test.ts. Tick Tests Written boxes. Commit. Let me know when done."
tmux send-keys -t test-writer Enter
sleep 90 && tmux capture-pane -t test-writer -p -S -30
# Verify: check test file, git log, checklist ticks

# ── DEVELOPER ──
tmux send-keys -t developer C-c; sleep 2
tmux send-keys -t developer "/new"; tmux send-keys -t developer Enter; sleep 3
tmux send-keys -t developer "Implement Sub-task 2.1. Read tests first at output/frontend/__tests__/carousel-autoscroll-progress.test.ts. Run tests. Tick Code Implemented boxes. Commit. Let me know when done."
tmux send-keys -t developer Enter
sleep 120 && tmux capture-pane -t developer -p -S -30
# Verify: run tests, git log, checklist ticks

# ── QA-REVIEWER ──
tmux send-keys -t qa-reviewer C-c; sleep 2
tmux send-keys -t qa-reviewer "/new"; tmux send-keys -t qa-reviewer Enter; sleep 3
tmux send-keys -t qa-reviewer "Review Sub-task 2.1. Tests at output/frontend/__tests__/carousel-autoscroll-progress.test.ts, code at output/frontend/src/components/Carousel.tsx. Run tests. Tick QA Reviewed boxes. Let me know when done."
tmux send-keys -t qa-reviewer Enter
sleep 120 && tmux capture-pane -t qa-reviewer -p -S -30
# If QA approves → next sub-task. If QA flags issues → route to Developer, then back to QA.
```