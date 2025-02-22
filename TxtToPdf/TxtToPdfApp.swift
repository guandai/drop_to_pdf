import SwiftUI

@main
struct MyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
//        WindowGroup {
//            ContentView().environmentObject(appDelegate)
//        }
//        .defaultSize(width: 250, height: 250)  // ✅ Start window at 300x300
//        .windowResizability(.contentSize)      // ✅ Disable resizing
    }
}
