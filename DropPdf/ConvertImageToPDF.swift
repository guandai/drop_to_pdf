import Cocoa
import PDFKit

func convertImageToPDF(imageFileURL: URL) async -> Bool {
    return await withCheckedContinuation { continuation in
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.5) {
            
            // 🔹 1. Request security-scoped resource access
            let didStart = imageFileURL.startAccessingSecurityScopedResource()
            defer {
                if didStart {
                    imageFileURL.stopAccessingSecurityScopedResource()
                }
            }
            
            // 🔹 2. Load the image
            guard let image = NSImage(contentsOf: imageFileURL) else {
                print("❌ ERROR: Could not load image from \(imageFileURL.path)")
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

            // 🔹 4. Generate timestamped name
            let originalName = imageFileURL.deletingPathExtension().lastPathComponent
            let newName = getTimeName(name: originalName) // e.g. "photo_20250224_1322.pdf"
            
            // 🔹 5. Ensure we save in the same folder
            let pdfURL = imageFileURL.deletingLastPathComponent().appendingPathComponent(newName)

            // 🔹 6. Try writing the file to the same location
            do {
                try pdfData.write(to: pdfURL, options: .atomic)
                print("✅ Image PDF saved at: \(pdfURL.path)")
                continuation.resume(returning: true)
            } catch {
                print("❌ ERROR: Failed to save Image PDF at: \(pdfURL.path), Error: \(error)")
                continuation.resume(returning: false)
            }
        }
    }
}
