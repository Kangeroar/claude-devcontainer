# check-ui
Use this skill to perform rapid "test-as-you-go" verification of UI changes using Playwright.

## Workflow
1. **Create a scratchpad test**: Write a focused Playwright test file in `tests/scratchpad/<test_name>.spec.ts`. Keep it minimal and targeted at the current change.
2. **Execute the check**: Run `.claude/skills/check-ui/check-ui.sh <test_name>`.
3. **Verify results**: Check the terminal output to confirm the UI behaves as expected.
4. **Cleanup**: Delete the test file from `tests/scratchpad/` once the verification is complete.

## Guidelines
- Use this for iterative development and bug fixing, not for formal regression testing.
- Ensure the local dev server is running at `http://localhost:3000` before running the script.
- Focus on a single behavior or edge case per scratchpad test to keep the loop fast.
