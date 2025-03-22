import Cocoa
import PDFKit



func getPdfContext(cgWidth: Int, cgHeight: Int) -> (NSMutableData, CGContext, CGRect)? {
    let pdfData = NSMutableData()
    guard let pdfConsumer = CGDataConsumer(data: pdfData as CFMutableData) else {
        print("❌ ERROR: Could not create PDF consumer")
        return nil
    }
    var mediaBox = CGRect(x: 0, y: 0, width: cgWidth, height: cgHeight)
    guard let pdfContext = CGContext(consumer: pdfConsumer, mediaBox: &mediaBox, nil) else {
        print("❌ Failed to create PDF pdfContext")
        return nil
    }

    return (pdfData, pdfContext, mediaBox)
}
func endContext(_ pdfContext: CGContext) {
    pdfContext.endPage()
    pdfContext.closePDF()
}

func textContent(_ pdfContext: CGContext, fileURL: URL, mediaBox: CGRect)  -> Bool {
    pdfContext.beginPDFPage(nil)
    let textAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 12),
        .foregroundColor: NSColor.black
    ]
    guard let string = try? String(contentsOf: fileURL, encoding: .utf8) else {
        print("❌ ERROR: Failed to read text file at \(fileURL.path)")
        return false
    }
    let attributedText = NSAttributedString(string: string, attributes: textAttributes)
    let framesetter = CTFramesetterCreateWithAttributedString(attributedText)
    let framePath = CGPath(rect: mediaBox.insetBy(dx: 20, dy: 20), transform: nil)
    let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, attributedText.length), framePath, nil)
    CTFrameDraw(frame, pdfContext)
    return true
}

func convertTxtToPDF(fileURL: URL) async -> Bool {
    return await withCheckedContinuation { continuation in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard getDidStart(fileURL: fileURL) else {
                print("❌ Security-scoped resource access failed: \(fileURL.path)")
                continuation.resume(returning: false)
                return
            }

            guard let (pdfData, pdfContext, mediaBox) = getPdfContext(cgWidth:595, cgHeight:842) else {
                print("❌ ERROR: Could not load image from \(fileURL.path)")
                continuation.resume(returning: false)
                return
            }

            
            if textContent(pdfContext, fileURL: fileURL, mediaBox: mediaBox) == false {
                continuation.resume(returning: false)
                return
            }

            endContext(pdfContext)
            
            Task {
                let immutablePdfData = pdfData as Data
                let success = await saveToPdf(fileURL: fileURL, pdfData: immutablePdfData)
                continuation.resume(returning: success)
            }
        }
    }
}
