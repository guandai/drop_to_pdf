import Cocoa
import PDFKit

func saveToPdf(pdfContext: CGContext, fileURL: URL, pdfData: Data) async -> Bool {
    return await withCheckedContinuation { continuation in
        
        pdfContext.endPage()
        pdfContext.closePDF()

        // 🔹 Generate timestamped name
        let originalName = fileURL.deletingPathExtension().lastPathComponent
        let newName = getTimeName(name: originalName) // e.g. "photo_20250224_1322.pdf"
            
        do {
            let finalPath = fileURL.deletingLastPathComponent().appendingPathComponent(newName)
            
            if PermissionsManager().isAppSandboxed() {
                _ = PermissionsManager().askUserToSavePDF(proposedFilename: finalPath.lastPathComponent, data: pdfData)
            }
            
            try pdfData.write(to: finalPath, options: .atomic)
            print("✅ Successfully copied PDF to OneDrive: \(finalPath.path)")
            continuation.resume(returning: true)
        } catch {
            print("❌ ERROR: Failed to copy PDF, Error: \(error)")
            continuation.resume(returning: false)
        }
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
