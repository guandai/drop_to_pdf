import SwiftUI

//@main
struct DropPdf: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var hasFullDiskAccess = PermissionsManager().checkFullDiskAccess()
    let antiwordClient = AntiwordClient()

    init() {
        ensureSingleInstance()
    }

    var body: some Scene {
        Settings {
            VStack {
                Text("Drop a .doc file to convert to text")
                Button("Convert DOC") {
                    let inputPath = "/Users/zhengdai/test.doc"
                    let outputPath = "/Users/zhengdai/test.txt"
                    
                    antiwordClient.convertDocToTxt(inputPath: inputPath, outputPath: outputPath) { success, message in
                        print(message)
                    }
                }
            }
        }
    }

    /// Ensures that only a single instance of the app runs
    private func ensureSingleInstance() {
        let bundleIdentifier = Bundle.main.bundleIdentifier!
        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier)

        if runningApps.count > 1 {
            NSApplication.shared.terminate(nil)
        }
    }
}
