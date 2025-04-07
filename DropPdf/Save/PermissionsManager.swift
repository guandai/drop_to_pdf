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
    
    func getPermission(_ finalPath: URL) async -> Bool {
        let path = finalPath.deletingLastPathComponent()
        if isAppSandboxed() && !isFolderGranted(path) {
            await MainActor.run {
                requestAccess(path.path())
            }

            if !isFolderGranted(path) {
                print(">>> debug reject  permission")
                return false
            }
        }
        return true
    }
    
    func setupDirectoryURL(_ initialURL: URL, _ panel: NSOpenPanel) {
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: initialURL.path, isDirectory: &isDirectory) {
            panel.directoryURL = isDirectory.boolValue ? initialURL : initialURL.deletingLastPathComponent()
        } else {
            panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser
            print("⚠️ Path not found, using default directory: \(panel.directoryURL!)")
        }
        
        print("🗂 directoryURL: \(panel.directoryURL?.absoluteString ?? "nil")")
    }
    
    func run_panel(_ panel: NSOpenPanel) {
        if panel.runModal() == .OK, let folderURL = panel.url {
            let fixedUrl = NameMod.toFileURL(folderURL)
            print("✅ Selected folder: \(fixedUrl.absoluteString)")
            
            // Directly use the URL from the panel (already encoded properly)
            storeSecurityScopedBookmark(for: fixedUrl)
            self.grantedFolderURLs.insert(fixedUrl)
            
            // Optional: Verify accessibility
            do {
                let _ = try fixedUrl.checkResourceIsReachable()
            } catch {
                print("❌ Accessibility check failed: \(error.localizedDescription)")
            }
        }
    }
    
    /// Ask user to select a folder, opening the dialog at a specified path if provided
    func requestAccess(_ initialPath: String) {
        let panel = NSOpenPanel()
        panel.title = "Select a folder to grant access"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
       
        // 1. Resolve path components
        let resolvedPath = NameMod.toFileString(initialPath)
        // 2. Create URL with UTF-8 awareness
        let initialURL = NameMod.stringToURL(resolvedPath)
        // 3. Validate directory existence
        setupDirectoryURL(initialURL, panel)
        // 4. Run panel and handle result
        run_panel(panel)
        
        objectWillChange.send()
    }

    /// Store security-scoped bookmark for a selected folder
    private func storeSecurityScopedBookmark(for url: URL) {
        do {
            let fixedUrl = NameMod.toFileURL(url)
            let bookmarkData = try fixedUrl.bookmarkData(options: .withSecurityScope)
            // Retrieve stored bookmarks
            var storedBookmarks = UserDefaults.standard.array(forKey: savedFoldersKey) as? [Data] ?? []
            storedBookmarks.append(bookmarkData)  // ✅ Store multiple bookmarks
            UserDefaults.standard.set(storedBookmarks, forKey: savedFoldersKey)

            DispatchQueue.main.async {
                if self.grantedFolderURLs.contains(fixedUrl) {
                     return
                } else {
                    self.grantedFolderURLs.insert(fixedUrl)
                }
                
            }
            objectWillChange.send()
            print("✅ Folder access granted: \(fixedUrl.path)")
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

    func isSystemTemporaryFolder(_ folderURL: URL) -> Bool {
        // Get the system temporary directory
        let systemTempDir = FileManager.default.temporaryDirectory

        // Standardize both URLs to ensure consistent comparison
        let standardizedFolderURL = folderURL.standardizedFileURL
        let standardizedTempDir = systemTempDir.standardizedFileURL

        // Check if the folder is the system temporary directory or a subdirectory of it
        let isTempFolder = standardizedFolderURL.path.hasPrefix(standardizedTempDir.path)

        if isTempFolder {
            print("✅ The folder is within the system temporary directory: \(folderURL.path)")
        } else {
            print("🗂️ The folder is NOT within the system temporary directory: \(folderURL.path)")
        }

        return isTempFolder
    }
    
    /// Check if a given folder has been granted access
    func isFolderGranted(_ folderURL: URL) -> Bool {
        if isSystemTemporaryFolder(folderURL) {
            print("check folder is system temp , so return true")
            return true
        }

        let isGranted = grantedFolderURLs.contains { $0.standardizedFileURL == folderURL.standardizedFileURL }
        if isGranted {
            print("✅ Folder access granted: \(folderURL.path)")
        } else {
            print("❌ Folder access not granted: \(folderURL.path)")
        }
        return isGranted
    }

    /// Check if a file's folder is allowed, request access if not
    func folderAccessWithCallback(for fileURL: URL, completion: @escaping (Bool) -> Void) {
        let fileDirectory = fileURL.deletingLastPathComponent()

        if grantedFolderURLs.contains(fileDirectory) {
            print("✅ Folder is already allowed: \(fileDirectory.path)")
            completion(true)
        } else {
            print("❌ Folder is not allowed: \(fileDirectory.path), requesting access...")
            DispatchQueue.main.async {
                self.requestAccess(fileDirectory.path)
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
        // "APP_SANDBOX_CONTAINER_ID" is Optional("com.twindai.DropPdf")
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
