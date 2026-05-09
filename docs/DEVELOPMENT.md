# Development

## Requirements

- macOS 26+
- Xcode 26.4.1+
- Swift 6.3+ toolchain

## Build

### Local Debug Build

```bash
cd /Users/jeremymcvay/dev/bestbrowser-native
swift build
```

### Run Tests

```bash
cd /Users/jeremymcvay/dev/bestbrowser-native
./test.sh
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

### Release Verification

Before cutting a release, run:

```bash
cd /Users/jeremymcvay/dev/bestbrowser-native
swift build
./test.sh
./build.sh
```

Then verify:

- `BestBrowser.app` launches successfully
- `releases/BestBrowser-v<version>.dmg` exists and mounts
- the docs and changelog match the shipped behavior

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
3. Run `./test.sh` when the change affects behavior or state flow.
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
- `CHANGELOG.md`

Historical milestone notes like `IMPLEMENTATION_SUMMARY.md`, `PHASE1_COMPLETE.md`, `PHASE2_COMPLETE.md`, and `WORK_COMPLETE.md` should only be used as archival context, not as current release-source material.

## Suggested Next Documentation Areas

If the project keeps growing, the next docs worth adding are:

- extension manifest reference
- browser command palette reference
- release checklist for DMG packaging and test passes
