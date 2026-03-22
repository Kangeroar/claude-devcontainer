---
name: assertNull private helper instead of import
description: Test files sometimes define a private assertNull helper function instead of adding the import — minor style issue, not a correctness blocker
type: feedback
---

In P2pSocketServerTest.kt, `assertNull` was defined as a private helper delegating to `org.junit.Assert.assertNull` because the import was missing. This is a style issue only — the tests function correctly. Flag it as a minor note but do not fail the review for it.

**Why:** The missing import was likely an oversight during test writing. The workaround is functional.

**How to apply:** When reviewing tests, if you see a private helper that just delegates to a standard assertion, note it as a minor style issue but do not untick boxes.
