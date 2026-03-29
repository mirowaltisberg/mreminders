# DeskMinder Sub-project 1: Core Widget + Timers + EventKit

**Date:** 2026-03-29
**Scope:** Floating pill widget, reminder creation, live countdown timers, Apple Reminders sync, standard notifications

---

## 1. Overview

DeskMinder is a native macOS reminder app for easily distracted users (especially ADHD). It creates short-term reminders with bold, impossible-to-miss notifications. The app runs as a floating desktop widget — a tiny translucent pill that sits on top of all windows.

Sub-project 1 delivers the core loop: create a reminder → watch it count down → get notified when time is up.

## 2. Target

- **Platform:** macOS 14.0+ (Sonoma minimum)
- **Tech:** Swift, SwiftUI, AppKit (window management), EventKit
- **Bundle ID:** com.miro.deskminder
- **App category:** Productivity
- **Privacy:** No data collected. Local + iCloud Reminders only.

## 3. Architecture

```
DeskMinderApp (@main, SwiftUI lifecycle)
├── AppDelegate (@NSApplicationDelegateAdaptor)
│   ├── Creates FloatingPanelController (NSPanel management)
│   └── Requests EventKit permissions on launch
├── FloatingPanelController
│   ├── NSPanel (borderless, nonactivating, floating level)
│   ├── Hosts SwiftUI views via NSHostingView
│   └── Saves/restores position via UserDefaults
├── ReminderManager (@Observable, singleton)
│   ├── EKEventStore (source of truth)
│   ├── Active reminders: [ActiveReminder] (in-memory, derived from EKReminder)
│   ├── Timer engine (1s tick, stores end dates not remaining seconds)
│   ├── create(text:, minutes:) → EKReminder + local ActiveReminder
│   ├── delete(id:) → removes EKReminder + local ActiveReminder
│   └── onTimerExpired(id:) → triggers notification
├── NotificationManager
│   ├── UNUserNotificationCenter setup
│   └── Schedules/fires standard macOS notifications
└── Views (SwiftUI)
    ├── PillWidgetView (main container, arranges pill stack)
    ├── ReminderPillView (single pill: time + text + X button)
    ├── NewReminderPillView (input pill: editable time + text field)
    └── No Settings, no History, no Menu Bar (later sub-projects)
```

## 4. Widget Design

### Shape & Style
- **Pill/capsule shape** — rounded rectangle with full corner radius (~20px for 36px height)
- **Apple Liquid Glass** aesthetic:
  - macOS 26+: `.glassEffect()` modifier
  - macOS 14-15: `NSVisualEffectView` with `.hudWindow` material + `.behindWindow` blending, wrapped in SwiftUI
  - Specular highlight on top edge (subtle inner white gradient)
  - Multi-layer shadow for depth
  - Saturated backdrop blur
- **Size:** ~220-280px wide × 36px tall per pill (width adapts to text content)
- **Adapts to light/dark** appearance automatically via system materials

### Layout Per Pill
```
[X button (circle, 30px)] [gap 8px] [ 🕐 MM:SS | Reminder text ]
```

- X button: circular glass button to the left of the pill
- Clock icon (SF Symbol `clock`): left side of pill
- Time: next to clock icon, monospaced digits
- Separator: vertical 1px line with gradient opacity
- Text: reminder text, truncated with ellipsis if too long

### Widget Stack
- Each active timer is its own pill
- Pills stack vertically with 6-8px gap
- At the bottom: the "new reminder" input pill (always visible)
- The + button replaces the X button on the input pill
- Entire stack is draggable as a unit

### States
1. **Empty** — Only the input pill visible. Shows "10 min" default + placeholder text.
2. **Active timers** — Timer pills stacked above the input pill. Each shows live countdown.
3. **Urgent** (< 60 seconds) — Pill tints red. X button tints red. Time font weight increases.
4. **Typing** — Input pill has focus ring (subtle blue border). Cursor blinks in text area.

## 5. Interaction Model

### Creating a Reminder
1. Click the time area on the input pill → scroll wheel / drag vertically to adjust minutes (1-99), or click to type a number directly
2. Click the text area → type reminder text
3. Press **Return** → reminder is created, timer starts counting down as a new pill above
4. Input pill resets to defaults (10 min, empty text)

### Deleting a Timer
- Click the X button on any active timer pill → pill animates out (slide + fade), timer is deleted, EKReminder is removed

### Adjusting Time (Input Pill)
- **Scroll wheel** over the time area: increments/decrements by 1 minute
- **Click** the time area: selects the text for direct numeric input
- **Drag vertically** on time area: continuous adjustment
- Range: 1 to 99 minutes (scroll/drag), 1 to 999 minutes (typed)

### Moving the Widget
- **Drag** anywhere on the pill stack (except interactive areas) to reposition
- Position saved to UserDefaults per-screen (keyed by screen identifier)

### Keyboard
- **Return**: Create reminder (when input pill has focus)
- **Escape**: Clear input / deselect
- **Tab**: Move between time and text fields

## 6. Window Management

### NSPanel Configuration
```swift
let panel = NSPanel(
    contentRect: frame,
    styleMask: [.borderless, .nonactivatingPanel],
    backing: .buffered,
    defer: false
)
panel.level = .floating
panel.isMovableByWindowBackground = true
panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
panel.hasShadow = false  // We draw our own glass shadows
panel.backgroundColor = .clear
panel.isOpaque = false
```

### Key Behaviors
- **Non-activating**: Clicking the widget does NOT steal focus from the current app. Text fields use `NSPanel`'s key window behavior — the panel becomes key only when the user clicks a text field, and resigns when they press Return or click elsewhere.
- **Always on top**: `.floating` level keeps it above normal windows
- **All Spaces**: `.canJoinAllSpaces` means the widget appears on every desktop/Space
- **No Dock icon**: `LSUIElement = YES` in Info.plist (app has no Dock presence)
- **Position persistence**: Save `NSPoint` + screen identifier to UserDefaults on drag end. Restore on launch.

### Quitting the App
- Since there's no Dock icon, the app is quit via:
  - Right-click the pill → context menu with "Quit DeskMinder"
  - Activity Monitor / Force Quit
  - (Menu bar mode in a later sub-project will add a proper quit option)

## 7. Timer Engine

### Data Model
```swift
struct ActiveReminder: Identifiable {
    let id: UUID
    let text: String
    let endDate: Date          // When the timer expires
    let ekReminderID: String   // EKReminder calendarItemIdentifier

    var remainingSeconds: Int {
        max(0, Int(endDate.timeIntervalSinceNow))
    }
    var isUrgent: Bool { remainingSeconds < 60 }
    var isExpired: Bool { remainingSeconds <= 0 }
    var displayTime: String {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
```

### Tick Mechanism
- `Timer.publish(every: 1, on: .main, in: .common)` for UI updates
- Store **end dates** (not remaining seconds) so timers survive sleep/wake accurately
- On each tick: ReminderManager updates a `currentDate` published property, which causes SwiftUI to re-evaluate all computed properties on ActiveReminder (remainingSeconds, isUrgent, displayTime)
- When `remainingSeconds` reaches 0: trigger notification, keep pill visible with "0:00" until user dismisses

### Multiple Timers
- All active timers run simultaneously
- No limit on timer count in sub-project 1 (IAP limits come later)
- Timers are ordered by creation time (newest at bottom, just above input pill)

## 8. EventKit Integration

### Setup
- On first launch: request full access to Reminders via `EKEventStore.requestFullAccessToReminders()`
- If denied: show a one-time alert explaining why access is needed, with a button to open System Settings > Privacy > Reminders
- If denied and user doesn't grant: app cannot function (EventKit is mandatory)

### Dedicated List
- On first successful access: check if a "DeskMinder" calendar (list) exists
- If not: create it via `EKCalendar(for: .reminder, eventStore:)` with a distinctive color
- All DeskMinder reminders go into this list

### Creating a Reminder
```swift
func create(text: String, minutes: Int) {
    let endDate = Date().addingTimeInterval(TimeInterval(minutes * 60))

    let ekReminder = EKReminder(eventStore: store)
    ekReminder.title = text
    ekReminder.calendar = deskMinderList
    ekReminder.addAlarm(EKAlarm(absoluteDate: endDate))
    try store.save(ekReminder, commit: true)

    let active = ActiveReminder(
        id: UUID(),
        text: text,
        endDate: endDate,
        ekReminderID: ekReminder.calendarItemIdentifier
    )
    activeReminders.append(active)
}
```

### Deleting a Reminder
- Remove the `EKReminder` from EventKit
- Remove the `ActiveReminder` from the in-memory array

### Sync Behavior
- Creating a reminder in DeskMinder → immediately appears in Apple Reminders on all devices via iCloud
- Completing/deleting in DeskMinder → removed from Apple Reminders
- We do NOT watch for external changes to the Reminders list in sub-project 1 (no two-way sync)

## 9. Notifications

### Standard macOS Notification
- When a timer reaches 0: fire a `UNNotificationRequest`
- Title: "DeskMinder"
- Body: The reminder text
- Sound: `.default` (system notification sound)
- The pill stays visible at "0:00" with the urgent (red) style until dismissed

### Permission
- Request notification permission on first launch alongside EventKit
- If denied: the pill still shows "0:00" and turns red — the visual alert is always there

### Future (Not Sub-project 1)
- Full-screen overlay notifications
- Custom sounds
- Haptic feedback
- Snooze options

## 10. Animations

All animations use SwiftUI spring curves:

- **Pill creation**: New pill slides in from below + fades in (`.spring(response: 0.4, dampingFraction: 0.8)`)
- **Pill deletion**: Slides out to the left + fades out, remaining pills close the gap smoothly
- **Urgent transition**: Smooth color interpolation when timer crosses 60-second threshold
- **Time scroll**: Number rolls with a ticker animation when scrolling to adjust time
- **Focus ring**: Fade in/out on the input pill border when gaining/losing focus
- **Widget drag**: Follows cursor with momentum (handled by NSPanel's `isMovableByWindowBackground`)

## 11. File Structure

```
DeskMinder/
├── DeskMinderApp.swift              // @main, SwiftUI App
├── AppDelegate.swift                // NSApplicationDelegateAdaptor, panel + permissions setup
├── Info.plist                       // LSUIElement = YES, privacy descriptions
├── DeskMinder.entitlements          // com.apple.security.personal-information.calendars
├── Models/
│   └── ActiveReminder.swift         // ActiveReminder struct
├── Managers/
│   ├── ReminderManager.swift        // @Observable, EventKit + timer engine
│   ├── NotificationManager.swift    // UNUserNotificationCenter wrapper
│   └── FloatingPanelController.swift // NSPanel creation + position persistence
├── Views/
│   ├── PillStackView.swift          // Arranges pills vertically
│   ├── ReminderPillView.swift       // Active timer pill (countdown + X)
│   ├── NewReminderPillView.swift    // Input pill (time selector + text field)
│   ├── GlassButtonView.swift        // Reusable circular glass button (X, +)
│   └── GlassPillBackground.swift    // Liquid Glass material + shape
├── Utilities/
│   └── LiquidGlass.swift            // Glass effect helpers, OS version checks
└── Assets.xcassets/
    └── AppIcon.appiconset/
```

## 12. Out of Scope (Later Sub-projects)

- Full-screen notification overlay
- Snooze functionality
- Menu bar mode + popover
- Global keyboard shortcut (show/hide widget)
- Launch at login
- Task mode
- ADHD focus sounds
- History window + SwiftData
- Settings window
- Multi-monitor (widget appears on one screen for now)
- StoreKit 2 IAP
- Localization
- App Store submission

## 13. Success Criteria

Sub-project 1 is done when:
1. App launches with no Dock icon, showing a floating glass pill on the desktop
2. User can set a time (scroll/type) and type reminder text, press Return to create
3. Timer pill appears above the input, counting down live in mm:ss
4. Multiple timers can run simultaneously
5. Clicking X on a timer dismisses it (with animation)
6. Timer at 0 fires a standard macOS notification
7. Timer pill turns red when < 60 seconds remain
8. All reminders sync to Apple Reminders app (visible on iPhone/Watch)
9. Widget is draggable, remembers position between launches
10. Widget appears on all Spaces/desktops
11. Liquid Glass material looks native on both light and dark mode
