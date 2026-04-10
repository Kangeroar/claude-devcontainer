# Test-Writer Agent Memory

## Project: Banknote Trading Frontend

### Testing Patterns Learned

**File-Based Testing Approach:**
- This project uses a file-based testing pattern with Node.js `fs` module
- Tests verify file existence and content using regex patterns
- Tests run in Node.js environment (not browser/JSdom)
- Pattern: Read file content, then assert against expected content using regex

**Test File Location:**
- All tests are in `__tests__/` directory at project root
- Test files use `.test.ts` extension (not `.test.tsx`)
- Jest configuration in `jest.config.js` specifies:
  - `testMatch: ['**/*.test.ts']`
  - `testEnvironment: 'node'`

**Common Test Patterns:**
1. Define project root: `path.resolve(__dirname, '..')`
2. Use `beforeAll` to read file content once per describe block
3. Handle missing files gracefully (set content to empty string)
4. Use regex for flexible content matching

**Key Testing Libraries:**
- `@jest/globals` for Jest functions (describe, it, expect, beforeAll)
- Node.js built-in `fs` and `path` modules for file operations

### Project Structure

**Frontend Location:** `/workspace/output/frontend/`
**Tech Stack:** Next.js 14, TypeScript, TailwindCSS, Jest
**App Router:** Using Next.js App Router (app/ directory)

### Testing Checklist Updates

When completing test writing:
1. Mark `[~]` as `[x]` in checklist for "Tests Written" column
2. Create worklog in `docs/worklogs/YYYY-MM-DD-<number>-<task_name>.md`
3. Commit changes with conventional commit format (feat: or test:)

### Footer Component Requirements

The Footer component tests verify:
- File structure (Footer.tsx in components/)
- Component imports (React, next/link)
- Copyright text with year and Banknote Trading branding
- Navigation links (Home, Browse, About Us, eBay)
- External eBay store link with target="_blank" and rel="noopener noreferrer"
- Tailwind classes for responsive layout and styling
- Contact information section
- Semantic footer element
- Accessibility (aria-label, semantic navigation)

### Layout Component Requirements

The Layout component tests verify:
- File structure (layout.tsx in app/)
- TypeScript types (children: React.ReactNode)
- HTML structure (html, body elements)
- SEO (Metadata export, title, description)
- Tailwind classes (min-h-screen, flex, flex-col, bg-)
- Font loading (next/font/google)
- Accessibility (lang attribute, semantic HTML)
- Server component (no 'use client' directive)
