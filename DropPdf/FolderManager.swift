import Cocoa
import UniformTypeIdentifiers
import Foundation

class PermissionsManager {
    func openFullDiskAccessSettings() {
       let urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
       
       if let url = URL(string: urlString) {
           NSWorkspace.shared.open(url)
       } else {
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
    
    
    func isAppSandboxed() -> Bool {
        return ProcessInfo.processInfo.environment["APP_SANDBOX_CONTAINER_ID"] != nil
    }

    func askUserToSavePDF(proposedFilename: String, data: Data) -> Bool {
        var success = false
        
        DispatchQueue.main.sync {
            let savePanel = NSSavePanel()
            savePanel.title = "Save PDF File"
            
            if #available(macOS 11.0, *) {
                savePanel.allowedContentTypes = [UTType.pdf]  // ✅ macOS 11+
            } else {
                savePanel.allowedFileTypes = ["pdf"]  // ✅ macOS 10.15 and earlier
            }
            
            savePanel.nameFieldStringValue = proposedFilename
            
            if savePanel.runModal() == .OK, let url = savePanel.url {
                success = savePDFToAllowedLocation(fileURL: url, data: data)
            }
        }
        
        return success
    }

    func savePDFToAllowedLocation(fileURL: URL, data: Data) -> Bool {
        let didStart = fileURL.startAccessingSecurityScopedResource()
        defer { if didStart { fileURL.stopAccessingSecurityScopedResource() } }

        do {
            try data.write(to: fileURL)
            print("✅ Successfully saved PDF at \(fileURL.path)")
            return true
        } catch {
            print("❌ ERROR: Failed to save PDF: \(error)")
            return false
        }
    }
}


