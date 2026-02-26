<div align="center">

<img src="assets/logo.png" width="128" alt="BoboMind Icon" />

# BoboMind

### Smart Clipboard Manager for macOS

**Your clipboard, supercharged.** BoboMind lives quietly in your menu bar and gives you instant, Spotlight-style access to everything you've ever copied — text, images, rich text, files, and more.

[![macOS 14+](https://img.shields.io/badge/macOS-Sonoma_14+-0A84FF?style=flat-square&logo=apple&logoColor=white)](https://www.apple.com/macos/sonoma/)
[![Swift 5.10](https://img.shields.io/badge/Swift-5.10-F05138?style=flat-square&logo=swift&logoColor=white)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/Built_with-SwiftUI-006AFF?style=flat-square&logo=swift&logoColor=white)](https://developer.apple.com/swiftui/)
[![SwiftData](https://img.shields.io/badge/Powered_by-SwiftData-34C759?style=flat-square&logo=apple&logoColor=white)](https://developer.apple.com/xcode/swiftdata/)
[![License](https://img.shields.io/badge/License-All_Rights_Reserved-lightgrey?style=flat-square)]()

---

**One hotkey. Infinite clipboard.**

Press `⌘ ⇧ V` and a beautiful floating panel appears — search your history, pick a clip, and it's pasted instantly.

<!-- 
SCREENSHOTS: Add your screenshots here
<img src="screenshots/main-panel.png" width="700" alt="BoboMind Main Panel" />
-->

</div>

---

## ✨ Why BoboMind?

macOS gives you one clipboard slot. BoboMind gives you **unlimited history** with zero friction.

| | |
|---|---|
| 🚀 **Zero friction** | Floating panel appears over any app, pastes directly — no window switching |
| ⚡ **Native speed** | 100% Swift + SwiftUI, feels as fast as Spotlight — no Electron, no overhead |
| 🔒 **Privacy first** | Your data stays on your Mac, never touches a server, no analytics |
| 🔑 **Password safe** | Automatically ignores copies from 1Password, Bitwarden, LastPass & more |

---

## 🎯 Features

### Instant Access
- **Spotlight-style floating panel** with frosted glass vibrancy effect
- **Global hotkey** (`⌘⇧V`) — works from any app, any fullscreen space
- **6 popup positions** — center, mouse cursor, top, bottom, left, right
- **Smooth animations** — fade-in/out transitions, polished macOS-native feel

### Clipboard Intelligence
- **Captures everything** — plain text, rich text, HTML, images, file URLs
- **Smart deduplication** — SHA256 content hashing prevents duplicate entries
- **Source tracking** — see which app each clip was copied from
- **Auto-cleanup** — configurable history limit (100 / 500 / 1K / 5K / unlimited)

### Powerful Search
- **3-tier search** — exact match → prefix match → fuzzy subsequence
- **Regex support** — wrap your pattern in `/slashes/` for regex search
- **Content type filters** — quick chips to filter by text, image, file, HTML
- **Fuzzy matcher** — finds what you need even with typos

### Organization
- 📌 **Pin clips** — keep important items always at the top
- 📁 **Groups** — organize clips into named collections with custom icons
- 📝 **Snippets** — save and manage reusable text templates
- 👁️ **Preview panel** — side-by-side content preview (text, images, rendered HTML)

### Privacy & Security
- 🛡️ Concealed content detection — skips password manager items automatically
- 🌐 Browser extension awareness — detects copies from Bitwarden, 1Password, LastPass, Dashlane, NordPass Chrome extensions
- 🚫 App exclusion list — block any app by bundle ID
- 💾 Local-only storage — SwiftData persistence, no cloud, no telemetry

### Customization
- 📐 Adjustable popup position and panel size (compact / standard / large)
- 👁️ Toggle preview panel on or off
- 🔊 Optional paste sound feedback
- 🚀 Launch at login via SMAppService
- 📦 Export / Import — back up your clips and snippets as JSON

---

## ⌨️ Keyboard Shortcuts

BoboMind is designed keyboard-first — you never need to touch the mouse.

| Shortcut | Action |
|:---------|:-------|
| `⌘⇧V` | Toggle floating panel |
| `↩` | Paste selected clip |
| `⇧↩` | Paste as plain text |
| `↑` / `↓` | Navigate clips |
| `⌘P` | Pin / Unpin clip |
| `⌫` | Delete selected clip |
| `⎋` | Close panel |

> 💡 The global hotkey is fully customizable from **Settings → Shortcuts**.

---

## 🔧 How It Works

```
Copy something anywhere
        ↓
ClipboardMonitor detects change (smart polling)
        ↓
Content hashed (SHA256) + checked for duplicates
        ↓
Stored in SwiftData with type, source app & timestamp
        ↓
Press ⌘⇧V → Floating panel appears
        ↓
Search, browse, or filter → Select a clip
        ↓
Written to system clipboard → Auto-pasted to target app
```

---

## 🏗️ Tech Stack

| Component | Technology |
|:----------|:-----------|
| Language | Swift 5.10 |
| UI Framework | SwiftUI |
| Persistence | SwiftData |
| Window System | NSPanel (non-activating, floating) |
| Global Hotkey | Carbon Events API |
| Hashing | CryptoKit (SHA256) |
| Platform | macOS Sonoma 14+ |

---

## 📁 Architecture

```
BoboMind/
├── App/                  # Entry point, AppDelegate, AppState
├── Models/               # SwiftData models
│   ├── ClipboardItem     #   Clipboard entry with content & metadata
│   ├── ClipGroup         #   User-created clip collections
│   ├── Snippet           #   Reusable text templates
│   ├── ContentType       #   Text, rich text, HTML, image, file
│   ├── PanelSize         #   Compact, standard, large
│   └── PopupPosition     #   6 panel placement options
├── Services/
│   ├── ClipboardMonitor  #   NSPasteboard polling & capture
│   ├── PasteService      #   Clipboard write with paste detection
│   ├── StorageService    #   SwiftData CRUD (ModelActor)
│   ├── HotkeyManager     #   Carbon global shortcut registration
│   ├── ExportImport      #   JSON backup & restore
│   └── ThumbnailCache    #   Async image preview caching
├── Views/
│   ├── Panel/            #   FloatingPanel (NSPanel subclass)
│   ├── Main/             #   Search bar, clip list, row view, preview
│   ├── Groups/           #   Group editor
│   ├── Settings/         #   General, shortcuts, appearance, about
│   ├── Snippets/         #   Snippet list and editor
│   └── Components/       #   Reusable UI (icons, empty state, toast)
└── Utilities/            #   Constants, FuzzyMatcher, extensions
```

---

## 🚀 Getting Started

### Requirements

- **macOS Sonoma 14** or later
- **Xcode 15** or later

### Build & Run

```bash
git clone https://github.com/burakhatipogluu/BoboMind.git
cd BoboMind
open BoboMind.xcodeproj
```

Build and run (`⌘R`). BoboMind will appear as a 🐾 icon in your menu bar.

### Configuration

Click the menu bar icon → **Settings** to customize:

| Setting | Options | Default |
|:--------|:--------|:--------|
| History limit | 100 / 500 / 1K / 5K / Unlimited | 500 |
| Popup position | Center, Mouse, Top, Bottom, Left, Right | Center |
| Panel size | Compact / Standard / Large | Standard |
| Preview panel | Show / Hide | Show |
| Paste sound | On / Off | On |
| Launch at login | On / Off | Off |
| Password manager exclusion | On / Off | On |

---

## 🔐 Privacy

BoboMind is built with privacy as a core principle:

- **100% offline** — no network calls, no analytics, no telemetry
- **Local storage only** — all data stays in your Mac's Application Support directory
- **Password manager safe** — automatically detects and ignores sensitive copies
- **You own your data** — export anytime, delete everything with one click

Read our full [Privacy Policy](PRIVACY.md).

---

## 📄 License

All rights reserved. © 2026 Burak Hatipoğlu

---

<div align="center">

**Made with ❤️ in Istanbul**

[Report Bug](https://github.com/burakhatipogluu/BoboMind/issues) · [Request Feature](https://github.com/burakhatipogluu/BoboMind/issues)

</div>
