import Cocoa
import PDFKit

func convertDocxToPDF(fileURL: URL)  async -> Bool {
    return await withCheckedContinuation { continuation in
        DispatchQueue.main.async {
            guard let extractedText = extractTextFromDocx(docxFileURL: fileURL) else {
                print("❌ ERROR: No text found in .docx")
                return continuation.resume(returning: false)
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
            
            Task {
                let success = await saveToPdf(pdfContext: pdfContext, fileURL: fileURL, pdfData: pdfData)
                continuation.resume(returning: success)
            }
        }
    }
}
