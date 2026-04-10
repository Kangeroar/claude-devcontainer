---
name: agent-protocol
description: "Communication protocol for subagents running in tmux sessions — signalling completion, context clearing, and checklist conventions"
---

# Agent Protocol Skill

Shared conventions for subagents running in tmux sessions. This covers how to signal completion, handle context clearing, and manage checklist boxes.

## Signalling Completion

When you finish your assigned task, you **must** output a clear completion signal so the Orchestrator can detect you're done using `tmux capture-pane`. Use one of these exact phrases:

- `"Ready for next task"`
- `"Awaiting your next instruction"`
- `"Task Complete"`
- `"✅"` / `"All done"` / `"Finished"`

**Always** include one of these as the **last line** of your response. The Orchestrator is polling your tmux pane output and relies on these signals to know when to proceed.

## Context Resetting (`/new`)

Between task assignments, the Orchestrator will reset your context by starting a fresh session. You will see a `/new` command sent to your session. This is **normal and expected** — it prevents stale instructions from previous tasks polluting your context window.

When your context is reset:
1. You will see the `/new` command arrive.
2. A new session starts — your conversation history is completely cleared.
3. Wait for the next task instruction from the Orchestrator.

> **Note:** `/compact` is a different command that only summarizes context to save tokens without fully clearing it. For a complete reset between tasks, always use `/new`.

**Why this matters:** Without clearing, agents can:
- Reference instructions from previous tasks
- Try to continue already-completed work
- Fill up their context window, degrading output quality
- Misunderstand the current task scope

## Checklist Conventions

### Three-Column Tickable Format

Every checklist uses this table format:

```markdown
| Tests Written | Code Implemented | QA Reviewed | Step |
|---------------|------------------|-------------|------|
| [ ] | [ ] | [ ] | Write tests for X |
| [ ] | [ ] | [ ] | Implement feature X |
| [ ] | [ ] | [ ] | QA review of X |
```

### Who Ticks What

| Role          | Column They Tick      | Marker |
|---------------|-----------------------|--------|
| Test-Writer   | `Tests Written`       | `[x]`  |
| Developer     | `Code Implemented`    | `[x]`  |
| QA-Reviewer   | `QA Reviewed`         | `[x]`  |

### Unticking Boxes

Only the **QA-Reviewer** unticks boxes. When QA finds an issue:

- Untick `Code Implemented` (change `[x]` to `[ ]`) if the implementation needs fixing.
- Untick `Tests Written` (change `[x]` to `[ ]`) if the tests also need fixing.
- **Always add a note** explaining the issue, prefixed with ⚠️:

```markdown
| [x] | [ ] | [ ] | Add CSS custom property ⚠️ BUG: var(--color-x) doesn't work in Tailwind v3 — use theme('colors.x') instead
```

### Reading Checklist Status

```bash
# Count completed items
grep -c "\[x\]" docs/checklists/YYYY-MM-DD-N-title.md

# Count remaining items
grep -c "\[ \]" docs/checklists/YYYY-MM-DD-N-title.md

# Show completed items
grep "\[x\]" docs/checklists/YYYY-MM-DD-N-title.md

# Show remaining items
grep "\[ \]" docs/checklists/YYYY-MM-DD-N-title.md
```

## Git Commit Conventions

- Use **conventional commit** messages: `feat:`, `fix:`, `test:`, `refactor:`, `chore:`, etc.
- Write **concise but descriptive** messages.
- **Never** use `git add -A` — stage only the specific files you changed to avoid committing other agents' work.
- Use `git add <file>` for each file you modified.

```bash
git add output/frontend/__tests__/my-feature.test.ts
git commit -m "test: add carousel autoscroll progress bar tests"
```

## Known Pitfalls

### Regex with JSX
Tests using `[^}]*` regex patterns fail across JSX because `}` appears in event handlers and template literals. Prefer:
- `[\s\S]*?` (non-greedy, matches anything including newlines)
- Targeted selectors: `/<div[^>]*className[^>]*carousel-progress-bar/`
- Split complex assertions into multiple simpler checks

### Tailwind v3 CSS Custom Properties
`var(--color-buttonLight-border)` does **not** work in Tailwind v3. Instead use:
- `theme('colors.buttonLight.border')` in CSS files
- Tailwind utility classes like `bg-buttonLight-border` in components
- Explicit `:root` definitions: `--my-color: theme('colors.buttonLight.border');`

### Agent Modifying Tests They Shouldn't
The Developer should **never** modify test files to make tests pass. If this happens, QA should untick "Code Implemented" and note the issue. The Developer must fix the implementation, not the tests.

### Long Output in tmux
If agent output fills the tmux buffer, capture more lines:
```bash
tmux capture-pane -t <session> -p -S -500
```
Or check files the agent wrote to disk directly rather than relying on the buffer.