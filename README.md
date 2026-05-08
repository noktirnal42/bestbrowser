# BestBrowser

Native macOS browser UI built with SwiftUI and WebKit, with privacy tooling and Apple on-device intelligence for reading assistance.

## Highlights

- Native Swift 6 macOS app with WebKit tab browsing
- Privacy tools for ad cleanup, popup stripping, and tracker blocking
- Apple Foundation Models integration for summaries, translation, simplification, and smarter suggestions
- Branded startup flow, generated app icon assets, and a custom new-tab home view
- Local history, bookmarks, and search indexing backed by GRDB

## Requirements

- macOS 26+
- Xcode 16.4+
- Apple Intelligence enabled on a supported Mac for AI features

## Build

```bash
cd /Users/jeremymcvay/dev/bestbrowser-native
swift build
```

To create the app bundle and DMG:

```bash
cd /Users/jeremymcvay/dev/bestbrowser-native
./build.sh
```

## AI Notes

BestBrowser no longer uses external LLM providers. AI features now run through Apple’s `FoundationModels` framework on device.

If Apple Intelligence is unavailable, browsing still works, but AI actions will show availability guidance instead of attempting remote calls.

## Current Areas

- [BestBrowser/BrowserWindow.swift](/Users/jeremymcvay/dev/bestbrowser-native/BestBrowser/BrowserWindow.swift): main window, tab content, new-tab home
- [BestBrowser/BrowserViewModel.swift](/Users/jeremymcvay/dev/bestbrowser-native/BestBrowser/BrowserViewModel.swift): tab state, navigation, bookmarks
- [BestBrowser/UI/SidebarView.swift](/Users/jeremymcvay/dev/bestbrowser-native/BestBrowser/UI/SidebarView.swift): history, bookmarks, search, AI tools
- [BestBrowser/AIClient.swift](/Users/jeremymcvay/dev/bestbrowser-native/BestBrowser/AIClient.swift): Apple Foundation Models integration
- [BestBrowser/Branding](/Users/jeremymcvay/dev/bestbrowser-native/BestBrowser/Branding): brand system and app visuals

## Status

- Privacy and storage foundation are in place
- Apple Intelligence integration is active
- New-tab UX, reading mode summary, and AI-aware suggestions are implemented
- Download manager, favicon work, and deeper browser features still need polish
