import Cocoa
import PDFKit


class RtfToPDF {
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

    func convertRtfToPDF(fileURL: URL) async -> Bool {
        print(">> RtfToPDF")
//        let renderContent = self.getContent
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
//                let saveToPdfIns = SaveToPdf()
                guard getDidStart(fileURL: fileURL) else {
                    print("❌ Security-scoped resource access failed: \(fileURL.path)")
                    continuation.resume(returning: false)
                    return
                }
                
                
                
            }
        }
    }

}
