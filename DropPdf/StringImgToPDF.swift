import Cocoa
import PDFKit

extension PDFDocument {
    /// Converts `PDFDocument` to `Data` while preserving images
    func toData() -> Data? {
        return self.dataRepresentation()
    }
}

class StringImgToPDF {
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
                    return
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

    func createPDF(docText: String, images: [Data], fileURL: URL) async -> Bool {
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let pdfDocument = PDFDocument()
                let pdfBounds = CGRect(x: 0, y: 0, width: 612, height: 792)

                // Create an image representation of the PDF page
                let pdfImage = NSImage(size: pdfBounds.size)
                pdfImage.lockFocus()

                // Create drawing context
                let context = NSGraphicsContext.current!.cgContext
                context.setFillColor(NSColor.white.cgColor)
                context.fill(pdfBounds)

                // Draw text
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .left
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 14),
                    .paragraphStyle: paragraphStyle
                ]
                docText.draw(in: CGRect(x: 20, y: 20, width: 572, height: 752), withAttributes: attributes)

                // ✅ Correctly Convert Each Data Object to NSImage
                var imageY: CGFloat = 100
                for imageData in images {
                    if let image = NSImage(data: imageData) {  // ✅ Convert each Data item separately
                        let imgRect = CGRect(x: 20, y: imageY, width: 200, height: 200)
                        image.draw(in: imgRect)
                        imageY += 220
                    }
                }

                pdfImage.unlockFocus()

                // Convert NSImage to PDFPage
                if let pdfPage = PDFPage(image: pdfImage) {
                    pdfDocument.insert(pdfPage, at: 0)
                }

                guard let pdfData = pdfDocument.dataRepresentation() else {
                    print("❌ ERROR: Failed to convert PDFDocument to Data")
                    continuation.resume(returning: false)
                    return
                }

                Task {
                    let success = await saveToPdf(fileURL: fileURL, pdfData: pdfData)
                    continuation.resume(returning: success)
                }
            }
        }
    }
}
