import SwiftUI

struct PillStackView: View {
    @Environment(ReminderManager.self) var manager

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
        .preferredColorScheme(.light)
        .environment(\.colorScheme, .light)
        .contextMenu {
            Button("Quit mreminders") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
