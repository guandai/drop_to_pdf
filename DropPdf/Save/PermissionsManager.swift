import Cocoa
import UniformTypeIdentifiers
import Foundation

class PermissionsManager: ObservableObject  {
    static let shared = PermissionsManager()
    
    @Published var grantedFolderURLs: Set<URL> = Set([])  // ✅ Store multiple folders

    private let savedFoldersKey = "SavedFoldersBookmarks"

    init() {
        restoreFolderAccess()
    }

    /// Ask user to select a folder, opening the dialog at a specified path if provided
    func requestAccess(_ initialPath: String? = nil) {
        let panel = NSOpenPanel()
        panel.title = "Select a folder to grant access"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        // Set the initial directory safely
        if let initialPath = initialPath {
            let initialURL = URL(fileURLWithPath: initialPath, isDirectory: true)
            panel.directoryURL = initialURL
        }

        if panel.runModal() == .OK, let folderURL = panel.url {
            storeSecurityScopedBookmark(for: folderURL)
        }
        objectWillChange.send()
    }

    /// Store security-scoped bookmark for a selected folder
    private func storeSecurityScopedBookmark(for url: URL) {
        do {
            let bookmarkData = try url.bookmarkData(options: .withSecurityScope)
            // Retrieve stored bookmarks
            var storedBookmarks = UserDefaults.standard.array(forKey: savedFoldersKey) as? [Data] ?? []
            storedBookmarks.append(bookmarkData)  // ✅ Store multiple bookmarks
            UserDefaults.standard.set(storedBookmarks, forKey: savedFoldersKey)

            DispatchQueue.main.async {
                if self.grantedFolderURLs.contains(url) {
                     return
                } else {
                    self.grantedFolderURLs.insert(url)
                }
                
            }
            objectWillChange.send()
            print("✅ Folder access granted: \(url.path)")
        } catch {
            print("❌ Failed to store bookmark: \(error)")
        }
    }

    /// Restore access to previously selected folders
    func restoreFolderAccess() {
        if let bookmarkDataArray = UserDefaults.standard.array(forKey: savedFoldersKey) as? [Data] {
            grantedFolderURLs.removeAll()
            for bookmarkData in bookmarkDataArray {
                do {
                    var isStale = false
                    let url = try URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, bookmarkDataIsStale: &isStale)

                    if isStale {
                        print("🪬 Bookmark data is stale, requesting permission again.")
                        continue
                    }

                    if url.startAccessingSecurityScopedResource() {
                        grantedFolderURLs.insert(url)
                        print("✅ Restored access to: \(url.path)")
                    } else {
                        print("❌ Failed to access security-scoped resource.")
                    }
                } catch {
                    print("❌ Failed to restore bookmark: \(error)")
                }
            }
        }
        objectWillChange.send()
    }

    /// Check if a given folder has been granted access
    func isFolderGranted(_ folderURL: URL) -> Bool {
        let isGranted = grantedFolderURLs.contains { $0.standardizedFileURL == folderURL.standardizedFileURL }
        if isGranted {
            print("✅ Folder access granted: \(folderURL.path)")
        } else {
            print("❌ Folder access not granted: \(folderURL.path)")
        }
        
        return isGranted
    }

    /// Check if a file's folder is allowed, request access if not
    func ensureFolderAccess(for fileURL: URL, completion: @escaping (Bool) -> Void) {
        let fileDirectory = fileURL.deletingLastPathComponent()

        if grantedFolderURLs.contains(fileDirectory) {
            print("✅ Folder is already allowed: \(fileDirectory.path)")
            completion(true)
        } else {
            print("❌ Folder is not allowed: \(fileDirectory.path), requesting access...")
            DispatchQueue.main.async {
                self.requestAccess()
                self.grantedFolderURLs.insert(fileDirectory)
                completion(true)
            }
        }
    }

    /// Clear all stored folder permissions
    func clearSavedFolderBookmarks() {
        UserDefaults.standard.removeObject(forKey: savedFoldersKey)
        
        DispatchQueue.main.async {
            self.grantedFolderURLs.removeAll()
        }
        
        objectWillChange.send()
        print("🗑️ Cleared all saved folder bookmarks.")
    }
    
    func isAppSandboxed() -> Bool {
        return ProcessInfo.processInfo.environment["APP_SANDBOX_CONTAINER_ID"] != nil
    }
}

func getDidStart (fileURL: URL) -> Bool {
    return true;
    //        let didStart = fileURL.startAccessingSecurityScopedResource()
    //        if didStart {
    //            fileURL.stopAccessingSecurityScopedResource()
    //            return true
    //        }
    //        return false
}
