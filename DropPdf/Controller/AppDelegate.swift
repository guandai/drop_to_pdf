import Cocoa
import SwiftUI
import UniformTypeIdentifiers

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    static var shared = AppDelegate()

    @Published var droppedFiles: [URL] = []
    @Published var processResult: [Int: (URL, Bool)] = [:]
    @Published var createOneFile: Bool = true
    @Published var batchTmpFolder: URL = NameMod.getTempFolder()

    var processFile = ProcessFile()
    var dropWindow: NSWindow?
    var windows: Windows?
    var menus: Menus?  // Add a property to hold a reference to Menus

    override init() {
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        print(">>> applicationDidFinishLaunching")
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
        Task {
            await AppDelegate.shared.startDrop(urls)
        }
    }

    func setDroppedFiles(_ urls: [URL]) {
        if AppDelegate.shared.createOneFile {
            AppDelegate.shared.batchTmpFolder = NameMod.getTempFolder()
            print("batchFolder: \(AppDelegate.shared.batchTmpFolder)")
        }
        AppDelegate.shared.droppedFiles.append(contentsOf: urls)
    }
    
    func startDrop (_ urls: [URL]) async -> [URL: Bool] {
        return await withCheckedContinuation { (continuation: CheckedContinuation<[URL: Bool], Never>) in
            DispatchQueue.main.async {
                AppDelegate.shared.setDroppedFiles(urls)
                Task {
                    var results = await AppDelegate.shared.processFile.processDroppedFiles(urls, self)
                    if AppDelegate.shared.createOneFile {
                        results = await AppDelegate.shared.bundleToOnePdf(urls)
                    }
                    continuation.resume(returning: results)
                }
            }
        }
    }
    
    func bundleToOnePdf(_ urls: [URL]) async -> [URL: Bool] {
        guard let firstUrl = urls.first else { return [:] }
        let bundleFile = firstUrl.deletingLastPathComponent().appendingPathComponent("bundle.pdf")

        let result = await SaveToPdf().saveBundleToPdf(AppDelegate.shared.batchTmpFolder, bundleFile)
        return [bundleFile: result]
    }
}
