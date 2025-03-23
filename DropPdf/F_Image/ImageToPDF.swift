import Cocoa
import PDFKit

class ImageToPDF {
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

    func convertImageToPDF(fileURL: URL) async -> Bool {
        print(">> convertImageToPDF")
        let renderContent = self.getContent

        let saveToPdfIns = SaveToPdf()
        guard getDidStart(fileURL: fileURL) else {
            print("❌ Security-scoped resource access failed: \(fileURL.path)")
            return false
        }

        guard let image = NSImage(contentsOf: fileURL) else {
            print("❌ ERROR: Could not load image from \(fileURL.path)")
            return false
        }

        guard
            let (pdfData, pdfContext, mediaBox) = saveToPdfIns.getPdfContext(
                image.size.width, image.size.height)
        else {
            print("❌ ERROR: Could not load image from \(fileURL.path)")
            return false
        }

        if renderContent(pdfContext, fileURL, mediaBox) == false {
            return false
        }

        saveToPdfIns.endContext(pdfContext)

        let immutablePdfData = pdfData as Data
        let success = await saveToPdfIns.saveDataToPdf(
            fileURL: fileURL, pdfData: immutablePdfData)
        return success
    }
}
