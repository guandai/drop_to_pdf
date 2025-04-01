import Cocoa
import SwiftUI
import UniformTypeIdentifiers

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    static var shared = AppDelegate()

    @Published var droppedFiles: [URL] = []
    @Published var processResult: [Int: (URL, Bool)] = [:]
    @Published var createOneFile: Bool = false
    @Published var batchTmpFolder: URL = NameMod.getTempFolder()

    var processFile = ProcessFile()
    var dropWindow: NSWindow?
    var windows: Windows?
    var menus: Menus?  // Add a property to hold a reference to Menus

    override init() {
        super.init()
    }
    
    func setBatchFolder() {
        let tempFolder = NameMod.getTempFolder()
        DispatchQueue.main.async {
            self.batchTmpFolder = tempFolder
        }
    }

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
            windows?.setupMainWindow()
        }
        return true
    }
    
    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        let urls = filenames.map { URL( fileURLWithPath: NameMod.toFileString($0)) }
        Task {
            await startDrop(urls)
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        Task {
            await self.startDrop(urls)
        }
    }

    func startDrop(_ urls: [URL]) async -> [URL: Bool]  {
        if AppDelegate.shared.createOneFile {
            DispatchQueue.main.async {
                AppDelegate.shared.setBatchFolder()
            }
            print(">>>>>>>> new bath \(AppDelegate.shared.batchTmpFolder)")
        }
        
        self.droppedFiles.append(contentsOf: urls)
        let result = await self.processFile.processDroppedFiles(urls, self)
        return result
    }
}
