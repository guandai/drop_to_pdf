import Cocoa
import PDFKit

enum FileProcessingError: Error {
    case unsupportedFileType
}

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 🔹 Bring the app to the foreground after launching
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func application(_ application: NSApplication, open urls: [URL]) {
        print("📂 Dropped onto app icon: \(urls.map { $0.path }.joined(separator: ", "))")
        
        Task {
            await processDroppedFiles(urls)
        }

        // 🔹 Bring the app window to the foreground
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    /// Processes multiple dropped files asynchronously
    func processDroppedFiles(_ urls: [URL]) async {
        for url in urls {
            print("📂 Dropped file: \(url.path)")
            
            let success = await processOneFile(url: url)

            if !success {
                print("❌ ERROR: Unsupported file type or failed conversion → \(url.lastPathComponent)")
            }
        }
    }
    
    /// Processes a single file and determines the correct conversion method
    func processOneFile(url: URL) async -> Bool {
        print("📂 Processing file: \(url.path)")
        
        if isImageFile(url: url) {
            return await convertImageToPDF(fileURL: url)
        } else if isTextFile(url: url) {
            return await convertTxtToPDF(fileURL: url, appDelegate: self)
        } else if isDocx(url: url) {
            return await convertDocxToPDF(fileURL: url)
        } else if url.pathExtension.lowercased() == "doc" {
            return await convertDocToPDF(fileURL: url)
        } else {
            print("⚠️ Unsupported file type → \(url.lastPathComponent)")
            return false
        }
    }

    /// Check if the app has Full Disk Access
    func checkFullDiskAccess() {
        let restrictedPath = "/Library/Application Support/com.apple.TCC"
        if FileManager.default.isReadableFile(atPath: restrictedPath) {
            print("✅ Full Disk Access is enabled.")
        } else {
            print("⚠️ Full Disk Access is NOT enabled. Prompting user...")
            DispatchQueue.main.async {
                openFullDiskAccessSettings()
            }
        }
    }
    

    /// Checks if the file is a valid text file
    func isTextFile(url: URL) -> Bool {
        return (try? String(contentsOf: url, encoding: .utf8)) != nil
    }

    /// Checks if the file is an image
    func isImageFile(url: URL) -> Bool {
        return NSImage(contentsOf: url) != nil
    }

    /// Checks if the file is a DOCX
    func isDocx(url: URL) -> Bool {
        return url.pathExtension.lowercased() == "docx"
    }
}

/// 🔹 Generates a timestamp string
func getTime() -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyyMMdd_HHmm" // Format: YYYYMMDD_HHMM
    return dateFormatter.string(from: Date())
}

/// 🔹 Generates a timestamped file name
func getTimeName(name: String) -> String {
    return "\(name)_\(getTime()).pdf"
}
