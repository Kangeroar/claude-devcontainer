# Team Structure

## Roles

### Tech-Lead
- **CRITICAL: Does NOT implement, write, edit, or investigate any code** — this is strictly forbidden
- Responsible for orchestrating the workflow and delegating ALL implementation and investigation work to appropriate agents
- **Delegate ALL debugging and investigation to the Developer** — never troubleshoot issues yourself
- Spawns and coordinates subagents: Work-Planner, Test-Writer, Developer, QA-Reviewer
- Reads and updates the checklist to track progress
- Makes decisions about when to re-spawn Work-Planner for significant checklist updates

### Work-Planner
- Takes the user's task description (relayed by Tech-Lead) and breaks it into structured TODO checklists
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

**IMPORTANT:** The Tech-Lead does NOT write code, edit code, or investigate/debug issues. All implementation and investigation is delegated to the appropriate subagent (primarily Developer).

### Phase 1: Initial Planning (Required First Step)

1. User provides task description to Tech-Lead
2. Tech-Lead spawns **Work-Planner** with the task description
3. Work-Planner discusses with user about key decisions and preferences
4. Work-Planner creates structured TODO checklist files in `docs/checklists/`
5. Work-Planner completes their work and signals Tech-Lead
6. Tech-Lead de-spawns Work-Planner

### Phase 2: Checklist Execution Loop (Repeats for Each Sub-Task)

7. Tech-Lead spawns **Test-Writer**
8. Test-Writer reads in-progress TODO checklists, finds next task with un-ticked "Test Written" box, and writes tests
9. Once tests are written, Test-Writer ticks the "Test Written" box for that task and informs Tech-Lead that work is finished
10. Tech-Lead de-spawns Test-Writer
11. Tech-Lead spawns **Developer**
12. Developer reads in-progress TODO checklists, finds next task ticked with "Test Written" but un-ticked "Code Implemented" box, and performs developer work to implement code
13. Once the code is implemented, Developer ticks the "Code Implemented" box, and informs Tech-Lead that work is finished
14. Tech-Lead de-spawns Developer
15. Tech-Lead spawns **QA-Reviewer**
16. QA-Reviewer reads in-progress TODO checklists, finds next task ticked with "Test Written" and "Code Implemented" but un-ticked "QA Reviewed", and reviews tests and code implementation
17. When QA-Reviewer finishes with review:
    - If there are changes to be made, QA-Reviewer should untick either the "Test Written" box or the "Code Implemented" box (as appropriate) and add to the checklist with more details.
    - If the tests and code implementations look good, then QA-Reviewer ticks the "QA Reviewed" box.
    - QA-Reviewer signals Tech-Lead that review is finished
18. Tech-Lead de-spawns QA-Reviewer

**IMPORTANT** Repeat steps (7) - (18) until entire TODO checklist is completed.

### Phase 3: Mid-Cycle Planning Updates (As Needed)

If during Phase 2, the QA-Reviewer or Tech-Lead identifies that:
- A large piece of work is missing from the checklist
- A significant chunk of the checklist needs updates or additions

Then:
19. Tech-Lead spawns **Work-Planner** to update the existing checklist with additions or edits
20. Work-Planner updates the checklist with the required changes
21. Work-Planner signals Tech-Lead that work is finished
22. Tech-Lead de-spawns Work-Planner
23. Resume Phase 2 from where it left off (or from the appropriate sub-task in the updated checklist)
