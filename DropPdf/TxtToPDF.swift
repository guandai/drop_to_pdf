import Cocoa
import PDFKit

class TxtToPDF {
    func getContent(_ pdfContext: CGContext, url: URL, box: CGRect)  -> Bool {
        pdfContext.beginPDFPage(nil)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: NSColor.black,
            .paragraphStyle: paragraphStyle
        ]
        guard let string = try? String(contentsOf: url, encoding: .utf8) else {
            print("❌ ERROR: Failed to read text file at \(url.path)")
            return false
        }
        
        let attributedText = NSAttributedString(string: string, attributes: textAttributes)
        let framesetter = CTFramesetterCreateWithAttributedString(attributedText)
        let framePath = CGPath(rect: box.insetBy(dx: 20, dy: 20), transform: nil)
        let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, attributedText.length), framePath, nil)
        CTFrameDraw(frame, pdfContext)
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
                
                guard let (pdfData, pdfContext, mediaBox) = saveToPdfIns.getPdfContext(cgWidth:595, cgHeight:842) else {
                    print("❌ ERROR: Could not load image from \(fileURL.path)")
                    continuation.resume(returning: false)
                    return
                }
                
                if renderContent(pdfContext, fileURL, mediaBox) == false {
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
