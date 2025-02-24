import Foundation

struct PermissionsManager {
    static func hasFullDiskAccess() -> Bool {
        let testPath = "/Library/Application Support"
        return FileManager.default.isReadableFile(atPath: testPath)
    }
}
