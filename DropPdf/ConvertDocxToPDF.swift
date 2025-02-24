import Cocoa
import PDFKit

func convertDocxToPDF(docFileURL: URL)  async -> Bool {
    return await withCheckedContinuation { continuation in
        DispatchQueue.main.async {
            guard let extractedText = extractTextFromDocx(docxFileURL: docFileURL) else {
                print("❌ ERROR: No text found in .docx")
                continuation.resume(returning: false)
                return
            }
            
            let pdfData = NSMutableData()
            let pdfConsumer = CGDataConsumer(data: pdfData as CFMutableData)!
            var mediaBox = CGRect(x: 0, y: 0, width: 595, height: 842)
            let pdfContext = CGContext(consumer: pdfConsumer, mediaBox: &mediaBox, nil)!
            
            pdfContext.beginPage(mediaBox: &mediaBox)
            NSGraphicsContext.saveGraphicsState()
            let graphicsContext = NSGraphicsContext(cgContext: pdfContext, flipped: false)
            NSGraphicsContext.current = graphicsContext
            
            // 🔥 Draw text inside PDF
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .left
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 12),
                .paragraphStyle: paragraphStyle
            ]
            
            let textRect = CGRect(x: 20, y: 20, width: 555, height: 800)
            NSString(string: extractedText).draw(in: textRect, withAttributes: attributes)
            
            NSGraphicsContext.restoreGraphicsState()
            pdfContext.endPage()
            pdfContext.closePDF()
            
            // ✅ Save PDF in same folder
            let originalName = docFileURL.deletingPathExtension().lastPathComponent
            let newName = getTimeName(name: originalName)
            let pdfURL = docFileURL.deletingLastPathComponent().appendingPathComponent(newName)
            
//            let pdfURL = docFileURL.deletingPathExtension().appendingPathExtension("pdf")
            let success = pdfData.write(to: pdfURL, atomically: true)
            
            if success {
                print("✅ PDF successfully saved at: \(pdfURL.path)")
                continuation.resume(returning: true)
            } else {
                print("❌ ERROR: Failed to save PDF")
                continuation.resume(returning: false)
            }
        }
    }
}
