import SwiftUI

@main
struct MyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var hasFullDiskAccess = PermissionsManager.checkFullDiskAccess()

    init() {
        ensureSingleInstance()
    }

    var body: some Scene {
        WindowGroup("Drop To PDF", id: "MainWindow") {
            if hasFullDiskAccess {
                DropView() // ✅ Show drop area if FDA is granted
            } else {
                FDAView() // ❌ Show FDA request screen if FDA is missing
            }   
        }
        .environmentObject(appDelegate)
        .handlesExternalEvents(matching: ["*"])
        .defaultSize(width: 250, height: 250)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) { } // Hide "New Window" option
        }
    }

    /// Ensures that only a single instance of the app runs
    private func ensureSingleInstance() {
        let bundleIdentifier = Bundle.main.bundleIdentifier!
        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier)

        if runningApps.count > 1 {
            // If another instance exists, terminate the current one
            NSApplication.shared.terminate(nil)
        }
    }
}
