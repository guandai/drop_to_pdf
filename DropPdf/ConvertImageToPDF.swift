import Cocoa
import PDFKit

func convertImageToPDF(fileURL: URL) async -> Bool {
    return await withCheckedContinuation { continuation in
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.5) {
            // 🔹 1. Request security-scoped resource access
            let didStart = fileURL.startAccessingSecurityScopedResource()
            defer {
                if didStart {
                    fileURL.stopAccessingSecurityScopedResource()
                }
            }
            
            // 🔹 2. Load the image
            guard let image = NSImage(contentsOf: fileURL) else {
                print("❌ ERROR: Could not load image from \(fileURL.path)")
                return continuation.resume(returning: false)
            }
            
            // 🔹 3. Create PDF data buffer
            let pdfData = NSMutableData()
            guard let pdfConsumer = CGDataConsumer(data: pdfData as CFMutableData) else {
                print("❌ ERROR: Could not create PDF consumer")
                return continuation.resume(returning: false)
            }
            
            var mediaBox = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
            guard let pdfContext = CGContext(consumer: pdfConsumer, mediaBox: &mediaBox, nil) else {
                print("❌ ERROR: Could not create PDF context")
                return continuation.resume(returning: false)
            }
            
            pdfContext.beginPage(mediaBox: &mediaBox)
            NSGraphicsContext.saveGraphicsState()
            
            let graphicsContext = NSGraphicsContext(cgContext: pdfContext, flipped: false)
            NSGraphicsContext.current = graphicsContext
            
            image.draw(in: mediaBox)
            NSGraphicsContext.restoreGraphicsState()
            
            
            Task {
                let immutablePdfData = pdfData as Data // ✅ Convert NSMutableData to immutable Data
                let success = await saveToPdf(pdfContext: pdfContext, fileURL: fileURL, pdfData: immutablePdfData)
                continuation.resume(returning: success)
            }
            
        }
    }
}
