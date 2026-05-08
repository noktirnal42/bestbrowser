# 🚀 Quick Start Guide - BestBrowser Native

## What You Have

A fully-featured native macOS browser with:
- ✅ Privacy Shield (ad/tracker blocking)
- ✅ Encrypted storage (history, bookmarks)
- ✅ AI integration (NVIDIA, Ollama, OpenRouter)
- ✅ Semantic search
- ✅ Content summarization
- ✅ Tab organization
- ✅ Cyberpunk branding

## Setup & Build

### 1. Install Dependencies
```bash
# GRDB (SQLite) is automatic via Swift Package Manager
# No additional setup needed!
```

### 2. Build Project
```bash
cd ~/dev/bestbrowser-native

# Via command line:
swift build -c release

# Via Xcode:
open .  # Then Cmd+R
```

### 3. Run the App
```bash
open BestBrowser.app
```

## First Run

1. **Splash Screen** - 2-second startup animation (cyberpunk themed)
2. **Database Init** - SQLite database created automatically in `~/Library/Application Support/com.bestbrowser`
3. **Privacy Shield** - Activates immediately (ad blocking enabled by default)

## Configure AI

1. Open Settings (Cmd+,)
2. Click "AI Provider" tab
3. Choose provider:
   - **NVIDIA NIM** (Recommended for cloud) - Get key at https://build.nvidia.com
   - **Ollama** (Local, free) - Install from https://ollama.ai
   - **OpenRouter** (Multi-model) - Get key at https://openrouter.ai
   - **LM Studio** (Local GUI) - Download from https://lmstudio.ai

4. Enter configuration:
   - Base URL (auto-filled)
   - API Key (if needed)
   - Model name (auto-filled)

5. Click "Test Connection" to verify

## Use the Features

### Privacy Shield
- Shows in Settings → Privacy Shield tab
- Real-time stats: ads blocked, trackers blocked, time saved
- Toggle ad/tracker blocking on/off

### Search & History
- Every page you visit is logged automatically
- Search for any page from Settings
- Find by URL or page title

### Tab Organization
- Open multiple tabs
- AI automatically categorizes them
- See categories: Social, Work, Dev, etc.

### Summarize Content
- Select text on any page
- Use AI to summarize (when AI is configured)
- Choose style: Concise, Detailed, Bullet Points, Paragraph

### Bookmarks
- (Coming in Phase 2 UI)
- Database is ready, just needs UI

## Project Files

```
Key Implementations:
├── Privacy Shield        → Privacy/PrivacyShield.swift
├── Database              → Storage/StorageManager.swift
├── AI Client             → AIClient.swift
├── Tab Organization      → AI/TabOrganizer.swift
├── Content Summary       → AI/ContentSummarizer.swift
├── Search                → Search/SemanticSearch.swift
├── Element Blocker       → Privacy/ElementBlocker.swift
├── Privacy Dashboard     → Views/PrivacyDashboardView.swift
└── Custom Branding       → Branding/BrandingManager.swift
```

## Troubleshooting

### App Won't Start
```bash
# Clean and rebuild
rm -rf .build/
swift build -c release
```

### Database Errors
- Check permissions: `~/Library/Application Support/com.bestbrowser/`
- Rebuild: `rm ~/Library/Application\ Support/com.bestbrowser/bestbrowser.db`

### AI Not Working
- Verify API key is correct
- Check firewall isn't blocking HTTPS
- For Ollama: ensure it's running (`ollama serve`)

### SourceKit Errors in Xcode
- These disappear after first build
- Command-line build should work even if IDE shows errors

## Next Steps

### You Can Try Now:
1. ✅ Browse the web with privacy protection
2. ✅ Check Privacy Shield stats
3. ✅ Configure AI provider
4. ✅ Test AI connection
5. ✅ Browse and auto-log history

### Phase 2 (UI Implementation):
- [ ] Sidebar with history/bookmarks
- [ ] Search bar with suggestions
- [ ] Favicon support
- [ ] Download manager
- [ ] Reading mode

### Phase 3 (Advanced):
- [ ] Vertical tabs
- [ ] Split view
- [ ] Sync (optional)
- [ ] Extensions

## Architecture

```
┌─────────────────────────┐
│   macOS SwiftUI App     │
├─────────────────────────┤
│  BrowserWindow (WebKit) │
│  │                      │
│  ├─ PrivacyShield       │  → Ad/tracker blocking
│  ├─ ElementBlocker      │  → Popup/ad removal
│  └─ SettingsWindow      │  → Config UI
│                         │
├─────────────────────────┤
│  AI Integration         │
│  ├─ AIClient            │  → Multiple providers
│  ├─ Summarizer          │  → Text processing
│  └─ TabOrganizer        │  → Categorization
├─────────────────────────┤
│  Storage & Search       │
│  ├─ StorageManager      │  → SQLite (GRDB)
│  ├─ SemanticSearch      │  → Full-text search
│  └─ Models              │  → Data definitions
├─────────────────────────┤
│  Branding               │
│  └─ BrandingManager     │  → Cyberpunk theme
└─────────────────────────┘
```

## Performance

- **Startup**: ~2 seconds (splash screen)
- **Memory**: ~200MB base + AI models (loaded on demand)
- **Privacy Shield**: 0 network overhead
- **Summarization**: 5-30 seconds (depends on text length & API)

## Privacy

- ✅ No telemetry
- ✅ No user tracking
- ✅ All data local (except optional AI APIs)
- ✅ Encrypted keychain for secrets
- ✅ No cloud sync without opt-in

---

**Ready to build?** Run:
```bash
cd ~/dev/bestbrowser-native && swift build -c release && open BestBrowser.app
```

Questions? Check the implementation files - they're well-commented!
