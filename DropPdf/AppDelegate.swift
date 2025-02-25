import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    @Published var droppedFiles: [URL] = []
    @EnvironmentObject var processFile: ProcessFile
    
    var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMainWindow()
    }

    /// 🔹 Ensure only one main window exists
    func setupMainWindow() {
        if let existingWindow = window, existingWindow.isVisible {
            // ✅ Window already exists → bring it to the front
            existingWindow.makeKeyAndOrderFront(nil)
        } else {
            // ❌ No existing window → create a new one
            let hostingController = NSHostingController(rootView: DropView().environmentObject(self))

            let newWindow = NSWindow(
                contentRect: NSRect(x: 100, y: 100, width: 400, height: 300),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )
            newWindow.title = "Drop To PDF"
            newWindow.contentView = hostingController.view
            newWindow.makeKeyAndOrderFront(nil)

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

        // ✅ Ensure only one window exists and reuse it
        setupMainWindow()

        Task {
            await processFile.processDroppedFiles(urls, self)
        }
    }
}
