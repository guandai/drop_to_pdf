import Cocoa
import PDFKit

class RtfToPDF {
    func getContent(_ pdfContext: CGContext, url: URL, box: CGRect) -> Bool {
        guard let image = NSImage(contentsOf: url) else {
            print("❌ ERROR: Could not load image from \(url.path)")
            return false
        }

        var mediaBox = box
        pdfContext.beginPage(mediaBox: &mediaBox)
        NSGraphicsContext.saveGraphicsState()
        let graphicsContext = NSGraphicsContext(
            cgContext: pdfContext, flipped: false)
        NSGraphicsContext.current = graphicsContext
        image.draw(in: mediaBox)
        NSGraphicsContext.restoreGraphicsState()

        return true
    }

    func convertRtfToPDF(fileURL: URL) async -> Bool {
        print(">> RtfToPDF")
        guard getDidStart(fileURL: fileURL) else {
            print("❌ Security-scoped resource access failed: \(fileURL.path)")
            return false
        }
        
        let result = await SaveToPdf().saveStringToPdf(fileURL: fileURL, text: "attributed.string")
        return result
    }

}
