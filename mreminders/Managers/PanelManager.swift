import AppKit
import SwiftUI

// MARK: - FloatingPanel

final class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 200),
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

// MARK: - PanelManager

@MainActor
final class PanelManager {

    private(set) var panel: FloatingPanel?

    private static let positionXKey = "panelPositionX"
    private static let positionYKey = "panelPositionY"

    func createPanel<Content: View>(with content: Content) {
        let panel = FloatingPanel()

        let hostingView = NSHostingView(rootView: content)
        hostingView.translatesAutoresizingMaskIntoConstraints = false

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
        return NSPoint(
            x: defaults.double(forKey: positionXKey),
            y: defaults.double(forKey: positionYKey)
        )
    }
}
