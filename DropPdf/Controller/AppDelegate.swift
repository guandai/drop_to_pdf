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

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("applicationDidFinishLaunching")
        UserDefaults.standard.set(false, forKey: "NSPrintSpoolerLogToConsole")
        windows = Windows(dropWindow, self)
        menus = Menus(windows)  // Initialize Menus
        windows?.menus = menus  // Set the weak reference
        windows?.setupMainWindow()
        menus?.setupMenuBar()
    }

    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        print(">>>>app applicationShouldHandleReopen")
        if flag {
            dropWindow?.makeKeyAndOrderFront(nil)
        } else {
            windows?.setupMainWindow()
        }
        return true
    }
    
    
    func application(_ application: NSApplication, open urls: [URL]) {
        print(">>>>app open urls")
        Task {
            await self.startDrop(urls)
        }
    }

    func setDroppedFiles(_ urls: [URL]) {
        print("setDroppedFiles")
        print(self.batchTmpFolder)
        if AppDelegate.shared.createOneFile {
            let tempFolder = NameMod.getTempFolder()
            self.batchTmpFolder = tempFolder
            print(tempFolder)
            print(self.batchTmpFolder)
        }
        self.droppedFiles.append(contentsOf: urls)
    }
    
    func startDrop (_ urls: [URL]) async -> [URL: Bool] {
        return await withCheckedContinuation { (continuation: CheckedContinuation<[URL: Bool], Never>) in
            DispatchQueue.main.async {
                print(">>>>>> startDrop")
                self.setDroppedFiles(urls)
                Task {
                    let results = await self.processFile.processDroppedFiles(urls, self)
                    continuation.resume(returning: results)
                }
            }
        }
    }
}
