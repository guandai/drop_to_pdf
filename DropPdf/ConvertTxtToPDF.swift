import Cocoa
import PDFKit



func getPdfContext() {
    let pdfData = NSMutableData()
    guard let pdfConsumer = CGDataConsumer(data: pdfData as CFMutableData) else {
        print("❌ ERROR: Could not create PDF consumer")
        return  false
    }
    var mediaBox = CGRect(x: 0, y: 0, width: cgWidth, height: cgheight)
    guard let pdfContext = CGContext(consumer: pdfConsumer, mediaBox: &mediaBox, nil) else {
        print("❌ Failed to create PDF pdfContext")
        return  false
    }

    return (pdfData, pdfContext)
}

func convertTxtToPDF(fileURL: URL) async -> Bool {
    return await withCheckedContinuation { continuation in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard getDidStart(fileURL: fileURL) else {
                print("❌ Security-scoped resource access failed: \(fileURL.path)")
                continuation.resume(returning: false)
                return
            }
            
            var string = ""
            do {
                string = try String(contentsOf: fileURL, encoding: .utf8)
            } catch {
                print("❌ ERROR: Failed to read text file, Error: \(error)")
                continuation.resume(returning: false)
                return
            }
            // 🧠 Create a PDF page with the text
            let pdfPage = PDFPage()
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 12),
                .foregroundColor: NSColor.black
            ]
            let attributedText = NSAttributedString(string: string, attributes: textAttributes)
             // A4 size in points
            let cgWidth = 595
            let cgheight = 842

            /////.
            
            //////


            pdfContext.beginPDFPage(nil)
            let framesetter = CTFramesetterCreateWithAttributedString(attributedText)
            let framePath = CGPath(rect: pageRect.insetBy(dx: 20, dy: 20), transform: nil)
            let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, attributedText.length), framePath, nil)
            CTFrameDraw(frame, pdfContext)


            //////  final
            pdfContext.endPDFPage()
            pdfContext.closePDF()





            // 🔹 2. Load the image
            // step 3 
            guard let image = NSImage(contentsOf: fileURL) else {
                print("❌ ERROR: Could not load image from \(fileURL.path)")
                 continuation.resume(returning: false)
                return
            }
            let cgWidth = image.size.width
            let cgheight = image.size.height
            // run share

            
            pdfContext.beginPage(mediaBox: &mediaBox)
            NSGraphicsContext.saveGraphicsState()
            let graphicsContext = NSGraphicsContext(cgContext: pdfContext, flipped: false)
            NSGraphicsContext.current = graphicsContext
            image.draw(in: mediaBox)
            NSGraphicsContext.restoreGraphicsState()

            
            //////  final

            
            Task {
                let immutablePdfData = pdfData as Data
                let success = await saveToPdf(fileURL: fileURL, pdfData: immutablePdfData)
                continuation.resume(returning: success)
            }
        }
    }
}
