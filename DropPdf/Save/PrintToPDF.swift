import Cocoa

class PrintToPDF {
    func getPrintInfo(_ finalPath: URL) -> NSPrintInfo {
        let margin: CGFloat = 30
        let printInfo = NSPrintInfo()
            printInfo.horizontalPagination = .automatic
            printInfo.verticalPagination = .automatic
            printInfo.paperSize = NSSize(width: 595, height: 842)
            printInfo.topMargin = margin
            printInfo.bottomMargin = margin
            printInfo.leftMargin = margin
            printInfo.rightMargin = margin
            printInfo.isHorizontallyCentered = true
            printInfo.isVerticallyCentered = false
            printInfo.jobDisposition = .save
            printInfo.dictionary()[
                NSPrintInfo.AttributeKey(
                    rawValue: NSPrintInfo.AttributeKey.jobSavingURL.rawValue)] =
                finalPath
        return printInfo
    }
    
    func runOpration(view printView: ContentPrintView, info printInfo: NSPrintInfo) -> Bool {
        let operation = NSPrintOperation(view: printView, printInfo: printInfo)
            operation.showsPrintPanel = false
            operation.showsProgressPanel = false

        let runResult = operation.run()
        print(runResult ? "✅ runResult PDF saved" : "❌ runResult PDF generation failed")
        return runResult
    }
    
    func getAttributedText(fileURL: URL, docType: NSAttributedString.DocumentType) -> NSAttributedString? {
        if docType == .html {
            return HtmlPrinter().getHtmlAttributedText(fileURL)
        }
        
        guard let attributedText = try? NSAttributedString(
            url: fileURL,
            options: [.documentType: docType],
            documentAttributes: nil)
        else {
            print("❌ Failed to load RTFD package from \(fileURL.path)")
            return nil
        }
        return attributedText
    }
    
    func printContentToPDF(finalPath: URL, fileURL: URL, docType: NSAttributedString.DocumentType) async -> Bool {
        let result = await MainActor.run { () -> Bool in
            guard let attributedText = getAttributedText(fileURL: fileURL, docType: docType) else {
                return false
            }

            let printView = ContentPrintView(
                frame: NSRect(x: 0, y: 0, width: 595, height: 842),
                attributedText: attributedText
            )
            print(">> get print view")
            return runOpration(view: printView, info: getPrintInfo(finalPath))
        }
        return result
    }
}
