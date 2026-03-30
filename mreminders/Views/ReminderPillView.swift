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

    private var accessibilityTimeText: String {
        let total = reminder.remainingSeconds(from: currentDate)
        let m = total / 60
        let s = total % 60
        if m > 0 {
            return "\(m) minutes \(s) seconds remaining"
        } else {
            return "\(s) seconds remaining"
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            GlassCircleButton(
                style: isUrgent || isExpired ? .urgentDismiss : .dismiss,
                accessibilityText: "Dismiss \(reminder.text)",
                action: onDelete
            )

            HStack(spacing: 10) {
                HStack(spacing: 5) {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                        .accessibilityHidden(true)
                    Text(reminder.displayTime(from: currentDate))
                        .font(.system(size: 13, weight: isUrgent ? .semibold : .medium)
                            .monospacedDigit())
                        .accessibilityLabel(accessibilityTimeText)
                }
                .foregroundStyle(
                    isUrgent || isExpired
                        ? Color.red
                        : Color.black.opacity(0.55)
                )

                PillSeparator(isUrgent: isUrgent || isExpired)
                    .accessibilityHidden(true)

                Text(reminder.text)
                    .font(.system(size: 13))
                    .foregroundStyle(
                        isUrgent || isExpired
                            ? Color.red.opacity(0.9)
                            : Color.black.opacity(0.75)
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
        .accessibilityElement(children: .combine)
        .transition(
            .asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        )
    }
}
