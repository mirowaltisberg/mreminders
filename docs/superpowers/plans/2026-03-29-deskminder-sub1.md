# DeskMinder Sub-project 1: Core Widget + Timers + EventKit — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a floating macOS pill widget that creates countdown reminders synced to Apple Reminders.

**Architecture:** SwiftUI app with `@NSApplicationDelegateAdaptor` for AppKit bridging. NSPanel hosts SwiftUI views via NSHostingView. ReminderManager (@Observable) wraps EventKit as single source of truth. 1-second timer tick drives countdown display.

**Tech Stack:** Swift 6, SwiftUI, AppKit (NSPanel), EventKit, UserNotifications, Combine (Timer.publish), XcodeGen

**Spec:** `docs/superpowers/specs/2026-03-29-deskminder-sub1-design.md`

---

## File Structure

```
mreminders/
├── project.yml                          # XcodeGen project definition
├── .gitignore
├── DeskMinder/
│   ├── DeskMinderApp.swift              # @main SwiftUI App, environment setup
│   ├── AppDelegate.swift                # NSPanel creation, permissions, lifecycle
│   ├── Info.plist                       # LSUIElement, privacy descriptions
│   ├── DeskMinder.entitlements          # Reminders calendar access
│   ├── Models/
│   │   └── ActiveReminder.swift         # Timer data model
│   ├── Managers/
│   │   ├── ReminderManager.swift        # EventKit + timer engine (@Observable)
│   │   ├── NotificationManager.swift    # UNUserNotificationCenter wrapper
│   │   └── PanelManager.swift           # NSPanel subclass + position persistence
│   ├── Views/
│   │   ├── PillStackView.swift          # Vertical stack of all pills
│   │   ├── ReminderPillView.swift       # Active timer pill (countdown + dismiss)
│   │   ├── NewReminderPillView.swift    # Input pill (time + text + Return to create)
│   │   └── LiquidGlassModifiers.swift   # Glass material, pill shape, glass button
│   └── Assets.xcassets/
│       ├── Contents.json
│       └── AppIcon.appiconset/
│           └── Contents.json
├── DeskMinderTests/
│   ├── ActiveReminderTests.swift
│   └── ReminderManagerTests.swift
```

---

### Task 1: Project Scaffolding

**Files:**
- Create: `project.yml`, `.gitignore`, all skeleton directories, `DeskMinder/Info.plist`, `DeskMinder/DeskMinder.entitlements`, `DeskMinder/Assets.xcassets/Contents.json`, `DeskMinder/Assets.xcassets/AppIcon.appiconset/Contents.json`, `DeskMinder/DeskMinderApp.swift`

- [ ] **Step 1: Initialize git repo**

```bash
cd /Users/miro/Desktop/Personal_Projects/mreminders
git init
```

- [ ] **Step 2: Create .gitignore**

Create `.gitignore`:

```gitignore
# Xcode
*.xcodeproj/xcuserdata/
*.xcworkspace/xcuserdata/
DerivedData/
build/
*.pbxuser
*.mode1v3
*.mode2v3
*.perspectivev3
*.xccheckout
*.moved-aside
*.hmap
*.ipa
*.dSYM.zip
*.dSYM

# XcodeGen
*.xcodeproj

# macOS
.DS_Store
.AppleDouble
.LSOverride

# Brainstorm assets
.superpowers/
```

- [ ] **Step 3: Create directory structure**

```bash
mkdir -p DeskMinder/Models DeskMinder/Managers DeskMinder/Views DeskMinder/Assets.xcassets/AppIcon.appiconset
mkdir -p DeskMinderTests
```

- [ ] **Step 4: Create Info.plist**

Create `DeskMinder/Info.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>LSUIElement</key>
    <true/>
    <key>NSRemindersUsageDescription</key>
    <string>DeskMinder syncs your reminders to Apple Reminders so they appear on all your devices.</string>
    <key>CFBundleName</key>
    <string>DeskMinder</string>
    <key>CFBundleDisplayName</key>
    <string>DeskMinder</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>LSMinimumSystemVersion</key>
    <string>$(MACOSX_DEPLOYMENT_TARGET)</string>
</dict>
</plist>
```

- [ ] **Step 5: Create entitlements**

Create `DeskMinder/DeskMinder.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <false/>
    <key>com.apple.security.personal-information.calendars</key>
    <true/>
</dict>
</plist>
```

Note: App Sandbox is disabled for development. The floating NSPanel with `.canJoinAllSpaces` requires this. For App Store submission (later sub-project), we'll re-evaluate sandbox compatibility.

- [ ] **Step 6: Create asset catalog stubs**

Create `DeskMinder/Assets.xcassets/Contents.json`:

```json
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

Create `DeskMinder/Assets.xcassets/AppIcon.appiconset/Contents.json`:

```json
{
  "images" : [
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "16x16"
    },
    {
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "16x16"
    },
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "32x32"
    },
    {
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "32x32"
    },
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "128x128"
    },
    {
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "128x128"
    },
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "256x256"
    },
    {
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "256x256"
    },
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "512x512"
    },
    {
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "512x512"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

- [ ] **Step 7: Create minimal DeskMinderApp.swift**

Create `DeskMinder/DeskMinderApp.swift`:

```swift
import SwiftUI

@main
struct DeskMinderApp: App {
    var body: some Scene {
        // No visible windows from SwiftUI — the NSPanel is managed by AppDelegate
        Settings {
            Text("DeskMinder Settings (coming soon)")
        }
    }
}
```

- [ ] **Step 8: Create project.yml for XcodeGen**

Create `project.yml`:

```yaml
name: DeskMinder
options:
  bundleIdPrefix: com.miro
  deploymentTarget:
    macOS: "14.0"
  minimumXcodeGenVersion: "2.38.0"
  generateEmptyDirectories: true

settings:
  base:
    SWIFT_VERSION: "6.0"
    MACOSX_DEPLOYMENT_TARGET: "14.0"
    SWIFT_STRICT_CONCURRENCY: complete

targets:
  DeskMinder:
    type: application
    platform: macOS
    sources:
      - path: DeskMinder
    settings:
      base:
        INFOPLIST_FILE: DeskMinder/Info.plist
        CODE_SIGN_ENTITLEMENTS: DeskMinder/DeskMinder.entitlements
        PRODUCT_BUNDLE_IDENTIFIER: com.miro.deskminder
        CODE_SIGN_IDENTITY: "-"
        PRODUCT_NAME: DeskMinder
        COMBINE_HIDPI_IMAGES: YES

  DeskMinderTests:
    type: bundle.unit-test
    platform: macOS
    sources:
      - path: DeskMinderTests
    dependencies:
      - target: DeskMinder
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.miro.deskminder.tests
```

- [ ] **Step 9: Install XcodeGen if needed and generate project**

```bash
which xcodegen || brew install xcodegen
cd /Users/miro/Desktop/Personal_Projects/mreminders
xcodegen generate
```

Expected: `⚙ Generating plists...` → `Created project DeskMinder.xcodeproj`

- [ ] **Step 10: Create a placeholder test file so the test target compiles**

Create `DeskMinderTests/ActiveReminderTests.swift`:

```swift
import Testing

@Suite("ActiveReminder Tests")
struct ActiveReminderTests {
    @Test("placeholder")
    func placeholder() {
        #expect(true)
    }
}
```

- [ ] **Step 11: Build to verify project compiles**

```bash
cd /Users/miro/Desktop/Personal_Projects/mreminders
xcodebuild -project DeskMinder.xcodeproj -scheme DeskMinder -configuration Debug build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 12: Commit**

```bash
git add .gitignore project.yml DeskMinder/ DeskMinderTests/
git commit -m "feat: scaffold DeskMinder macOS app project"
```

---

### Task 2: ActiveReminder Model + Tests

**Files:**
- Create: `DeskMinder/Models/ActiveReminder.swift`
- Modify: `DeskMinderTests/ActiveReminderTests.swift`

- [ ] **Step 1: Write tests for ActiveReminder**

Replace `DeskMinderTests/ActiveReminderTests.swift`:

```swift
import Testing
import Foundation
@testable import DeskMinder

@Suite("ActiveReminder Tests")
struct ActiveReminderTests {

    @Test("remainingSeconds returns positive when timer active")
    func remainingSecondsActive() {
        let reminder = ActiveReminder(
            id: UUID(),
            text: "Test",
            endDate: Date().addingTimeInterval(120),
            ekReminderID: "test-id"
        )
        let remaining = reminder.remainingSeconds(from: Date())
        #expect(remaining > 115 && remaining <= 120)
    }

    @Test("remainingSeconds returns 0 when expired")
    func remainingSecondsExpired() {
        let reminder = ActiveReminder(
            id: UUID(),
            text: "Test",
            endDate: Date().addingTimeInterval(-10),
            ekReminderID: "test-id"
        )
        #expect(reminder.remainingSeconds(from: Date()) == 0)
    }

    @Test("isUrgent true when under 60 seconds")
    func urgentUnder60() {
        let reminder = ActiveReminder(
            id: UUID(),
            text: "Test",
            endDate: Date().addingTimeInterval(30),
            ekReminderID: "test-id"
        )
        #expect(reminder.isUrgent(from: Date()) == true)
    }

    @Test("isUrgent false when over 60 seconds")
    func notUrgentOver60() {
        let reminder = ActiveReminder(
            id: UUID(),
            text: "Test",
            endDate: Date().addingTimeInterval(90),
            ekReminderID: "test-id"
        )
        #expect(reminder.isUrgent(from: Date()) == false)
    }

    @Test("isUrgent false when expired (0 seconds)")
    func notUrgentWhenExpired() {
        let reminder = ActiveReminder(
            id: UUID(),
            text: "Test",
            endDate: Date().addingTimeInterval(-5),
            ekReminderID: "test-id"
        )
        #expect(reminder.isUrgent(from: Date()) == false)
    }

    @Test("isExpired true when past end date")
    func expiredPastEndDate() {
        let reminder = ActiveReminder(
            id: UUID(),
            text: "Test",
            endDate: Date().addingTimeInterval(-1),
            ekReminderID: "test-id"
        )
        #expect(reminder.isExpired(from: Date()) == true)
    }

    @Test("displayTime formats correctly")
    func displayTimeFormat() {
        let now = Date()
        let reminder = ActiveReminder(
            id: UUID(),
            text: "Test",
            endDate: now.addingTimeInterval(754), // 12 min 34 sec
            ekReminderID: "test-id"
        )
        let display = reminder.displayTime(from: now)
        #expect(display == "12:34")
    }

    @Test("displayTime shows 0:00 when expired")
    func displayTimeExpired() {
        let reminder = ActiveReminder(
            id: UUID(),
            text: "Test",
            endDate: Date().addingTimeInterval(-60),
            ekReminderID: "test-id"
        )
        #expect(reminder.displayTime(from: Date()) == "0:00")
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd /Users/miro/Desktop/Personal_Projects/mreminders
xcodebuild test -project DeskMinder.xcodeproj -scheme DeskMinderTests -configuration Debug 2>&1 | grep -E "(Test |error:|BUILD)"
```

Expected: Compilation errors — `ActiveReminder` not found.

- [ ] **Step 3: Implement ActiveReminder**

Create `DeskMinder/Models/ActiveReminder.swift`:

```swift
import Foundation

struct ActiveReminder: Identifiable, Equatable {
    let id: UUID
    let text: String
    let endDate: Date
    let ekReminderID: String

    func remainingSeconds(from now: Date = Date()) -> Int {
        max(0, Int(endDate.timeIntervalSince(now).rounded(.up)))
    }

    func isUrgent(from now: Date = Date()) -> Bool {
        let remaining = remainingSeconds(from: now)
        return remaining > 0 && remaining < 60
    }

    func isExpired(from now: Date = Date()) -> Bool {
        remainingSeconds(from: now) <= 0
    }

    func displayTime(from now: Date = Date()) -> String {
        let total = remainingSeconds(from: now)
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }
}
```

- [ ] **Step 4: Regenerate project and run tests**

```bash
cd /Users/miro/Desktop/Personal_Projects/mreminders
xcodegen generate
xcodebuild test -project DeskMinder.xcodeproj -scheme DeskMinderTests -configuration Debug 2>&1 | grep -E "(Test |passed|failed|BUILD)"
```

Expected: All tests pass, `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add DeskMinder/Models/ActiveReminder.swift DeskMinderTests/ActiveReminderTests.swift
git commit -m "feat: add ActiveReminder model with time computation"
```

---

### Task 3: ReminderManager — EventKit Integration

**Files:**
- Create: `DeskMinder/Managers/ReminderManager.swift`

- [ ] **Step 1: Implement ReminderManager with EventKit**

Create `DeskMinder/Managers/ReminderManager.swift`:

```swift
import Foundation
import EventKit
import Combine

@Observable
@MainActor
final class ReminderManager {

    // MARK: - Published State

    var activeReminders: [ActiveReminder] = []
    var currentDate: Date = Date()
    var permissionGranted: Bool = false

    // MARK: - Private

    private let store = EKEventStore()
    private var timerCancellable: AnyCancellable?
    private var deskMinderCalendar: EKCalendar?
    private var notifiedReminderIDs: Set<UUID> = []

    // Callback when a timer expires (set by AppDelegate to trigger notifications)
    var onReminderExpired: ((ActiveReminder) -> Void)?

    // MARK: - Initialization

    func requestAccess() async {
        do {
            let granted = try await store.requestFullAccessToReminders()
            permissionGranted = granted
            if granted {
                setupCalendar()
            }
        } catch {
            permissionGranted = false
        }
    }

    // MARK: - Calendar Setup

    private func setupCalendar() {
        // Look for existing DeskMinder list
        let calendars = store.calendars(for: .reminder)
        if let existing = calendars.first(where: { $0.title == "DeskMinder" }) {
            deskMinderCalendar = existing
            return
        }

        // Create a new one
        let calendar = EKCalendar(for: .reminder, eventStore: store)
        calendar.title = "DeskMinder"

        // Use the default (local or iCloud) source
        if let defaultSource = store.defaultCalendarForNewReminders()?.source {
            calendar.source = defaultSource
        } else if let localSource = store.sources.first(where: { $0.sourceType == .local }) {
            calendar.source = localSource
        } else {
            return
        }

        do {
            try store.saveCalendar(calendar, commit: true)
            deskMinderCalendar = calendar
        } catch {
            // Fall back to default calendar
            deskMinderCalendar = store.defaultCalendarForNewReminders()
        }
    }

    // MARK: - Timer Engine

    func startTimer() {
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in
                guard let self else { return }
                MainActor.assumeIsolated {
                    self.currentDate = date
                    self.checkExpired()
                }
            }
    }

    func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    private func checkExpired() {
        for reminder in activeReminders {
            if reminder.isExpired(from: currentDate) && !notifiedReminderIDs.contains(reminder.id) {
                notifiedReminderIDs.insert(reminder.id)
                onReminderExpired?(reminder)
            }
        }
    }

    // MARK: - CRUD

    func createReminder(text: String, minutes: Int) {
        guard let calendar = deskMinderCalendar else { return }

        let endDate = Date().addingTimeInterval(TimeInterval(minutes * 60))

        let ekReminder = EKReminder(eventStore: store)
        ekReminder.title = text
        ekReminder.calendar = calendar
        ekReminder.addAlarm(EKAlarm(absoluteDate: endDate))

        do {
            try store.save(ekReminder, commit: true)
        } catch {
            return
        }

        let active = ActiveReminder(
            id: UUID(),
            text: text,
            endDate: endDate,
            ekReminderID: ekReminder.calendarItemIdentifier
        )
        activeReminders.append(active)
    }

    func deleteReminder(_ reminder: ActiveReminder) {
        // Remove from EventKit
        if let ekReminder = store.calendarItem(withIdentifier: reminder.ekReminderID) as? EKReminder {
            do {
                try store.remove(ekReminder, commit: true)
            } catch {
                // Continue with local removal even if EventKit fails
            }
        }

        // Remove from local state
        activeReminders.removeAll { $0.id == reminder.id }
        notifiedReminderIDs.remove(reminder.id)
    }
}
```

- [ ] **Step 2: Regenerate project and build**

```bash
cd /Users/miro/Desktop/Personal_Projects/mreminders
xcodegen generate
xcodebuild -project DeskMinder.xcodeproj -scheme DeskMinder -configuration Debug build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Write unit tests for ReminderManager timer logic**

Create `DeskMinderTests/ReminderManagerTests.swift`:

```swift
import Testing
import Foundation
@testable import DeskMinder

@Suite("ReminderManager Tests")
struct ReminderManagerTests {

    @Test("checkExpired calls onReminderExpired for expired reminders")
    @MainActor
    func checkExpiredTriggersCallback() async {
        let manager = ReminderManager()

        // Manually inject an expired reminder (bypassing EventKit for test)
        let expired = ActiveReminder(
            id: UUID(),
            text: "Expired",
            endDate: Date().addingTimeInterval(-10),
            ekReminderID: "fake-id"
        )
        manager.activeReminders.append(expired)

        var expiredReminders: [ActiveReminder] = []
        manager.onReminderExpired = { reminder in
            expiredReminders.append(reminder)
        }

        // Simulate a tick
        manager.currentDate = Date()

        // Give the timer check a moment (the actual check happens in startTimer sink,
        // but we can test the logic indirectly by calling startTimer and waiting)
        manager.startTimer()
        try? await Task.sleep(for: .milliseconds(1500))
        manager.stopTimer()

        #expect(expiredReminders.count == 1)
        #expect(expiredReminders.first?.text == "Expired")
    }

    @Test("expired reminder only fires callback once")
    @MainActor
    func expiredOnlyFiresOnce() async {
        let manager = ReminderManager()

        let expired = ActiveReminder(
            id: UUID(),
            text: "Expired",
            endDate: Date().addingTimeInterval(-10),
            ekReminderID: "fake-id"
        )
        manager.activeReminders.append(expired)

        var callCount = 0
        manager.onReminderExpired = { _ in callCount += 1 }

        manager.startTimer()
        try? await Task.sleep(for: .milliseconds(2500))
        manager.stopTimer()

        #expect(callCount == 1)
    }
}
```

- [ ] **Step 4: Regenerate and run tests**

```bash
cd /Users/miro/Desktop/Personal_Projects/mreminders
xcodegen generate
xcodebuild test -project DeskMinder.xcodeproj -scheme DeskMinderTests -configuration Debug 2>&1 | grep -E "(Test |passed|failed|BUILD)"
```

Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add DeskMinder/Managers/ReminderManager.swift DeskMinderTests/ReminderManagerTests.swift
git commit -m "feat: add ReminderManager with EventKit and timer engine"
```

---

### Task 4: NotificationManager

**Files:**
- Create: `DeskMinder/Managers/NotificationManager.swift`

- [ ] **Step 1: Implement NotificationManager**

Create `DeskMinder/Managers/NotificationManager.swift`:

```swift
import Foundation
import UserNotifications

@MainActor
final class NotificationManager {

    static let shared = NotificationManager()

    private init() {}

    func requestPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            if !granted {
                // Notifications denied — app still works via visual pill alerts
            }
        } catch {
            // Silently continue — visual alerts still work
        }
    }

    func fireNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Fire immediately
        )

        UNUserNotificationCenter.current().add(request)
    }
}
```

- [ ] **Step 2: Regenerate project and build**

```bash
cd /Users/miro/Desktop/Personal_Projects/mreminders
xcodegen generate
xcodebuild -project DeskMinder.xcodeproj -scheme DeskMinder -configuration Debug build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add DeskMinder/Managers/NotificationManager.swift
git commit -m "feat: add NotificationManager for timer expiry alerts"
```

---

### Task 5: PanelManager — Floating NSPanel

**Files:**
- Create: `DeskMinder/Managers/PanelManager.swift`

- [ ] **Step 1: Implement PanelManager with FloatingPanel subclass**

Create `DeskMinder/Managers/PanelManager.swift`:

```swift
import AppKit
import SwiftUI

// MARK: - FloatingPanel

final class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }

    override init(
        contentRect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing backingStoreType: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        level = .floating
        isMovableByWindowBackground = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        hasShadow = false
        backgroundColor = .clear
        isOpaque = false
        titleVisibility = .hidden
        titlebarAppearsTransparent = true

        // Restore saved position
        if let savedFrame = PanelManager.loadPosition() {
            setFrameOrigin(savedFrame)
        } else {
            centerOnScreen()
        }
    }

    private func centerOnScreen() {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let x = screenFrame.midX - frame.width / 2
        let y = screenFrame.maxY - 120
        setFrameOrigin(NSPoint(x: x, y: y))
    }

    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
        PanelManager.savePosition(frame.origin)
    }
}

// MARK: - PanelManager

@MainActor
final class PanelManager {

    private(set) var panel: FloatingPanel?

    private static let positionXKey = "panelPositionX"
    private static let positionYKey = "panelPositionY"

    func createPanel<Content: View>(with content: Content) {
        let panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 200),
            styleMask: [],
            backing: .buffered,
            defer: false
        )

        let hostingView = NSHostingView(rootView: content)
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        // Use a clear container view
        let containerView = NSView(frame: panel.contentView!.bounds)
        containerView.wantsLayer = true
        containerView.layer?.backgroundColor = .clear
        containerView.addSubview(hostingView)

        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: containerView.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            hostingView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
        ])

        panel.contentView = containerView
        panel.orderFrontRegardless()

        self.panel = panel
    }

    static func savePosition(_ origin: NSPoint) {
        UserDefaults.standard.set(Double(origin.x), forKey: positionXKey)
        UserDefaults.standard.set(Double(origin.y), forKey: positionYKey)
    }

    static func loadPosition() -> NSPoint? {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: positionXKey) != nil else { return nil }
        let x = defaults.double(forKey: positionXKey)
        let y = defaults.double(forKey: positionYKey)
        return NSPoint(x: x, y: y)
    }
}
```

- [ ] **Step 2: Regenerate project and build**

```bash
cd /Users/miro/Desktop/Personal_Projects/mreminders
xcodegen generate
xcodebuild -project DeskMinder.xcodeproj -scheme DeskMinder -configuration Debug build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add DeskMinder/Managers/PanelManager.swift
git commit -m "feat: add floating NSPanel with position persistence"
```

---

### Task 6: Liquid Glass Modifiers

**Files:**
- Create: `DeskMinder/Views/LiquidGlassModifiers.swift`

- [ ] **Step 1: Implement Liquid Glass pill background and button**

Create `DeskMinder/Views/LiquidGlassModifiers.swift`:

```swift
import SwiftUI
import AppKit

// MARK: - Glass Pill Background

struct GlassPillBackground: View {
    var isUrgent: Bool = false

    var body: some View {
        if #available(macOS 26, *) {
            glassPillModern(isUrgent: isUrgent)
        } else {
            glassPillLegacy(isUrgent: isUrgent)
        }
    }

    @available(macOS 26, *)
    private func glassPillModern(isUrgent: Bool) -> some View {
        Capsule()
            .fill(.clear)
            .glassEffect(.regular.interactive, in: .capsule)
            .overlay {
                if isUrgent {
                    Capsule()
                        .fill(Color.red.opacity(0.15))
                        .strokeBorder(Color.red.opacity(0.3), lineWidth: 1)
                }
            }
    }

    private func glassPillLegacy(isUrgent: Bool) -> some View {
        Capsule()
            .fill(.ultraThinMaterial)
            .overlay {
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            colors: isUrgent
                                ? [Color.red.opacity(0.4), Color.red.opacity(0.2)]
                                : [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            }
            .overlay(alignment: .top) {
                // Specular highlight
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.15), Color.clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .frame(height: 18)
                    .padding(.horizontal, 1)
                    .padding(.top, 1)
            }
            .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 8)
            .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Glass Circle Button

struct GlassCircleButton: View {
    enum Style {
        case dismiss
        case add
        case urgentDismiss
    }

    let style: Style
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if #available(macOS 26, *) {
                    circleModern
                } else {
                    circleLegacy
                }
                iconView
            }
            .frame(width: 30, height: 30)
        }
        .buttonStyle(.plain)
    }

    private var iconView: some View {
        Group {
            switch style {
            case .dismiss, .urgentDismiss:
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(
                        style == .urgentDismiss
                            ? Color.red.opacity(0.8)
                            : Color.primary.opacity(0.55)
                    )
            case .add:
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.accentColor.opacity(0.9))
            }
        }
    }

    @available(macOS 26, *)
    private var circleModern: some View {
        Circle()
            .fill(.clear)
            .glassEffect(.regular.interactive, in: .circle)
            .overlay {
                if style == .urgentDismiss {
                    Circle()
                        .fill(Color.red.opacity(0.15))
                        .strokeBorder(Color.red.opacity(0.3), lineWidth: 1)
                }
            }
    }

    private var circleLegacy: some View {
        Circle()
            .fill(.ultraThinMaterial)
            .overlay {
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: style == .urgentDismiss
                                ? [Color.red.opacity(0.4), Color.red.opacity(0.2)]
                                : [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            }
            .overlay(alignment: .top) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.18), Color.clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .frame(height: 15)
                    .padding(.horizontal, 1)
                    .padding(.top, 1)
            }
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Pill Separator

struct PillSeparator: View {
    var isUrgent: Bool = false

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: isUrgent
                        ? [Color.red.opacity(0.02), Color.red.opacity(0.3), Color.red.opacity(0.02)]
                        : [Color.primary.opacity(0.02), Color.primary.opacity(0.2), Color.primary.opacity(0.02)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 1, height: 18)
    }
}
```

- [ ] **Step 2: Regenerate project and build**

```bash
cd /Users/miro/Desktop/Personal_Projects/mreminders
xcodegen generate
xcodebuild -project DeskMinder.xcodeproj -scheme DeskMinder -configuration Debug build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

Note: The `glassEffect` API may need adjustment based on the exact macOS 26 SDK. If the build fails on `.glassEffect(.regular.interactive, in: .capsule)`, check the Xcode 26 SwiftUI docs for the correct signature and update accordingly. The fallback path using `.ultraThinMaterial` works on all supported macOS versions.

- [ ] **Step 3: Commit**

```bash
git add DeskMinder/Views/LiquidGlassModifiers.swift
git commit -m "feat: add Liquid Glass pill and button views"
```

---

### Task 7: ReminderPillView — Active Timer Display

**Files:**
- Create: `DeskMinder/Views/ReminderPillView.swift`

- [ ] **Step 1: Implement ReminderPillView**

Create `DeskMinder/Views/ReminderPillView.swift`:

```swift
import SwiftUI

struct ReminderPillView: View {
    let reminder: ActiveReminder
    let currentDate: Date
    let onDelete: () -> Void

    private var isUrgent: Bool {
        reminder.isUrgent(from: currentDate)
    }

    private var isExpired: Bool {
        reminder.isExpired(from: currentDate)
    }

    var body: some View {
        HStack(spacing: 8) {
            // X button
            GlassCircleButton(
                style: isUrgent || isExpired ? .urgentDismiss : .dismiss,
                action: onDelete
            )

            // Pill body
            HStack(spacing: 10) {
                // Clock icon + time
                HStack(spacing: 5) {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                    Text(reminder.displayTime(from: currentDate))
                        .font(.system(size: 13, weight: isUrgent ? .semibold : .medium)
                            .monospacedDigit())
                }
                .foregroundStyle(
                    isUrgent || isExpired
                        ? Color.red.opacity(0.9)
                        : Color.primary.opacity(0.85)
                )

                PillSeparator(isUrgent: isUrgent || isExpired)

                // Reminder text
                Text(reminder.text)
                    .font(.system(size: 13))
                    .foregroundStyle(
                        isUrgent || isExpired
                            ? Color.primary.opacity(0.95)
                            : Color.primary.opacity(0.9)
                    )
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background {
                GlassPillBackground(isUrgent: isUrgent || isExpired)
            }
        }
        .transition(
            .asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        )
    }
}
```

- [ ] **Step 2: Regenerate project and build**

```bash
cd /Users/miro/Desktop/Personal_Projects/mreminders
xcodegen generate
xcodebuild -project DeskMinder.xcodeproj -scheme DeskMinder -configuration Debug build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add DeskMinder/Views/ReminderPillView.swift
git commit -m "feat: add ReminderPillView with countdown and urgent state"
```

---

### Task 8: NewReminderPillView — Input Pill

**Files:**
- Create: `DeskMinder/Views/NewReminderPillView.swift`

- [ ] **Step 1: Implement NewReminderPillView with scroll-to-set time and text input**

Create `DeskMinder/Views/NewReminderPillView.swift`:

```swift
import SwiftUI

struct NewReminderPillView: View {
    @State private var minutes: Int = 10
    @State private var text: String = ""
    @State private var isEditingTime: Bool = false
    @State private var timeText: String = "10"
    @FocusState private var textFieldFocused: Bool
    @FocusState private var timeFieldFocused: Bool

    let onCreate: (_ text: String, _ minutes: Int) -> Void

    var body: some View {
        HStack(spacing: 8) {
            // + button
            GlassCircleButton(style: .add) {
                textFieldFocused = true
            }

            // Pill body
            HStack(spacing: 10) {
                // Time area — click to edit, scroll to adjust
                timeSection

                PillSeparator()

                // Text input
                TextField("Type reminder...", text: $text)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.primary.opacity(0.9))
                    .focused($textFieldFocused)
                    .onSubmit {
                        submitReminder()
                    }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background {
                GlassPillBackground()
            }
            .onScrollWheel { delta in
                adjustMinutes(by: delta)
            }
        }
    }

    // MARK: - Time Section

    @ViewBuilder
    private var timeSection: some View {
        HStack(spacing: 5) {
            Image(systemName: "clock")
                .font(.system(size: 12))

            if isEditingTime {
                TextField("", text: $timeText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: .medium).monospacedDigit())
                    .frame(width: 36)
                    .multilineTextAlignment(.trailing)
                    .focused($timeFieldFocused)
                    .onSubmit {
                        commitTimeEdit()
                    }
                    .onAppear {
                        timeFieldFocused = true
                    }

                Text("min")
                    .font(.system(size: 13, weight: .medium))
            } else {
                Text("\(minutes) min")
                    .font(.system(size: 13, weight: .medium).monospacedDigit())
                    .onTapGesture {
                        timeText = "\(minutes)"
                        isEditingTime = true
                    }
            }
        }
        .foregroundStyle(Color.primary.opacity(0.7))
    }

    // MARK: - Actions

    private func submitReminder() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, minutes > 0 else { return }
        onCreate(trimmed, minutes)
        text = ""
        // Keep current minutes as default for next reminder
    }

    private func commitTimeEdit() {
        if let value = Int(timeText), value >= 1, value <= 999 {
            minutes = value
        }
        timeText = "\(minutes)"
        isEditingTime = false
        textFieldFocused = true
    }

    private func adjustMinutes(by delta: Int) {
        let newValue = minutes + delta
        minutes = min(99, max(1, newValue))
        timeText = "\(minutes)"
    }
}

// MARK: - Scroll Wheel Modifier

struct ScrollWheelModifier: ViewModifier {
    let onScroll: (Int) -> Void

    func body(content: Content) -> some View {
        content
            .onContinuousHover { phase in
                // Hover tracking needed for scroll detection scope
            }
            .background {
                ScrollWheelReceiver(onScroll: onScroll)
            }
    }
}

struct ScrollWheelReceiver: NSViewRepresentable {
    let onScroll: (Int) -> Void

    func makeNSView(context: Context) -> ScrollWheelNSView {
        let view = ScrollWheelNSView()
        view.onScroll = onScroll
        return view
    }

    func updateNSView(_ nsView: ScrollWheelNSView, context: Context) {
        nsView.onScroll = onScroll
    }
}

final class ScrollWheelNSView: NSView {
    var onScroll: ((Int) -> Void)?
    private var accumulated: CGFloat = 0

    override func scrollWheel(with event: NSEvent) {
        accumulated += event.scrollingDeltaY
        // Fire for each "unit" of scroll
        if accumulated > 3 {
            onScroll?(1)
            accumulated = 0
        } else if accumulated < -3 {
            onScroll?(-1)
            accumulated = 0
        }
    }
}

extension View {
    func onScrollWheel(_ handler: @escaping (Int) -> Void) -> some View {
        modifier(ScrollWheelModifier(onScroll: handler))
    }
}
```

- [ ] **Step 2: Regenerate project and build**

```bash
cd /Users/miro/Desktop/Personal_Projects/mreminders
xcodegen generate
xcodebuild -project DeskMinder.xcodeproj -scheme DeskMinder -configuration Debug build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

If there are Swift 6 Sendable warnings on the NSView subclass, add `@MainActor` to `ScrollWheelNSView` and `ScrollWheelReceiver`, or mark the `onScroll` closure as `@Sendable` if needed.

- [ ] **Step 3: Commit**

```bash
git add DeskMinder/Views/NewReminderPillView.swift
git commit -m "feat: add input pill with scroll-to-set time and text field"
```

---

### Task 9: PillStackView — Main Container

**Files:**
- Create: `DeskMinder/Views/PillStackView.swift`

- [ ] **Step 1: Implement PillStackView**

Create `DeskMinder/Views/PillStackView.swift`:

```swift
import SwiftUI

struct PillStackView: View {
    @Environment(ReminderManager.self) var manager

    var body: some View {
        VStack(spacing: 6) {
            // Active timer pills (oldest at top, newest at bottom)
            ForEach(manager.activeReminders) { reminder in
                ReminderPillView(
                    reminder: reminder,
                    currentDate: manager.currentDate,
                    onDelete: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            manager.deleteReminder(reminder)
                        }
                    }
                )
            }

            // Input pill (always at bottom)
            NewReminderPillView { text, minutes in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    manager.createReminder(text: text, minutes: minutes)
                }
            }
        }
        .padding(12)
        .fixedSize()
    }
}
```

- [ ] **Step 2: Regenerate project and build**

```bash
cd /Users/miro/Desktop/Personal_Projects/mreminders
xcodegen generate
xcodebuild -project DeskMinder.xcodeproj -scheme DeskMinder -configuration Debug build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add DeskMinder/Views/PillStackView.swift
git commit -m "feat: add PillStackView arranging timer and input pills"
```

---

### Task 10: AppDelegate — Wire Everything Together

**Files:**
- Create: `DeskMinder/AppDelegate.swift`
- Modify: `DeskMinder/DeskMinderApp.swift`

- [ ] **Step 1: Implement AppDelegate**

Create `DeskMinder/AppDelegate.swift`:

```swift
import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var panelManager = PanelManager()
    private let reminderManager = ReminderManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from Dock (belt and suspenders — Info.plist also sets LSUIElement)
        NSApp.setActivationPolicy(.accessory)

        // Request permissions
        Task {
            await reminderManager.requestAccess()
            await NotificationManager.shared.requestPermission()
        }

        // Wire notification callback
        reminderManager.onReminderExpired = { [weak self] reminder in
            NotificationManager.shared.fireNotification(
                title: "DeskMinder",
                body: reminder.text
            )
        }

        // Start timer engine
        reminderManager.startTimer()

        // Create the floating panel with SwiftUI content
        let contentView = PillStackView()
            .environment(reminderManager)

        panelManager.createPanel(with: contentView)
    }

    func applicationWillTerminate(_ notification: Notification) {
        reminderManager.stopTimer()
    }
}
```

- [ ] **Step 2: Update DeskMinderApp.swift to use AppDelegate**

Replace `DeskMinder/DeskMinderApp.swift`:

```swift
import SwiftUI

@main
struct DeskMinderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No visible SwiftUI windows — the NSPanel is managed by AppDelegate
        Settings {
            Text("DeskMinder Settings (coming soon)")
                .frame(width: 300, height: 200)
        }
    }
}
```

- [ ] **Step 3: Regenerate project and build**

```bash
cd /Users/miro/Desktop/Personal_Projects/mreminders
xcodegen generate
xcodebuild -project DeskMinder.xcodeproj -scheme DeskMinder -configuration Debug build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Run the app to test visually**

```bash
cd /Users/miro/Desktop/Personal_Projects/mreminders
open DeskMinder.xcodeproj
```

In Xcode, press Cmd+R to run. Verify:
- A floating pill appears on the desktop
- No Dock icon
- The pill shows a time selector and text field
- You can type a reminder and press Return
- A countdown pill appears above the input
- The pill is draggable

- [ ] **Step 5: Commit**

```bash
git add DeskMinder/AppDelegate.swift DeskMinder/DeskMinderApp.swift
git commit -m "feat: wire AppDelegate with panel, managers, and SwiftUI content"
```

---

### Task 11: Context Menu + Right-Click to Quit

**Files:**
- Modify: `DeskMinder/Views/PillStackView.swift`

- [ ] **Step 1: Add context menu to PillStackView**

In `DeskMinder/Views/PillStackView.swift`, add a context menu to the outer VStack. Replace the body:

```swift
    var body: some View {
        VStack(spacing: 6) {
            ForEach(manager.activeReminders) { reminder in
                ReminderPillView(
                    reminder: reminder,
                    currentDate: manager.currentDate,
                    onDelete: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            manager.deleteReminder(reminder)
                        }
                    }
                )
            }

            NewReminderPillView { text, minutes in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    manager.createReminder(text: text, minutes: minutes)
                }
            }
        }
        .padding(12)
        .fixedSize()
        .contextMenu {
            Button("Quit DeskMinder") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
```

- [ ] **Step 2: Regenerate project and build**

```bash
cd /Users/miro/Desktop/Personal_Projects/mreminders
xcodegen generate
xcodebuild -project DeskMinder.xcodeproj -scheme DeskMinder -configuration Debug build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add DeskMinder/Views/PillStackView.swift
git commit -m "feat: add right-click context menu with Quit option"
```

---

### Task 12: Run All Tests + Integration Verification

**Files:** None new — verification only.

- [ ] **Step 1: Run all unit tests**

```bash
cd /Users/miro/Desktop/Personal_Projects/mreminders
xcodegen generate
xcodebuild test -project DeskMinder.xcodeproj -scheme DeskMinderTests -configuration Debug 2>&1 | grep -E "(Test |passed|failed|BUILD)"
```

Expected: All tests pass, `** BUILD SUCCEEDED **`

- [ ] **Step 2: Build release configuration**

```bash
xcodebuild -project DeskMinder.xcodeproj -scheme DeskMinder -configuration Release build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Manual integration checklist**

Run the app from Xcode (Cmd+R) and verify each success criterion from the spec:

1. [ ] App launches with no Dock icon
2. [ ] Floating glass pill visible on desktop
3. [ ] Can scroll/type to set time on input pill
4. [ ] Can type reminder text and press Return to create
5. [ ] Timer pill appears above input, counting down live
6. [ ] Can create multiple timers simultaneously
7. [ ] Clicking X on a timer dismisses it with animation
8. [ ] Timer at 0 fires a macOS notification
9. [ ] Timer pill turns red when < 60 seconds
10. [ ] Open Apple Reminders — reminders appear in "DeskMinder" list
11. [ ] Widget is draggable, stays on top of other windows
12. [ ] Widget appears on all Spaces (switch Spaces to verify)
13. [ ] Right-click → Quit DeskMinder works
14. [ ] Relaunch → widget appears at saved position

- [ ] **Step 4: Fix any issues found during verification**

Address any failures from the checklist. Common issues to watch for:
- **Panel doesn't accept text input**: Verify `canBecomeKey` returns `true` in `FloatingPanel`
- **Timer doesn't tick**: Verify `startTimer()` is called in `applicationDidFinishLaunching`
- **EventKit denied**: Check System Settings > Privacy > Reminders > DeskMinder
- **Notification not showing**: Check System Settings > Notifications > DeskMinder

- [ ] **Step 5: Final commit**

```bash
cd /Users/miro/Desktop/Personal_Projects/mreminders
git add -A
git commit -m "chore: integration verification and fixes"
```

(Only commit if there were fixes. If everything passed, skip this step.)
