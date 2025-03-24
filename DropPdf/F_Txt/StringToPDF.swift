import Cocoa
import PDFKit

class StringToPDF {
    func getDidStart(fileURL: URL) -> Bool {
        return true
    }

    func getString(url: URL, str: String? = nil) -> String? {
            let content: String
            if let providedString = str {
                content = providedString
            } else {
                guard let loadedString = try? String(contentsOf: url, encoding: .utf8) else {
                    print("❌ ERROR: Failed to read text file at \(url.path)")
                    return nil
                }
                content = loadedString
            }
            return content
        }

    func drawInContent(ctx: CGContext, url: URL, box: CGRect, str: String? = nil) -> Bool {
        guard let string = getString(url: url, str: str) else {
            return false
        }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont(name: "Helvetica", size: 12) ?? NSFont.systemFont(ofSize: 12),
            .foregroundColor: NSColor.black,
            .paragraphStyle: paragraphStyle
        ]

        let attributedText = NSAttributedString(string: string, attributes: textAttributes)
        let framesetter = CTFramesetterCreateWithAttributedString(attributedText)
        var currentRange = CFRange(location: 0, length: 0)
        let textLength = attributedText.length
        let pageRect = box
        let textFrameRect = pageRect.insetBy(dx: 20, dy: 20)
        let path = CGPath(rect: textFrameRect, transform: nil)

        while currentRange.location < textLength {
            ctx.beginPDFPage(nil)  // ✅ Start page first

            let frame = CTFramesetterCreateFrame(framesetter, currentRange, path, nil)
            CTFrameDraw(frame, ctx)

            let visibleRange = CTFrameGetVisibleStringRange(frame)
            currentRange.location += visibleRange.length

            ctx.endPDFPage() // ✅ Close page after drawing
        }
        
        return true
    }
    
    func stringToPdf(fileURL: URL, string: String) async -> Bool {
        let drawInContentIns = StringToPDF().drawInContent
        let saveToPdfIns = SaveToPdf()

        guard let (pdfData, pdfContext, mediaBox) = saveToPdfIns.getPdfContext(595, 842, 0) else {
            print("❌ ERROR: Could not load image from \(fileURL.path)")
            return false
        }
        if drawInContentIns(pdfContext, fileURL, mediaBox, string) == false {
            return false
        }
        pdfContext.closePDF()
        return await saveToPdfIns.saveDataToPdf(fileURL: fileURL, data: pdfData as Data)
    }
}
