import SwiftUI

@main
struct TxtToPdfApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appDelegate)  // ✅ Inject AppDelegate correctly
        }
    }
}
