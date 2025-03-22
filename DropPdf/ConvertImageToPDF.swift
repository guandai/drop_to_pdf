import Cocoa
import PDFKit


class ImageToPDF {
    func getContent(_ pdfContext: CGContext, url: URL, box: CGRect)  -> Bool {
        guard let image = NSImage(contentsOf: url) else {
            print("❌ ERROR: Could not load image from \(url.path)")
            return false
        }

        var mediaBox = box
        pdfContext.beginPage(mediaBox: &mediaBox)
        NSGraphicsContext.saveGraphicsState()
        let graphicsContext = NSGraphicsContext(cgContext: pdfContext, flipped: false)
        NSGraphicsContext.current = graphicsContext
        image.draw(in: mediaBox)
        NSGraphicsContext.restoreGraphicsState()
        
        return true
    }

    func convertImageToPDF(fileURL: URL) async -> Bool {
        let renderContent = self.getContent
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let toPdf = SaveToPdf()
                guard getDidStart(fileURL: fileURL) else {
                    print("❌ Security-scoped resource access failed: \(fileURL.path)")
                    continuation.resume(returning: false)
                    return
                }
                    
                guard let image = NSImage(contentsOf: fileURL) else {
                    print("❌ ERROR: Could not load image from \(fileURL.path)")
                    continuation.resume(returning: false)
                    return
                }
                
                guard let (pdfData, pdfContext, mediaBox) = toPdf.getPdfContext(
                    cgWidth:Int(image.size.width), cgHeight:Int(image.size.height)) else {
                    print("❌ ERROR: Could not load image from \(fileURL.path)")
                    continuation.resume(returning: false)
                    return
                }
                
                if renderContent(pdfContext, fileURL, mediaBox) == false {
                    continuation.resume(returning: false)
                    return
                }

                toPdf.endContext(pdfContext)
                
                Task {
                    let immutablePdfData = pdfData as Data // ✅ Convert NSMutableData to immutable Data
                    let success = await toPdf.saveToPdf(fileURL: fileURL, pdfData: immutablePdfData)
                    continuation.resume(returning: success)
                    return
                }
                
            }
        }
    }

}
