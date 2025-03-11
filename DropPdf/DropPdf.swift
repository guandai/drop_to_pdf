import SwiftUI

@main
struct DropPdf: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var permissionsManager = PermissionsManager.shared
    @State private var showSettings = false  // State for showing settings dialog

    var body: some Scene {
        // 🔹 Add a settings window (opened from menu)
        Settings {
            SettingsView()
        }
    }
}
