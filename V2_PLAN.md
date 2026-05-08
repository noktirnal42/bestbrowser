# BestBrowser V2 Plan

BestBrowser V2 should make the browser feel like an intelligent private workspace, not just a tab container with an assistant attached.

The core product bet:

- people do not want “AI in a browser”
- people want help finishing tasks across many pages
- the browser should understand goals, memory, and synthesis
- privacy and on-device intelligence should be the default, not an afterthought

## Product Vision

BestBrowser V2 becomes a goal-aware browser that can:

- understand why a set of tabs exists
- preserve context across sessions
- summarize and compare information across tabs
- reduce tab overload
- turn browsing into action

The browser should feel like:

- a research assistant
- a project memory layer
- a private synthesis engine
- a task finisher

## What Browsers Still Miss

Current browsers are good at:

- loading pages
- syncing tabs
- keeping bookmarks
- searching history

Current browsers are weak at:

- understanding user intent
- remembering why a tab matters
- synthesizing across many tabs
- managing overload intelligently
- extracting action items from the web
- monitoring pages for meaningful change

That gap is BestBrowser’s opening.

## V2 Principles

1. On-device first

- default AI and memory operations should run locally when possible
- cloud features should be optional and explicit
- user trust is product surface, not just policy

2. Goal-aware by default

- a browser session should map to a task, project, or question
- tabs should be grouped around user intent, not just windows

3. Cross-tab intelligence is the killer feature

- the real value is not page chat
- the real value is synthesis, comparison, clustering, and progress across many sources

4. Action over novelty

- every AI feature should either save time, reduce confusion, or help finish something
- avoid gimmicks that look impressive but do not change workflow

5. Explainability matters

- summaries should cite pages
- comparisons should link to evidence
- suggestions should be inspectable

## Primary User Jobs

### Research

- “I’m researching a product, tool, or topic”
- “Help me compare, deduplicate, summarize, and decide”

### Planning

- “I’m planning a trip, purchase, project, or event”
- “Keep related pages organized and extract next steps”

### Knowledge Work

- “I’m reading docs, specs, articles, and issue threads”
- “Turn this session into memory, action items, and a brief”

### Monitoring

- “I care when this page changes”
- “Watch this and tell me what matters”

## V2 Feature Pillars

### 1. Workspace Sessions

Purpose:
- replace loose tab piles with goal-based workspaces

What it does:
- save a session as a workspace with title, purpose, tags, and summary
- auto-suggest workspace names from open tabs
- let users reopen a workspace with tabs, notes, and AI memory
- show “what changed since last session”

Why it matters:
- users do not think in tabs, they think in tasks

Example:
- “Japan Trip Planning”
- “Swift Package Networking Bug”
- “Espresso Machine Research”

### 2. Session Briefing

Purpose:
- give users a quick understanding of what is open and why it matters

What it does:
- summarize all open tabs into one short brief
- identify repeated sources and duplicates
- show major themes and unresolved questions
- generate a “next best actions” list

Why it matters:
- tab overload is often comprehension overload

Example outputs:
- “You have 12 tabs across 3 themes: pricing, reviews, and setup guides.”
- “3 tabs are duplicates, 2 are best for technical depth, 1 contains the final purchasing details.”

### 3. Cross-Tab Compare

Purpose:
- compare multiple pages directly inside the browser

What it does:
- compare products, docs, articles, policies, or sources
- extract structured dimensions automatically
- highlight agreements, conflicts, and omissions
- support “compare selected tabs” and “compare all in workspace”

Why it matters:
- this is one of the most common reasons people open many tabs

High-value compare modes:
- products and pricing
- feature/spec comparisons
- article/source agreement vs disagreement
- docs/version differences
- job listings
- travel and hotel options

### 4. Smart Memory

Purpose:
- remember what mattered, not just where you went

What it does:
- store semantic history with page summaries and user intent
- support queries like:
  - “where was that page explaining Swift async streams?”
  - “find the site comparing Japanese rail passes”
  - “what was the article I read about local-first apps?”
- attach lightweight notes and takeaways to pages

Why it matters:
- history is only useful when it can answer intent-level questions

### 5. Watch Mode

Purpose:
- turn the browser into a monitoring tool for the pages users care about

What it does:
- monitor a page for meaningful changes
- detect specific AI-filtered changes instead of any raw diff
- track:
  - price changes
  - issue status changes
  - shipping availability
  - schedule updates
  - policy or docs changes
  - product release notes
- show “what changed” summaries

Why it matters:
- users often revisit the same pages manually just to check status

### 6. Action Extraction

Purpose:
- help users turn browsing into progress

What it does:
- extract tasks, dates, links, addresses, prices, deadlines, and contacts
- generate checklists from selected tabs
- allow “save as task list” or “send to workspace notes”

Why it matters:
- many browsing sessions exist because the user is trying to do something concrete

### 7. Attention Management

Purpose:
- reduce overload and make tab cleanup useful

What it does:
- classify tabs as active, reference, stale, duplicate, or monitor-worthy
- suggest cleanup and hibernation
- let users sort tabs by project relevance or intent
- create “read now”, “save for later”, “watch”, and “archive” flows

Why it matters:
- the browser should help users stay oriented, not just accumulate state

## Feature Tiers

### Tier 1: Must Ship in V2

- Workspace Sessions
- Session Briefing
- Cross-Tab Compare
- Smart Memory
- Watch Mode

These features define the product.

### Tier 2: Strong V2 Additions

- Action Extraction
- Attention Management
- Improved reading workflows
- Workspace notes and citation-linked summaries

### Tier 3: Later Expansion

- optional cloud sync with encrypted workspace state
- collaborative workspaces
- voice session briefings
- mobile companion and handoff
- extension/import layer

## Suggested UX Surfaces

### New Tab Page

V2 home should show:

- active workspaces
- recent briefs
- monitored pages
- suggested resume points
- one “what am I working on?” entry point

### Workspace Sidebar

A new workspace sidebar should contain:

- workspace title and purpose
- tabs in that workspace
- AI brief
- notes and extracted actions
- watchlist items
- compare and summarize actions

### Compare Surface

A dedicated compare view should support:

- selected tabs
- auto-generated structured rows
- source citations per row
- export to markdown or table

### Memory Search

Search should evolve from:

- page title/url lookup

to:

- intent and takeaway lookup
- page clusters
- “show me what I learned”

## Technical Architecture Direction

### AI/ML Stack

Primary:

- Apple Foundation Models for on-device summarization, transformation, extraction, and classification

Support layers:

- local embeddings for semantic memory and workspace recall
- heuristic fallbacks when Apple Intelligence is unavailable
- structured prompt templates for compare, brief, extract, and monitor flows

Future option:

- optional cloud enrichment for heavier cross-tab reasoning, disabled by default

### Data Model Additions

Add new entities:

- `Workspace`
- `WorkspaceTab`
- `WorkspaceSummary`
- `PageMemory`
- `PageNote`
- `WatchRule`
- `WatchSnapshot`
- `ExtractedAction`

Suggested relationships:

- workspace has many tabs
- page can belong to many workspaces
- page memory links to URL + title + semantic summary
- watch rules produce snapshots and AI change summaries

### Local Storage

Extend GRDB schema to support:

- workspaces
- semantic notes
- monitor jobs
- extracted actions
- compare result caches

### Page Processing Pipeline

For each meaningful page:

1. capture cleaned text
2. generate lightweight summary
3. compute semantic representation
4. attach to workspace if applicable
5. store searchable memory

### Monitoring Pipeline

For watch mode:

1. fetch page snapshot
2. clean and normalize content
3. compare to prior snapshot
4. use AI to classify meaningful vs noisy change
5. generate user-facing change summary

## Phased Roadmap

### Phase A: Workspace Foundation

Ship:

- workspace model
- save/open workspace
- workspace summaries
- resume where you left off

Success metric:

- users can replace bookmark folders and tab hoarding with workspaces

### Phase B: Cross-Tab Intelligence

Ship:

- compare selected tabs
- session briefing
- duplicate/source overlap detection
- AI-generated next-step suggestions

Success metric:

- multi-tab sessions become easier to understand and close

### Phase C: Memory

Ship:

- semantic history
- page summaries and notes
- memory-first search

Success metric:

- users find past knowledge, not just past URLs

### Phase D: Watch Mode

Ship:

- page monitoring
- price and status watches
- meaningful change summaries

Success metric:

- users stop manually revisiting the same pages

### Phase E: Action Layer

Ship:

- action extraction
- date and task collection
- workspace checklist generation

Success metric:

- browsing sessions end with actionable output

## Example Flagship Workflows

### Buying Workflow

User opens 9 product tabs.

BestBrowser should:

- group them into one workspace
- compare price, features, and reviews
- identify the best-value options
- save a decision summary
- optionally watch price changes

### Research Workflow

User reads 12 articles and docs.

BestBrowser should:

- generate a session brief
- show consensus and disagreement
- save source-linked notes
- extract unresolved questions

### Planning Workflow

User opens flights, hotels, maps, and visa pages.

BestBrowser should:

- cluster by subtask
- summarize options
- extract deadlines and booking actions
- watch important pages for price or status changes

## What I Would Personally Want

If BestBrowser V2 feels great, it should answer:

- “What am I doing with these tabs?”
- “What changed since last time?”
- “Which of these pages actually matter?”
- “What do these sources agree on?”
- “What should I do next?”
- “Where did I see that thing last week?”

That is the standard.

## Non-Goals for V2

These may matter later, but they should not define V2:

- competing on every browser customization feature
- generic LLM chat without workflow value
- extension marketplace before core workspace intelligence is strong
- social/collaborative features before solo workflows feel excellent

## Recommended V2 Scope

If we keep V2 disciplined, this is the right scope:

- Workspace Sessions
- Session Briefing
- Cross-Tab Compare
- Smart Memory
- Watch Mode
- Light Action Extraction

That combination is differentiated, useful, and aligned with the current codebase direction.

## Immediate Build Plan After V2 Approval

1. Add workspace data model and schema
2. Add workspace sidebar and save/resume flows
3. Build session briefing over current tab/page extraction
4. Build selected-tab compare surface
5. Extend semantic memory beyond history search
6. Add watch rules and page snapshot storage

## Final Product Test

BestBrowser V2 succeeds if a user can say:

“This browser helps me think, remember, and decide. It doesn’t just show me pages.”
