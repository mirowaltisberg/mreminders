# mreminders

A tiny macOS reminder app that floats on your desktop. For people who forget things 5 seconds after thinking of them.

Inspired by [DeskMinder](https://deskminder.appps.od.ua/).

---

**Type. Set time. Return. That's it.**

A translucent pill sits on your desktop. You type a reminder, set a duration, and press Return. It counts down. When it hits zero, you get slapped with a notification. No accounts, no cloud, no complexity.

Every reminder syncs to Apple Reminders instantly — so it shows up on your iPhone, iPad, and Apple Watch too.

## What it looks like

A floating pill widget with Apple's Liquid Glass material:

```
  (x)  [ 04:32  |  Join standup call  ]
  (x)  [ 12:15  |  Check CI build     ]
  (+)  [ 10 min |  Type reminder...   ]
```

- Each active timer is its own pill, counting down live
- Pill turns red when < 60 seconds remain
- Click X to dismiss, scroll wheel to adjust time
- Drag to reposition anywhere on screen

## Install

**Requirements:** macOS 14+ (Sonoma), Xcode 26+, [XcodeGen](https://github.com/yonaskolb/XcodeGen)

```bash
git clone https://github.com/mirowaltisberg/mreminders.git
cd mreminders
brew install xcodegen   # if you don't have it
xcodegen generate
```

Then either:

```bash
# Terminal
xcodebuild -scheme mreminders build && open ~/Library/Developer/Xcode/DerivedData/mreminders-*/Build/Products/Debug/mreminders.app
```

Or open `mreminders.xcodeproj` in Xcode and hit Cmd+R.

On first launch, grant **Reminders** and **Notifications** permissions when prompted.

## How to use

| | |
|---|---|
| **Create reminder** | Type text, press Return |
| **Set time** | Scroll wheel over the time, or click to type (1-999 min) |
| **Dismiss timer** | Click the X button on any pill |
| **Move widget** | Drag the pill stack anywhere |
| **Quit** | Right-click the widget |

The widget floats above all windows, appears on every Space, and has no Dock icon.

## How it works

- **EventKit** is the source of truth. Every reminder is an `EKReminder` in a dedicated "mreminders" list. iCloud syncs it everywhere.
- **Timer engine** stores end dates (not remaining seconds) so countdowns survive sleep/wake.
- **NSPanel** with `.nonactivatingPanel` style — clicking the widget never steals focus from your current app.
- **Liquid Glass** on macOS 26+ via `.glassEffect()`, with `.ultraThinMaterial` fallback on older versions.

## Project structure

```
mreminders/
  mremindersApp.swift             @main, SwiftUI lifecycle
  AppDelegate.swift               Panel + permissions + wiring
  Models/
    ActiveReminder.swift          Timer data model
  Managers/
    ReminderManager.swift         EventKit + 1s timer tick
    NotificationManager.swift     UNUserNotificationCenter
    PanelManager.swift            Floating NSPanel, position memory
  Views/
    PillStackView.swift           Vertical pill layout
    ReminderPillView.swift        Active timer (countdown + X)
    NewReminderPillView.swift     Input pill (time + text)
    LiquidGlassModifiers.swift    Glass materials + buttons
```

## Roadmap

- [ ] Full-screen notification overlay (the killer feature)
- [ ] Snooze (1, 5, 10, 15, 30 min)
- [ ] Menu bar mode
- [ ] Global keyboard shortcut to show/hide
- [ ] Task mode with ADHD focus sounds
- [ ] History window
- [ ] Settings
- [ ] Multi-monitor support

## Built with

Swift 6 / SwiftUI / AppKit / EventKit / Combine

## License

MIT
