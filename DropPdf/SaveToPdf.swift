import Cocoa
import PDFKit

func saveToPdf(pdfContext: CGContext, fileURL: URL, pdfData: NSMutableData) async -> Bool {
    return await withCheckedContinuation { continuation in
        
        pdfContext.endPage()
        pdfContext.closePDF()

        // 🔹 Generate timestamped name
        let originalName = fileURL.deletingPathExtension().lastPathComponent
        let newName = getTimeName(name: originalName) // e.g. "photo_20250224_1322.pdf"

        // 🔹 Save temporary PDF in Documents folder
        let tempDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let tempPDF = tempDir.appendingPathComponent(newName) // ✅ Use full file path

        do {
            try pdfData.write(to: tempPDF, options: .atomic)

            // 🔹 Final destination in OneDrive
            let finalPath = fileURL.deletingLastPathComponent().appendingPathComponent(newName)
            
            try FileManager.default.copyItem(at: tempPDF, to: finalPath) // ✅ Correct copy method

            print("✅ Successfully copied PDF to OneDrive: \(finalPath.path)")
            continuation.resume(returning: true)
        } catch {
            print("❌ ERROR: Failed to copy PDF, Error: \(error)")
            continuation.resume(returning: false)
        }
    }
}
