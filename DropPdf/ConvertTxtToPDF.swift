import Cocoa
import PDFKit

func convertTxtToPDF(txtFileURL: URL, appDelegate: AppDelegate) async -> Bool  {
    let folderManager = FolderManager()

    return await withCheckedContinuation { continuation in        
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

                // 🔹 4. Generate timestamped name
                let originalName = txtFileURL.deletingPathExtension().lastPathComponent
                let newName = getTimeName(name: originalName) // e.g. "photo_20250224_1322.pdf"
                
                // 🔹 5. Ensure we save in the same folder
                let pdfURL = txtFileURL.deletingLastPathComponent().appendingPathComponent(newName)

                // 🔹 6. Try writing the file to the same location
                do {
                    try pdfData.write(to: pdfURL, options: .atomic)
                    print("✅ Image PDF saved at: \(pdfURL.path)")
                    continuation.resume(returning: true)
                } catch {
                    print("❌ ERROR: Failed to save Image PDF at: \(pdfURL.path), Error: \(error)")
                    continuation.resume(returning: false)
                }
                
            } catch {
                print("❌ ERROR: Failed to convert TXT to PDF: \(error)")
                continuation.resume(returning: false)
                return
            }
        }
    }
}
