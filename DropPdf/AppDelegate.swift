import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    @Published var droppedFiles: [URL] = []
    var processFile = ProcessFile() // ✅ Use a normal instance (NOT @StateObject)

    var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMainWindow()
    }

    /// 🔹 Ensure only one main window exists
    func setupMainWindow() {
        if let existingWindow = self.window, existingWindow.isVisible {
            // ✅ Reuse existing window
            existingWindow.makeKeyAndOrderFront(nil)
        } else {
            // ❌ No existing window → Create a new one
            let hostingController = NSHostingController(rootView: DropView()
                .environmentObject(self) // ✅ Inject AppDelegate
                .environmentObject(self.processFile)) // ✅ Inject ProcessFile

            let newWindow = NSWindow(
                contentRect: NSRect(x: 100, y: 100, width: 400, height: 300),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )
            newWindow.title = "Drop To PDF"
            newWindow.contentView = hostingController.view
            newWindow.makeKeyAndOrderFront(nil)
            newWindow.isReleasedWhenClosed = false // ✅ Prevent accidental window loss

            self.window = newWindow
        }
    }

    /// 🔹 Handle files dropped onto the app icon
    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        let urls = filenames.map { URL(fileURLWithPath: $0) }
        handleFileDrop(urls)
    }

    /// 🔹 Handle files opened via drag-and-drop or double-clicking
    func application(_ application: NSApplication, open urls: [URL]) {
        handleFileDrop(urls)
    }

    /// 🔹 Process dropped files
    private func handleFileDrop(_ urls: [URL]) {
        DispatchQueue.main.async {
            self.droppedFiles.append(contentsOf: urls)
        }

        // ✅ Bring app to the foreground
        NSApplication.shared.activate(ignoringOtherApps: true)

        // ✅ Ensure only one window exists
        setupMainWindow()

        Task {
            await processFile.processDroppedFiles(urls, self)
        }
    }
}
