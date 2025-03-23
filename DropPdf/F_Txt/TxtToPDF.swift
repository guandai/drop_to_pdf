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
        let getStr = self.getString
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let saveToPdfIns = SaveToPdf()
                
                guard getDidStart(fileURL: fileURL) else {
                    print("❌ Security-scoped resource access failed: \(fileURL.path)")
                    continuation.resume(returning: false)
                    return
                }
                
                let (_, finalPath) = saveToPdfIns.getPathes(fileURL)
                let myText = getStr(fileURL, nil)

                if let text = myText {
                    let result = PrintToPDF().exportTextToPDF(text: text, to: finalPath)
                    continuation.resume(returning: result)
                    return
                }
                
                continuation.resume(returning: false)
            }
        }
    }
}
