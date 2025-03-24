import Cocoa

class PrintToPDF {
    func getPrintInfo(_ finalPath: URL) -> NSPrintInfo {
        let printInfo = NSPrintInfo()
            printInfo.horizontalPagination = .automatic
            printInfo.verticalPagination = .automatic
            printInfo.paperSize = NSSize(width: 595, height: 842)
            printInfo.topMargin = 20
            printInfo.bottomMargin = 20
            printInfo.leftMargin = 20
            printInfo.rightMargin = 20
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
        print(runResult ? "✅ PDF saved" : "❌ PDF generation failed")
        return runResult
    }

    func printContentToPDF( finalPath: URL, fileURL: URL, docType: NSAttributedString.DocumentType) async -> Bool {
        guard let data = try? Data(contentsOf: fileURL) else {
            print("❌ Failed to load RTF data")
            return false
        }
        
        let result = await MainActor.run { () -> Bool in
            guard let attributedText = try? NSAttributedString(
                data: data,
                options: [.documentType: docType],
                documentAttributes: nil
            ) else {
                print("❌ Failed to load attributed text and content as \(docType)")
                return false
            }
            let printView = ContentPrintView(
                frame: NSRect(x: 0, y: 0, width: 595, height: 842),
                attributedText: attributedText
            )
            return runOpration(view: printView, info: getPrintInfo(finalPath))
        }
        return result
    }
}
