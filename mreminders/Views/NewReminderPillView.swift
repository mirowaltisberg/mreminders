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
            GlassCircleButton(style: .add) {
                textFieldFocused = true
            }

            HStack(spacing: 10) {
                timeSection

                PillSeparator()

                TextField("Type reminder...", text: $text)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.black.opacity(0.75))
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
            .background {
                ScrollWheelReceiver { delta in
                    adjustMinutes(by: delta)
                }
            }
        }
    }

    // MARK: - Time Section

    @ViewBuilder
    private var timeSection: some View {
        HStack(spacing: 5) {
            Image(systemName: "clock")
                .font(.system(size: 12))
                .accessibilityHidden(true)

            if isEditingTime {
                TextField("", text: $timeText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: .medium).monospacedDigit())
                    .frame(width: 44)
                    .multilineTextAlignment(.trailing)
                    .focused($timeFieldFocused)
                    .onSubmit {
                        commitTimeEdit()
                    }
                    .onAppear {
                        timeFieldFocused = true
                    }
                    .accessibilityLabel("Duration in minutes")

                Text("min")
                    .font(.system(size: 13, weight: .medium))
                    .accessibilityHidden(true)
            } else {
                Text("\(minutes) min")
                    .font(.system(size: 13, weight: .medium).monospacedDigit())
                    .onTapGesture {
                        timeText = "\(minutes)"
                        isEditingTime = true
                    }
                    .accessibilityLabel("Duration: \(minutes) minutes. Tap to edit, scroll to adjust.")
                    .accessibilityAddTraits(.isButton)
            }
        }
        .foregroundStyle(Color.black.opacity(0.5))
    }

    // MARK: - Actions

    private func submitReminder() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, minutes > 0 else { return }
        onCreate(trimmed, minutes)
        text = ""
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
        minutes = min(999, max(1, newValue))
        timeText = "\(minutes)"
    }
}

// MARK: - Scroll Wheel

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
        accumulated -= event.scrollingDeltaY
        if accumulated > 3 {
            onScroll?(1)
            accumulated -= 3
        } else if accumulated < -3 {
            onScroll?(-1)
            accumulated += 3
        }
    }
}
