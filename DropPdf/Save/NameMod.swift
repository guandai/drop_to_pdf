import Cocoa

struct NameMod {
    static func getTempFolder() -> URL {
        let tempFolder = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString) // Use a unique identifier

        do {
            try FileManager.default.createDirectory(
                at: tempFolder, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("❌ Failed to create temporary folder: \(error)")
        }
        return tempFolder
    }

    /// 🔹 Generates a timestamp string
    static func getTime() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"  // Format: YYYYMMDD_HHMM
        return dateFormatter.string(from: Date())
    }

    /// 🔹 Generates a timestamped file name
    static func getTimeName(name: String) -> String {
        return "\(name)_\(getTime()).pdf"
    }
    
    static func toFileString(_ initialPath: String) -> String {
        return (initialPath as NSString).expandingTildeInPath // Handle ~
            .replacingOccurrences(of: "file://", with: "") // Remove existing URL scheme
            .removingPercentEncoding ?? initialPath // Decode if pre-encoded
    }
    
    static func toFileString(_ initialURL: URL) -> String {
        return toFileString(initialURL.path())
    }
    
    static func toFileURL(_ initialPath: String) -> URL {
        return stringToURL(toFileString(initialPath))
    }
    
    static func toFileURL(_ initialURL: URL) -> URL {
        return toFileURL(initialURL.path())
    }
    
    static func stringToURL (_ path: String) -> URL {
        return URL(fileURLWithPath: path).standardized // Resolve symlinks
    }
    
    static func fixUtf8Url(_ fileURL: URL) -> URL {
        var fixURL = URL(
            fileURLWithPath: fileURL.path(), isDirectory: false
        ).standardized
            .resolvingSymlinksInPath()
        let fileName = fixURL.lastPathComponent.removingPercentEncoding ?? fixURL.lastPathComponent
        print(fileName)
        fixURL = fixURL.deletingLastPathComponent()
        fixURL = fixURL.appendingPathComponent(fileName)
        return fixURL
    }
    
    static func fixUtf8Url(_ fileString: String) -> URL {
        return fixUtf8Url(stringToURL(fileString))
    }
}
