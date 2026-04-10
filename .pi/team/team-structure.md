# Team Structure

## Tech-Lead
- responsible for spawning agents and coordinating work

## Test-Writer
- responsible for taking each subtask and writing tests that cover the required functionality, even if the code doesn't compile

## Developer
- responsible for doing actual developer work and code implementations in line with TODO checklist items, doing the minimal code change that passes the tests

## QA-Reviewer
- responsible for ensuring that tests:
    - are robust
    - are appropriate and meaningful
    - do not short-circuit implementation (e.g. `assertTrue(true)`) just for code coverage

- responsible for reviewing that the code implementation:
    - aligns with requirement from TODO markdown checklist file
    - passes all tests that are intended to pass
    - has excellent code quality
    - has appropriate naming conventions

- responsible for ticking off TODO work items, and deleting completed TODO markdown lists

# Team Workflow
1. Tech-lead receives task
2. Tech-Lead spawns Test-Writer
3. Test-Writer reads in-progress TODO checklists, and observed next task with an un-ticked box in the "Test Written" box, and writes tests
4. Once tests are written, Test-Writer ticks the "Test Written" box for that task and informs Tech-Lead that work is finished
5. Tech-Lead de-spawns Test-Writer
6. Tech-Lead spawns Developer
7. Developer reads in-progress TODO checklists, and observes next task ticked with "Test Written" but un-ticked "Code Implemented" box, and performs developer work to perform code
8. Once the code is implemented, Developer ticks the "Code Implemented" box, and informs Tech-Lead that work is finished
9. Tech-Lead de-spawns Developer
10. Tech-Lead spawns QA-Reviewer
11. QA-Reviewer reads in-progress TODO checklists, and observes next task ticked with "Test Written" and "Code Implemented" but un-ticked with "QA Reviewed", and reviews tests and code implementation for this task
12. When QA-Reviewer finishes with review, if there are changes to be made, QA-Reviewer should untick either the "Test Written" box or the "Code Implemented" box (as appropriate) and add to the checklist with more details. If the tests and code implementations look good, then QA-Reviewer ticks the "QA Reviewed" box.
**IMPORTANT** Repeat steps (2) - (12) until entire TODO checklist is completed.
