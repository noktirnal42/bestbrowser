# BestBrowser V3 Plan

BestBrowser V3 should make the app feel complete as a daily-use browser while deepening the parts that make it uniquely yours: private workspaces, cross-tab intelligence, and a browser that adapts to your personal flow.

## Core V3 Bet

V2 established the intelligence layer:

- workspace sessions
- session briefing
- cross-tab compare
- smart memory
- watch mode

V3 should strengthen two things at once:

1. browser fundamentals that people now expect from serious modern browsers
2. BestBrowser-specific features that turn browsing into a private, personal operating environment

The goal is not to become a generic Chrome clone with AI.

The goal is to become:

- a personal research browser
- a private synthesis browser
- a browser shaped around your own habits and projects

## What V3 Needs To Solve

### 1. BestBrowser still lacks some daily-driver browser basics

Even with the V2 intelligence layer, the product is still missing several high-value browser capabilities:

- split view
- tab groups
- vertical tabs
- tab hibernation or unload
- session restore
- reopen closed tabs
- site-level trust and permission controls
- find in page
- media control center
- web apps or site apps

These features are no longer “nice to have” if BestBrowser is meant to be a real primary browser.

### 2. BestBrowser can go further than mainstream browsers on intent and memory

Leading browsers now offer:

- AI-assisted grouping
- split view
- workspaces
- sidebar assistants
- web apps
- stronger tab organization

But they are still weak at:

- remembering why pages matter
- routing work automatically by intent
- turning browsing into extracted actions
- linking monitoring, memory, and compare into one workflow

That is where BestBrowser should push harder.

### 3. BestBrowser should feel more personal

The browser should not feel like a theme on top of WebKit.
It should feel like a private tool made for one person with a specific style and working rhythm.

That means:

- stronger customization
- more intentional workspace-oriented navigation
- fewer generic browser defaults
- more user-shaped layout modes

## Product Principles For V3

### 1. Serious browser first

If the app cannot handle everyday tab and site workflows well, the AI layer will not matter.

### 2. On-device by default

Intelligence, summaries, memory, and organization should stay local whenever possible.

### 3. Research is the hero workflow

The browser should be exceptional at comparison, synthesis, revisit, and progress tracking across many tabs.

### 4. Personal control matters

The browser should be moldable:

- layout
- toolbar
- workspaces
- visual identity
- routing behavior

### 5. AI must produce action

Every intelligence feature should help the user:

- decide
- compare
- remember
- monitor
- extract
- finish

## Competitive Context

Current browsers already set the baseline:

- Microsoft Edge emphasizes vertical tabs, profiles, passkeys, media controls, shopping tools, and page-aware Copilot.
- Firefox now includes tab groups, AI-assisted tab grouping, split view, unload tabs, tab notes, widgets, and web apps.
- Opera offers split screen, tab islands, tab traces, and playful tab personalization.
- SigmaOS is explicitly workspace-first.
- Arc introduced live folders, link routing, pinned tabs, and library-driven organization.
- Vivaldi remains strongest on deep personalization, notes, and browser customizability.

BestBrowser should not copy everything.
It should close the most important browser-baseline gaps, then double down on the areas others still underdeliver.

## V3 Feature Tiers

## Tier 1: Must Ship

These are the highest-leverage V3 features.

### 1. Split View

Why it matters:

- best feature-to-effort ratio
- directly supports compare and research workflows
- now standard enough to feel expected

User outcome:

- compare two pages side by side
- compare products, docs, articles, or dashboards without tab flipping

Key capabilities:

- create split view from two tabs
- compare current tab with selected tab
- preserve split pair as part of workspace state
- optional “compare in split view” shortcut from compare UI

### 2. Tab Groups and Vertical Tabs

Why it matters:

- core browser organization is still weak in the current app
- perfect fit for workspace-first browsing

User outcome:

- organize tabs visually by task
- collapse groups
- see more titles at once
- reduce horizontal tab-strip overload

Key capabilities:

- tab groups with names and colors
- vertical tab mode
- optional AI-suggested groups from session context
- group-to-workspace linkage

### 3. Session Restore and Reopen Closed Tabs

Why it matters:

- table-stakes browser trust feature
- especially important for research sessions

User outcome:

- recover from crashes or relaunches
- recover accidentally closed tabs and sessions

Key capabilities:

- restore last session on launch
- reopen last closed tab
- reopen last closed group or workspace session

### 4. Site Trust Panel

Why it matters:

- current privacy tooling exists, but it is mostly invisible or coarse
- users need a trustworthy, page-level control surface

User outcome:

- understand what the current page is doing
- inspect and change site-specific privacy settings

Key capabilities:

- HTTPS / page identity state
- trackers blocked on this page
- cookies and storage summary
- notification, camera, microphone, location state
- cleanup exemptions for app-like sites

### 5. Action Extraction

Why it matters:

- this is one of the strongest product differentiators
- it turns “read and remember” into “browse and finish”

User outcome:

- extract tasks, deadlines, prices, addresses, contacts, and links from pages or workspaces
- turn open tabs into a checklist

Key capabilities:

- extract from current page
- extract from selected tabs
- extract from workspace
- save results into workspace notes or action lists

## Tier 2: Strong V3 Additions

### 6. Link Routing Rules

Inspired by:

- Arc’s Air Traffic Control

User outcome:

- links open in the right workspace, window, or site-app automatically

Examples:

- GitHub issue links open in “Dev”
- booking links open in “Travel”
- YouTube opens in a media app window

### 7. Web Apps / Site Apps

User outcome:

- turn frequently used sites into focused app windows

Examples:

- Gmail
- YouTube Music
- Calendar
- Notion
- Slack

### 8. Tab Hibernation / Unload

User outcome:

- keep huge research sessions open without paying full memory cost

### 9. Media Control Center

User outcome:

- control media across tabs from one place
- jump directly to playing tabs

### 10. Workspace Notes and Resume Briefs

User outcome:

- each workspace becomes a living project surface, not just a saved tab set

Key capabilities:

- freeform notes
- cited summaries
- “what changed since last open”
- resume suggestions

## Tier 3: Personalization and Long-Term Differentiation

### 11. Live Folders / Dynamic Workspace Feeds

User outcome:

- workspaces update automatically from watched sources, saved searches, or monitored pages

### 12. Toolbar and Layout Customization

User outcome:

- choose compact, minimal, reading, or research-oriented chrome
- move or hide less important controls

### 13. Theme Packs and Personal Start Page

User outcome:

- browser feels more like your own environment

### 14. Mouse Gestures and Shortcut Customization

User outcome:

- power-user control without cluttering the UI

### 15. Multi-Profile Contexts

User outcome:

- separate work, personal, admin, testing, or client contexts cleanly

## Recommended Delivery Order

This is the order that best balances product impact and implementation dependency.

### Phase A: Browser Core

1. Split View
2. Session Restore and Reopen Closed Tabs
3. Tab Groups
4. Vertical Tabs
5. Tab Hibernation

### Phase B: Trust and Control

6. Site Trust Panel
7. Find in Page
8. Media Control Center
9. Web Apps / Site Apps

### Phase C: BestBrowser Intelligence

10. Action Extraction
11. Link Routing Rules
12. Workspace Notes and Resume Briefs
13. Live Folders

### Phase D: Personalization

14. Toolbar customization
15. Theme packs and personal start page
16. Shortcut and gesture customization
17. Multi-profile contexts

## Engineering Plan

## Phase A: Browser Core Infrastructure

Add:

- `TabGroup`
- `SplitSession`
- `ClosedTabRecord`
- `BrowserSessionSnapshot`

Suggested files:

- `BestBrowser/Models/TabModels.swift`
- `BestBrowser/Services/SessionRestoreService.swift`
- `BestBrowser/Services/TabOrganizationService.swift`
- `BestBrowser/UI/VerticalTabSidebarView.swift`
- `BestBrowser/UI/SplitBrowserView.swift`

Storage additions:

- `tab_groups`
- `group_tabs`
- `closed_tabs`
- `browser_sessions`

## Phase B: Site Trust and Utility Layer

Add:

- site permission model
- site-specific privacy exceptions
- trust status summary

Suggested files:

- `BestBrowser/Models/SitePermissionModels.swift`
- `BestBrowser/Services/SitePermissionsService.swift`
- `BestBrowser/UI/SiteTrustPanelView.swift`
- `BestBrowser/UI/FindInPageView.swift`
- `BestBrowser/UI/MediaCenterView.swift`

## Phase C: Action and Routing Intelligence

Add:

- extracted actions
- routing rules
- workspace notes

Suggested files:

- `BestBrowser/AI/ActionExtractionService.swift`
- `BestBrowser/Models/ActionModels.swift`
- `BestBrowser/Models/RoutingRuleModels.swift`
- `BestBrowser/Services/LinkRoutingService.swift`
- `BestBrowser/UI/WorkspaceNotesView.swift`
- `BestBrowser/UI/ActionInboxView.swift`

Storage additions:

- `workspace_notes`
- `workspace_actions`
- `routing_rules`

## Phase D: Personalization Layer

Add:

- toolbar layout presets
- user theme profiles
- customizable new-tab modules

Suggested files:

- `BestBrowser/Models/CustomizationModels.swift`
- `BestBrowser/Services/CustomizationService.swift`
- `BestBrowser/UI/ToolbarCustomizerView.swift`
- `BestBrowser/UI/StartPageCustomizerView.swift`

## UX Milestones

### Milestone 1

- split view
- reopen closed tab
- restore last session

### Milestone 2

- tab groups
- vertical tabs
- unload inactive tabs

### Milestone 3

- site trust panel
- find in page
- media center

### Milestone 4

- action extraction
- workspace notes
- routing rules

### Milestone 5

- web apps
- dynamic workspaces
- toolbar and theme customization

## MVP Cut Recommendation

If V3 needs a disciplined shipping boundary, ship:

- split view
- session restore
- reopen closed tabs
- tab groups
- site trust panel
- action extraction
- workspace notes

Hold for later:

- vertical tabs
- web apps
- media center
- link routing
- live folders
- profiles
- full toolbar customization

That cut would make the browser feel dramatically more complete without overextending the release.

## BestBrowser V3 Identity

V3 should not try to win by having the longest feature list.

It should win by combining:

- serious browser organization
- strong privacy defaults
- on-device intelligence
- research-first workflows
- personal customization

The best version of BestBrowser is one where:

- your tabs become projects
- your projects become memory
- your memory turns into actions
- and the browser feels like it belongs to you

## Immediate Next Step

Start V3 with a narrow implementation kickoff:

1. Split View
2. Session Restore
3. Reopen Closed Tabs

Those three give the fastest jump in “this feels like a real primary browser” while reinforcing the workspace and compare features that already exist.
