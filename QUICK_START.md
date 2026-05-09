# Quick Start

BestBrowser is a SwiftPM-based native macOS browser workspace built around WebKit, local persistence, privacy tooling, and Apple’s on-device Foundation Models integration.

## Requirements

- macOS 26+
- Xcode 26.4.1+
- Swift 6.3+
- Apple Intelligence enabled on a supported Mac for AI features

## Build

```bash
cd /Users/jeremymcvay/dev/bestbrowser-native
swift build
```

## Test

```bash
cd /Users/jeremymcvay/dev/bestbrowser-native
./test.sh
```

## Package and Launch

```bash
cd /Users/jeremymcvay/dev/bestbrowser-native
./build.sh
open /Users/jeremymcvay/dev/bestbrowser-native/BestBrowser.app
```

`./build.sh` regenerates brand assets, creates `BestBrowser.app`, and writes a DMG to `releases/BestBrowser-v<version>.dmg`.

`./test.sh` runs the same XCTest suite through an explicit all-tests filter, which keeps current Swift 6.3/macOS 26 runs free of unrelated `CoreData`/`NSXPCConnection` log noise.

## First Run

1. Launch `BestBrowser.app`.
2. The app initializes its local database in `~/Library/Application Support/com.bestbrowser/`.
3. Privacy Shield starts enabled by default.
4. Open Settings with `Cmd+,` to verify privacy, search, and Apple Intelligence status.

## Current Core Surfaces

- `Browser`: tabbed browsing, split browsing, page tools, command routing
- `Workspaces`: save and restore grouped browser sessions
- `Watchlist`: monitor important pages over time
- `Memory`: keep recalled summaries and pinned notes for revisited pages
- `Extensions`: run bundled manifest-driven page actions
- `Music`: keep DI.fm, Spotify, or Apple Music open in a dedicated surface
- `Video`: keep YouTube, Twitch, Prime Video, or Max nearby in a dedicated pane

## Apple Intelligence Setup

1. Open Settings with `Cmd+,`.
2. Select the `Apple Intelligence` tab.
3. Click `Test Connection`.
4. If the model is unavailable, use the status message to confirm whether Apple Intelligence is disabled, still preparing, or unsupported on the current Mac.

BestBrowser no longer uses external AI providers, API keys, or custom model endpoints.

## Troubleshooting

### Build Problems

```bash
cd /Users/jeremymcvay/dev/bestbrowser-native
rm -rf .build
swift build
```

### Packaging Problems

```bash
cd /Users/jeremymcvay/dev/bestbrowser-native
./build.sh
```

### Database Reset

```bash
rm -f ~/Library/Application\ Support/com.bestbrowser/bestbrowser.db
```

### AI Features Unavailable

- Confirm the Mac supports Apple Intelligence.
- Confirm Apple Intelligence is enabled in macOS settings.
- Wait for the on-device model to finish preparing if the app reports `model not ready`.

## Source of Truth

- `README.md`: product overview and repo layout
- `docs/ARCHITECTURE.md`: stores, services, scenes, and WebKit structure
- `docs/DEVELOPMENT.md`: local build, test, and packaging workflow
- `V3_PLAN.md`: product priorities
- `VNEXT_REBUILD_PLAN.md`: architectural migration direction

Treat older milestone summaries like `PHASE1_COMPLETE.md`, `PHASE2_COMPLETE.md`, `IMPLEMENTATION_SUMMARY.md`, and `WORK_COMPLETE.md` as historical notes rather than current setup guidance.
