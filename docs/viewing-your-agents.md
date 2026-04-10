# Viewing Your Agent Team in Action

This guide shows you how to open 4 terminals so you can watch all the agents work in real time.

## Overview

The Orchestrator and each subagent run in their own tmux session. By "attaching" each session to its own terminal, you get a live dashboard of everything happening across the team.

```
┌─────────────────┬──────────────────┐
│   Orchestrator   │   Test-Writer    │
│   (main)         │   (test-writer)  │
├─────────────────┼──────────────────┤
│   Developer      │   QA-Reviewer    │
│   (developer)    │   (qa-reviewer)  │
└─────────────────┴──────────────────┘
```

## Prerequisites

The Orchestrator (or you) must have already created the tmux sessions. If they haven't been created yet, run:

```bash
tmux new-session -d -s test-writer "ollama launch pi --model kimi-k2.5:cloud"
tmux new-session -d -s developer   "ollama launch pi --model kimi-k2.5:cloud"
tmux new-session -d -s qa-reviewer "ollama launch pi --model glm-5.1:cloud"
```

Verify they exist:

```bash
tmux list-sessions
```

You should see at least `test-writer`, `developer`, and `qa-reviewer`. The Orchestrator itself runs in whatever your current/primary tmux session is.

## Opening the 4 Terminals

Open 4 terminal windows (or tabs, or a terminal multiplexer like iTerm2 splits). Then attach each one to the corresponding tmux session:

### Terminal 1 — Orchestrator

```bash
tmux attach -t <your-main-session>
```

This is the session the Orchestrator is running in. If you launched the Orchestrator yourself, you're probably already attached here. If not, find the session name with `tmux list-sessions`.

### Terminal 2 — Test-Writer

```bash
tmux attach -t test-writer
```

### Terminal 3 — Developer

```bash
tmux attach -t developer
```

### Terminal 4 — QA-Reviewer

```bash
tmux attach -t qa-reviewer
```

## That's It

From here you can watch in real time as:

1. The **Orchestrator** terminal sends commands into the other sessions via `tmux send-keys`.
2. The **Test-Writer** terminal lights up as it writes tests and commits.
3. The **Developer** terminal shows implementation work and test runs.
4. The **QA-Reviewer** terminal shows review output and any ⚠️ issues flagged.

You don't need to type anything in terminals 2–4 — they are read-only views. All control flows from the Orchestrator in terminal 1.

## Tips

- **If a terminal appears blank** — the agent may not have received a task yet. It will populate once the Orchestrator sends it instructions.
- **If you see `/new` appear** — that's the Orchestrator resetting an agent's context between tasks (starting a fresh session). Normal behaviour.
- **To detach without closing** — press `Ctrl-b` then `d`. The session keeps running in the background.
- **To reattach after detaching** — just run the same `tmux attach -t <session>` command again.
- **Scrolling in a tmux session** — press `Ctrl-b` then `[` to enter scroll/copy mode. Use arrow keys or Page Up/Down. Press `q` to exit scroll mode.