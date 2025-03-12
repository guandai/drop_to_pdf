import Cocoa
import PDFKit

func convertImageToPDF(fileURL: URL) async -> Bool {
    return await withCheckedContinuation { continuation in
        DispatchQueue.main.async {
            // 🔹 1. Request security-scoped resource access
            guard StringImgToPDF().getDidStart(fileURL: fileURL) else {
                print("❌ Security-scoped resource access failed: \(fileURL.path)")
                 continuation.resume(returning: false)
                return
            }
                
            // 🔹 2. Load the image
            guard let image = NSImage(contentsOf: fileURL) else {
                print("❌ ERROR: Could not load image from \(fileURL.path)")
                 continuation.resume(returning: false)
                return
            }
            
            // 🔹 3. Create PDF data buffer
            let pdfData = NSMutableData()
            guard let pdfConsumer = CGDataConsumer(data: pdfData as CFMutableData) else {
                print("❌ ERROR: Could not create PDF consumer")
                 continuation.resume(returning: false)
                return
            }
            
            var mediaBox = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
            guard let pdfContext = CGContext(consumer: pdfConsumer, mediaBox: &mediaBox, nil) else {
                print("❌ ERROR: Could not create PDF context")
                 continuation.resume(returning: false)
                return
            }
            
            pdfContext.beginPage(mediaBox: &mediaBox)
            NSGraphicsContext.saveGraphicsState()
            
            let graphicsContext = NSGraphicsContext(cgContext: pdfContext, flipped: false)
            NSGraphicsContext.current = graphicsContext
            
            image.draw(in: mediaBox)
            NSGraphicsContext.restoreGraphicsState()

            pdfContext.endPage()
            pdfContext.closePDF()
            
            
            Task {
                let immutablePdfData = pdfData as Data // ✅ Convert NSMutableData to immutable Data
                let success = await saveToPdf(fileURL: fileURL, pdfData: immutablePdfData)
                continuation.resume(returning: success)
                return
            }
            
        }
    }
}
