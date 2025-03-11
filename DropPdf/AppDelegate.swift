import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
  @Published var droppedFiles: [URL] = []
  var processFile = ProcessFile()
  var window: NSWindow?


  func applicationDidFinishLaunching(_ notification: Notification) {
    self.setupMainWindow()
  }

  /// ✅ Handle dock icon click → Reopen the drop area
  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool
  {
    if flag {
      window?.makeKeyAndOrderFront(nil)  // ✅ Bring window to front
    } else {
      setupMainWindow()  // ✅ Recreate window if closed
    }
    return true
  }

    func setupMainWindow() {
            if let existingWindow = self.window, existingWindow.isVisible {
                existingWindow.makeKeyAndOrderFront(nil)
                NSApplication.shared.activate(ignoringOtherApps: true)
                return
            }


            let hostingController = NSHostingController(
                rootView: AnyView(DropView()
                    .environmentObject(self)  // ✅ Pass AppDelegate to manage state
                    .environmentObject(self.processFile)
            ))

            let newWindow = NSWindow(
                contentRect: NSRect(x: 200, y: 200, width: 400, height: 300),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )
            newWindow.center()
            newWindow.title = "Drop To PDF"
            newWindow.contentView = hostingController.view
            newWindow.makeKeyAndOrderFront(nil)
            newWindow.isReleasedWhenClosed = false

            self.window = newWindow
            NSApplication.shared.activate(ignoringOtherApps: true)
        }

        override init() {
            super.init()
        }
    
//        /// ✅ Handle folder access and switch view
//        private func handleFolderAccess() {
//            PermissionsManager().requestAccess()
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // Slight delay for UI update
//                self.hasAccess = PermissionsManager().hasSavedFolderBookmark()
//                self.setupMainWindow()  // ✅ Reopen window with updated state
//            }
//        }

  /// ✅ Handle files dropped onto the app icon
  func application(_ sender: NSApplication, openFiles filenames: [String]) {
    let urls = filenames.map { URL(fileURLWithPath: $0) }
    handleFileDrop(urls)
  }

  /// ✅ Handle files opened via drag-and-drop or double-clicking
  func application(_ application: NSApplication, open urls: [URL]) {
    handleFileDrop(urls)
  }

  /// ✅ Process dropped files
  private func handleFileDrop(_ urls: [URL]) {
    DispatchQueue.main.async {
      self.droppedFiles.append(contentsOf: urls)
    }

    // ✅ Ensure only one window exists before processing files
    setupMainWindow()

    // ✅ Ensure first file drop correctly converts to PDF
    DispatchQueue.main.async {
      Task {
        await self.processFile.processDroppedFiles(urls, self)
      }
    }
  }
}
