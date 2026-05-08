# Architecture

## Overview

BestBrowser is a SwiftPM-based macOS app that has been progressively refactored from a single browser window implementation into a feature-oriented architecture with explicit stores, services, and scene-level routing.

The current direction is:

- scene-level app shell
- browser-specific shell and content surfaces
- explicit state stores
- smaller services for browser behaviors
- persistent WebKit wrappers for browsing and media

## Major Layers

### App and Scene Layer

- `BestBrowser/BestBrowserApp.swift`
- `BestBrowser/Features/Browser/BrowserSceneRootView.swift`
- `BestBrowser/Features/Sidebar/SidebarRailView.swift`

This layer owns the high-level application structure:

- scene selection
- sidebar visibility
- transitions between Browser, Workspaces, Watchlist, Memory, Extensions, Music, and Video
- scene-level persistent UI like the music strip and floating video pane

### Browser Shell Layer

- `BestBrowser/Features/Browser/BrowserShellView.swift`
- `BestBrowser/Features/Browser/BrowserMainColumnView.swift`
- `BestBrowser/Features/Browser/BrowserChromeComponents.swift`

This is the primary browsing experience:

- browser chrome
- tab rail
- toolbar
- split-view presentation
- browser overlays and controls

### Core State Stores

- `BestBrowser/Core/Stores/BrowserNavigationStore.swift`
- `BestBrowser/Core/Stores/BrowserShellStore.swift`
- `BestBrowser/Core/Stores/BrowserWorkspaceStore.swift`

These stores exist to keep important state out of giant SwiftUI views.

#### `BrowserNavigationStore`

Owns browser-navigation concerns such as:

- tabs
- active tab selection
- split-view relationships
- tab grouping
- session snapshot shaping

#### `BrowserShellStore`

Owns transient shell presentation state such as:

- command palette
- sheets
- focus mode
- picker presentation

#### `BrowserWorkspaceStore`

Owns app-level scene routing and sidebar visibility.

## Browser Services

The service layer now carries logic that previously lived inline in the browser model:

- `BrowserCommandCoordinator.swift`: app/browser command routing
- `BrowserSessionCoordinator.swift`: session restore and archive rules
- `BrowserPageActionService.swift`: page cleanup, video repair, popup stripping
- `BrowserPageContextService.swift`: page text/context extraction and page metadata
- `MediaPlaybackControlService.swift`: browser/music/video media volume and playback control
- `SiteCompatibilityService.swift`: site-specific compatibility logic
- `BrowserAuthenticationService.swift`: passkey and authentication support

## WebKit Integration

### Main Browser Web Views

- `BestBrowser/Features/Browser/BrowserWebView.swift`

This file owns:

- `WKWebView` construction
- compatibility user agent
- navigation delegates
- download interception
- page-finish hooks
- browser media-state refresh hooks

### Persistent Media Players

- `BestBrowser/Features/Media/PersistentWebPlayer.swift`
- `BestBrowser/Features/Music/MusicPlayerView.swift`
- `BestBrowser/Features/Video/VideoPlayerView.swift`

Media surfaces use persistent `WKWebView` instances so playback and navigation context survive surface switches better than disposable web views would.

## Privacy Layer

- `BestBrowser/Privacy/PrivacyShield.swift`
- `BestBrowser/Privacy/ElementBlocker.swift`

The privacy layer combines:

- content-rule based blocking
- page cleanup
- compatibility bypasses where necessary

The content-rule path is applied per-web-view and now re-evaluated on navigation, which matters for apps that move between fragile and standard sites.

## Persistence and Sessions

- `BestBrowser/Storage/StorageManager.swift`
- `BestBrowser/Services/SessionRestoreService.swift`
- `BestBrowser/Services/WorkspaceService.swift`
- `BestBrowser/Models/WorkspaceModels.swift`
- `BestBrowser/Models/TabGroupModels.swift`

Persistence supports:

- browser sessions
- grouped tabs
- closed-tab reopen stacks
- workspace save/restore
- grouped workspace recovery

## Extensions

- `BestBrowser/Features/Extensions/BrowserExtensionHost.swift`
- `BestBrowser/Features/Extensions/ExtensionsLibraryView.swift`
- `BestBrowser/Features/Extensions/BundledExtensions/*.json`

BestBrowser does not load Safari extensions directly into `WKWebView`. Instead, it uses its own manifest-driven in-app extension model for:

- bundled tools
- user-provided manifests
- page relevance matching
- toolbar/library placement

## Current Architectural Strengths

- Cleaner separation between shell state, navigation state, and browser services
- Shared media primitives used by both Music and Video
- Scene-level routing instead of overloading the browser sidebar
- Explicit service layer for compatibility, session, media, and page tools

## Current Architectural Tensions

- Some browser behaviors still pass through `BrowserViewModel.swift`, which remains important but not yet minimal
- Provider-specific web-player quirks still leak into shared media infrastructure
- Privacy and compatibility behavior need ongoing tuning because modern web apps are inconsistent in `WKWebView`

## Direction of Travel

The intended end state is:

- `BrowserSceneRootView` as the stable app shell
- compact feature views for major surfaces
- state mostly in stores
- behavior mostly in services
- thinner view models
- fewer notification-based action loops

That direction is already well underway, even though some legacy pieces still remain in the tree.
