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
- Creates checklist files in `docs/checklists/` with phases and sub-tasks
- Each sub-task has a 3-column tickable format (Tests Written | Code Implemented | QA Reviewed)

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
3. Work-Planner creates structured TODO checklist files in `docs/checklists/`
4. Work-Planner signals completion — checklist is ready

> **The Orchestrator workflow below assumes a checklist already exists.** Do not proceed if there is not a clear checklist to orchestrate work around.

### Phase 1: Checklist Execution Loop (Repeats for Each Sub-Task)

**The cycle always starts with Test-Writer.** For each sub-task in the checklist:

1. Orchestrator spawns **Test-Writer**
2. Test-Writer reads in-progress TODO checklists, finds next task with un-ticked "Test Written" box, and writes tests
3. Once tests are written, Test-Writer ticks the "Test Written" box for that task and informs Orchestrator that work is finished
4. Orchestrator de-spawns Test-Writer
5. Orchestrator spawns **Developer**
6. Developer reads in-progress TODO checklists, finds next task ticked with "Test Written" but un-ticked "Code Implemented" box, and performs developer work to implement code
7. Once the code is implemented, Developer ticks the "Code Implemented" box, and informs Orchestrator that work is finished
8. Orchestrator de-spawns Developer
9. Orchestrator spawns **QA-Reviewer**
10. QA-Reviewer reads in-progress TODO checklists, finds next task ticked with "Test Written" and "Code Implemented" but un-ticked "QA Reviewed", and reviews tests and code implementation
11. When QA-Reviewer finishes with review:
    - If there are changes to be made, QA-Reviewer should untick either the "Test Written" box or the "Code Implemented" box (as appropriate) and add to the checklist with more details.
    - If the tests and code implementations look good, then QA-Reviewer ticks the "QA Reviewed" box.
    - QA-Reviewer signals Orchestrator that review is finished
12. Orchestrator de-spawns QA-Reviewer

**IMPORTANT** Repeat steps (1) - (12) until entire TODO checklist is completed.

### Phase 2: Mid-Cycle Planning Updates (As Needed)

If during Phase 1, the QA-Reviewer or Orchestrator identifies that:
- A large piece of work is missing from the checklist
- A significant chunk of the checklist needs updates or additions

Then:
13. Orchestrator spawns **Work-Planner** to update the existing checklist with additions or edits
14. Work-Planner updates the checklist with the required changes
15. Work-Planner signals Orchestrator that work is finished
16. Orchestrator de-spawns Work-Planner
17. Resume Phase 1 from where it left off (or from the appropriate sub-task in the updated checklist)
