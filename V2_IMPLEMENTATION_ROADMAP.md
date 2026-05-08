# BestBrowser V2 Implementation Roadmap

This document turns [V2_PLAN.md](/Users/jeremymcvay/dev/bestbrowser-native/V2_PLAN.md) into an execution roadmap with schema changes, UI milestones, technical tasks, and an MVP cut.

## Goal

Ship a V2 MVP that makes BestBrowser meaningfully better at:

- organizing work by goal
- summarizing sessions across many tabs
- remembering what matters
- comparing sources and pages
- monitoring pages for change

## V2 MVP Definition

The smallest compelling V2 should include:

1. Workspace Sessions
2. Session Briefing
3. Cross-Tab Compare
4. Smart Memory
5. Basic Watch Mode

Nice-to-have but deferrable:

- full action extraction pipeline
- encrypted cloud sync
- collaboration
- voice features

## Recommended Delivery Order

1. Data foundation
2. Workspace model and UI
3. Session briefing
4. Cross-tab compare
5. Smart memory
6. Watch mode
7. Action extraction

That order keeps the work incremental and lets each phase reuse the previous one’s data structures.

## Phase 0: Foundation Cleanup

Purpose:

- prepare current V1 code for V2 feature growth

Tasks:

- centralize page text extraction from `WKWebView`
- centralize page metadata extraction:
  - title
  - canonical URL
  - favicon
  - host
  - timestamp
- introduce a shared page-analysis pipeline service
- standardize async AI request helpers around `AIClient`
- add better error types for:
  - AI unavailable
  - extraction failure
  - persistence failure

Suggested files:

- new: `BestBrowser/AI/PageAnalysisService.swift`
- new: `BestBrowser/Models/WorkspaceModels.swift`
- new: `BestBrowser/Services/WorkspaceService.swift`

## Schema Changes

These tables are the core V2 storage additions.

### `workspaces`

- `id INTEGER PRIMARY KEY`
- `uuid TEXT UNIQUE NOT NULL`
- `title TEXT NOT NULL`
- `purpose TEXT`
- `summary TEXT`
- `status TEXT NOT NULL`
- `created_at INTEGER NOT NULL`
- `updated_at INTEGER NOT NULL`
- `last_opened_at INTEGER`

### `workspace_tabs`

- `id INTEGER PRIMARY KEY`
- `workspace_id INTEGER NOT NULL`
- `url TEXT NOT NULL`
- `title TEXT`
- `favicon_url TEXT`
- `note TEXT`
- `added_at INTEGER NOT NULL`
- `last_seen_at INTEGER`

### `page_memory`

- `id INTEGER PRIMARY KEY`
- `url TEXT NOT NULL`
- `normalized_url TEXT NOT NULL`
- `title TEXT`
- `host TEXT`
- `summary TEXT`
- `takeaway TEXT`
- `keywords TEXT`
- `last_visited_at INTEGER NOT NULL`
- `visit_count INTEGER DEFAULT 1`

### `workspace_briefs`

- `id INTEGER PRIMARY KEY`
- `workspace_id INTEGER NOT NULL`
- `brief_type TEXT NOT NULL`
- `content TEXT NOT NULL`
- `created_at INTEGER NOT NULL`

### `compare_sessions`

- `id INTEGER PRIMARY KEY`
- `workspace_id INTEGER`
- `title TEXT`
- `source_urls TEXT NOT NULL`
- `result_markdown TEXT`
- `created_at INTEGER NOT NULL`

### `watch_rules`

- `id INTEGER PRIMARY KEY`
- `uuid TEXT UNIQUE NOT NULL`
- `url TEXT NOT NULL`
- `title TEXT`
- `watch_type TEXT NOT NULL`
- `prompt TEXT`
- `status TEXT NOT NULL`
- `last_checked_at INTEGER`
- `created_at INTEGER NOT NULL`

### `watch_snapshots`

- `id INTEGER PRIMARY KEY`
- `watch_rule_id INTEGER NOT NULL`
- `content_hash TEXT NOT NULL`
- `summary TEXT`
- `change_summary TEXT`
- `created_at INTEGER NOT NULL`

## Domain Models

Add these Swift models first:

- `Workspace`
- `WorkspaceStatus`
- `WorkspaceTab`
- `PageMemory`
- `WorkspaceBrief`
- `CompareSession`
- `WatchRule`
- `WatchSnapshot`

Keep them GRDB-compatible from day one.

## UI Milestones

### Milestone 1: Workspace Shell

User-facing result:

- user can create, rename, open, and delete workspaces
- user can save current session into a workspace

UI work:

- add “Workspaces” tab to sidebar
- add workspace list view
- add workspace detail panel
- add “Save Session to Workspace” action

Suggested files:

- new: `BestBrowser/UI/WorkspaceSidebarView.swift`
- new: `BestBrowser/UI/WorkspaceDetailView.swift`

### Milestone 2: Session Briefing

User-facing result:

- user can click “Brief This Session”
- browser returns a compact summary of what open tabs contain

UI work:

- add session briefing card to new-tab home
- add session briefing action in command palette
- show brief with cited tabs

Suggested files:

- new: `BestBrowser/AI/SessionBriefingService.swift`
- new: `BestBrowser/UI/SessionBriefView.swift`

### Milestone 3: Cross-Tab Compare

User-facing result:

- user can compare selected tabs
- browser highlights similarities, differences, and key factors

UI work:

- add tab selection mode
- add “Compare Tabs” action
- add compare result surface with sections and citations

Suggested files:

- new: `BestBrowser/UI/CompareTabsView.swift`
- new: `BestBrowser/AI/CompareService.swift`

### Milestone 4: Smart Memory

User-facing result:

- search can retrieve prior pages by meaning, not just title/url

UI work:

- add memory results to search sidebar
- add saved takeaways to page revisit flows
- add lightweight note/takeaway editor

Suggested files:

- new: `BestBrowser/AI/PageMemoryService.swift`
- new: `BestBrowser/UI/PageMemoryView.swift`

### Milestone 5: Watch Mode

User-facing result:

- user can watch a page and get meaningful change summaries

UI work:

- add “Watch This Page” action
- add watch list UI
- show change summaries and timestamps

Suggested files:

- new: `BestBrowser/Monitoring/WatchService.swift`
- new: `BestBrowser/UI/WatchListView.swift`

## Technical Task Breakdown

### A. Workspace Infrastructure

- create GRDB migrations for new tables
- add `WorkspaceService`
- implement:
  - create workspace
  - rename workspace
  - delete workspace
  - add/remove tabs
  - save current session
  - reopen workspace session

### B. Shared Page Extraction

- centralize extraction of:
  - visible text
  - metadata
  - simplified text
- create page snapshot object:
  - `url`
  - `title`
  - `host`
  - `text`
  - `faviconURL`
  - `capturedAt`

### C. AI Pipelines

- `SessionBriefingService`
  - inputs: open tabs or workspace tabs
  - outputs: summary, themes, duplicates, next steps

- `CompareService`
  - inputs: selected page snapshots
  - outputs: structured compare markdown

- `PageMemoryService`
  - inputs: page snapshot
  - outputs: summary, keywords, takeaway

- `WatchService`
  - inputs: watch rule + latest snapshot
  - outputs: meaningful change summary

### D. Search Evolution

- extend current search index
- merge semantic memory results with:
  - history
  - bookmarks
  - indexed pages
- support “memory” result type

### E. Monitoring Infrastructure

- define watch rule types:
  - generic content change
  - price change
  - issue status change
  - release notes update
- store snapshots and hashes
- schedule checks via app automation later if desired

## AI/ML Feature Details

### Session Briefing Prompt Shape

Input:

- titles
- URLs
- extracted text snippets

Output:

- top themes
- important pages
- duplicates
- unresolved questions
- next actions

### Compare Prompt Shape

Input:

- selected tab snapshots

Output:

- overview
- comparison factors
- agreements
- disagreements
- strongest sources

### Memory Prompt Shape

Input:

- page text

Output:

- 2-3 sentence summary
- 1 sentence takeaway
- short keyword list

### Watch Mode Prompt Shape

Input:

- previous snapshot summary
- current snapshot summary

Output:

- “meaningful change” yes/no
- concise change summary
- priority classification

## MVP Cut List

If V2 scope starts slipping, cut in this order:

1. advanced compare formatting
2. page note editing
3. multiple watch rule types
4. action extraction
5. workspace sharing

Do not cut:

- workspaces
- session briefing
- compare
- memory foundation

Those are the product.

## Suggested Milestones by Build

### Build 1

- schema migrations
- workspace model
- workspace CRUD
- save/open session

### Build 2

- session briefing pipeline
- workspace summary cards
- command palette integration

### Build 3

- compare selected tabs
- compare result view
- save compare sessions

### Build 4

- memory summaries
- memory-backed search
- page takeaways

### Build 5

- watch rules
- snapshot storage
- change summaries

## Acceptance Criteria

### Workspace Sessions

- user can save open tabs into a named workspace
- reopening workspace restores tabs and summary context

### Session Briefing

- user gets a short useful brief from current tabs
- brief references real tabs and themes

### Compare

- user can compare at least 2 selected tabs
- result is readable and source-linked

### Smart Memory

- user can retrieve a previously visited page by semantic intent

### Watch Mode

- user can mark a page for watching
- browser can store at least one change summary against that watch

## Engineering Notes

- keep AI outputs cacheable where possible
- preserve graceful fallback when Apple Intelligence is unavailable
- keep all V2 features useful even with partial AI degradation
- do not over-couple workspace UI to one storage layout
- prioritize evidence-linked summaries over confident but opaque prose

## Immediate Next Task Recommendation

Start with:

1. `WorkspaceModels.swift`
2. GRDB migrations in `StorageManager`
3. `WorkspaceService.swift`
4. basic `WorkspaceSidebarView.swift`

That unlocks the rest of V2 without wasted UI work.
