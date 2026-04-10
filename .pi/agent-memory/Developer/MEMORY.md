## Learnings and Solutions

### Project Structure
- Frontend code is located in `/workspace/output/frontend/`
- Components go in `/workspace/output/frontend/components/`
- Tests use Jest and are in `__tests__/` directory
- Utility functions are in `/workspace/output/frontend/lib/utils.ts`

### Component Implementation Patterns
- Use `'use client'` directive for client-side components
- Import types from `@/types/banknote`
- Import utilities from `@/lib/utils`
- Use TailwindCSS for styling
- Follow existing styling patterns (font-serif, text-foreground, etc.)

### Title Truncation Logic
- The `truncateTitle` utility returns `{line1, line2, wasTruncated}`
- For single-line titles, line2 is empty string
- Use non-breaking space (`\u00A0`) for empty line2 to maintain height
- Fixed height container (`h-[3.5rem]`) ensures consistent card alignment

## User Preferences

### Code Style
- Minimal implementation to pass current tests only
- Follow existing component patterns in BanknoteCard.tsx
- Use same TailwindCSS classes for consistency

### Architecture
- Create separate reusable components (BanknoteCardContent)
- Support optional onClick prop for future modal functionality
- Preserve event bubbling behavior (stopPropagation on Link click)
