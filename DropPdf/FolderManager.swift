import Cocoa

import Foundation

struct PermissionsManager {
    static func openFullDiskAccessSettings() {
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
    static func checkFullDiskAccess() -> Bool {
        // `/Library/Application Support/com.apple.TCC` is typically restricted.
        let restrictedPath = "/Library/Application Support/com.apple.TCC"
        // If we can read it, we likely have FDA. This is a heuristic, not 100% guaranteed.
        return FileManager.default.isReadableFile(atPath: restrictedPath)
    }


    
}


