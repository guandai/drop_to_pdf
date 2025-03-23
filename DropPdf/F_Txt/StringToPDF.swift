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

    func getContent(ctx: CGContext, url: URL, box: CGRect, str: String? = nil)  -> Bool {
            ctx.beginPDFPage(nil)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .left
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 12),
                .foregroundColor: NSColor.black,
                .paragraphStyle: paragraphStyle
            ]

            guard let string = getString(url: url, str: str) else {
                return false
            }
            
            let attributedText = NSAttributedString(string: string, attributes: textAttributes)
            let framesetter = CTFramesetterCreateWithAttributedString(attributedText)
            let framePath = CGPath(rect: box.insetBy(dx: 20, dy: 20), transform: nil)
            let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, attributedText.length), framePath, nil)
            CTFrameDraw(frame, ctx)
            return true
        }
    
    func toPdf(string: String, fileURL: URL) async -> Bool {
        let getContentIns = StringToPDF().getContent
        let saveToPdfIns = SaveToPdf()

        print(">>> StringToPDF toPdf")
        guard let (pdfData, pdfContext, mediaBox) = saveToPdfIns.getPdfContext(595, 842, 10) else {
            print("❌ ERROR: Could not load image from \(fileURL.path)")
            return false
        }
        if getContentIns(pdfContext, fileURL, mediaBox, string) == false {
            return false
        }
        saveToPdfIns.endContext(pdfContext)
        
        let immutablePdfData = pdfData as Data
        let success = await SaveToPdf().saveDataToPdf(fileURL: fileURL, pdfData: immutablePdfData)
        return success
    }
}
