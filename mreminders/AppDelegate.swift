import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var panelManager = PanelManager()
    private let reminderManager = ReminderManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        Task {
            await reminderManager.requestAccess()
            await NotificationManager.shared.requestPermission()
        }

        reminderManager.onReminderExpired = { reminder in
            NotificationManager.shared.fireNotification(
                title: "mreminders",
                body: reminder.text
            )
        }

        reminderManager.startTimer()

        let contentView = PillStackView()
            .environment(reminderManager)

        panelManager.createPanel(with: contentView)
    }

    func applicationWillTerminate(_ notification: Notification) {
        reminderManager.stopTimer()
    }
}
