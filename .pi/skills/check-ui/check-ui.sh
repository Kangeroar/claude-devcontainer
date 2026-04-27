#!/bin/bash
# Quick UI check script for "test-as-you-go" development
# Usage: ./scripts/check-ui.sh <test_name> [test_dir]
#
# When only <test_name> is given, looks for <test_name>.spec.ts in the current
# directory. When <test_dir> is also given, looks in that directory instead.
#
# Examples:
#   ./scripts/check-ui.sh carousel-to-modal
#     → Looks for carousel-to-modal.spec.ts in current directory
#   ./scripts/check-ui.sh crud banknote-trading-admin/tests/scratchpad
#     → Looks for banknote-trading-admin/tests/scratchpad/crud.spec.ts
#
# Note: Playwright will automatically build and serve the production static site.
# No need to manually start a dev server - see playwright.config.ts webServer config.

set -e

TEST_NAME=$1

if [ -z "$TEST_NAME" ]; then
  echo "Usage: ./scripts/check-ui.sh <test_name> [test_dir]"
  echo ""
  echo "Examples:"
  echo "  ./scripts/check-ui.sh carousel-to-modal"
  echo "    → Looks for carousel-to-modal.spec.ts in current directory"
  echo ""
  echo "  ./scripts/check-ui.sh crud banknote-trading-admin/tests/scratchpad"
  echo "    → Looks for banknote-trading-admin/tests/scratchpad/crud.spec.ts"
  exit 1
fi

TEST_DIR=${2:-'.'}
SPEC_FILE="${TEST_DIR}/${TEST_NAME}.spec.ts"

if [ ! -f "$SPEC_FILE" ]; then
  echo "Error: Test file '$SPEC_FILE' not found."
  echo ""
  if [ -z "${2+x}" ]; then
    echo "No <test_dir> was provided. Either:"
    echo "  1. Run from the directory containing your .spec.ts file, or"
    echo "  2. Provide the path explicitly:"
    echo "       ./.pi/skills/check-ui/check-ui.sh $TEST_NAME <path/to/tests>"
    echo ""
    echo "     For example:"
    echo "       ./.pi/skills/check-ui/check-ui.sh carousel-to-modal output/frontend/__tests__/playwright"
    echo "       ./.pi/skills/check-ui/check-ui.sh crud banknote-trading-admin/tests/scratchpad"
  fi
  exit 1
fi

# Resolve TEST_DIR to an absolute path to avoid dirname(".") loop
ABSOLUTE_DIR="$(cd "$(dirname "$SPEC_FILE")" && pwd)"

# Walk up looking for playwright config (max 10 levels to prevent runaway)
SEARCH_DIR="$ABSOLUTE_DIR"
MAX_DEPTH=10
DEPTH=0
while [ "$SEARCH_DIR" != '/' ] && [ $DEPTH -lt $MAX_DEPTH ]; do
  for EXT in ts js mjs; do
    if [ -f "$SEARCH_DIR/playwright.config.$EXT" ]; then
      PROJECT_ROOT="$SEARCH_DIR"
      break 2
    fi
  done
  SEARCH_DIR="$(dirname "$SEARCH_DIR")"
  DEPTH=$((DEPTH + 1))
done

if [ -z "$PROJECT_ROOT" ]; then
  PROJECT_ROOT="$ABSOLUTE_DIR"
  echo "Warning: No playwright.config.ts found. Using test directory."
fi

# Build relative path from project root to spec file
RELATIVE_PATH="${SPEC_FILE#$PROJECT_ROOT/}"
# If SPEC_FILE is absolute but PROJECT_ROOT is relative, try with absolute
if [ "$RELATIVE_PATH" = "$SPEC_FILE" ]; then
  ABS_SPEC="$(cd "$(dirname "$SPEC_FILE")" && pwd)/$(basename "$SPEC_FILE")"
  RELATIVE_PATH="${ABS_SPEC#$PROJECT_ROOT/}"
fi

echo "Running quick check: $TEST_NAME..."
(cd "$PROJECT_ROOT" && npx playwright test "$RELATIVE_PATH" --project=chromium --reporter=line)
