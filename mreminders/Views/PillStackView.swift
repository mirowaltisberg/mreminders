import SwiftUI

struct PillStackView: View {
    @Environment(ReminderManager.self) var manager

    private static let maxVisibleReminders = 8
    private static let pillHeight: CGFloat = 46

    var body: some View {
        VStack(spacing: 6) {
            if !manager.permissionGranted {
                PermissionWarningPill()
            }

            if manager.activeReminders.count > Self.maxVisibleReminders {
                ScrollView {
                    reminderList
                }
                .frame(maxHeight: Self.pillHeight * CGFloat(Self.maxVisibleReminders))
            } else {
                reminderList
            }

            NewReminderPillView { text, minutes in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    manager.createReminder(text: text, minutes: minutes)
                }
            }
        }
        .padding(12)
        .fixedSize(horizontal: true, vertical: false)
        .preferredColorScheme(.light)
        .environment(\.colorScheme, .light)
        .contextMenu {
            Button("Quit mreminders") {
                NSApplication.shared.terminate(nil)
            }
        }
    }

    private var reminderList: some View {
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
        }
    }
}

// MARK: - Permission Warning

struct PermissionWarningPill: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12))
                .foregroundStyle(Color.orange)

            Text("Reminders access needed")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.black.opacity(0.75))

            Spacer()

            Text("Open Settings")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.accentColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background {
            GlassPillBackground()
        }
        .onTapGesture {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Reminders") {
                NSWorkspace.shared.open(url)
            }
        }
        .accessibilityLabel("Reminders access needed. Tap to open Settings.")
    }
}
