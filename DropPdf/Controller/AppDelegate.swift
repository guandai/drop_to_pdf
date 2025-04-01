import Cocoa
import SwiftUI
import UniformTypeIdentifiers

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    @Published var droppedFiles: [URL] = []
    @Published var processResult: [Int: (URL, Bool)] = [:]
    var processFile = ProcessFile()
    var dropWindow: NSWindow?
    var windows: Windows?
    var menus: Menus?  // Add a property to hold a reference to Menus

    func applicationDidFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.set(false, forKey: "NSPrintSpoolerLogToConsole")
        windows = Windows(dropWindow, self)
        menus = Menus(windows)  // Initialize Menus
        windows?.menus = menus  // Set the weak reference
        windows?.setupMainWindow()
        menus?.setupMenuBar()
    }

    func applicationShouldHandleReopen(
        _ sender: NSApplication, hasVisibleWindows flag: Bool
    ) -> Bool {
        if flag {
            dropWindow?.makeKeyAndOrderFront(nil)
        } else {
            windows?.setupMainWindow()EnvironmentObject
        }
        return true
    }

    override init() {
        super.init()
    }
    
    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        let urls = filenames.map { URL( fileURLWithPath: NameMod.toFileString($0)) }
        handleFileDrop(urls)
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        handleFileDrop(urls)
    }

    private func handleFileDrop(_ urls: [URL]) {
        DispatchQueue.main.async {
            self.droppedFiles.append(contentsOf: urls)
        }
        windows?.setupMainWindow()

        DispatchQueue.main.async {
            Task {
                await self.processFile.processDroppedFiles(urls, self)
            }
        }
    }
}
