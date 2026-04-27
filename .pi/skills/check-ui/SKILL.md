---
name: check-ui
description: rapid "test-as-you-go" verification of UI changes using Playwright to view the actual web frontend UI.
---

## Workflow
1. **Create a scratchpad test**: Write a focused Playwright test file. Keep it minimal and targeted at the current change.
   - **Public frontend**: `output/frontend/__tests__/playwright/<test_name>.spec.ts`
   - **Admin app**: `banknote-trading-admin/tests/scratchpad/<test_name>.spec.ts`
2. **Execute the check**: Run `.claude/skills/check-ui/check-ui.sh <test_name> [test_dir]`.
   - **From your project directory** (looks in current directory): `.claude/skills/check-ui/check-ui.sh crud`
   - **From anywhere** (explicit path): `.claude/skills/check-ui/check-ui.sh crud banknote-trading-admin/tests/scratchpad`
3. **Verify results**: Check the terminal output to confirm the UI behaves as expected.
4. **Cleanup**: Delete the test file once the verification is complete.

## Guidelines
- Use this for iterative development and bug fixing, not for formal regression testing.
- Playwright will automatically build (`npm run build`) and serve the production static site before running tests.
- This ensures tests run against the actual production build, catching issues like missing `output: 'export'` config.
- Focus on a single behavior or edge case per scratchpad test to keep the loop fast.
- Note: First run will be slower (build time ~30-60s), subsequent runs reuse the existing server if already running.
- **Two modes**:
  - Pass only `<test_name>` to search in the **current directory** (run from your test directory).
  - Pass `<test_name> <test_dir>` to specify an **explicit path** (run from anywhere).
- The script auto-discovers `playwright.config.ts` by walking up from the test directory to find the project root.
