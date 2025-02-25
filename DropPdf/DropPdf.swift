import SwiftUI

@main
struct MyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var hasFullDiskAccess = PermissionsManager.checkFullDiskAccess()

    init() {
        ensureSingleInstance()
    }

    var body: some Scene {
        Settings {
            EmptyView() // ✅ Prevents unwanted extra windows
        }
    }

    /// Ensures that only a single instance of the app runs
    private func ensureSingleInstance() {
        let bundleIdentifier = Bundle.main.bundleIdentifier!
        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier)

        if runningApps.count > 1 {
            NSApplication.shared.terminate(nil) // ✅ If another instance exists, close it
        }
    }
}
