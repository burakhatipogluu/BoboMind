<div align="center">

# BoboMind

### Smart Clipboard Manager for macOS

**Your clipboard, supercharged.** BoboMind lives quietly in your menu bar and gives you instant, Spotlight-style access to everything you've ever copied — text, images, rich text, files, and more.

[![macOS 14+](https://img.shields.io/badge/macOS-Sonoma_14+-0A84FF?style=flat-square&logo=apple&logoColor=white)](https://www.apple.com/macos/sonoma/)
[![Swift 5.10](https://img.shields.io/badge/Swift-5.10—F05138?style=flat-square&logo=swift&logoColor=white)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/Built_with-SwiftUI-006AFF?style=flat-square&logo=swift&logoColor=white)](https://developer.apple.com/swiftui/)
[![SwiftData](https://img.shields.io/badge/Powered_by-SwiftData-34C759?style=flat-square&logo=apple&logoColor=white)](https://developer.apple.com/xcode/swiftdata/)

---

**One hotkey. Infinite clipboard.**

Press `Cmd + Shift + V` and a beautiful floating panel appears — search your history, pick a clip, and it's pasted instantly.

</div>

---

## Why BoboMind?

macOS gives you one clipboard slot. BoboMind gives you **unlimited history** with zero friction.

- **Zero window switching** - the floating panel appears over any app and pastes directly
- **No Electron, no overhead** — 100% native Swift + SwiftUI, feels as fast as Spotlight
- **Privacy first** — your data stays on your Mac, never touches a server
- **Password safe** — automatically ignores copies from 1Password, Bitwarden, LastPass, and more

---

## Features

### Instant Access
- **Spotlight-style floating panel** with frosted glass vibrancy effect
- **Global hotkey** (`Cmd + Shift + V`) — works from any app, any fullscreen space
- **6 popup positions** — center, mouse cursor, top, bottom, left, right
- **Smooth animations** — fade-in/out transitions, polished macOS-native feel

### Clipboard Intelligence
- **Captures everything** — plain text, rich text, HTML, images, file URLs, colors
- **Smart deduplication** — SHA256 content hashing prevents duplicate entries
- **Source tracking** — see which app each clip was copied from
- **Auto-cleanup** — configurable history limit (100 / 500 / 1,000 / 5,000 / unlimited)

### Powerful Search
- **3-tier cascade search** — exact match, prefix match, then fuzzy subsequence matching
- **Content type filters** — quick chips to filter by text, image, file, HTML, etc.
- **Fuzzy matcher** — finds what you need even with typos or partial queries

### Organization
- **Pin clips** — keep frequently used items always at the top
- **Custom groups** — organize clips into named collections
- **Snippets** — save and manage reusable text templates
- **Preview panel** — side-by-side content preview (text, images, rendered HTML)

### Privacy & Security
- **Concealed content detection** — skips items from password managers automatically
- **Browser extension awareness** — detects and ignores copies from Bitwarden, 1Password, LastPass, Dashlane, NordPass Chrome extensions
- **App exclusion list** — manually exclude any app by bundle ID
- **Local-only storage** — SwiftData persistence, no cloud, no telemetry

### Customization
- **Popup position** — choose where the panel appears on screen
- **Preview panel toggle** — show or hide the content preview sidebar
- **Sound effects** — optional paste sound feedback
- **Launch at login** — auto-start via SMAppService
- **Export / Import** — back up and restore your clips and snippets as JSON

---

## Keyboard Shortcuts

BoboMind is designed to be used without touching the mouse.

| Shortcut | Action |
|:---------|:----—--|
| `Cmd + Shift + V` | Toggle floating panel |
| `Enter` | Paste selected clip |
| `Shift + Enter` | Paste as plain text |
| `Up` / `Down` | Navigate clips |
| `Cmd + P` | Pin / Unpin clip |
| `Delete` | Delete selected clip |
| `Escape` | Close panel |

The global hotkey is fully customizable from Settings > Shortcuts.

---

## How It Works

```
Copy something anywhere
        |
        v
ClipboardMonitor detects change (polling every 0.5s)
        |
        v
Content is hashed (SHA256) and checked for duplicates
        |
        v
Stored in SwiftData with type, source app, and timestamp
        |
        v
Press Cmd+Shift+V --> Floating panel appears
        |
        v
Search, browse, or filter --> Select a clip
        |
        v
Clip is written to system clipboard --> Auto-pasted to target app
```

---

## Tech Stack

| Component | Technology |
|:----------|:-----------|
| Language | Swift 5.10 |
| UI Framework | SwiftUI |
| Persistence | SwiftData |
| Window System | NSPanel (non-activating, floating) |
| Global Hotkey | [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) by Sindre Sorhus |
| Hashing | CryptoKit (SHA256) |
| Platform | macOS Sonoma 14+ |

---

## Architecture

```
BoboMind/
├── App/                  # App entry point, AppDelegate, AppState
├── Models/               # SwiftData models
│   ├── ClipboardItem     #   Clipboard entry with content & metadata
│   ├── ClipGroup         #   User-created clip collections
│   ├── Snippet           #   Reusable text templates
│   ├── ContentType       #   Text, rich text, HTML, image, file, color
│   └── PopupPosition     #   6 panel placement options
├── Services/
│   ├── ClipboardMonitor  #   NSPasteboard polling & capture
│   ├── PasteService      #   Clipboard write & simulated paste
│   ├── StorageService    #   SwiftData CRUD operations
│   ├── HotkeyManager     #   Global shortcut registration
│   ├── ExportImport      #   JSON backup & restore
│   └── ThumbnailCache    #   Image preview caching
├── Views/
│   ├── Panel/            #   NSPanel subclass (Spotlight-like window)
│   ├── Main/             #   Search bar, clip list, row view, preview
│   ├── Groups/           #   Group editor and sidebar
│   ├── Settings/         #   General, shortcuts, appearance, about
│   ├── Snippets/         #   Snippet list and editor
│   └── Components/       #   Reusable UI pieces (icons, empty state, time ago)
└── Utilities/            #   Constants, FuzzyMatcher, extensions
```

---

## Getting Started

### Requirements

- **macOS Sonoma 14** or later
- **Xcode 15** or later

### Build & Run

```bash
# Clone the repository
git clone https://github.com/burakhatipogluu/BoboMind.git
cd BoboMind

# Open in Xcode
open Package.swift
```

Build and run from Xcode (`Cmd + R`). BoboMind will appear as a menu bar icon.

### Configuration

Click the menu bar icon to access Settings:

| Setting | Options | Default |
|:--------|:--------|:--------|
| History limit | 100 / 500 / 1,000 / 5,000 / Unlimited | 500 |
| Popup position | Center, Mouse Cursor, Top, Bottom, Left, Right | Center |
| Preview panel | Show / Hide | Show |
| Paste sound | On / Off | On |
| Launch at login | On / Off | Off |
| Password manager exclusion | On / Off | On |

---

## Contributing

Contributions are welcome! Feel free to open an issue or submit a pull request.

## License

All rights reserved.
