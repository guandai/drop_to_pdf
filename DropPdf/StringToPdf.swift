import Cocoa
import PDFKit

class StringToPdf {
    func toPdf(string: String, fileURL: URL) async -> Bool  {
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let pdfData = NSMutableData()
                let pdfConsumer = CGDataConsumer(
                    data: pdfData as CFMutableData
                )!
                var mediaBox = CGRect(x: 0, y: 0, width: 595, height: 842)
                let pdfContext = CGContext(
                    consumer: pdfConsumer,
                    mediaBox: &mediaBox,
                    nil
                )!
                
                pdfContext.beginPage(mediaBox: &mediaBox)
                NSGraphicsContext.saveGraphicsState()
                let graphicsContext = NSGraphicsContext(
                    cgContext: pdfContext,
                    flipped: false
                )
                NSGraphicsContext.current = graphicsContext
                
                // 🔥 Draw text inside PDF
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .left
                
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 12),
                    .paragraphStyle: paragraphStyle
                ]
                
                let textRect = CGRect(x: 20, y: 20, width: 555, height: 800)
                NSString(string: string)
                    .draw(in: textRect, withAttributes: attributes)
                NSGraphicsContext.restoreGraphicsState()

                pdfContext.endPage()
                pdfContext.closePDF()
                
                Task {
                    let immutablePdfData = pdfData as Data // ✅ Convert NSMutableData to immutable Data
                    let success = await saveToPdf(
                        fileURL: fileURL,
                        pdfData: immutablePdfData
                    )
                    continuation.resume(returning: success)
                }
            }
        }
    }
    
    func getDidStart (fileURL: URL) -> Bool {
        return true;
//        let didStart = fileURL.startAccessingSecurityScopedResource()
//        if didStart {
//            fileURL.stopAccessingSecurityScopedResource()
//            return true
//        }
//        return false
    }
}
