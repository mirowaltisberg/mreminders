import SwiftUI
import AppKit

// MARK: - Glass Pill Background

struct GlassPillBackground: View {
    var isUrgent: Bool = false

    var body: some View {
        if #available(macOS 26, *) {
            glassPillModern
        } else {
            glassPillLegacy
        }
    }

    @available(macOS 26, *)
    private var glassPillModern: some View {
        Capsule()
            .fill(.clear)
            .glassEffect(.regular.interactive(), in: .capsule)
            .overlay {
                if isUrgent {
                    Capsule()
                        .fill(Color.red.opacity(0.15))
                        .strokeBorder(Color.red.opacity(0.3), lineWidth: 1)
                }
            }
    }

    private var glassPillLegacy: some View {
        Capsule()
            .fill(Color.white.opacity(0.75))
            .overlay {
                Capsule()
                    .strokeBorder(
                        isUrgent
                            ? Color.red.opacity(0.3)
                            : Color.white.opacity(0.9),
                        lineWidth: 0.5
                    )
            }
            .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 4)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
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
    var accessibilityText: String = ""
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
        .accessibilityLabel(accessibilityText.isEmpty ? defaultAccessibilityLabel : accessibilityText)
    }

    private var defaultAccessibilityLabel: String {
        switch style {
        case .dismiss, .urgentDismiss: "Dismiss"
        case .add: "Add reminder"
        }
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
                            : Color.black.opacity(0.4)
                    )
            case .add:
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }
        }
    }

    @available(macOS 26, *)
    private var circleModern: some View {
        Circle()
            .fill(.clear)
            .glassEffect(.regular.interactive(), in: .circle)
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
            .fill(Color.white.opacity(0.65))
            .overlay {
                Circle()
                    .strokeBorder(
                        style == .urgentDismiss
                            ? Color.red.opacity(0.3)
                            : Color.white.opacity(0.85),
                        lineWidth: 0.5
                    )
            }
            .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Pill Separator

struct PillSeparator: View {
    var isUrgent: Bool = false

    var body: some View {
        Rectangle()
            .fill(
                isUrgent
                    ? Color.red.opacity(0.25)
                    : Color.black.opacity(0.12)
            )
            .frame(width: 1, height: 16)
    }
}
