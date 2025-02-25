import SwiftUI

@main
struct MyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        ensureSingleInstance()
    }

    var body: some Scene {
        sceneContent
    }

    @SceneBuilder
    var sceneContent: some Scene {
        WindowGroup("Drop To PDF", id: "MainWindow") {
            ContentView()
                .environmentObject(appDelegate)
        }
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
