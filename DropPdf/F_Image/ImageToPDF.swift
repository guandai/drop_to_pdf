import Cocoa
import PDFKit

class ImageToPDF {
    func drawInContent(_ pdfContext: CGContext, url: URL, box: CGRect) -> Bool {
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

    func convertImageToPDF(fileURL: URL) async -> Bool {
        print(">> convertImageToPDF")
        let drawInContentIns = self.drawInContent

        guard getDidStart(fileURL: fileURL) else {
            print("❌ Security-scoped resource access failed: \(fileURL.path)")
            return false
        }

        guard let image = NSImage(contentsOf: fileURL) else {
            print("❌ ERROR: Could not load image from \(fileURL.path)")
            return false
        }

        let saveToPdfIns = SaveToPdf()
        guard
            let (pdfData, pdfContext, mediaBox) = saveToPdfIns.getPdfContext(
                image.size.width, image.size.height)
        else {
            print("❌ ERROR: Could not load image from \(fileURL.path)")
            return false
        }

        if drawInContentIns(pdfContext, fileURL, mediaBox) == false {
            return false
        }

        saveToPdfIns.endContext(pdfContext)
        return await saveToPdfIns.saveDataToPdf(fileURL: fileURL, data: pdfData as Data)
    }
}
