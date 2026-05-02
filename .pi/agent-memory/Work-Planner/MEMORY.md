# Work-Planner Memory

## Task Decomposition Learnings

- Checklists should use the 3-column tickable table format exclusively for actionable steps
- Sub-tasks must be small enough for one agent session (~1-2 hours max)
- Each checklist file must follow the naming convention: `YYYY-MM-DD-<number>-<title>.md`
- Always include the 3 phases: Tests Written → Code Implemented → QA Reviewed
- Reference existing project patterns (e.g. `ConvexClientProvider.tsx`) rather than reinventing
- When planning work that spans multiple projects (e.g. shared backend + new frontend), clearly label "Where:" for each phase
- Backward-compatibility should be called out explicitly (e.g. optional schema fields preserve existing data)
- Auth placeholder approach is preferred over half-implemented real auth when YAGNI applies
- Convex file storage integration is simpler than managing external S3/Cloudinary when already using Convex as the main backend
- Include a "swap-in guide" for future tech migrations (e.g. placeholder auth → Convex Auth)

## Project Context

- Banknote Trading: public frontend at `output/frontend/`, admin at `banknote-trading-admin/`
- Both share the same self-hosted Convex instance at `:3210` (API) / `:3211` (file storage site origin)
- Convex schema uses `banknotes` table with indexes `by_banknote_id`, `by_country`, `by_mostPopular`
- Schema has `imageUrl` (optional string) and `imageStorageId` (optional `_storage` id) fields
- 46 banknote images to migrate from `public/images/banknotes/` → Convex file storage (checklist 2026-04-26-2, Phases 5–8)
- Existing frontend pattern: `ConvexClientProvider.tsx` wraps children with `ConvexProvider`
- Admin has `uploadImageToConvex` in `lib/convex-upload.ts` for image upload flow
- Admin scaffold: Next.js 16, React 19, Tailwind CSS v4
- Public frontend: Next.js 14, React 18, Tailwind CSS v3 (static export with `images.unoptimized: true`)
- Admin auth is a placeholder; real Convex Auth integration deferred to future checklist
- Image storage tasks (migration, static removal, Next.js config, HTTP cache headers) are in `2026-04-26-2-convex-admin-backend.md`
- Frontend data caching tasks (LRU cache, useCachedQuery, TTL strategy) are in `2026-04-27-2-frontend-data-caching.md`
- Admin portal does NOT implement caching — always reads live data from Convex
- Client-side LRU cache: `lib/banknote-cache.ts` with `BanknoteLRUCache` (max 60, TTL 5min)
- Write-through semantics: Convex reactive subscriptions overwrite cache, not mutation hooks
- Convex storage images use `immutable` Cache-Control (content-addressed, never change at same storageId)
