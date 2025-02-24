import Cocoa

import SwiftUI

struct FDAView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Full Disk Access Required")
                .font(.title2)
            
            Text("This app needs Full Disk Access to read or write certain protected files. Please enable it in System Settings → Privacy & Security → Full Disk Access.")
                .multilineTextAlignment(.center)
                .frame(width: 300)
            
            Button("Open Full Disk Access Settings") {
                openFullDiskAccessSettings()
            }
        }
        .padding()
        .frame(width: 400, height: 200)
    }
}

func openFullDiskAccessSettings() {
    // Attempt to open Full Disk Access pane
    // - On macOS Ventura (13+), this URL may open System Settings at “Privacy & Security,”
    //   but might not jump directly to “Full Disk Access.”
    // - On older macOS (12 and below), it should open Security & Privacy at Full Disk Access.
    
    let urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
    
    if let url = URL(string: urlString) {
        NSWorkspace.shared.open(url)
    } else {
        // Fallback: just open main System Settings
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Library/PreferencePanes/Security.prefPane"))
    }
}


/// Attempt to detect Full Disk Access by testing a restricted path.
func checkFullDiskAccess() -> Bool {
    // `/Library/Application Support/com.apple.TCC` is typically restricted.
    let restrictedPath = "/Library/Application Support/com.apple.TCC"
    // If we can read it, we likely have FDA. This is a heuristic, not 100% guaranteed.
    return FileManager.default.isReadableFile(atPath: restrictedPath)
}


func requestFolderAccess() -> URL? {
    var selectedFolder: URL?

    DispatchQueue.main.sync { // ✅ Ensures UI runs on the main thread
        let openPanel = NSOpenPanel()
        openPanel.message = "Select a folder where PDFs should be saved."
        openPanel.prompt = "Allow"
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false

        if openPanel.runModal() == .OK, let folderURL = openPanel.url {
            print("✅ User granted access to: \(folderURL.path)")
            selectedFolder = folderURL
        } else {
            print("⚠️ No folder selected, defaulting to Downloads")
            selectedFolder = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads")
        }
    }

    return selectedFolder
}
