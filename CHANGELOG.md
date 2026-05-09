# Changelog

All notable project changes should be tracked here in a release-oriented format.

## 0.3.1

### Improved

- Browser feature files were broken into smaller scene, support, toolbar, split-view, and WebKit bridge components
- Browser state and authentication flow cleanup reduced stale selection behavior and removed deprecated auth handling
- Storage schema/bootstrap logic was pulled out of the main storage manager for a slimmer persistence layer
- Build, test, and packaging docs were aligned around the current Swift 6.3 and macOS 26 workflow

### Packaging

- `./test.sh` is now the recommended clean verification path before packaging
- `./build.sh` produces the release DMG for the current `VERSION` value
- historical phase and implementation notes are now explicitly treated as archival docs

## 0.3.0

### Added

- Scene-based app shell with Browser, Workspaces, Watchlist, Memory, Extensions, Music, and Video surfaces
- Dedicated music surface with DI.fm, Spotify, and Apple Music support
- Dedicated video surface with YouTube, Twitch, Prime Video, and Max support
- Floating video companion pane and bottom music mini player
- In-app extension system with bundled browser tools
- Apple Passwords and passkey support path
- Branded asset generation pipeline for icons and launch graphics

### Improved

- Browser architecture split into cleaner stores, services, and feature views
- Session restore, reopen closed tabs, and grouped workspace persistence
- Split view, tab grouping, and vertical tab support
- Watchlist, page memory, and compare tooling
- README, architecture docs, development docs, branding docs, and contribution guidance

### Known Rough Edges

- Provider-specific media playback quirks still exist
- WebKit compatibility behavior still needs ongoing tuning
- Privacy and media controls still need more real-world refinement

## 0.2.0

### Added

- Branded native macOS browser shell
- Privacy tooling and Apple Foundation Models integration
- Workspace and browsing foundations

### Notes

- This was the earlier milestone before the vNext shell and media surfaces expanded significantly
