---
name: tmux-orchestration
description: "Commands and patterns for managing subagent tmux sessions"
---

# Tmux Orchestration Skill

Everything the Orchestrator needs to create, communicate with, and tear down subagent tmux sessions.

## Workflow Overview

The workflow has three phases per feature:
1. **Planning Phase** (runs first, before Orchestrator starts) — Work-Planner creates the checklist
2. **Checklist Execution** — For each feature: Test table rows → Code table rows → Final Review table rows
3. **Mid-Cycle Planning Updates** — Work-Planner re-spawned as needed for large structural changes

**Within each feature, the subtables are processed in order:**
- `#### Test` table: each row → Test-Writer writes test → QA-Reviewer reviews
- `#### Code` table: each row → Developer implements → QA-Reviewer reviews
- `#### Final Review` table: each row → QA-Reviewer verifies

**Critical:** The Orchestrator does NOT write code or investigate/debug issues. All implementation and investigation is delegated to the appropriate subagent (primarily Developer).

**Important: The Orchestrator workflow assumes a checklist already exists.** The Work-Planner completes before the Orchestrator begins. The first step of the orchestration loop is always to spawn the Test-Writer.

## Creating Sessions

```bash
# Create a session for each subagent role (always use -y flag for headless launch)
tmux new-session -d -s work-planner "ollama launch pi --model glm-5.1:cloud -y"
tmux new-session -d -s test-writer "ollama launch pi --model minimax-m2.7:cloud -y"
tmux new-session -d -s developer   "ollama launch pi --model minimax-m2.7:cloud -y"
tmux new-session -d -s qa-reviewer "ollama launch pi --model kimi-k2.6:cloud -y"
```

### Changing Models Without Recreating Sessions

To switch the model of an existing agent session, use the `/model` command inside the session instead of killing and recreating:

```bash
# Switch qa-reviewer to kimi-k2.6:cloud
tmux send-keys -t qa-reviewer "/model ollama/kimi-k2.6:cloud"
tmux send-keys -t qa-reviewer Enter
sleep 3

# Switch test-writer to minimax-m2.7:cloud
tmux send-keys -t test-writer "/model ollama/minimax-m2.7:cloud"
tmux send-keys -t test-writer Enter
sleep 3
```

This is faster and preserves session state. Only kill and recreate (`tmux kill-session` + `tmux new-session`) if the session is truly stuck or broken.

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

# Example multi-line instruction (use literal newlines)
# Make sure to tailor to each of developer, test-writer and qa-reviewer
tmux send-keys -t developer "You are the developer agent, with agent description in `.pi/agents/developer.md`. Implement feature 1.1 from the #### Code table in docs/checklists/2026-04-10-1-carousel-autoscroll-progress-bar.md. Specifically: 'Add sortColumn and sortDirection state to BanknoteListPage'. Read tests first at output/frontend/__tests__/carousel-autoscroll-progress.test.ts. Run tests, tick Implemented box, commit, let me know when done."
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

Send `/new` to start a fresh session (this fully clears context and resets the token counter). **Important:** `/new` also resets the model back to the default, so you must immediately re-set the correct model afterwards:

```bash
# 1. Cancel any ongoing generation
tmux send-keys -t developer C-c
sleep 2

# 2. Start a fresh session (fully resets context AND model)
tmux send-keys -t developer "/new"
tmux send-keys -t developer Enter
sleep 3

# 3. Re-set the model (required — /new resets it to default)
tmux send-keys -t developer "/model ollama/minimax-m2.7:cloud"
tmux send-keys -t developer Enter
sleep 3

# 4. Now send the new task
tmux send-keys -t developer "Your new task..."
tmux send-keys -t developer Enter
```

### Model assignments per role:

| Role | Command after `/new` |
|------|---------------------|
| work-planner | `/model ollama/glm-5.1:cloud` |
| test-writer | `/model ollama/minimax-m2.7:cloud` |
| developer | `/model ollama/minimax-m2.7:cloud` |
| qa-reviewer | `/model ollama/kimi-k2.6:cloud` |

> **`/new` vs `/compact`:** `/new` starts a completely fresh session, resetting the token counter (X%/203k) AND the model. `/compact` only summarizes the existing context to save tokens — it does **not** fully clear it. Always use `/new` between tasks, then immediately re-set the model.
>
> **Why re-setting the model matters:** After `/new`, the session reverts to whatever the default model is (often `glm-5.1:cloud`). If you forget to re-set, your QA reviewer might end up running on the test-writer model, or vice versa — breaking the independent-perspective principle for QA.

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

# Check specific subsection progress
grep -A 20 "#### Test" docs/checklists/YYYY-MM-DD-N-title.md | grep -E "\[x\]|\[ \]"
grep -A 20 "#### Code" docs/checklists/YYYY-MM-DD-N-title.md | grep -E "\[x\]|\[ \]"
grep -A 20 "#### Final Review" docs/checklists/YYYY-MM-DD-N-title.md | grep -E "\[x\]|\[ \]"
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
tmux send-keys -t developer "Quick fix from QA review: var(--color-buttonLight-border) doesn't work in Tailwind v3. Change to theme('colors.buttonLight.border'). Also update test regex if needed. Run tests, tick Implemented in the Code table row, commit, let me know when done."
tmux send-keys -t developer Enter

# 3. After Developer fixes, clear QA context and send re-review
tmux send-keys -t qa-reviewer C-c
sleep 2
tmux send-keys -t qa-reviewer "/new"
tmux send-keys -t qa-reviewer Enter
sleep 3
tmux send-keys -t qa-reviewer "Re-review: Developer fixed the var(--color-buttonLight-border) issue. Verify the fix at <file>. Run tests, tick QA Reviewed in the Code table row, let me know when done."
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

# If still failing, kill and recreate the session (always use -y flag):
tmux kill-session -t developer
tmux new-session -d -s developer "ollama launch pi --model minimax-m2.7:cloud -y"
sleep 5
tmux send-keys -t developer "I'm the Orchestrator. Your task is..."
tmux send-keys -t developer Enter

# To just change the model without recreating the session:
tmux send-keys -t developer "/model ollama/minimax-m2.7:cloud"
tmux send-keys -t developer Enter
sleep 3
```

## Tearing Down Sessions

```bash
# When a session is no longer needed
tmux kill-session -t test-writer

# Kill all agent sessions at once
tmux kill-session -t work-planner
tmux kill-session -t test-writer
tmux kill-session -t developer
tmux kill-session -t qa-reviewer
```

## Full Cycle Example

### Assumed Work Completed

Assumes Work-Planner agent has already created a checklist like this:

```markdown
### Feature 1.1: Carousel Autoscroll Progress Bar

#### Test

| Implemented | QA Reviewed | Description |
|-------------|-------------|-------------|
| [ ] | [ ] | Write test: progress bar fills as autoscroll timer advances |
| [ ] | [ ] | Write test: progress bar resets when user interacts (click/hover) |
| [ ] | [ ] | Write test: progress bar completes fill when autoscroll reaches end |

#### Code

| Implemented | QA Reviewed | Description |
|-------------|-------------|-------------|
| [ ] | [ ] | Implement progress bar component with animated fill |
| [ ] | [ ] | Wire progress bar to autoscroll timer state |
| [ ] | [ ] | Add reset behavior on user interaction |

#### Final Review

| QA Reviewed | Description |
|-------------|-------------|
| [ ] | Verify all 3 tests pass |
| [ ] | Visual check: progress bar animates smoothly |
| [ ] | Run scratchpad UI test for visual regression |
```

### Phase A: Test Table (Row by Row)

```bash
# ── TEST-WRITER: Row 1 of Test table ──
tmux send-keys -t test-writer C-c; sleep 2
tmux send-keys -t test-writer "/new"; tmux send-keys -t test-writer Enter; sleep 3
tmux send-keys -t test-writer "/model ollama/minimax-m2.7:cloud"
tmux send-keys -t test-writer Enter; sleep 3
tmux send-keys -t test-writer "From Feature 1.1 Test table row 1 in docs/checklists/2026-04-10-1-carousel-autoscroll-progress-bar.md: write test for 'progress bar fills as autoscroll timer advances'. Add to output/frontend/__tests__/carousel-autoscroll-progress.test.ts. Tick Implemented for that row. Commit. Let me know when done."
tmux send-keys -t test-writer Enter
sleep 90 && tmux capture-pane -t test-writer -p -S -30

# ── QA-REVIEWER: Row 1 of Test table ──
tmux send-keys -t qa-reviewer C-c; sleep 2
tmux send-keys -t qa-reviewer "/new"; tmux send-keys -t qa-reviewer Enter; sleep 3
tmux send-keys -t qa-reviewer "/model ollama/kimi-k2.6:cloud"
tmux send-keys -t qa-reviewer Enter; sleep 3
tmux send-keys -t qa-reviewer "Review Feature 1.1 Test table row 1: test at output/frontend/__tests__/carousel-autoscroll-progress.test.ts. Run tests. Tick QA Reviewed for that row. Let me know when done."
tmux send-keys -t qa-reviewer Enter
sleep 60 && tmux capture-pane -t qa-reviewer -p -S -30

# ── Repeat for Test table rows 2, 3 ──
# (same pattern as above for each remaining Test row)
```

### Phase B: Code Table (Row by Row)

```bash
# ── DEVELOPER: Row 1 of Code table ──
tmux send-keys -t developer C-c; sleep 2
tmux send-keys -t developer "/new"; tmux send-keys -t developer Enter; sleep 3
tmux send-keys -t developer "/model ollama/minimax-m2.7:cloud"
tmux send-keys -t developer Enter; sleep 3
tmux send-keys -t developer "Implement Feature 1.1 Code table row 1: 'Implement progress bar component with animated fill'. Read tests at output/frontend/__tests__/carousel-autoscroll-progress.test.ts. Run tests. Tick Implemented for that row. Commit. Let me know when done."
tmux send-keys -t developer Enter
sleep 120 && tmux capture-pane -t developer -p -S -30

# ── QA-REVIEWER: Row 1 of Code table ──
tmux send-keys -t qa-reviewer C-c; sleep 2
tmux send-keys -t qa-reviewer "/new"; tmux send-keys -t qa-reviewer Enter; sleep 3
tmux send-keys -t qa-reviewer "/model ollama/kimi-k2.6:cloud"
tmux send-keys -t qa-reviewer Enter; sleep 3
tmux send-keys -t qa-reviewer "Review Feature 1.1 Code table row 1. Tests at output/frontend/__tests__/carousel-autoscroll-progress.test.ts, code at output/frontend/src/components/Carousel.tsx. Run tests. Tick QA Reviewed for that row. Let me know when done."
tmux send-keys -t qa-reviewer Enter
sleep 120 && tmux capture-pane -t qa-reviewer -p -S -30

# ── Repeat for Code table rows 2, 3 ──
```

### Phase C: Final Review Table (Row by Row)

```bash
# ── QA-REVIEWER: Row 1 of Final Review table ──
tmux send-keys -t qa-reviewer C-c; sleep 2
tmux send-keys -t qa-reviewer "/new"; tmux send-keys -t qa-reviewer Enter; sleep 3
tmux send-keys -t qa-reviewer "/model ollama/kimi-k2.6:cloud"
tmux send-keys -t qa-reviewer Enter; sleep 3
tmux send-keys -t qa-reviewer "Perform Feature 1.1 Final Review table row 1: 'Verify all 3 tests pass'. Run the full test suite. Tick QA Reviewed for that row. Let me know when done."
tmux send-keys -t qa-reviewer Enter
sleep 60 && tmux capture-pane -t qa-reviewer -p -S -30

# ── Repeat for Final Review table rows 2, 3 ──
```

### Mid-Cycle Work-Planner Re-Spawn (As Needed)

If QA identifies a missing feature (e.g., "Add keyboard navigation"), edit the checklist directly with new rows. If the change is large (multiple new features), spawn Work-Planner:

```bash
tmux new-session -d -s work-planner "ollama launch pi --model glm-5.1:cloud -y"
sleep 5

tmux send-keys -t work-planner "I'm the Orchestrator. Update the existing checklist
docs/checklists/2026-04-10-1-carousel-autoscroll-progress-bar.md to add:
- New feature 1.2: Keyboard navigation support
Add Test, Code, and Final Review tables.
Let me know when done."
tmux send-keys -t work-planner Enter

sleep 60 && tmux capture-pane -t work-planner -p -S -30

# De-spawn after update is complete
tmux kill-session -t work-planner

# Resume checklist loop from where it left off
```
