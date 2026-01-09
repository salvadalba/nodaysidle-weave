# 📖 Weave User Guide

Welcome to **Weave** — your native macOS companion for organizing voice dictations into topical workspaces!

---

## 🚀 Getting Started

### First Launch

1. **Open Weave** from your Applications folder or build from Xcode
2. You'll see an empty workspace with two options:
   - **Create Project** — Add a custom project column
   - **Add Sample Data** — Quick start with Ideas, Tasks, Bugs, Notes

### Creating Your First Projects

Click **"Add Sample Data"** to create four default project columns:

| Project | Color | Keywords |
|---------|-------|----------|
| 💜 **Ideas** | Purple | idea, concept, brainstorm, think |
| 💙 **Tasks** | Blue | task, todo, do, work |
| ❤️ **Bugs** | Red | bug, fix, error, issue |
| 💚 **Notes** | Green | note, remember, memo |

---

## 🎤 Using with Super Whisper Pro

Weave is designed to work seamlessly with **Super Whisper Pro**:

1. **Start Listening** — Click the ▶️ play button in Weave's toolbar
2. **Dictate** in Super Whisper Pro
3. Super Whisper automatically copies text to clipboard
4. **Weave captures** the clipboard content
5. **AI classifies** the topic and routes to the matching column

### Example Dictations

| You say... | Routes to |
|------------|-----------|
| *"I have an idea for a new feature"* | 💜 Ideas |
| *"I need to fix the login bug"* | ❤️ Bugs |
| *"Remember to call the client tomorrow"* | 💚 Notes |
| *"Add task to review the pull request"* | 💙 Tasks |

---

## ⌨️ Manual Clipboard Capture

Don't have Super Whisper Pro? No problem!

1. **Start Listening** (▶️ button)
2. **Copy any text** (⌘C) from anywhere
3. Weave automatically captures and classifies it!

Try copying this: *"There's a critical bug in the payment system"*

---

## 🎯 Understanding Classification

### How It Works

Weave uses Apple's **NaturalLanguage framework** for on-device AI:

1. **Keyword Matching** — Direct topic word detection (highest weight)
2. **Semantic Similarity** — NLEmbedding for meaning-based matching
3. **Confidence Scoring** — 0-100% confidence in the classification

### Confidence Levels

| Score | Meaning |
|-------|---------|
| 🟢 **60-100%** | High confidence, routed to matching project |
| 🟡 **30-59%** | Medium confidence, may create new project |
| 🔴 **0-29%** | Low confidence, goes to "Uncategorized" |

---

## ➕ Creating Custom Projects

1. Click the **+** button in the toolbar
2. Enter a **Project Name** (e.g., "Meetings")
3. Choose a **Color**
4. Add **Keywords** (comma-separated): `meeting, call, sync, standup`
5. Click **Create Project**

### Tips for Keywords

- Use **singular and plural**: `bug, bugs`
- Include **synonyms**: `error, issue, problem`
- Add **action words**: `fix, debug, resolve`
- Keep them **lowercase** (matching is case-insensitive)

---

## ⚙️ Settings

Access settings via the **⚙️ gear icon**:

### Classification Tab

| Setting | Description | Default |
|---------|-------------|---------|
| **Confidence Threshold** | Minimum score to match a project | 60% |
| **Auto-Create Projects** | Create new projects for unknown topics | On |

### Clipboard Tab

| Setting | Description | Default |
|---------|-------------|---------|
| **Polling Interval** | How often to check clipboard | 250ms |
| **Debounce Duration** | Wait before processing | 500ms |
| **Minimum Length** | Ignore text shorter than | 3 chars |

### Recommended Settings

- **Fast typist?** Lower debounce to 200ms
- **Slow network?** Keep polling at 250ms
- **Too many projects?** Raise confidence to 70%

---

## 📊 Understanding the UI

### Project Column

```
┌─────────────────────────┐
│ 💜 Ideas           (3)  │  ← Header with color & count
├─────────────────────────┤
│ ┌─────────────────────┐ │
│ │ "New feature idea"  │ │  ← Droplet card
│ │ 2 min ago    85% 🟢 │ │  ← Timestamp & confidence
│ └─────────────────────┘ │
│ ┌─────────────────────┐ │
│ │ "Brainstorm UI"     │ │
│ │ 5 min ago    72% 🟢 │ │
│ └─────────────────────┘ │
└─────────────────────────┘
```

### Status Indicator

Bottom-right corner shows:

- 🟢 **Listening** — Actively monitoring clipboard
- ⚫ **Paused** — Click to start listening
- **X captured** — Number of droplets processed this session

---

## 🔒 Privacy & Security

### Local-First Design

- ✅ **All processing on-device** — No internet required
- ✅ **No cloud sync** — Data never leaves your Mac
- ✅ **No analytics** — We don't track anything
- ✅ **App Sandbox** — Runs in secure container

### Data Storage

Your data is stored locally in:

```
~/Library/Application Support/Weave/
```

---

## 🛠️ Troubleshooting

### Droplets Not Appearing?

1. ✅ Is Weave **listening**? (Check for 🟢 indicator)
2. ✅ Is text **long enough**? (Minimum 3 characters)
3. ✅ Is it **text content**? (Images/files are ignored)

### Wrong Classification?

1. **Add more keywords** to the correct project
2. **Lower confidence threshold** in Settings
3. **Drag droplet** to correct column (coming soon!)

### App Not Responding?

1. Quit and reopen Weave
2. Check Console.app for logs (search "com.weave.app")

---

## 🎨 Design Tips

### Aerospace Tiling

Weave's responsive layout works great with tiling window managers:

- **Narrow tile** → Columns stack vertically
- **Wide tile** → Columns spread horizontally
- **Full screen** → All columns visible

### Recommended Layouts

| Screen Size | Suggested Columns |
|-------------|-------------------|
| 13" MacBook | 2-3 projects |
| 15" MacBook | 3-4 projects |
| 27" iMac | 5-6 projects |
| Ultrawide | 7+ projects |

---

## 💡 Pro Tips

1. **Keep projects focused** — 4-6 projects is ideal
2. **Use specific keywords** — "authentication" beats "auth"
3. **Review regularly** — Archive old droplets weekly
4. **Start broad** — You can always split projects later

---

## 📬 Feedback

Found a bug? Have a feature request?

- 🐛 [Report Issues](https://github.com/salvadalba/nodaysidle-weave/issues)
- 💡 [Feature Requests](https://github.com/salvadalba/nodaysidle-weave/discussions)

---

<p align="center">
  <strong>Happy Weaving! 🧵</strong>
</p>
