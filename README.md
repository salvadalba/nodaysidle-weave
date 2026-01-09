<p align="center">
  <img src="assets/hero.png" alt="Weave - Voice to Topical Workspaces" width="600">
</p>

# 🧵 Weave

**A native macOS companion brain for Super Whisper Pro** that automatically transforms continuous voice streams into visually organized, topical workspaces.

[![macOS](https://img.shields.io/badge/macOS-14.0+-black?style=flat-square&logo=apple)](https://developer.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-6.2-orange?style=flat-square&logo=swift)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-Native-blue?style=flat-square)](https://developer.apple.com/xcode/swiftui/)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

---

## ✨ Features

- **🎤 Clipboard Monitoring** — Automatically captures dictation from Super Whisper Pro
- **🧠 On-Device AI Classification** — Zero-shot topic detection using Apple's NaturalLanguage framework
- **📦 Topical Workspaces** — Droplets auto-route to project columns (Ideas, Tasks, Bugs, Notes)
- **🎨 Glass Morphism UI** — Beautiful `.ultraThinMaterial` design with fluid animations
- **📱 Responsive Layout** — Adapts to any window size (perfect for Aerospace tiling!)
- **🔒 Privacy-First** — All processing happens locally, no cloud, no data leaves your Mac

---

## 🚀 Quick Start

### Requirements

- macOS 14.0+
- Xcode 15.0+ (or Xcode 26+)
- Super Whisper Pro (optional, for voice dictation)

### Build & Run

```bash
# Clone the repository
git clone https://github.com/salvadalba/nodaysidle-weave.git
cd nodaysidle-weave

# Open in Xcode
open Weave.xcodeproj

# Build and Run (⌘R)
```

Or build from command line:

```bash
xcodebuild -project Weave.xcodeproj -scheme Weave -configuration Debug build
open build/Build/Products/Debug/Weave.app
```

---

## 🎯 How It Works

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│ Super Whisper   │────▶│  Clipboard       │────▶│  Classification │
│ Pro (Dictate)   │     │  Listener        │     │  Service        │
└─────────────────┘     └──────────────────┘     └────────┬────────┘
                                                          │
                                                          ▼
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Project        │◀────│  Routing         │◀────│  Topic Match    │
│  Columns UI     │     │  Service         │     │  + Confidence   │
└─────────────────┘     └──────────────────┘     └─────────────────┘
```

1. **Dictate** with Super Whisper Pro (or just copy text)
2. **Weave monitors** your clipboard every 250ms
3. **AI classifies** the content using semantic similarity
4. **Droplet routes** to the matching project column
5. **Data persists** locally with SwiftData

---

## 🏗️ Architecture

| Layer | Technology |
|-------|------------|
| **UI** | SwiftUI, Glass Morphism, Adaptive Grid |
| **State** | `@Observable`, Combine |
| **Data** | SwiftData (local SQLite) |
| **AI** | NaturalLanguage framework (NLTagger, NLEmbedding) |
| **Logging** | OSLog with categories |

### Project Structure

```
Weave/
├── WeaveApp.swift              # App entry point
├── Models/
│   ├── Project.swift           # @Model for project columns
│   └── Droplet.swift           # @Model for text droplets
├── Services/
│   ├── ClipboardListenerService.swift
│   ├── ClassificationService.swift
│   ├── PersistenceService.swift
│   ├── DropletRoutingService.swift
│   └── DropletAnimationService.swift
├── Views/
│   ├── ContentView.swift       # Main responsive layout
│   ├── ProjectColumn.swift     # Glass column component
│   ├── DropletView.swift       # Droplet card component
│   └── SettingsView.swift      # Preferences UI
├── ViewModels/
│   └── ContentViewModel.swift  # Service coordinator
└── Utilities/
    └── Logging.swift           # OSLog infrastructure
```

---

## ⚙️ Settings

Access via the **⚙️ gear icon** in the toolbar:

| Setting | Description |
|---------|-------------|
| **Confidence Threshold** | Minimum score for topic matching (default: 60%) |
| **Polling Interval** | How often to check clipboard (100-500ms) |
| **Debounce Duration** | Wait time before processing (200-1000ms) |
| **Auto-Create Projects** | Create new projects for unknown topics |

---

## 🎨 Design Philosophy

- **Local-First** — No servers, no APIs, no internet required
- **Privacy-Focused** — Your voice, your data, stays on your Mac
- **Native Experience** — Pure SwiftUI, no web views or Electron
- **Fluid UI** — Glass morphism with responsive animations

---

## 📋 Roadmap

- [ ] Drag-and-drop droplet reordering
- [ ] Export to Markdown/JSON
- [ ] Keyboard shortcuts
- [ ] Menu bar quick capture
- [ ] iCloud sync (opt-in)
- [ ] Custom classification models (CoreML)

---

## 🤝 Contributing

Contributions welcome! Please read the contributing guidelines and submit PRs.

---

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

---

<p align="center">
  <strong>Built with ❤️ for Super Whisper Pro users</strong><br>
  <sub>Made with SwiftUI, SwiftData, and NaturalLanguage</sub>
</p>
