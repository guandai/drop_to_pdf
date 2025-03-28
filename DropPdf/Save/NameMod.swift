import Cocoa

struct NameMod {
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
}
