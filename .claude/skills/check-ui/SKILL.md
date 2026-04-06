# check-ui
Use this skill to perform rapid "test-as-you-go" verification of UI changes using Playwright.

## Workflow
1. **Create a scratchpad test**: Write a focused Playwright test file in `output/frontend/__tests__/playwright/<test_name>.spec.ts`. Keep it minimal and targeted at the current change.
2. **Execute the check**: Run `.claude/skills/check-ui/check-ui.sh <test_name>`.
3. **Verify results**: Check the terminal output to confirm the UI behaves as expected.
4. **Cleanup**: Delete the test file from `output/frontend/__tests__/playwright/` once the verification is complete.

## Guidelines
- Use this for iterative development and bug fixing, not for formal regression testing.
- Playwright will automatically build (`npm run build`) and serve the production static site before running tests.
- This ensures tests run against the actual production build, catching issues like missing `output: 'export'` config.
- Focus on a single behavior or edge case per scratchpad test to keep the loop fast.
- Note: First run will be slower (build time ~30-60s), subsequent runs reuse the existing server if already running.
