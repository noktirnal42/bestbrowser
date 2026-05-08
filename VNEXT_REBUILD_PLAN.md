# BestBrowser v0.3 Rebuild Plan

## Goal

Roll BestBrowser into a cleaner, more durable version that keeps the differentiated ideas:

- private on-device AI
- workspaces and memory
- cross-tab compare
- watch mode
- personal browser UX

while replacing the unstable architecture that made compatibility, UI polish, and browser correctness harder to maintain.

## Why Rebuild

The current app proves product direction, but too much responsibility is concentrated in a few files:

- `BrowserWindow.swift`
- `BrowserViewModel.swift`
- `StorageManager.swift`

That makes it hard to:

- reason about tab state vs window state vs app state
- fix site compatibility without regressions
- ship polished UI changes without touching browser logic
- add features like trust panels, split workflows, and web app mode cleanly

## v0.3 Principles

1. Browser correctness first
- page rendering, navigation, downloads, permissions, and compatibility should be stable before layering more AI

2. Separate product layers
- browser core
- compatibility/privacy
- workspace and intelligence
- design system and shell

3. Parallel migration, not a flag day
- keep the current app functional while new modules come online

4. Smaller files, explicit ownership
- app-wide state
- window/browser state
- feature stores
- services

## Target Structure

```text
BestBrowser/
  App/
    AppVersion.swift
    AppRootView.swift
  Core/
    Models/
      BrowserTab.swift
    Stores/
      BrowserWorkspaceStore.swift
    Services/
      SiteCompatibilityService.swift
  Features/
    Browser/
      BrowserSceneRootView.swift
    Home/
      HomeDashboardView.swift
    Sidebar/
      SidebarRailView.swift
  Shared/
    Design/
      BrowserDesignSystem.swift
```

## Migration Phases

### Phase 1: Foundation

- centralize versioning
- extract browser tab model
- extract site compatibility rules
- scaffold a new browser workspace store
- add a vNext scene shell

### Phase 2: Browser Core

- move navigation and tab lifecycle out of `BrowserViewModel`
- isolate WebKit wrappers and download routing
- add a real site compatibility layer
- formalize focused live-player fallback behavior

### Phase 3: Window Shell

- replace the current all-in-one browser window with:
  - sidebar rail
  - browser scene root
  - home/dashboard surface
  - detail panes for compare, watches, and workspaces

### Phase 4: Intelligence Layer

- move workspaces, memory, compare, and watch services behind stable feature stores
- separate AI summarization pipelines from UI event code

### Phase 5: Ship Candidate

- UI polish pass
- browser compatibility regression pass
- smoke tests for:
  - YouTube
  - Gmail
  - Docs
  - Slack
  - Notion
  - downloads
  - session restore
  - workspace persistence

## Immediate Deliverables In This Pass

- `VERSION` as the single source of truth for release versioning
- extracted `BrowserTab` model
- extracted `SiteCompatibilityService`
- initial `BrowserWorkspaceStore`
- initial `BrowserSceneRootView`

## Non-Goals For This First Pass

- full migration of browser state
- removing the legacy browser shell yet
- changing storage schema
- repackaging release artifacts immediately

## Success Criteria

The rebuild has started successfully when:

- versioning is centralized
- core browser types are no longer trapped inside `BrowserViewModel.swift`
- compatibility logic is no longer mixed into general tab state
- a new shell exists in code as the destination for migration
- the app still builds
