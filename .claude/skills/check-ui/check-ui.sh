#!/bin/bash
# Quick UI check script for "test-as-you-go" development
# Usage: ./scripts/check-ui.sh [test_name]

set -e

# Ensure the dev server is running (assuming localhost:3000)
# If not running, this will fail quickly.
if ! curl -s http://localhost:3000 > /dev/null; then
  echo "Error: Dev server is not running at http://localhost:3000"
  echo "Please start the server before running UI checks."
  exit 1
fi

TEST_NAME=$1

if [ -z "$TEST_NAME" ]; then
  echo "Usage: ./scripts/check-ui.sh <test_name>"
  echo "Example: ./scripts/check-ui.sh my-feature"
  echo "This will run tests/scratchpad/${TEST_NAME}.spec.ts"
  exit 1
fi

FILE="tests/scratchpad/${TEST_NAME}.spec.ts"

if [ ! -f "$FILE" ]; then
  echo "Error: Test file $FILE not found."
  exit 1
fi

echo "Running quick check: $TEST_NAME..."
npx playwright test "$FILE" --project=chromium --reporter=line
