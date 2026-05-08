# Branding

## Core Positioning

BestBrowser is not meant to read like a generic AI browser or “faster Safari clone.”

The product voice is:

- private
- focused
- ambient
- workspace-oriented
- native to macOS

Current tagline in code:

> Quiet focus. Your web.

Source:

- `BestBrowser/Branding/BrandingManager.swift`

## Brand Assets

### Source and Generated Assets

- Source export assets: `BestBrowser/BrandingAssets/`
- App asset catalog: `BestBrowser/Assets.xcassets/`
- Asset generation script: `Scripts/generate_brand_assets.swift`

Current generated exports:

- `app-icon-master.png`
- `brandmark-hero.png`
- `launch-badge.png`

## Visual Palette

Defined in `BestBrowser/Branding/BrandingManager.swift`.

### Named Brand Colors

- `signalBlue`: cool accent / info tone
- `signalSky`: primary light highlight
- `signalAmber`: warm action tone
- `fog`: soft foreground text tone
- `darkBg`: root background
- `darkCard`: primary dark panel
- `darkBorder`: edge definition
- `raisedCard`: elevated surface
- `chrome`: window/control surface
- `glow`: warm highlight accent

### Semantic Mappings

- `primary = signalSky`
- `secondary = signalAmber`
- `accent = signalBlue`
- `background = darkBg`
- `cardBackground = darkCard`
- `border = darkBorder`

## Typography

The code currently identifies:

- `font = "SF Mono"`
- `displayFont = "New York"`

In practice, the app uses system SwiftUI typography extensively, but the brand direction is clear:

- expressive but restrained display treatment
- monospaced micro-labels for tool/control metadata
- warm, editorial dark surfaces instead of generic blue/white SaaS styling

## UI Personality

BestBrowser’s best UI moments should feel:

- editorial rather than dashboard-heavy
- moody rather than sterile
- calm rather than neon-chaotic
- precise rather than overloaded

That means:

- dark, warm surfaces
- soft glow used sparingly
- compact chrome
- strong section titles
- minimal accidental visual noise

## Brand Usage Guidelines

### Do

- Use the existing palette and semantic mappings
- Favor calm, premium dark surfaces over flat black
- Keep toolbar and mini-player controls compact
- Use monospaced labels for small metadata or transport labels when helpful
- Let the icon and launch assets do the heavy lifting on identity

### Don’t

- Introduce random bright accent colors
- Drift into purple-heavy default AI branding
- Mix multiple unrelated visual languages
- Overuse glow, shadows, or oversized chips
- Let utility controls overpower content

## Asset Pipeline

Brand assets are regenerated during packaging:

```bash
./build.sh
```

That script calls:

```bash
swift Scripts/generate_brand_assets.swift
```

The generated assets are then copied into the app bundle and used for:

- app icon
- startup visuals
- branded resource graphics

## Repo Presentation

For GitHub-facing docs and release material:

- use the full product name `BestBrowser`
- keep messaging short and confident
- describe it as a native macOS browser workspace, not only as an AI browser
- emphasize focus, privacy, and ambient web context

## Good One-Line Descriptions

Use these as starting points in docs or releases:

- `A native macOS browser workspace for focused research, ambient media, and private browsing tools.`
- `BestBrowser turns the web into a calmer, more organized workspace.`
- `A native browser shell for people who keep research, music, video, and page context open at the same time.`
