import SwiftUI

@main
struct MyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // 1) Give the window a unique "id:"
        WindowGroup("Main Window", id: "MainWindow") {
            ContentView()
                .environmentObject(appDelegate)
        }
        // 2) Force ALL external events (file opens) to reuse this scene
        .handlesExternalEvents(matching: ["*"])
        .defaultSize(width: 250, height: 250)
        .windowResizability(.contentSize)
    }
}
