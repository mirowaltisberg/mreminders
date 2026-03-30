import AppKit
import SwiftUI

// MARK: - FloatingPanel

final class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 200),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
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
        appearance = NSAppearance(named: .aqua)

        if let savedOrigin = PanelManager.loadPosition() {
            setFrameOrigin(savedOrigin)
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

// MARK: - Transparent Container

/// Custom NSView that explicitly draws nothing — guarantees full transparency.
/// NSHostingView draws an opaque background by default that cannot be cleared
/// through standard API. This container sits underneath and draws clear.
final class TransparentContainerView: NSView {
    override var isOpaque: Bool { false }
    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.clear.set()
        dirtyRect.fill()
    }

    override func layout() {
        super.layout()
        // On every layout pass, force-clear any opaque backgrounds
        // that SwiftUI's hosting view may have reintroduced
        clearBackgrounds(self)
    }

    private func clearBackgrounds(_ view: NSView) {
        for subview in view.subviews {
            if !(subview is NSVisualEffectView) {
                subview.wantsLayer = true
                subview.layer?.backgroundColor = .clear
                subview.layer?.isOpaque = false
            }
            clearBackgrounds(subview)
        }
    }
}

// MARK: - PanelManager

@MainActor
final class PanelManager {

    private(set) var panel: FloatingPanel?

    private static let positionXKey = "panelPositionX"
    private static let positionYKey = "panelPositionY"

    func createPanel<Content: View>(with content: Content) {
        let panel = FloatingPanel()

        // 1. Create transparent container as the panel's content view
        let container = TransparentContainerView()
        container.wantsLayer = true
        container.layer?.backgroundColor = .clear
        container.layer?.isOpaque = false
        panel.contentView = container

        // 2. Create hosting view with light appearance for white glass
        let hostingView = NSHostingView(
            rootView: content
                .environment(\.colorScheme, .light)
        )
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = .clear
        hostingView.layer?.isOpaque = false
        hostingView.appearance = NSAppearance(named: .aqua)

        container.addSubview(hostingView)

        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: container.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            hostingView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        ])

        // 3. Re-enforce transparency after content is set
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.invalidateShadow()

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
        return NSPoint(
            x: defaults.double(forKey: positionXKey),
            y: defaults.double(forKey: positionYKey)
        )
    }
}
