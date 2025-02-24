import Cocoa
import AppKit

import Foundation

struct PermissionsManager {
    static func hasFullDiskAccess() -> Bool {
        let testPath = "/Library/Application Support"
        return FileManager.default.isReadableFile(atPath: testPath)
    }
}



class FolderManager {
    private let bookmarkKey = "SavedFolderBookmark"

    func hasFullDiskAccess() -> Bool {
        let testPath = "/Library/Application Support"
        return FileManager.default.isReadableFile(atPath: testPath)
    }
    
    func saveFolderManager(_ folderURL: URL) {
        do {
            let bookmarkData = try folderURL.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            UserDefaults.standard.set(bookmarkData, forKey: bookmarkKey)
            print("✅ Folder permission saved.")
        } catch {
            print("❌ ERROR: Failed to save folder permission: \(error)")
        }
    }
    
    
    func getSavedFolderManager() -> URL? {
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
    
    
    func requestFolderManager() -> URL {
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



func askUserForSaveFolder() -> URL? {
    var selectedURL: URL? = nil
    
    DispatchQueue.main.sync {  // ✅ Ensure UI runs on the main thread
        let dialog = NSOpenPanel()
        dialog.title = "Choose the OneDrive Folder to Save PDF"
        dialog.showsResizeIndicator = true
        dialog.showsHiddenFiles = false
        dialog.canChooseDirectories = true
        dialog.canChooseFiles = false
        dialog.allowsMultipleSelection = false

        if dialog.runModal() == .OK {
            selectedURL = dialog.url
        }
    }
    
    return selectedURL
}
