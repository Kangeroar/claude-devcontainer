---
name: checklist location and format
description: Project checklists are in /workspace/docs/checklists/; QA approval means changing [ ] to [x] in the QA Reviewed column
type: project
---

Checklists live at `/workspace/docs/checklists/` as markdown files named `YYYY-MM-DD-<N>-<topic>.md`.

Each checklist row has three checkbox columns: Tests Written | Code Implemented | QA Reviewed.

To approve a step: edit the markdown table cell in the QA Reviewed column from `[ ]` to `[x]`.

**Why:** The team uses these checklists to coordinate the TDD cycle across Test-Writer, Developer, and QA-Reviewer agents.

**How to apply:** Always edit the checklist file directly using the Edit tool after a PASS decision.
