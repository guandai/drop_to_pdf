import Cocoa
import PDFKit


// ✅ Ensure AppDelegate conforms to ObservableObject
class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    let bookmarkKey = "SavedFolderBookmark"
    
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls where url.pathExtension.lowercased() == "txt" {
            print("📂 Dragged file onto app icon: \(url.path)")
            convertTxtToPDF(txtFileURL: url)  // ✅ Automatically generate the PDF
        }
    }
    
    func convertTxtToPDF(txtFileURL: URL) {
        myConvertTxtToPDF(txtFileURL: txtFileURL, appDelegate: self)
    }
    
    
    
    func saveFolderPermission(_ folderURL: URL) {
        do {
            let bookmarkData = try folderURL.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            UserDefaults.standard.set(bookmarkData, forKey: bookmarkKey)
            print("✅ Folder permission saved.")
        } catch {
            print("❌ ERROR: Failed to save folder permission: \(error)")
        }
    }
    
    
    
    func getSavedFolderPermission() -> URL? {
        if let bookmarkData = UserDefaults.standard.data(forKey: bookmarkKey) {
            var isStale = false
            do {
                let folderURL = try URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
                if !isStale {
                    _ = folderURL.startAccessingSecurityScopedResource()  // ✅ Request permission
                    return folderURL
                } else {
                    print("⚠️ Stored folder permission is stale. Requesting again.")
                }
            } catch {
                print("❌ ERROR: Failed to retrieve stored folder permission: \(error)")
            }
        }
        return nil
    }
    
    
    func requestFolderPermission() -> URL {
        let openPanel = NSOpenPanel()
        openPanel.message = "Choose a folder where PDFs will be saved automatically."
        openPanel.prompt = "Allow"
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false

        if openPanel.runModal() == .OK, let selectedFolder = openPanel.url {
            _ = selectedFolder.startAccessingSecurityScopedResource()  // ✅ Request access
            print("✅ User granted access to: \(selectedFolder.path)")
            return selectedFolder
        } else {
            print("⚠️ No folder selected, defaulting to Downloads")
            return FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads")
        }
    }
}



