import SwiftUI

@main
struct DropPdf: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var permissionsManager = PermissionsManager.shared

    init() {
        UserDefaults.standard.set(false, forKey: "NSPrintSpoolerLogToConsole")
    }
    
    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}
