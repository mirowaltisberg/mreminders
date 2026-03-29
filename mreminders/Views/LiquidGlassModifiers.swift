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
