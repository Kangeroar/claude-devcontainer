# Team Structure

## Roles

### Orchestrator
- **CRITICAL: Does NOT implement, write, edit, or investigate any code** — this is strictly forbidden
- Responsible for orchestrating the workflow and delegating ALL implementation and investigation work to appropriate agents
- **Delegate ALL debugging and investigation to the Developer** — never troubleshoot issues yourself
- Spawns and coordinates subagents: Work-Planner, Test-Writer, Developer, QA-Reviewer
- Reads and updates the checklist to track progress
- Makes decisions about when to re-spawn Work-Planner for significant checklist updates

### Work-Planner
- Takes the user's task description (relayed by Orchestrator) and breaks it into structured TODO checklists
- Discusses with user about key decisions and preferences
- Creates checklist files in `docs/checklists/` with each feature having three subsections:
  - `#### Test` table (columns: `Implemented`, `QA Reviewed`, `Description`)
  - `#### Code` table (columns: `Implemented`, `QA Reviewed`, `Description`)
  - `#### Final Review` table (columns: `QA Reviewed`, `Description`)

### Test-Writer
- Responsible for taking each subtask and writing tests that cover the required functionality, even if the code doesn't compile

### Developer
- Responsible for doing actual developer work and code implementations in line with TODO checklist items, doing the minimal code change that passes the tests

### QA-Reviewer
- Responsible for ensuring that tests:
    - are robust
    - are appropriate and meaningful
    - do not short-circuit implementation (e.g. `assertTrue(true)`) just for code coverage

- Responsible for reviewing that the code implementation:
    - aligns with requirement from TODO markdown checklist file
    - passes all tests that are intended to pass
    - has excellent code quality
    - has appropriate naming conventions

- Responsible for ticking off TODO work items, and deleting completed TODO markdown lists

## Team Workflow

**IMPORTANT:** The Orchestrator does NOT write code, edit code, or investigate/debug issues. All implementation and investigation is delegated to the appropriate subagent (primarily Developer).

### Phase 0: Planning (Completed First, Before Orchestration Starts)

The **Work-Planner** runs independently **before** the Orchestrator workflow begins. This phase is complete when a checklist exists.

1. Work-Planner receives the task description
2. Work-Planner discusses with user about key decisions and preferences
3. Work-Planner creates structured TODO checklist files in `docs/checklists/` with the new format:
   - Each feature has three subsections: `#### Test`, `#### Code`, `#### Final Review`
   - **Test** and **Code** tables have columns: `Implemented`, `QA Reviewed`, `Description`
   - **Final Review** table has columns: `QA Reviewed`, `Description` (no `Implemented` column)
4. Work-Planner signals completion — checklist is ready

> **The Orchestrator workflow below assumes a checklist already exists.** Do not proceed if there is not a clear checklist to orchestrate work around.

### Phase 1: Checklist Execution (Per-Feature, Three Subtables)

For each feature in the checklist, process its three subsections **in order**: Test, then Code, then Final Review.

#### Sub-phase 1A: Test Table (Row by Row)

For **each row** in the `#### Test` table:

1. Orchestrator sends task to **Test-Writer** — write the test described in that row
2. Test-Writer writes the test, ticks `Implemented` for that row, signals completion
3. Orchestrator sends task to **QA-Reviewer** — review that test
4. QA-Reviewer reviews the test, ticks `QA Reviewed` for that row (or unticks `Implemented` and adds notes if there are issues)
5. If issues are flagged, route back to Test-Writer to fix, then back to QA

Repeat for each Test table row. Then proceed to Code.

#### Sub-phase 1B: Code Table (Row by Row)

For **each row** in the `#### Code` table:

6. Orchestrator sends task to **Developer** — implement the item described in that row
7. Developer implements the code, runs tests, ticks `Implemented` for that row, signals completion
8. Orchestrator sends task to **QA-Reviewer** — review that implementation
9. QA-Reviewer reviews the code, ticks `QA Reviewed` for that row (or unticks `Implemented` and adds notes if there are issues)
10. If issues are flagged, route back to Developer to fix, then back to QA

Repeat for each Code table row. Then proceed to Final Review.

#### Sub-phase 1C: Final Review Table (Row by Row)

For **each row** in the `#### Final Review` table:

11. Orchestrator sends task to **QA-Reviewer** — perform the verification described in that row
12. QA-Reviewer performs the check, ticks `QA Reviewed` for that row (there is no `Implemented` column in this table)
13. If issues are flagged, route back to Developer (or Test-Writer) to fix, then back to QA

Repeat for each Final Review table row. Then move to the next feature.

### Mid-Cycle Updates: Small Changes vs. Large Changes

During the execution loop, if QA identifies issues:

- **Small changes** — QA should edit the checklist directly: untick relevant `Implemented`/`QA Reviewed` boxes and add notes in the `Description` column or as new rows. No need to spawn Work-Planner.
- **Large changes** — if whole new features need to be added or the checklist structure needs significant changes, spawn the **Work-Planner** to update the checklist, then resume execution.
