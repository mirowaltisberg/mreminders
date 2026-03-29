import SwiftUI

@main
struct mremindersApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            Text("mreminders Settings (coming soon)")
                .frame(width: 300, height: 200)
        }
    }
}
