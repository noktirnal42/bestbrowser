# Development

## Requirements

- macOS 15+
- Xcode 16.4+
- Swift 6 toolchain

## Build

### Local Debug Build

```bash
cd /Users/jeremymcvay/dev/bestbrowser-native
swift build
```

### Run Tests

```bash
cd /Users/jeremymcvay/dev/bestbrowser-native
swift test
```

### Package the App and DMG

```bash
cd /Users/jeremymcvay/dev/bestbrowser-native
./build.sh
```

That script:

- regenerates branding assets
- performs a release build
- creates `BestBrowser.app`
- creates `releases/BestBrowser-v<version>.dmg`

## Versioning

The shipping version is stored in [`VERSION`](../VERSION).

Supporting files:

- `BestBrowser/App/AppVersion.swift`
- `build.sh`

Update `VERSION` before packaging a new release.

## Repository Conventions

### Source Layout

- `BestBrowser/`: app source
- `Tests/`: SwiftPM tests
- `Scripts/`: utility and asset-generation scripts
- `docs/`: repository-facing documentation

### Ignored Local Artifacts

The repository ignores:

- `.build/`
- `BestBrowser.app/`
- `releases/`
- `.DS_Store`

These are packaging/runtime outputs, not source.

## Recommended Workflow

1. Make focused source or documentation changes.
2. Run `swift build`.
3. Run `swift test` when the change affects behavior or state flow.
4. Run `./build.sh` when validating the packaged app or DMG.
5. Launch the app bundle for real-world behavior checks:

```bash
open /Users/jeremymcvay/dev/bestbrowser-native/BestBrowser.app
```

## AI and Platform Notes

### Apple Foundation Models

BestBrowser uses Apple’s on-device `FoundationModels` path rather than an external hosted provider.

Implications:

- AI features depend on Apple Intelligence availability
- browsing still works without AI availability
- AI-facing UI should degrade clearly instead of failing silently

### WebKit Reality

This project is a custom browser built on `WKWebView`, so some services behave differently than Safari or Chromium:

- passkeys and auth flows can be site-dependent
- media providers often need provider-specific compatibility work
- ad/tracker blocking can affect fragile web apps
- YouTube, DI.fm, Spotify, Twitch, Prime Video, and Max all need occasional tuning

## Release Notes Inputs

Useful source files when preparing release notes:

- `README.md`
- `V3_PLAN.md`
- `VNEXT_REBUILD_PLAN.md`
- `IMPLEMENTATION_SUMMARY.md`
- `WORK_COMPLETE.md`

## Suggested Next Documentation Areas

If the project keeps growing, the next docs worth adding are:

- a dedicated `CHANGELOG.md`
- extension manifest reference
- browser command palette reference
- release checklist for DMG packaging and test passes
