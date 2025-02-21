import Cocoa
import PDFKit

// ✅ Standalone function for TXT to PDF conversion
func myConvertTxtToPDF(txtFileURL: URL, appDelegate: AppDelegate) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        do {
            let text = try String(contentsOf: txtFileURL, encoding: .utf8)

            // 📌 Define A4 Page Size
            let pdfData = NSMutableData()
            let pdfConsumer = CGDataConsumer(data: pdfData as CFMutableData)!
            var mediaBox = CGRect(x: 0, y: 0, width: 595, height: 842)
            let pdfContext = CGContext(consumer: pdfConsumer, mediaBox: &mediaBox, nil)!

            pdfContext.beginPage(mediaBox: &mediaBox)
            NSGraphicsContext.saveGraphicsState()
            let graphicsContext = NSGraphicsContext(cgContext: pdfContext, flipped: false)
            NSGraphicsContext.current = graphicsContext

            // 🔥 Draw text manually
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .left

            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 12),
                .paragraphStyle: paragraphStyle
            ]

            let textRect = CGRect(x: 20, y: 20, width: 555, height: 800)
            NSString(string: text).draw(in: textRect, withAttributes: attributes)

            NSGraphicsContext.restoreGraphicsState()
            pdfContext.endPage()
            pdfContext.closePDF()

            // ✅ Generate Timestamp
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd_HHmm" // Format: YYYYMMDD_HHMM
            let timestamp = dateFormatter.string(from: Date())

            // ✅ Append Date-Time to Filename
            let originalFileName = txtFileURL.deletingPathExtension().lastPathComponent
            let newFileName = "\(originalFileName)_\(timestamp).pdf"

            // 📌 Get Folder Location from AppDelegate (for sandbox permissions)
            let folderURL: URL
            if let savedURL = appDelegate.getSavedFolderPermission() {
                folderURL = savedURL
            } else {
                folderURL = appDelegate.requestFolderPermission()
                appDelegate.saveFolderPermission(folderURL)
            }

            let pdfURL = folderURL.appendingPathComponent(newFileName)

            let success = pdfData.write(to: pdfURL, atomically: true)

            if success {
                print("✅ PDF successfully saved at: \(pdfURL.path)")
            } else {
                print("❌ ERROR: Failed to save PDF at: \(pdfURL.path)")
            }

        } catch {
            print("❌ ERROR: Failed to convert TXT to PDF: \(error)")
        }
    }
}
