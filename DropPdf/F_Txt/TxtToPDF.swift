import Cocoa
import PDFKit

class TxtToPDF {
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
    
    func convertTxtToPDF(fileURL: URL) async -> Bool {
        print(">> convertTxtToPDF")
        let renderContent = self.getContent
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let saveToPdfIns = SaveToPdf()
                
                guard getDidStart(fileURL: fileURL) else {
                    print("❌ Security-scoped resource access failed: \(fileURL.path)")
                    continuation.resume(returning: false)
                    return
                }
                
                guard let (pdfData, pdfContext, mediaBox) = saveToPdfIns.getPdfContext(595, 842) else {
                    print("❌ ERROR: Could not load image from \(fileURL.path)")
                    continuation.resume(returning: false)
                    return
                }
                
                if renderContent(pdfContext, fileURL, mediaBox, nil) == false {
                    continuation.resume(returning: false)
                    return
                }
                
                saveToPdfIns.endContext(pdfContext)
                
                Task {
                    let immutablePdfData = pdfData as Data
                    let success = await SaveToPdf().saveToPdf(fileURL: fileURL, pdfData: immutablePdfData)
                    continuation.resume(returning: success)
                }
            }
        }
    }
}
