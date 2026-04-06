# LLM Wiki Schema

This document defines the structure, conventions, and workflows for maintaining this personal knowledge base. The LLM (Claude) owns the wiki layer; the human owns the sources and direction.

---

## Architecture Overview

## Directory Structure

```
/
├── raw/               # Immutable source documents (articles, papers, notes, images)
│   ├── articles/
│   ├── books/
│   ├── notes/
│   └── assets/
├── wiki/              # LLM-generated markdown files (summaries, entities, concepts)
│   ├── sources/
│   ├── entities/
│   ├── concepts/
│   ├── syntheses/
│   └── overview.md
├── docs/              # Documentation, worklogs, diagrams
│   ├── worklogs/
│   └── diagrams/
├── CLAUDE.md          # Wiki schema (this is the rulebook)
├── index.md           # Content-oriented catalog of all wiki pages
└── log.md             # Activity log - chronological record of all operations
```
---

## Directory Conventions

### raw/ — Source of Truth
- **Rule**: Files here are IMMUTABLE. The LLM reads but never modifies.
- **Structure**:
  - `raw/articles/` — Web articles, PDFs, papers
  - `raw/books/` — Book chapters or excerpts
  - `raw/notes/` — Personal notes, journal entries
  - `raw/assets/` — Images, diagrams, attachments
- **Naming**: Use descriptive filenames: `2026-04-06-article-slug.md` or `book-title-chapter-03.md`
- **Frontmatter**: Sources should include YAML frontmatter with metadata:
  ```yaml
  ---
  title: "Article Title"
  source: "https://example.com/article"
  date_added: "2026-04-06"
  type: "article"  # article | book | paper | note | image
  tags: ["tag1", "tag2"]
  ---
  ```

### wiki/ — The Knowledge Base
- **Rule**: The LLM owns this directory entirely. Creates, updates, deletes pages.
- **Structure**:
  - `wiki/sources/` — Source summaries (one per raw source)
  - `wiki/entities/` — People, organizations, places, works
  - `wiki/concepts/` — Ideas, theories, frameworks, definitions
  - `wiki/syntheses/` — Comparisons, analyses, deep dives
  - `wiki/overview.md` — High-level map of the knowledge domain
- **Frontmatter**: All wiki pages must include:
  ```yaml
  ---
  title: "Page Title"
  type: "entity"  # source | entity | concept | synthesis
  created: "2026-04-06"
  modified: "2026-04-06"
  source_count: 1  # Number of sources contributing to this page
  tags: ["tag1", "tag2"]
  ---
  ```

### docs/ — Project Documentation
- `docs/worklogs/` — Daily work logs (YYYY-MM-DD-N-task_name.md)
- `docs/diagrams/` — LikeC4 architecture diagrams
- `docs/GEMINI.md` — High-level project documentation (not a work log)

---

## Page Types & Formats

### Source Summary (`wiki/sources/*.md`)
One page per ingested source. Captures the essence.

```markdown
---
title: "Source Title"
type: source
created: "2026-04-06"
modified: "2026-04-06"
source_count: 1
tags: ["topic", "author"]
---

# Source Title

**Original**: [link or reference]
**Date Added**: 2026-04-06
**Source Type**: article

## Key Takeaways
- Bullet points of main ideas
- Important claims or findings

## Detailed Summary
Paragraph form summary...

## Entities Mentioned
- [[Entity Name]] — brief description
- [[Another Entity]] — brief description

## Concepts Covered
- [[Concept Name]] — brief description

## Quotes
> "Notable quote from source" (p. 42)

## Questions Raised
- Question that this source brings up?

## Connections
- Related: [[Other Source]]
- Contradicts: [[Conflicting Source]]
- Supports: [[Related Concept]]
```

### Entity Page (`wiki/entities/*.md`)
Pages for people, organizations, places, works.

```markdown
---
title: "Entity Name"
type: entity
created: "2026-04-06"
modified: "2026-04-06"
source_count: 2
tags: ["person", "field"]
---

# Entity Name

**Type**: Person | Organization | Place | Work
**First Mentioned**: [[Source Name]]

## Overview
Brief description of who/what this is...

## Key Information
- Attribute: value
- Attribute: value

## Appears In
- [[Source 1]] — context of mention
- [[Source 2]] — context of mention

## Related Entities
- [[Related Person]] — relationship
- [[Related Organization]] — relationship

## Evolution of Understanding
- *[2026-04-06]*: Initial understanding from [[Source 1]]
- *[2026-04-07]*: Updated understanding from [[Source 2]] - contradicts previous claim about X
```

### Concept Page (`wiki/concepts/*.md`)
Pages for ideas, theories, frameworks, definitions.

```markdown
---
title: "Concept Name"
type: concept
created: "2026-04-06"
modified: "2026-04-06"
source_count: 3
tags: ["framework", "psychology"]
---

# Concept Name

**Type**: Theory | Framework | Definition | Phenomenon
**First Defined**: [[Source Name]]

## Definition
Clear, concise definition...

## Explanation
Deeper explanation with examples...

## Sources Discussing This
- [[Source 1]] — definition and origin
- [[Source 2]] — application
- [[Source 3]] — critique

## Related Concepts
- [[Parent Concept]] — broader category
- [[Related Concept]] — similar/complementary
- [[Opposing Concept]] — contrasting view

## Evolution
- *[2026-04-06]*: Initial definition from [[Source 1]]
- *[2026-04-08]*: [[Source 2]] challenges the traditional view by...
```

### Synthesis Page (`wiki/syntheses/*.md`)
Comparisons, analyses, deep dives that combine multiple sources.

```markdown
---
title: "Synthesis Title"
type: synthesis
created: "2026-04-06"
modified: "2026-04-06"
source_count: 4
tags: ["comparison", "analysis"]
---

# Synthesis Title

**Question/Topic**: What is being explored?
**Sources**: [[Source 1]], [[Source 2]], [[Source 3]], [[Source 4]]

## Summary
Key findings in brief...

## Detailed Analysis
...

## Comparison Table
| Aspect | Source 1 | Source 2 | Source 3 |
|--------|----------|----------|----------|
| View   | X        | Y        | Z        |

## Tensions/Contradictions
- Source 1 claims X, but Source 2 argues Y

## Conclusion
...

## Filed
*[2026-04-06]* Created from query: "How do X and Y compare?"
```

---

## Workflows

### INGEST: Adding a New Source

When the human adds a source to `raw/` and requests ingestion:

1. **Read** the source file completely
2. **Discuss** key takeaways with the human (stay involved, guide emphasis)
3. **Create** `wiki/sources/<source-slug>.md` with full summary
4. **Extract** entities mentioned → create/update `wiki/entities/<entity>.md`
5. **Extract** concepts discussed → create/update `wiki/concepts/<concept>.md`
6. **Update** `wiki/overview.md` if this source changes high-level understanding
7. **Update** `index.md` with new/updated pages
8. **Log** the ingest in `log.md`
9. **Document** work in `docs/worklogs/YYYY-MM-DD-N-ingest.md`
10. **Update** diagrams in `docs/diagrams/` if architecture changed

**Principles during ingest**:
- Cross-reference aggressively: link to existing pages
- Flag contradictions with existing knowledge
- Update existing pages when new information arrives
- One source often touches 10-15 wiki pages

### QUERY: Answering Questions

When the human asks a question:

1. **Read** `index.md` to find relevant pages
2. **Read** the identified wiki pages
3. **Synthesize** an answer with citations (`[[Page Name]]`)
4. **Discuss** the answer with the human
5. **Ask**: "Should I file this as a synthesis page?"
   - If yes → create `wiki/syntheses/<synthesis-slug>.md`
   - Update `index.md` and `log.md`

**Output formats** (depending on question):
- Markdown response (default)
- Comparison table
- Slide deck (Marp format)
- Chart/diagram (matplotlib or LikeC4)

### LINT: Health-Checking the Wiki

Run periodically (suggest weekly or after every ~10 sources):

1. **Contradictions**: Scan for conflicting claims across pages
2. **Stale claims**: Identify claims superseded by newer sources
3. **Orphans**: Find pages with no inbound links
4. **Missing pages**: Identify important concepts mentioned but not paged
5. **Missing cross-references**: Find mentions that should be links
6. **Data gaps**: Suggest web searches or new sources to fill gaps
7. **Log** the lint pass and findings in `log.md`

---

## Cross-Reference Conventions

- **WikiLinks**: Use `[[Page Name]]` for internal links
- **Aliases**: Use `[[Page Name|display text]]` when needed
- **Sections**: Use `[[Page Name#Section]]` for specific sections
- **Backlinks**: Every page should have an "Appears In" or "Referenced By" section

---

## Index Format (`index.md`)

```markdown
# Wiki Index

*Last updated: 2026-04-06*

## Sources (12)
- [[source/article-name]] — One-line summary (2026-04-06, article)
- [[source/another-source]] — One-line summary (2026-04-05, book)

## Entities (8)
- [[entity/person-name]] — One-line description (2 sources)
- [[entity/organization]] — One-line description (1 source)

## Concepts (5)
- [[concept/framework]] — One-line description (3 sources)

## Syntheses (2)
- [[synthesis/comparison]] — One-line description (4 sources)

## Tags
- #psychology (5 pages)
- #ai (4 pages)
- #productivity (3 pages)
```

---

## Log Format (`log.md`)

```markdown
# Wiki Log

## [2026-04-06] ingest | Article Title
- Added: wiki/sources/article-title.md
- Updated: wiki/entities/author-name.md, wiki/concepts/key-concept.md
- Notes: Interesting finding about X

## [2026-04-06] query | How does X relate to Y?
- Created: wiki/syntheses/x-y-comparison.md
- Sources used: 3

## [2026-04-05] lint | Weekly health check
- Found: 2 orphan pages, 1 contradiction
- Fixed: Added cross-references to orphan pages
- Flagged: Contradiction between [[Source A]] and [[Source B]] regarding X
```

---

## Human ↔ LLM Interaction Patterns

**Human responsibilities**:
- Curate sources (add to `raw/`, ensure good filenames and frontmatter)
- Direct analysis (ask questions, guide emphasis)
- Review outputs (read summaries, check updates)
- Make judgment calls (on contradictions, what to prioritize)

**LLM responsibilities**:
- All wiki maintenance (create, update, cross-reference)
- Summarization and synthesis
- Bookkeeping (logging, indexing)
- Flagging issues (contradictions, gaps, orphans)

**Typical session flow**:
1. Human adds source to `raw/`
2. Human: "Ingest the new article"
3. LLM: reads source, discusses takeaways, creates/updates wiki pages
4. Human reviews in Obsidian, asks follow-up questions
5. LLM answers, optionally files as synthesis
6. Both agree when to run lint pass

---

## Tips & Best Practices

- **Stay involved during ingest**: Don't batch too many sources at once. Read summaries, guide emphasis.
- **Use Obsidian**: Open Obsidian on one side, Claude on the other. Browse the graph view.
- **Download images**: In Obsidian Settings → Files and links, set attachments to `raw/assets/`. Use Ctrl+Shift+D to download images locally.
- **Git commit**: The wiki is a git repo. Commit after significant operations.
- **Web Clipper**: Use Obsidian Web Clipper for quick article capture.
- **Dataview**: Consider the Dataview plugin for dynamic tables from frontmatter.

---

## Evolution

This schema is not fixed. As we learn what works:
- Update page templates
- Add new page types
- Refine workflows
- Document changes in `docs/worklogs/`

The goal: a compounding knowledge base where the maintenance burden approaches zero.
