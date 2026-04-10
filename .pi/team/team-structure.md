# Team Structure

## Architecture

All agents run in separate **tmux sessions**. The Orchestrator communicates with subagents by sending keystrokes into their session and reading their output back.

```
┌───────────────────────────────────────────────────┐
│                  Orchestrator                     │
│            (main tmux session)                    │
│                                                   │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐       │
│  │test-writer│  │developer │  │qa-reviewer│       │
│  │  session  │  │  session  │  │  session  │        │
│  │kimi-k2.5  │  │kimi-k2.5 │  │ glm-5.1  │       │
│  └──────────┘  └──────────┘  └──────────┘       │
│                                                   │
│  Communication: tmux send-keys → tmux capture-pane│
└───────────────────────────────────────────────────┘
```

## Roles

| Role           | tmux Session   | Typical Model     | Responsibility |
|----------------|----------------|--------------------|----------------|
| **Orchestrator**| (main)         | varies             | Coordinates workflow, creates/resets agent sessions, does not write code |
| **Work-Planner**| `work-planner`| opus               | Breaks tasks into phased checklists with 3-column tickable steps |
| **Test-Writer**| `test-writer`  | kimi-k2.5:cloud    | Writes tests before implementation exists |
| **Developer**  | `developer`    | kimi-k2.5:cloud    | Implements minimal code to pass tests |
| **QA-Reviewer**| `qa-reviewer`  | glm-5.1:cloud      | Reviews tests for robustness, code for quality, ticks off checklist items |

Use a **different model** for QA-Reviewer when possible — an independent perspective catches bugs the implementation model misses.

## Communication Protocol

- **Send instruction:** `tmux send-keys -t <session> "<message>"` then `Enter`
- **Read response:** `tmux capture-pane -t <session> -p -S -<lines>`
- **Reset context:** `tmux send-keys -t <session> "/new"` then `Enter`
- **Cancel output:** `tmux send-keys -t <session> C-c`
- **Check completion:** look for "Ready for next task", "Task Complete", "✅", "Awaiting your next instruction"

Always **reset agent context with `/new`** before assigning a new task. This starts a fresh session. (`/compact` only summarizes — it does not clear context. Use `/new` for a full reset.) Agents accumulate stale history that confuses subsequent assignments.

See `.pi/skills/tmux-orchestration` for the full command reference and `.pi/skills/agent-protocol` for signalling conventions.

## Checklist Format

Every checklist in `docs/checklists/` uses this 3-column tickable table per step:

```markdown
| Tests Written | Code Implemented | QA Reviewed | Step |
|---------------|------------------|-------------|------|
| [ ] | [ ] | [ ] | Write tests for X |
| [ ] | [ ] | [ ] | Implement feature X |
| [ ] | [ ] | [ ] | QA review of X |
```

- **Test-Writer** ticks `Tests Written`
- **Developer** ticks `Code Implemented`
- **QA-Reviewer** ticks `QA Reviewed`

QA-Reviewer may **untick** boxes when issues are found, adding a note describing the problem. The Orchestrator then routes that note back to the appropriate agent.

## Team Workflow

1. **Orchestrator** receives task
2. **Orchestrator** spawns **Work-Planner** (optional, if checklists don't exist yet)
3. Work-Planner creates checklists → signals done → Orchestrator clears and closes session
4. For each sub-task in the checklist:
   a. **Orchestrator** clears and sends task to **Test-Writer**
   b. Test-Writer writes tests, ticks "Tests Written", commits, signals done
   c. **Orchestrator** verifies tests, clears and sends task to **Developer**
   d. Developer reads tests, implements code, ticks "Code Implemented", commits, signals done
   e. **Orchestrator** verifies implementation, clears and sends task to **QA-Reviewer**
   f. QA-Reviewer reviews, ticks "QA Reviewed" (or unticks with notes), signals done
   g. If QA flagged issues → Orchestrator routes notes to Developer to fix → back to QA-Reviewer
5. Repeat step 4 until all sub-tasks in the checklist are fully reviewed