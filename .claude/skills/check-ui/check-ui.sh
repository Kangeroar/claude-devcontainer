#!/bin/bash
# Quick UI check script for "test-as-you-go" development
# Usage: ./scripts/check-ui.sh [test_name]
#
# Note: Playwright will automatically build and serve the production static site.
# No need to manually start a dev server - see playwright.config.ts webServer config.

set -e

TEST_NAME=$1

if [ -z "$TEST_NAME" ]; then
  echo "Usage: ./scripts/check-ui.sh <test_name>"
  echo "Example: ./scripts/check-ui.sh my-feature"
  echo "This will run output/frontend/__tests__/playwright/${TEST_NAME}.spec.ts"
  exit 1
fi

FILE="output/frontend/__tests__/playwright/${TEST_NAME}.spec.ts"

if [ ! -f "$FILE" ]; then
  echo "Error: Test file $FILE not found."
  exit 1
fi

echo "Running quick check: $TEST_NAME..."
npx playwright test "$FILE" --project=chromium --reporter=line
