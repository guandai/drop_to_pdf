import Cocoa
import PDFKit

func convertTxtToPDF(fileURL: URL, appDelegate: AppDelegate) async -> Bool {
    return await withCheckedContinuation { continuation in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            do {
                let text = try String(contentsOf: fileURL, encoding: .utf8)
                
                // 📌 Define A4 Page Size
                let pdfData = NSMutableData()
                let pdfConsumer = CGDataConsumer(data: pdfData as CFMutableData)!
                var mediaBox = CGRect(x: 0, y: 0, width: 595, height: 842)
                let pdfContext = CGContext(consumer: pdfConsumer, mediaBox: &mediaBox, nil)!
                
                pdfContext.beginPage(mediaBox: &mediaBox)
                NSGraphicsContext.saveGraphicsState()
                let graphicsContext = NSGraphicsContext(cgContext: pdfContext, flipped: false)
                NSGraphicsContext.current = graphicsContext
                
                // 🔥 Ensure Text is Drawn
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .left

                let attributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 12),
                    .paragraphStyle: paragraphStyle
                ]

                let textRect = CGRect(x: 20, y: 20, width: 555, height: 800)
                NSString(string: text).draw(in: textRect, withAttributes: attributes)
                
                // ✅ Restore Graphics Context
                NSGraphicsContext.restoreGraphicsState()

                // ✅ Make sure the page is ended before closing the PDF
                pdfContext.endPage()
                pdfContext.closePDF() // Ensure this is called **after** drawing text
                
                Task {
                    let success = await saveToPdf(pdfContext: pdfContext, fileURL: fileURL, pdfData: pdfData as Data)
                    continuation.resume(returning: success)
                }
            } catch {
                print("❌ ERROR: Failed to read text file, Error: \(error)")
                continuation.resume(returning: false)
            }
        }
    }
}
