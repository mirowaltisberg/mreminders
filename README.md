# mreminders

A lightweight macOS desktop reminder app. Floating pill widget, countdown timers, synced to Apple Reminders.

Built for people who get easily distracted — create a reminder in under 3 seconds, get notified when time's up.

## Features

- **Floating pill widget** — always-on-top, draggable, lives on every Space
- **Countdown timers** — live mm:ss display, multiple simultaneous timers
- **Apple Reminders sync** — every reminder syncs via iCloud to iPhone, iPad, Apple Watch
- **Liquid Glass UI** — native macOS 26 glass effect with light-mode fallback
- **Zero friction** — type text, set time, press Return. Done.
- **No Dock icon** — runs silently as an accessory app

## Requirements

- macOS 14.0+ (Sonoma)
- Xcode 26+ / Swift 6
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

## Setup

```bash
# Install XcodeGen if needed
brew install xcodegen

# Generate Xcode project
xcodegen generate

# Build and run
xcodebuild -project mreminders.xcodeproj -scheme mreminders -configuration Debug build
open ~/Library/Developer/Xcode/DerivedData/mreminders-*/Build/Products/Debug/mreminders.app
```

Or open `mreminders.xcodeproj` in Xcode and press Cmd+R.

## Usage

| Action | How |
|---|---|
| Set time | Scroll wheel over time area, or click to type |
| Create reminder | Type text + press Return |
| Dismiss timer | Click the X button |
| Move widget | Drag anywhere on the pill |
| Quit | Right-click → Quit mreminders |

## Architecture

```
mreminders/
├── mremindersApp.swift          # SwiftUI App entry point
├── AppDelegate.swift            # NSPanel setup, permissions, wiring
├── Models/
│   └── ActiveReminder.swift     # Timer data model
├── Managers/
│   ├── ReminderManager.swift    # EventKit + timer engine
│   ├── NotificationManager.swift
│   └── PanelManager.swift       # Floating NSPanel + position persistence
└── Views/
    ├── PillStackView.swift      # Main widget layout
    ├── ReminderPillView.swift   # Active timer pill
    ├── NewReminderPillView.swift # Input pill
    └── LiquidGlassModifiers.swift # Glass material + buttons
```

## Tech Stack

Swift 6 · SwiftUI · AppKit (NSPanel) · EventKit · UserNotifications · Combine

## License

Private project.
