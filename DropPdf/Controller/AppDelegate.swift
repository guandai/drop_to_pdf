
import Cocoa
import SwiftUI
import UniformTypeIdentifiers

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    @Published var droppedFiles: [URL] = []
    @Published var processResult: [Int: (URL, Bool)] = [:]
    var processFile = ProcessFile()
    var window: NSWindow?
    var mainWindow: Windows?

    func applicationDidFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.set(false, forKey: "NSPrintSpoolerLogToConsole")
        self.mainWindow = Windows(window, self)
        mainWindow?.setupMainWindow()
        mainWindow?.setupMenuBar()
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    func applicationShouldHandleReopen(
        _ sender: NSApplication, hasVisibleWindows flag: Bool
    ) -> Bool {
        if flag {
            window?.makeKeyAndOrderFront(nil)
        } else {
            mainWindow?.setupMainWindow()
        }
        return true
    }

    override init() {
        super.init()
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        let urls = filenames.map { URL(fileURLWithPath: $0) }
        handleFileDrop(urls)
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        handleFileDrop(urls)
    }


    private func handleFileDrop(_ urls: [URL]) {
        DispatchQueue.main.async {
            self.droppedFiles.append(contentsOf: urls)
        }
        self.mainWindow?.setupMainWindow()

        DispatchQueue.main.async {
            Task {
                await self.processFile.processDroppedFiles(urls, self)
            }
        }
    }
}

